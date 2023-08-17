# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Locker::Flock;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box::Locker';

use strict;
use warnings;

use IO::File;
use Fcntl         qw/:DEFAULT :flock/;
use Errno         qw/EAGAIN/;


sub name() {'FLOCK'}

sub _try_lock($)
{   my ($self, $file) = @_;
    flock $file, LOCK_EX|LOCK_NB;
}

sub _unlock($)
{   my ($self, $file) = @_;
    flock $file, LOCK_UN;
    $self;
}



# 'r+' is require under Solaris and AIX, other OSes are satisfied with 'r'.
my $lockfile_access_mode = ($^O eq 'solaris' || $^O eq 'aix') ? 'r+' : 'r';

sub lock()
{   my $self   = shift;
    my $folder = $self->folder;

    if($self->hasLock)
    {   $self->log(WARNING => "Folder $folder already flocked.");
        return 1;
    }

    my $filename = $self->filename;

    my $file   = IO::File->new($filename, $lockfile_access_mode);
    unless($file)
    {   $self->log(ERROR =>
           "Unable to open flock file $filename for $folder: $!");
        return 0;
    }

    my $timeout = $self->timeout;
    my $end     = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;

    while(1)
    {   if($self->_try_lock($file))
        {   $self->{MBLF_filehandle} = $file;
            return $self->SUPER::lock;
        }

        if($! != EAGAIN)
        {   $self->log(ERROR =>
               "Will never get a flock on $filename for $folder: $!");
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

    my $file     = IO::File->new($filename, $lockfile_access_mode);
    unless($file)
    {   my $folder = $self->folder;
        $self->log(ERROR =>
            "Unable to check lock file $filename for $folder: $!");
        return 0;
    }

    $self->_try_lock($file) or return 0;
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
