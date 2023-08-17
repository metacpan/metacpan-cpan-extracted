# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::File;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box';

use strict;
use warnings;

use filetest 'access';

use Mail::Box::File::Message;

use Mail::Message::Body::Lines;
use Mail::Message::Body::File;
use Mail::Message::Body::Delayed;
use Mail::Message::Body::Multipart;

use Mail::Message::Head;

use Carp;
use File::Copy;
use File::Spec;
use File::Basename;
use POSIX ':unistd_h';

# tell() is not available for open(my $fh) on perl versions <= 5.10  So,
# we need to stick to IO::File syntax.
use IO::File;

my $windows;
BEGIN { $windows = $^O =~ m/mswin32/i }


my $default_folder_dir = exists $ENV{HOME} ? $ENV{HOME} . '/Mail' : '.';

sub _default_body_type($$)
{   my $size = shift->guessBodySize || 0;
    'Mail::Message::Body::'.($size > 100000 ? 'File' : 'Lines');
}

sub init($)
{   my ($self, $args) = @_;
    $args->{folderdir} ||= $default_folder_dir;
    $args->{body_type} ||= \&_default_body_type;
    $args->{lock_file} ||= '--';   # to be resolved later

    defined $self->SUPER::init($args)
        or return;

    my $class    = ref $self;

    my $filename = $self->{MBF_filename}
       = $self->folderToFilename
           ( $self->name
           , $self->folderdir
           );

    if(-e $filename) {;}    # Folder already exists
    elsif($args->{create} && $class->create($args->{folder}, %$args)) {;}
    else
    {   $self->log(PROGRESS =>
                      "File $filename for folder $self does not exist.");
        return;
    }

    $self->{MBF_policy}  = $args->{write_policy};

    # Lock the folder.

    my $locker   = $self->locker;

    my $lockfile = $locker->filename;
    if($lockfile eq '--')            # filename to be used not resolved yet
    {   my $lockdir   = $filename;
        $lockdir      =~ s!/([^/]*)$!!;
        my $extension = $args->{lock_extension} || '.lock';

        $locker->filename
          ( File::Spec->file_name_is_absolute($extension) ? $extension
          : $extension =~ m!^\.!  ? "$filename$extension"
          :                         File::Spec->catfile($lockdir, $extension)
          );
    }

    unless($locker->lock)
    {   $self->log(ERROR => "Cannot get a lock on $class folder $self.");
        return;
    }

    # Check if we can write to the folder, if we need to.

    if($self->writable && ! -w $filename)
    {   $self->log(WARNING => "Folder $self file $filename is write-protected.");
        $self->{MB_access} = 'r';
    }

    # Start parser if reading is required.

      $self->{MB_access} !~ m/r/ ? $self
    : $self->parser              ? $self
    :                              undef;
}


sub create($@)
{   my ($thingy, $name, %args) = @_;
    my $class     = ref $thingy      || $thingy;
    my $folderdir = $args{folderdir} || $default_folder_dir;
    my $subext    = $args{subfolder_extension};    # not always available
    my $filename  = $class->folderToFilename($name, $folderdir, $subext);

    return $class if -f $filename;

    my $dir       = dirname $filename;
    if(-f $dir && defined $subext)
    {   $dir      .= $subext;
        $filename  = File::Spec->catfile($dir, basename $filename);
    }

    $class->log(ERROR => "Cannot create directory $dir for folder $name: $!"),return
        unless -d $dir || mkdir $dir, 0755;

    $class->moveAwaySubFolder($filename, $subext)
        if -d $filename && defined $subext;

    my $create = IO::File->new($filename, 'w');
    unless($create)
    {   $class->log(WARNING => "Cannot create folder file $name: $!");
        return;
    }

    $class->log(PROGRESS => "Created folder $name.");
    $create->close or return;
    $class;
}

sub foundIn($@)
{   my $class = shift;
    my $name  = @_ % 2 ? shift : undef;
    my %args  = @_;
    $name   ||= $args{folder} or return;

    my $folderdir = $args{folderdir} || $default_folder_dir;
    my $filename  = $class->folderToFilename($name, $folderdir);

    -f $filename;
}

sub organization() { 'FILE' }

sub size()
{   my $self = shift;
    $self->isModified ? $self->SUPER::size : -s $self->filename;
}

sub close(@)
{   my $self = $_[0];            # be careful, we want to set the calling
    undef $_[0];                 #    ref to undef, as the SUPER does.
    shift;

    my $rc = $self->SUPER::close(@_);

    if(my $parser = delete $self->{MBF_parser}) { $parser->stop }

    $rc;
}


