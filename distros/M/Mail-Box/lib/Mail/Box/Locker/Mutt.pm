# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Locker::Mutt;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box::Locker';

use strict;
use warnings;

use POSIX      qw/sys_wait_h/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->{MBLM_exe} = $args->{exe} || 'mutt_dotlock';
    $self;
}

sub name()     {'MUTT'}
sub lockfile() { shift->filename . '.lock' }



sub exe() {shift->{MBLM_exe}}



sub unlock()
{   my $self = shift;
    $self->hasLock
        or return $self;

    unless(system($self->exe, '-u', $self->filename))
    {   my $folder = $self->folder;
        $self->log(WARNING => "Couldn't remove mutt-unlock $folder: $!");
    }

    $self->SUPER::unlock;
    $self;
}



sub lock()
{   my $self   = shift;
    my $folder = $self->folder;
    if($self->hasLock)
    {   $self->log(WARNING => "Folder $folder already mutt-locked");
        return 1;
    }

    my $filename = $self->filename;
    my $lockfn   = $self->lockfile;

    my $timeout  = $self->timeout;
    my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
    my $expire   = $self->expires / 86400;  # in days for -A
    my $exe      = $self->exe;

    while(1)
    {
        if(system($exe, '-p', '-r', 1, $filename))
        {   unless(WIFEXITED($?) && WEXITSTATUS($?)==3)
            {   $self->log(ERROR => "Will never get a mutt-lock: $!");
                return 0;
            }
        }
        else
        {   return $self->SUPER::lock;
        }

        if(-e $lockfn && -A $lockfn > $expire)
        {
            if(system($exe, '-f', '-u', $filename))
            {   $self->log(ERROR =>
                   "Failed to remove expired mutt-lock $lockfn: $!");
                last;
            }
            else
            {   $self->log(WARNING => "Removed expired mutt-lock $lockfn");
                redo;
            }
        }

        last unless --$end;
        sleep 1;
    }

    return 0;
}


sub isLocked()
{   my $self     = shift;
    system($self->exe, '-t', $self->filename);
    WIFEXITED($?) && WEXITSTATUS($?)==3;
}

1;

