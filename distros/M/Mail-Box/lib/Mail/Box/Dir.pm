# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Dir;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box';

use strict;
use warnings;
use filetest 'access';

use Mail::Box::Dir::Message;

use Mail::Message::Body::Lines;
use Mail::Message::Body::File;
use Mail::Message::Body::Delayed;
use Mail::Message::Body::Multipart;

use Mail::Message::Head;
use Mail::Message::Head::Delayed;

use Carp;
use File::Copy;
use File::Spec;
use File::Basename;


sub init($)
{   my ($self, $args)    = @_;

    $args->{body_type} ||= sub {'Mail::Message::Body::Lines'};

    return undef
        unless $self->SUPER::init($args);

    my $class            = ref $self;
    my $directory        = $self->{MBD_directory}
        = $args->{directory} || $self->directory;

       if(-d $directory) {;}
    elsif($args->{create} && $class->create($directory, %$args)) {;}
    else
    {   $self->log(NOTICE => "No directory $directory for folder of $class");
        return undef;
    }

    # About locking

    for($args->{lock_file})
    {   $self->locker->filename
          ( !defined $_ ? File::Spec->catfile($directory, '.lock')   # default
          : File::Spec->file_name_is_absolute($_) ? $_               # absolute
          :               File::Spec->catfile($directory, $_)        # relative
          );
    }

    # Check if we can write to the folder, if we need to.

    if($self->writable && -e $directory && ! -w $directory)
    {   $self->log(WARNING=> "Folder directory $directory is write-protected.");
        $self->{MB_access} = 'r';
    }

    $self;
}

#-------------------------------------------

sub organization() { 'DIRECTORY' }

#-------------------------------------------


sub directory()
{   my $self = shift;

    $self->{MBD_directory}
       ||= $self->folderToDirectory($self->name, $self->folderdir);
}

#-------------------------------------------

sub nameOfSubFolder($;$)
{   my ($thing, $name) = (shift, shift);
    my $parent = @_ ? shift : ref $thing ? $thing->directory : undef;
    defined $parent ? "$parent/$name" : $name;
}

#-------------------------------------------


sub folderToDirectory($$)
{   my ($class, $name, $folderdir) = @_;
    my $dir = ( $name =~ m#^=\/?(.*)# ? "$folderdir/$1" : $name);
    $dir =~ s!/$!!;
    $dir;
}

sub storeMessage($)
{   my ($self, $message) = @_;
    $self->SUPER::storeMessage($message);
    my $fn = $message->filename or return $message;
    $self->{MBD_by_fn}{$fn} = $message;
}


sub messageInFile($) { $_[0]->{MBD_by_fn}{$_[1]} }


sub readMessageFilenames() {shift->notImplemented}

#-------------------------------------------

1;
