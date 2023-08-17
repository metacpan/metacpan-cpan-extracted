# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Reporter';

use strict;
use warnings;

use Mail::Box::Message;
use Mail::Box::Locker;
use File::Spec;

use Carp;
use Scalar::Util 'weaken';
use List::Util   qw/sum first/;
use Devel::GlobalDestruction 'in_global_destruction';


#-------------------------------------------


use overload '@{}' => sub { shift->{MB_messages} }
           , '""'  => 'name'
           , 'cmp' => sub {$_[0]->name cmp "${_[1]}"};

#-------------------------------------------


sub new(@)
{   my $class        = shift;

    if($class eq __PACKAGE__)
    {   my $package = __PACKAGE__;

        croak <<USAGE;
You should not instantiate $package directly, but rather one of the
sub-classes, such as Mail::Box::Mbox.  If you need automatic folder
type detection then use Mail::Box::Manager.
USAGE
    }

    my %args = @_;
    weaken $args{manager};   # otherwise, the manager object may live too long

    my $self = $class->SUPER::new
      ( @_
      , init_options => \%args     # for clone
      ) or return;

    $self->read or return
        if $self->{MB_access} =~ /r|a/;

    $self;
}

sub init($)
{   my ($self, $args) = @_;

    return unless defined $self->SUPER::init($args);

    my $class      = ref $self;
    my $foldername = $args->{folder} || $ENV{MAIL};
    unless($foldername)
    {   $self->log(ERROR => "No folder name specified.");
        return;
    }

    $self->{MB_foldername}   = $foldername;
    $self->{MB_init_options} = $args->{init_options};
    $self->{MB_coerce_opts}  = $args->{coerce_options} || [];
    $self->{MB_access}       = $args->{access}         || 'r';
    $self->{MB_remove_empty}
         = defined $args->{remove_when_empty} ? $args->{remove_when_empty} : 1;

    $self->{MB_save_on_exit}
         = defined $args->{save_on_exit} ? $args->{save_on_exit} : 1;

    $self->{MB_messages}     = [];
    $self->{MB_msgid}        = {};
    $self->{MB_organization} = $args->{organization}      || 'FILE';
    $self->{MB_linesep}      = "\n";
    $self->{MB_keep_dups}    = !$self->writable || $args->{keep_dups};
    $self->{MB_fix_headers}  = $args->{fix_headers};

    my $folderdir = $self->folderdir($args->{folderdir});
    $self->{MB_trusted}      = exists $args->{trusted} ? $args->{trusted}
      : substr($foldername, 0, 1) eq '='               ? 1
      : !defined $folderdir                            ? 0
      : substr($foldername, 0, length $folderdir) eq $folderdir;

    if(exists $args->{manager})
    {   $self->{MB_manager}  = $args->{manager};
        weaken($self->{MB_manager});
    }

    my $message_type = $self->{MB_message_type}
        = $args->{message_type}     || $class . '::Message';
    $self->{MB_body_type}
        = $args->{body_type}        || 'Mail::Message::Body::Lines';
    $self->{MB_body_delayed_type}
        = $args->{body_delayed_type}|| 'Mail::Message::Body::Delayed';
    $self->{MB_head_delayed_type}
        = $args->{head_delayed_type}|| 'Mail::Message::Head::Delayed';
    $self->{MB_multipart_type}
        = $args->{multipart_type}   || 'Mail::Message::Body::Multipart';
    $self->{MB_field_type}          = $args->{field_type};

    my $headtype     = $self->{MB_head_type}
        = $args->{head_type}        || 'Mail::Message::Head::Complete';

    my $extract  = $args->{extract} || 'extractDefault';
    $self->{MB_extract}
      = ref $extract eq 'CODE' ? $extract
      : $extract eq 'ALWAYS'   ? sub {1}
      : $extract eq 'LAZY'     ? sub {0}
      : $extract eq 'NEVER'    ? sub {1}  # compatibility
      : $extract =~ m/\D/      ? sub {no strict 'refs';shift->$extract(@_)}
      :     sub { my $size = $_[1]->guessBodySize;
                  defined $size && $size < $extract;
                };

    #
    # Create a locker.
    #

    $self->{MB_locker}
      = $args->{locker}
      || Mail::Box::Locker->new
          ( folder   => $self
          , method   => $args->{lock_type}
          , timeout  => $args->{lock_timeout}
          , expires  => $args->{lock_wait}
          , file     => ($args->{lockfile} || $args->{lock_file})
          , $self->logSettings
          );

    $self;
}

