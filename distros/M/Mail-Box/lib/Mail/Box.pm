# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box;{
our $VERSION = '4.01';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error info mistake panic trace warning/ ];

use Mail::Box::Message     ();
use Mail::Box::Locker      ();

use Scalar::Util           qw/weaken/;
use List::Util             qw/sum first/;
use Devel::GlobalDestruction 'in_global_destruction';

#--------------------

#--------------------

use overload
	'@{}' => sub { $_[0]->{MB_messages} },
	'""'  => 'name',
	'cmp' => sub { $_[0]->name cmp "${_[1]}" };

#--------------------

sub new(@)
{	my ($class, %args) = @_;

	if($class eq __PACKAGE__)
	{	my $package = __PACKAGE__;

		print STDERR <<USAGE;
You should not instantiate $package directly, but rather one of the
sub-classes, such as Mail::Box::Mbox.  If you need automatic folder
type detection then use Mail::Box::Manager.
USAGE
		exit 1;
	}

	weaken $args{manager};   # otherwise, the manager object may live too long
	my $self = $class->SUPER::new(%args, init_options => \%args);

	$self->read or return
		if $self->{MB_access} =~ /r|a/;

	$self;
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	my $class      = ref $self;
	my $foldername = $args->{folder} || $ENV{MAIL}
		or error __x"no folder name specified.";

	$self->{MB_foldername}   = $foldername;
	$self->{MB_init_options} = $args->{init_options};
	$self->{MB_coerce_opts}  = $args->{coerce_options} || [];
	$self->{MB_access}       = $args->{access}         || 'r';
	$self->{MB_remove_empty} = exists $args->{remove_when_empty} ? $args->{remove_when_empty} : 1;
	$self->{MB_save_on_exit} = exists $args->{save_on_exit} ? $args->{save_on_exit} : 1;
	$self->{MB_messages}     = [];
	$self->{MB_msgid}        = {};
	$self->{MB_organization} = $args->{organization} || 'FILE';
	$self->{MB_linesep}      = "\n";
	$self->{MB_keep_dups}    = $args->{keep_dups};
	$self->{MB_fix_headers}  = $args->{fix_headers};

	my $folderdir = $self->folderdir($args->{folderdir});
	$self->{MB_trusted}      = exists $args->{trusted} ? $args->{trusted}
	  : substr($foldername, 0, 1) eq '='               ? 1
	  : !defined $folderdir                            ? 0
	  :    substr($foldername, 0, length $folderdir) eq $folderdir;

	if(exists $args->{manager})
	{	$self->{MB_manager}  = $args->{manager};
		weaken($self->{MB_manager});
	}

	$self->{MB_message_type}      = $args->{message_type}      || $class . '::Message';
	$self->{MB_head_type}         = $args->{head_type}         || 'Mail::Message::Head::Complete';
	$self->{MB_body_type}         = $args->{body_type}         || 'Mail::Message::Body::Lines';
	$self->{MB_body_delayed_type} = $args->{body_delayed_type} || 'Mail::Message::Body::Delayed';
	$self->{MB_head_delayed_type} = $args->{head_delayed_type} || 'Mail::Message::Head::Delayed';
	$self->{MB_multipart_type}    = $args->{multipart_type}    || 'Mail::Message::Body::Multipart';
	$self->{MB_field_type}        = $args->{field_type};

	my $extract  = $args->{extract} || 'extractDefault';
	$self->{MB_extract}
	  = ref $extract eq 'CODE' ? $extract
	  : $extract eq 'ALWAYS'   ? sub { 1 }
	  : $extract eq 'LAZY'     ? sub { 0 }
	  : $extract eq 'NEVER'    ? sub { 1 }  # compatibility
	  : $extract =~ m/\D/      ? sub { no strict 'refs'; shift->$extract(@_) }
	  :   sub { my $size = $_[1]->guessBodySize; defined $size && $size < $extract };

	#
	# Create a locker.
	#

	$self->{MB_locker} = $args->{locker} || Mail::Box::Locker->new(
		folder   => $self,
		method   => $args->{lock_type},
		timeout  => $args->{lock_timeout},
		expires  => $args->{lock_wait},
		file     => ($args->{lockfile} || $args->{lock_file}),
	);

	$self;
}