sub appendMessages(@)
{   my $class  = shift;
    my %args   = @_;

    my @messages
      = exists $args{message}  ? $args{message}
      : exists $args{messages} ? @{$args{messages}}
      :                          return ();

    my $folder   = $class->new(lock_type => 'NONE', @_, access => 'w+')
       or return ();
 
    my $filename = $folder->filename;

    my $out      = IO::File->new($filename, 'a');
    unless($out)
    {   $class->log(ERROR => "Cannot append messages to folder file $filename: $!");
        return ();
    }

    my $msgtype = $class.'::Message';
    my @coerced;

    foreach my $msg (@messages)
    {   my $coerced
           = $msg->isa($msgtype) ? $msg
           : $msg->can('clone')  ? $msgtype->coerce($msg->clone)
           :                       $msgtype->coerce($msg);

        $coerced->write($out);
        push @coerced, $coerced;
    }

    my $ok = $folder->close;
    $out->close && $ok
       or return 0;

    @coerced;
}

#-------------------------------------------


sub filename() { shift->{MBF_filename} }

#-------------------------------------------


sub parser()
{   my $self = shift;

    return $self->{MBF_parser}
        if defined $self->{MBF_parser};

    my $source = $self->filename;

    my $mode = $self->{MB_access} || 'r';
    $mode    = 'r+' if $mode eq 'rw' || $mode eq 'a';

    my $parser = $self->{MBF_parser}
       = Mail::Box::Parser->new
        ( filename  => $source
        , mode      => $mode
        , trusted   => $self->{MB_trusted}
        , fix_header_errors => $self->{MB_fix_headers}
        , $self->logSettings
        ) or return;

    $parser->pushSeparator('From ');
    $parser;
}

sub readMessages(@)
{   my ($self, %args) = @_;

    $self->messageCreateOptions
     ( $args{message_type}
     , $self->logSettings
     , folder     => $self
     , head_type  => $args{head_type}
     , field_type => $args{field_type}
     , trusted    => $args{trusted}
     );

    $self->updateMessages;
}
 

sub updateMessages(@)
{   my ($self, %args) = @_;
    my $parser   = $self->parser or return;

    # On a directory, simulate an empty folder with only subfolders.
    my $filename = $self->filename;
    return $self if -d $filename;

    if(my $last  = $self->message(-1))
    {  (undef, my $end) = $last->fileLocation;
       $parser->filePosition($end);
    }

    my ($type, @msgopts) = $self->messageCreateOptions;
    my $count    = 0;

    while(1)
    {   my $message = $type->new(@msgopts);
        last unless $message->readFromParser($parser);
        $self->storeMessage($message);
        $count++;
    }

    $self->log(PROGRESS => "Found $count new messages in $filename")
        if $count;

    $self;
}


sub messageCreateOptions(@)
{   my ($self, @options) = @_;
    if(@options)
    {   ref($_) && ref($_) =~ m/^Mail::/ && weaken $_ for @options;
        $self->{MBF_create_options} = \@options;
    }
    
    @{$self->{MBF_create_options}};
}


sub moveAwaySubFolder($$)
{   my ($self, $dir, $extension) = @_;
    $self->log(ERROR => "Cannot move away sub-folder $dir")
       unless move $dir, $dir.$extension;
    $self;
}

sub delete(@)
{   my $self = shift;
    $self->SUPER::delete(@_);
    unlink $self->filename;
}


sub writeMessages($)
{   my ($self, $args) = @_;

    my $filename = $self->filename;
    if( ! @{$args->{messages}} && $self->{MB_remove_empty})
    {   $self->log(WARNING => "Cannot remove folder $self file $filename: $!")
             unless unlink $filename;
        return $self;
    }

    my $policy = exists $args->{policy} ? $args->{policy} : $self->{MBF_policy};
    $policy  ||= '';

    my $success
      = ! -e $filename       ? $self->_write_new($args)
      : $policy eq 'INPLACE' ? $self->_write_inplace($args)
      : $policy eq 'REPLACE' ? $self->_write_replace($args)
      : $self->_write_replace($args) ? 1
      : $self->_write_inplace($args);

    unless($success)
    {   $self->log(ERROR => "Unable to update folder $self.");
        return;
    }

#   $self->parser->restart;
    $self;
}

