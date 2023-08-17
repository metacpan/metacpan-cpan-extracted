# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Locker::FcntlLock;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box::Locker';

use strict;
use warnings;

use Fcntl;
use IO::File;
use Errno   qw/EAGAIN/;
use File::FcntlLock;



sub init($)
{   my ($self, $args) = @_;
    $args->{file} = $args->{posix_file} if $args->{posix_file};
    $self->SUPER::init($args);
}

sub name() {'FcntlLock'}

sub _try_lock($)
{   my ($self, $file) = @_;
    my $fl = File::FcntlLock->new;
    $fl->l_type(F_WRLCK);
    $? = $fl->lock($file, F_SETLK);
    $?==0;
}

sub _unlock($)
{   my ($self, $file) = @_;
    my $fl = File::FcntlLock->new;
    $fl->l_type(F_UNLCK);
    $fl->lock($file, F_SETLK);
    $self;
}


sub lock()
{   my $self   = shift;

    if($self->hasLock)
    {   my $folder = $self->folder;
        $self->log(WARNING => "Folder $folder already lockf'd");
        return 1;
    }

    my $filename = $self->filename;

    my $file   = IO::File->new($filename, 'r+');
    unless(defined $file)
    {   my $folder = $self->folder;
        $self->log(ERROR =>
           "Unable to open FcntlLock lock file $filename for $folder: $!");
        return 0;
    }

    my $timeout = $self->timeout;
    my $end     = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;

    while(1)
    {   if($self->_try_lock($file))
        {   $self->SUPER::lock;
            $self->{MBLF_filehandle} = $file;
            return 1;
        }

        unless($!==EAGAIN)
        {   my $folder = $self->folder;
            $self->log(ERROR =>
                "Will never get a FcntlLock lock on $filename for $folder: $!");
            last;
        }

        last unless --$end;
        sleep 1;
    }

    return 0;
}



sub isLocked()
{   my $self     = shift;
    my $filename = $self->filename;

    my $file     = IO::File->new($filename, "r");
    unless($file)
    {   my $folder = $self->folder;
        $self->log(ERROR =>
               "Unable to check lock file $filename for $folder: $!");
        return 0;
    }

    $self->_try_lock($file)==0 or return 0;
    $self->_unlock($file);
    $file->close;

    $self->SUPER::unlock;
    1;
}

sub unlock()
{   my $self = shift;

    $self->_unlock(delete $self->{MBLF_filehandle})
       if $self->hasLock;

    $self->SUPER::unlock;
    $self;
}

1;