#--------------------

sub removeEmpty() { $_[0]->{MB_remove_empty} }


sub folderdir(;$) {	my $self = shift; @_ ? $self->{MB_folderdir} = shift : $self->{MB_folderdir} }


sub type() { $_[0]->notImplemented }


sub name() { $_[0]->{MB_foldername} }


sub isTrusted()  { $_[0]->{MB_trusted} }
sub fixHeaders() { $_[0]->{MB_fix_headers} }

#--------------------

sub foundIn($@) { $_[0]->notImplemented }


sub url()
{	my $self = shift;
	$self->type . ':' . $self->name;
}


sub size() { sum 0, map $_->size, $_[0]->messages('ACTIVE') }


sub update(@)
{	my $self = shift;

	$self->updateMessages(
		trusted      => $self->isTrusted,
		head_type    => $self->{MB_head_type},
		field_type   => $self->{MB_field_type},
		message_type => $self->{MB_message_type},
		body_delayed_type => $self->{MB_body_delayed_type},
		head_delayed_type => $self->{MB_head_delayed_type},
		@_,
	);

	$self;
}


sub organization() { $_[0]->notImplemented }


sub addMessage($@)
{	my $self    = shift;
	my $message = shift or return $self;
	my %args    = @_;

	$message->can('folder') && defined $message->folder
		and error __x"you cannot add a message which is already part of a folder to a new one.  Please use moveTo or copyTo.";

	# Force the message into the right folder-type.
	my $coerced = $self->coerce($message);
	$coerced->folder($self);

	unless($coerced->head->isDelayed)
	{	# Do not add the same message twice, unless keep_dups.
		my $msgid = $coerced->messageId;

		unless($self->{MB_keep_dups})
		{	if(my $found = $self->messageId($msgid))
			{	$coerced->label(deleted => 1);
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
{	my $self = shift;
	map $self->addMessage($_), @_;
}


sub copyTo($@)
{	my ($self, $to, %args) = @_;

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
{	my ($self, $to, @options) = @_;
	my ($select, $flatten, $recurse, $delete, $share) = @options;

	$to->writable
		or error __x"destination folder {name} is not writable.", name => $to;

	# Take messages from this folder.
	my @select = $self->messages($select);
	trace "Copying ".@select." messages from $self to $to.";

	foreach my $msg (@select)
	{	$msg->copyTo($to, share => $share)
			or error __x"copying failed for one message.";

		$msg->label(deleted => 1) if $delete;
	}

	$flatten || $recurse
		or return $self;

	# Take subfolders

  SUBFOLDER:
	foreach my $subf ($self->listSubFolders(check => 1))
	{	my $subfolder = $self->openSubFolder($subf, access => 'r');

		if($flatten)   # flatten
		{	unless($subfolder->_copy_to($to, @options))
			{	$subfolder->close;
				return;
			}
		}
		else           # recurse
		{	my $subto = $to->openSubFolder($subf, create => 1, access => 'rw');
			unless($subfolder->_copy_to($subto, @options))
			{	$subfolder->close;
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
{	my ($self, %args) = @_;
	my $force = $args{force} || 0;

	return 1 if $self->{MB_is_closed};
	$self->{MB_is_closed}++;

	# Inform manager that the folder is closed.
	my $manager = delete $self->{MB_manager};
	$manager->close($self, close_by_self =>1)
		if defined $manager && !$args{close_by_manager};

	my $when  = $args{write} // 'MODIFIED';
	my $write
	  = $when eq 'MODIFIED' ? $self->isModified
	  : $when eq 'ALWAYS'   ? 1
	  : $when eq 'NEVER'    ? 0
	  :    error __x"unknown value to folder->close(write => {when}).", when => $when;

	my $locker = $self->locker;
	if($write && !$force && !$self->writable)
	{	warning __x"changes not written to read-only folder {name}; suggestion: \$folder->close(write => 'NEVER')", name => $self->name;
		$locker->unlock if $locker;
		$self->{MB_messages} = [];    # Boom!
		return 0;
	}

	my $rc = ! $write ||
		$self->write(force => $force, save_deleted => $args{save_deleted} || 0);

	$locker->unlock if $locker;
	$self->{MB_messages} = [];                  # Boom!
	$rc;
}


sub delete(@)
{	my ($self, %args) = @_;
	my $recurse = exists $args{recursive} ? $args{recursive} : 1;

	# Extra protection: do not remove read-only folders.
	unless($self->writable)
	{	warning __x"folder {name} not deleted: not writable.", name => $self->name;
		$self->close(write => 'NEVER');
		return;
	}

	# Sub-directories need to be removed first.
	if($recurse)
	{	foreach ($self->listSubFolders)
		{	my $sub = $self->openRelatedFolder (folder => "$self/$_", access => 'd', create => 0);
			defined $sub && $sub->delete(%args);
		}
	}

	$self->close(write => 'NEVER');
	$self;
}


sub appendMessages(@) { $_[0]->notImplemented }

#--------------------

sub writable()  { $_[0]->access =~ /w|a|d/ }
sub writeable() { $_[0]->writable }  # compatibility [typo]
sub readable()  { 1 }  # compatibility


sub access(;$)  { my $self = shift; @_ ? $self->{MB_access} = shift : $self->{MB_access} }


sub modified(;$)
{	my $self = shift;
	@_ or return $self->isModified;   # compat 2.036

	return
		if $self->{MB_modified} = shift;    # force modified flag

	# Unmodify all messages as well
	$_->modified(0) for $self->messages;
	0;
}


sub isModified()
{	my $self     = shift;
	return 1 if $self->{MB_modified};

	foreach my $msg (@{$self->{MB_messages}})
	{	return $self->{MB_modified} = 1
			if $msg->isDeleted || $msg->isModified;
	}
$self->{MB_modified} = first { $_->isModified } @{$self->{MB_messages}};

	0;
}

#--------------------

sub message(;$$)
{	my ($self, $index) = (shift, shift);
	@_ ? $self->{MB_messages}[$index] = shift : $self->{MB_messages}[$index];
}


sub messageId($;$)
{	my ($self, $msgid) = (shift, shift);

	if($msgid =~ m/\<([^>]+)\>/s )
	{	$msgid = $1 =~ s/\s//grs;

		index($msgid, '@') >= 0
			or warning __x"message-id '{msgid}' does not contain a domain.", msgid => $msgid;
	}

	@_ or return $self->{MB_msgid}{$msgid};

	my $message = shift;

	# Undefine message?
	unless($message)
	{	delete $self->{MB_msgid}{$msgid};
		return;
	}

	my $double = $self->{MB_msgid}{$msgid};
	if(defined $double && !$self->{MB_keep_dups})
	{	my $head1 = $message->head;
		my $head2 = $double->head;

		my $subj1 = $head1->get('subject') || '';
		my $subj2 = $head2->get('subject') || '';

		my $to1   = $head1->get('to') || '';
		my $to2   = $head2->get('to') || '';

		# Auto-delete doubles.
		return $message->label(deleted => 1)
			if $subj1 eq $subj2 && $to1 eq $to2;

		warning __x"different messages with id {msgid}.", msgid => $msgid;
		$msgid = $message->takeMessageId(undef);
	}

	$self->{MB_msgid}{$msgid} = $message;
	weaken($self->{MB_msgid}{$msgid});
	$message;
}

sub messageID(@) { shift->messageId(@_) } # compatibility


sub find($)
{	my ($self, $msgid) = (shift, shift);
	my $msgids = $self->{MB_msgid};

	if($msgid =~ m/\<([^>]*)\>/s)
	{	$msgid = $1 =~ s/\s//grs;
	}
	else
	{	# Illegal message-id
		$msgid =~ s/\s/+/gs;
	}

	$msgids->{$msgid} // $self->scanForMessages(undef, $msgid, 'EVER', 'ALL');
}


sub messages($;$)
{	my $self = shift;
	my $msgs = $self->{MB_messages};

	@_ or return @$msgs;

	if(@_==2)   # range
	{	my ($begin, $end) = @_;
		my $nr = @$msgs;
		$begin += $nr   if $begin < 0;
		$begin  = 0     if $begin < 0;
		$end   += $nr   if $end < 0;
		$end    = $nr-1 if $end >= $nr;
		return $begin > $end ? () : @{$msgs}[$begin..$end];
	}

	my $what = shift;
	my $action
	  = ref $what eq 'CODE'? $what
	  : $what eq 'DELETED' ? sub { $_[0]->isDeleted }
	  : $what eq 'ACTIVE'  ? sub { not $_[0]->isDeleted }
	  : $what eq 'ALL'     ? sub { 1 }
	  : $what =~ s/^\!//   ? sub { not $_[0]->label($what) }
	  :                      sub { $_[0]->label($what) };

	grep $action->($_), @$msgs;
}


sub nrMessages(@) { scalar shift->messages(@_) }


sub messageIds()    { map $_->messageId, $_[0]->messages }
sub allMessageIds() { $_[0]->messageIds }  # compatibility
sub allMessageIDs() { $_[0]->messageIds }  # compatibility


sub current(;$)
{	my $self = shift;

	unless(@_)
	{	return $self->{MB_current}
			if exists $self->{MB_current};

		# Which one becomes current?
		my $current
		   = $self->findFirstLabeled(current => 1)
		  || $self->findFirstLabeled(seen    => 0)
		  || $self->message(-1)
		  || return undef;

		$current->label(current => 1);
		return $self->{MB_current} = $current;
	}

	my $next = shift;
	if(my $previous = $self->{MB_current})
	{	$previous->label(current => 0);
	}

	($self->{MB_current} = $next)->label(current => 1);
	$next;
}


sub scanForMessages($$$$)
{	my ($self, $startid, $msgids, $moment, $window) = @_;

	# Set-up msgid-list
	my %search = map +($_ => 1), ref $msgids ? @$msgids : $msgids;
	keys %search or return ();

	# do not run on empty folder
	my $nr_messages = $self->messages
		or return keys %search;

	my $startmsg = defined $startid ? $self->messageId($startid) : undef;

	# Set-up window-bound.
	my $bound = 0;
	if($window ne 'ALL' && defined $startmsg)
	{	$bound = $startmsg->seqnr - $window;
		$bound = 0 if $bound < 0;
	}

	my $last = ($self->{MBM_last} || $nr_messages) -1;
	return keys %search if defined $bound && $bound > $last;

	# Set-up time-bound
	my $after
	  = $moment eq 'EVER'   ? 0
	  : $moment =~ m/^\d+$/ ? $moment
	  : !$startmsg          ? 0
	  :    $startmsg->timestamp - $self->timespan2seconds($moment);

	while($last >= $bound)
	{	my $message = $self->message($last);
		my $msgid   = $message->messageId; # triggers load

		if(delete $search{$msgid})  # where we looking for this one?
		{	keys %search or last;
		}

		last if $message->timestamp < $after;
		$last--;
	}

	$self->{MBM_last} = $last;
	keys %search;
}


sub findFirstLabeled($;$$)
{	my ($self, $label, $set, $msgs) = @_;

	  !defined $set || $set
	? (first {     $_->label($label) } (defined $msgs ? @$msgs : $self->messages))
	: (first { not $_->label($label) } (defined $msgs ? @$msgs : $self->messages));
}

#--------------------

sub listSubFolders(@) { () }   # by default no sub-folders


sub openRelatedFolder(@)
{	my $self    = shift;
	my @options = (%{$self->{MB_init_options}}, @_);

	  $self->{MB_manager}
	? $self->{MB_manager}->open(type => ref($self), @options)
	: (ref $self)->new(@options);
}


sub openSubFolder($@)
{	my $self = shift;
	my $name = $self->nameOfSubFolder(shift);
	$self->openRelatedFolder(@_, folder => $name);
}


sub nameOfSubFolder($;$)
{	my ($thing, $name) = (shift, shift);
	my $parent = @_ ? shift : ref $thing ? $thing->name : undef;
	defined $parent ? "$parent/$name" : $name;
}


sub topFolderWithMessages() { 1 }

#--------------------

sub read(@)
{	my $self = shift;
	$self->{MB_open_time}    = time;

	local $self->{MB_lazy_permitted} = 1;

	# Read from existing folder.
	$self->readMessages(
		trusted      => $self->{MB_trusted},
		head_type    => $self->{MB_head_type},
		field_type   => $self->{MB_field_type},
		message_type => $self->{MB_message_type},
		body_delayed_type => $self->{MB_body_delayed_type},
		head_delayed_type => $self->{MB_head_delayed_type},
		@_
	) or return;

	$self->{MB_modified} and panic "Modified $self->{MB_modified}";
	$self;
}


sub write(@)
{	my ($self, %args) = @_;

	$args{force} || $self->writable
		or error __x"folder {name} is opened read-only.", name => $self->name;

	my (@keep, @destroy);
	if($args{save_deleted})
	{	@keep = $self->messages;
	}
	else
	{	foreach my $msg ($self->messages)
		{	if($msg->isDeleted)
			{	push @destroy, $msg;
				$msg->diskDelete;
			}
			else { push @keep, $msg }
		}
	}

	@destroy || $self->isModified
		or trace("Folder $self not changed, so not updated."), return $self;

	$args{messages} = \@keep;
	$self->writeMessages(\%args);
	$self->modified(0);
	$self->{MB_messages} = \@keep;
	$self;
}


sub determineBodyType($$)
{	my ($self, $message, $head) = @_;

	return $self->{MB_body_delayed_type}
		if $self->{MB_lazy_permitted}
		&& ! $message->isPart
		&& ! $self->{MB_extract}->($self, $head);

	my $bodytype = $self->{MB_body_type};
	ref $bodytype ? $bodytype->($head) : $bodytype;
}

sub extractDefault($)
{	my ($self, $head) = @_;
	my $size = $head->guessBodySize;
	defined $size ? $size < 10000 : 0  # immediately extract < 10kb
}

sub lazyPermitted($)
{	my $self = shift;
	$self->{MB_lazy_permitted} = shift;
}


sub storeMessage($)
{	my ($self, $message) = @_;

	push @{$self->{MB_messages}}, $message;
	$message->seqnr( @{$self->{MB_messages}} -1);
	$message;
}


my %seps = (CR => "\015", LF => "\012", CRLF => "\015\012");

sub lineSeparator(;$)
{	my $self = shift;
	@_ or return $self->{MB_linesep};

	my $sep  = shift;
	$sep = $seps{$sep} if exists $seps{$sep};

	$self->{MB_linesep} = $sep;
	$_->lineSeparator($sep) for $self->messages;
	$sep;
}


sub create($@) { $_[0]->notImplemented }



sub coerce($@)
{	my ($self, $message) = (shift, shift);
	my $mmtype = $self->{MB_message_type};
	$message->isa($mmtype) ? $message : $mmtype->coerce($message, @_);
}


sub readMessages(@) { $_[0]->notImplemented }


sub updateMessages(@) { $_[0] }


sub writeMessages(@) { $_[0]->notImplemented }


sub locker() { $_[0]->{MB_locker} }


sub toBeThreaded(@)
{	my $self = shift;
	my $manager = $self->{MB_manager} or return $self;
	$manager->toBeThreaded($self, @_);
	$self;
}


sub toBeUnthreaded(@)
{	my $self = shift;
	my $manager = $self->{MB_manager} or return $self;
	$manager->toBeThreaded($self, @_);
	$self;
}

#--------------------

sub timespan2seconds($)
{
	$_[1] =~ /^\s*(\d+\.?\d*|\.\d+)\s*(hour|day|week)s?\s*$/
		or error(__x"invalid timespan '{span}'.", span => $_[1]), return undef;

	  $2 eq 'hour' ? $1 * 3600
	: $2 eq 'day'  ? $1 * 86400
	:                $1 * 604800;  # week
}

#--------------------

sub DESTROY
{	my $self = shift;
	in_global_destruction || $self->{MB_is_closed}
		or $self->close;
}

#--------------------

1;