#-------------------------------------------


sub folderdir(;$)
{   my $self = shift;
    $self->{MB_folderdir} = shift if @_;
    $self->{MB_folderdir};
}

sub foundIn($@) { shift->notImplemented }


sub name() {shift->{MB_foldername}}


sub type() {shift->notImplemented}


sub url()
{   my $self = shift;
    $self->type . ':' . $self->name;
}


sub size() { sum map { $_->size } shift->messages('ACTIVE') }


sub update(@)
{   my $self = shift;

    $self->updateMessages
      ( trusted      => $self->{MB_trusted}
      , head_type    => $self->{MB_head_type}
      , field_type   => $self->{MB_field_type}
      , message_type => $self->{MB_message_type}
      , body_delayed_type => $self->{MB_body_delayed_type}
      , head_delayed_type => $self->{MB_head_delayed_type}
      , @_
      );

    $self;
}


sub organization() { shift->notImplemented }


sub addMessage($@)
{   my $self    = shift;
    my $message = shift or return $self;
    my %args    = @_;

    confess <<ERROR if $message->can('folder') && defined $message->folder;
You cannot add a message which is already part of a folder to a new
one.  Please use moveTo or copyTo.
ERROR

    # Force the message into the right folder-type.
    my $coerced = $self->coerce($message);
    $coerced->folder($self);

    unless($coerced->head->isDelayed)
    {   # Do not add the same message twice, unless keep_dups.
        my $msgid = $coerced->messageId;

        unless($self->{MB_keep_dups})
        {   if(my $found = $self->messageId($msgid))
            {   $coerced->label(deleted => 1);
                return $found;
            }
        }

        $self->messageId($msgid, $coerced);
        $self->toBeThreaded($coerced);
    }

    $self->storeMessage($coerced);
    $coerced;
}


sub addMessages(@)
{   my $self = shift;
    map $self->addMessage($_), @_;
}


sub copyTo($@)
{   my ($self, $to, %args) = @_;

    my $select      = $args{select} || 'ACTIVE';
    my $subfolders  = exists $args{subfolders} ? $args{subfolders} : 1;
    my $can_recurse = not $self->isa('Mail::Box::POP3');

    my ($flatten, $recurse)
       = $subfolders eq 'FLATTEN' ? (1, 0)
       : $subfolders eq 'RECURSE' ? (0, 1)
       : !$subfolders             ? (0, 0)
       : $can_recurse             ? (0, 1)
       :                            (1, 0);

    my $delete = $args{delete_copied} || 0;
    my $share  = $args{share}         || 0;

    $self->_copy_to($to, $select, $flatten, $recurse, $delete, $share);
}

# Interface may change without warning.
sub _copy_to($@)
{   my ($self, $to, @options) = @_;
    my ($select, $flatten, $recurse, $delete, $share) = @options;

    $self->log(ERROR => "Destination folder $to is not writable."),
        return unless $to->writable;

    # Take messages from this folder.
    my @select = $self->messages($select);
    $self->log(PROGRESS =>
        "Copying ".@select." messages from $self to $to.");

    foreach my $msg (@select)
    {   if($msg->copyTo($to, share => $share))
             { $msg->label(deleted => 1) if $delete }
        else { $self->log(ERROR => "Copying failed for one message.") }
    }

    return $self unless $flatten || $recurse;

    # Take subfolders

  SUBFOLDER:
    foreach ($self->listSubFolders(check => 1))
    {   my $subfolder = $self->openSubFolder($_, access => 'r');
        $self->log(ERROR => "Unable to open subfolder $_"), next
            unless defined $subfolder;

        if($flatten)   # flatten
        {    unless($subfolder->_copy_to($to, @options))
             {   $subfolder->close;
                 return;
             }
        }
        else           # recurse
        {    my $subto = $to->openSubFolder($_, create => 1, access => 'rw');
             unless($subto)
             {   $self->log(ERROR => "Unable to create subfolder $_ of $to");
                 next SUBFOLDER;
             }

             unless($subfolder->_copy_to($subto, @options))
             {   $subfolder->close;
                 $subto->close;
                 return;
             }

             $subto->close;
        }

        $subfolder->close;
    }

    $self;
}