sub _write_new($)
{   my ($self, $args) = @_;

    my $filename = $self->filename;
    my $new      = IO::File->new($filename, 'w');
    return 0 unless defined $new;

    $new->binmode;
    $_->write($new) foreach @{$args->{messages}};

    $new->close or return 0;

    $self->log(PROGRESS =>
        "Wrote new folder $self with ".@{$args->{messages}}."msgs.");
    1;
}

# First write to a new file, then replace the source folder in one
# move.  This is much slower than inplace update, but it is safer,
# The folder is always in the right shape, even if the program is
# interrupted.

sub _write_replace($)
{   my ($self, $args) = @_;

    my $filename = $self->filename;
    my $tmpnew   = $self->tmpNewFolder($filename);

    my $new      = IO::File->new($tmpnew, 'w')   or return 0;
    $new->binmode;

    my $old      = IO::File->new($filename, 'r') or return 0;
    $old->binmode;

    my ($reprint, $kept) = (0,0);

    foreach my $message ( @{$args->{messages}} )
    {
        my $newbegin = $new->tell;
        my $oldbegin = $message->fileLocation;

        if($message->isModified)
        {   $message->write($new);
            $message->moveLocation($newbegin - $oldbegin)
               if defined $oldbegin;
            $reprint++;
            next;
        }

        my ($begin, $end) = $message->fileLocation;
        my $need = $end-$begin;

        $old->seek($begin, 0);
        my $whole;
        my $size = $old->read($whole, $need);

        $self->log(ERROR => "File too short to get write message "
                            . $message->seqnr. " ($size, $need)")
           unless $size == $need;

        $new->print($whole);
        $new->print($Mail::Message::crlf_platform ? "\r\n" : "\n");

        $message->moveLocation($newbegin - $oldbegin);
        $kept++;
    }

    my $ok = $new->close;
    $old->close && $ok
        or return 0;

    if($windows)
    {   # Windows does not like to move to existing filenames
        unlink $filename;

        # Windows cannot move to files which are opened.
        $self->parser->closeFile;
    }

    unless(move $tmpnew, $filename)
    {   $self->log(WARNING =>
            "Cannot replace $filename by $tmpnew, to update folder $self: $!");

        unlink $tmpnew;
        return 0;
    }

    $self->log(PROGRESS => "Folder $self replaced ($kept, $reprint)");
    1;
}

# Inplace is currently very poorly implemented.  From the first
# location where changes appear, all messages are rewritten.

sub _write_inplace($)
{   my ($self, $args) = @_;

    my @messages = @{$args->{messages}};
    my $last;

    my ($msgnr, $kept) = (0, 0);
    while(@messages)
    {   my $next = $messages[0];
        last if $next->isModified || $next->seqnr!=$msgnr++;
        $last    = shift @messages;
        $kept++;
    }

    if(@messages==0 && $msgnr==$self->messages)
    {   $self->log(PROGRESS => "No changes to be written to $self.");
        return 1;
    }

    $_->body->load foreach @messages;

    my $mode     = $^O eq 'MSWin32' ? 'a' : 'r+';
    my $filename = $self->filename;
    my $old      = IO::File->new($filename, $mode) or return 0;

    # Chop the folder after the messages which does not have to change.

    my $end = defined $last ? ($last->fileLocation)[1] : 0;

    $end =~ m/(.*)/;  # untaint, only required by perl5.6.1
    $end = $1;

    unless($old->truncate($end))
    {   # truncate impossible: try replace writing
        $old->close;
        return 0;
    }

    unless(@messages)
    {   # All further messages only are flagged to be deleted
        $old->close or return 0;
        $self->log(PROGRESS => "Folder $self shortened in-place ($kept kept)");
        return 1;
    }

    # go to the end of the truncated output file.
    $old->seek(0, 2);

    # Print the messages which have to move.
    my $printed = @messages;
    foreach my $message (@messages)
    {   my $oldbegin = $message->fileLocation;
        my $newbegin = $old->tell;
        $message->write($old);
        $message->moveLocation($newbegin - $oldbegin);
    }

    $old->close or return 0;
    $self->log(PROGRESS => "Folder $self updated in-place ($kept, $printed)");
    1;
}

#-------------------------------------------


sub folderToFilename($$;$)
{   my ($thing, $name, $folderdir) = @_;

    substr $name, 0, 1, $folderdir
        if substr $name, 0, 1 eq '=';

    $name;
}

sub tmpNewFolder($) { shift->filename . '.tmp' }

#-------------------------------------------


1;