sub close(@)
{   my ($self, %args) = @_;
    my $force = $args{force} || 0;

    return 1 if $self->{MB_is_closed};
    $self->{MB_is_closed}++;

    # Inform manager that the folder is closed.
    my $manager = delete $self->{MB_manager};
    $manager->close($self, close_by_self =>1)
        if defined $manager && !$args{close_by_manager};

    my $write;
    for($args{write} || 'MODIFIED')
    {   $write = $_ eq 'MODIFIED' ? $self->isModified
               : $_ eq 'ALWAYS'   ? 1
               : $_ eq 'NEVER'    ? 0
               : croak "Unknown value to folder->close(write => $_).";
    }

    my $locker = $self->locker;
    if($write && !$force && !$self->writable)
    {   $self->log(WARNING => "Changes not written to read-only folder $self.
Suggestion: \$folder->close(write => 'NEVER')");
    	$locker->unlock if $locker;
        $self->{MB_messages} = [];    # Boom!
        return 0;
    }

    my $rc = !$write
          || $self->write
               ( force => $force
               , save_deleted => $args{save_deleted} || 0
               );

    $locker->unlock if $locker;
    $self->{MB_messages} = [];                  # Boom!
    $rc;
}


sub delete(@)
{   my ($self, %args) = @_;
    my $recurse = exists $args{recursive} ? $args{recursive} : 1;

    # Extra protection: do not remove read-only folders.
    unless($self->writable)
    {   $self->log(ERROR => "Folder $self not deleted: not writable.");
        $self->close(write => 'NEVER');
        return;
    }

    # Sub-directories need to be removed first.
    if($recurse)
    {   foreach ($self->listSubFolders)
        {   my $sub = $self->openRelatedFolder
               (folder => "$self/$_", access => 'd', create => 0);
            defined $sub && $sub->delete(%args);
        }
    }

    $self->close(write => 'NEVER');
    $self;
}

#-------------------------------------------


sub appendMessages(@) {shift->notImplemented}

#-------------------------------------------


sub writable()  {shift->{MB_access} =~ /w|a|d/ }
sub writeable() {shift->writable}  # compatibility [typo]
sub readable()  {1}  # compatibility


sub access()    {shift->{MB_access}}


sub modified(;$)
{   my $self = shift;
    return $self->isModified unless @_;   # compat 2.036

    return
      if $self->{MB_modified} = shift;    # force modified flag

    # unmodify all messages
    $_->modified(0) foreach $self->messages;
    0;
}


sub isModified()
{   my $self     = shift;
    return 1 if $self->{MB_modified};

    foreach (@{$self->{MB_messages}})
    {    return $self->{MB_modified} = 1
            if $_->isDeleted || $_->isModified;
    }

    0;
}

#-------------------------------------------


sub message(;$$)
{   my ($self, $index) = (shift, shift);
    @_ ?  $self->{MB_messages}[$index] = shift : $self->{MB_messages}[$index];
}


sub messageId($;$)
{   my ($self, $msgid) = (shift, shift);

    if($msgid =~ m/\<([^>]+)\>/s )
    {   $msgid = $1;
        $msgid =~ s/\s//gs;

        $self->log(WARNING => "Message-id '$msgid' does not contain a domain.")
            unless index($msgid, '@') >= 0;
    }

    return $self->{MB_msgid}{$msgid} unless @_;

    my $message = shift;

    # Undefine message?
    unless($message)
    {   delete $self->{MB_msgid}{$msgid};
        return;
    }

    my $double = $self->{MB_msgid}{$msgid};
    if(defined $double && !$self->{MB_keep_dups})
    {   my $head1 = $message->head;
        my $head2 = $double->head;

        my $subj1 = $head1->get('subject') || '';
        my $subj2 = $head2->get('subject') || '';

        my $to1   = $head1->get('to') || '';
        my $to2   = $head2->get('to') || '';

        # Auto-delete doubles.
        return $message->label(deleted => 1)
            if $subj1 eq $subj2 && $to1 eq $to2;

        $self->log(WARNING => "Different messages with id $msgid");
        $msgid = $message->takeMessageId(undef);
    }

    $self->{MB_msgid}{$msgid} = $message;
    weaken($self->{MB_msgid}{$msgid});
    $message;
}

sub messageID(@) {shift->messageId(@_)} # compatibility


sub find($)
{   my ($self, $msgid) = (shift, shift);
    my $msgids = $self->{MB_msgid};

    if($msgid =~ m/\<([^>]*)\>/s)
    {   $msgid = $1;
        $msgid =~ s/\s//gs;
    }
    else
    {   # Illegal message-id
        $msgid =~ s/\s/+/gs;
    }

    $self->scanForMessages(undef, $msgid, 'EVER', 'ALL')
        unless exists $msgids->{$msgid};

    $msgids->{$msgid};
}


sub messages($;$)
{   my $self = shift;

    return @{$self->{MB_messages}} unless @_;
    my $nr = @{$self->{MB_messages}};

    if(@_==2)   # range
    {   my ($begin, $end) = @_;
        $begin += $nr   if $begin < 0;
        $begin  = 0     if $begin < 0;
        $end   += $nr   if $end < 0;
        $end    = $nr-1 if $end >= $nr;

        return () if $begin > $end;

        my @range = @{$self->{MB_messages}}[$begin..$end];
        return @range;
    }

    my $what = shift;
    my $action
      = ref $what eq 'CODE'? $what
      : $what eq 'DELETED' ? sub {$_[0]->isDeleted}
      : $what eq 'ACTIVE'  ? sub {not $_[0]->isDeleted}
      : $what eq 'ALL'     ? sub {1}
      : $what =~ s/^\!//   ? sub {not $_[0]->label($what)}
      :                      sub {$_[0]->label($what)};

    grep {$action->($_)} @{$self->{MB_messages}};
}


sub nrMessages(@) { scalar shift->messages(@_) }


sub messageIds()    { map {$_->messageId} shift->messages }
sub allMessageIds() {shift->messageIds}  # compatibility
sub allMessageIDs() {shift->messageIds}  # compatibility


sub current(;$)
{   my $self = shift;

    unless(@_)
    {   return $self->{MB_current}
           if exists $self->{MB_current};
	
        # Which one becomes current?
	my $current
	  = $self->findFirstLabeled(current => 1)
	 || $self->findFirstLabeled(seen    => 0)
	 || $self->message(-1)
	 || return undef;

        $current->label(current => 1);
        $self->{MB_current} = $current;
	return $current;
    }

    my $next = shift;
    if(my $previous = $self->{MB_current})
    {    $previous->label(current => 0);
    }

    ($self->{MB_current} = $next)->label(current => 1);
    $next;
}


sub scanForMessages($$$$)
{   my ($self, $startid, $msgids, $moment, $window) = @_;

    # Set-up msgid-list
    my %search = map +($_ => 1), ref $msgids ? @$msgids : $msgids;
    return () unless keys %search;

    # do not run on empty folder
    my $nr_messages = $self->messages
        or return keys %search; 

    my $startmsg = defined $startid ? $self->messageId($startid) : undef;

    # Set-up window-bound.
    my $bound = 0;
    if($window ne 'ALL' && defined $startmsg)
    {   $bound = $startmsg->seqnr - $window;
        $bound = 0 if $bound < 0;
    }

    my $last = ($self->{MBM_last} || $nr_messages) -1;
    return keys %search if defined $bound && $bound > $last;

    # Set-up time-bound
    my $after = $moment eq 'EVER'   ? 0
              : $moment =~ m/^\d+$/ ? $moment
              : !$startmsg          ? 0
              : $startmsg->timestamp - $self->timespan2seconds($moment);

    while($last >= $bound)
    {   my $message = $self->message($last);
        my $msgid   = $message->messageId; # triggers load

        if(delete $search{$msgid})  # where we looking for this one?
        {    last unless keys %search;
        }

        last if $message->timestamp < $after;
        $last--;
    }

    $self->{MBM_last} = $last;
    keys %search;
}


sub findFirstLabeled($;$$)
{   my ($self, $label, $set, $msgs) = @_;

    if(!defined $set || $set)
    {   my $f = first { $_->label($label) }
           (defined $msgs ? @$msgs : $self->messages);
    }
    else
    {   return first { not $_->label($label) }
           (defined $msgs ? @$msgs : $self->messages);
    }
}

#-------------------------------------------


sub listSubFolders(@) { () }   # by default no sub-folders


sub openRelatedFolder(@)
{   my $self    = shift;
    my @options = (%{$self->{MB_init_options}}, @_);

    $self->{MB_manager}
    ? $self->{MB_manager}->open(type => ref($self), @options)
    : (ref $self)->new(@options);
}


sub openSubFolder($@)
{   my $self = shift;
    my $name = $self->nameOfSubFolder(shift);
    $self->openRelatedFolder(@_, folder => $name);
}


sub nameOfSubFolder($;$)
{   my ($thing, $name) = (shift, shift);
    my $parent = @_ ? shift : ref $thing ? $thing->name : undef;
    defined $parent ? "$parent/$name" : $name;
}


sub topFolderWithMessages() { 1 }

#-------------------------------------------


sub read(@)
{   my $self = shift;
    $self->{MB_open_time}    = time;

    local $self->{MB_lazy_permitted} = 1;

    # Read from existing folder.
    return unless $self->readMessages
      ( trusted      => $self->{MB_trusted}
      , head_type    => $self->{MB_head_type}
      , field_type   => $self->{MB_field_type}
      , message_type => $self->{MB_message_type}
      , body_delayed_type => $self->{MB_body_delayed_type}
      , head_delayed_type => $self->{MB_head_delayed_type}
      , @_
      );

    if($self->{MB_modified})
    {   $self->log(INTERNAL => "Modified $self->{MB_modified}");
        $self->{MB_modified} = 0;  #after reading, no changes found yet.
    }

    $self;
}

#-------------------------------------------


sub write(@)
{   my ($self, %args) = @_;

    unless($args{force} || $self->writable)
    {   $self->log(ERROR => "Folder $self is opened read-only.");
        return;
    }

    my (@keep, @destroy);
    if($args{save_deleted})
    {   @keep = $self->messages;
    }
    else
    {   foreach ($self->messages)
        {   if($_->isDeleted)
            {   push @destroy, $_;
                $_->diskDelete;
            }
            else {push @keep, $_}
        }
    }

    unless(@destroy || $self->isModified)
    {   $self->log(PROGRESS => "Folder $self not changed, so not updated.");
        return $self;
    }

    $args{messages} = \@keep;
    unless($self->writeMessages(\%args))
    {   $self->log(WARNING => "Writing folder $self failed.");
        return undef;
    }

    $self->modified(0);
    $self->{MB_messages} = \@keep;

    $self;
}


sub determineBodyType($$)
{   my ($self, $message, $head) = @_;

    return $self->{MB_body_delayed_type}
        if $self->{MB_lazy_permitted}
        && ! $message->isPart
        && ! $self->{MB_extract}->($self, $head);

    my $bodytype = $self->{MB_body_type};
    ref $bodytype ? $bodytype->($head) : $bodytype;
}

sub extractDefault($)
{   my ($self, $head) = @_;
    my $size = $head->guessBodySize;
    defined $size ? $size < 10000 : 0  # immediately extract < 10kb
}

sub lazyPermitted($)
{   my $self = shift;
    $self->{MB_lazy_permitted} = shift;
}


sub storeMessage($)
{   my ($self, $message) = @_;

    push @{$self->{MB_messages}}, $message;
    $message->seqnr( @{$self->{MB_messages}} -1);
    $message;
}


my %seps = (CR => "\015", LF => "\012", CRLF => "\015\012");

sub lineSeparator(;$)
{   my $self = shift;
    return $self->{MB_linesep} unless @_;

   my $sep   = shift;
   $sep = $seps{$sep} if exists $seps{$sep};

   $self->{MB_linesep} = $sep;
   $_->lineSeparator($sep) foreach $self->messages;
   $sep;
}


sub create($@) {shift->notImplemented}



sub coerce($@)
{   my ($self, $message) = (shift, shift);
    my $mmtype = $self->{MB_message_type};
    $message->isa($mmtype) ? $message : $mmtype->coerce($message, @_);
}


sub readMessages(@) {shift->notImplemented}


sub updateMessages(@) { shift }


sub writeMessages(@) {shift->notImplemented}


sub locker() { shift->{MB_locker} }


sub toBeThreaded(@)
{   my $self = shift;

    my $manager = $self->{MB_manager}
       or return $self;

    $manager->toBeThreaded($self, @_);
    $self;
}


sub toBeUnthreaded(@)
{   my $self = shift;

    my $manager = $self->{MB_manager}
       or return $self;

    $manager->toBeThreaded($self, @_);
    $self;
}

#-------------------------------------------


sub timespan2seconds($)
{
    if( $_[1] =~ /^\s*(\d+\.?\d*|\.\d+)\s*(hour|day|week)s?\s*$/ )
    {     $2 eq 'hour' ? $1 * 3600
        : $2 eq 'day'  ? $1 * 86400
        :                $1 * 604800;  # week
    }
    else
    {   $_[0]->log(ERROR => "Invalid timespan '$_' specified.");
        undef;
    }
}

#-------------------------------------------


sub DESTROY
{   my $self = shift;
    $self->close unless in_global_destruction || $self->{MB_is_closed};
}

#-------------------------------------------


1;
