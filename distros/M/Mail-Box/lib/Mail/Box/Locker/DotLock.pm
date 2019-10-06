# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Locker::DotLock;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Box::Locker';

use strict;
use warnings;

use IO::File;
use File::Spec;
use Errno      qw/EEXIST/;
use Carp;


sub init($)
{   my ($self, $args) = @_;
    $args->{file} = $args->{dotlock_file} if $args->{dotlock_file};
    $self->SUPER::init($args);
}

sub name() {'DOTLOCK'}

sub folder(;$)
{   my $self = shift;
    @_ && $_[0] or return $self->SUPER::folder;

    my $folder = shift;
    unless(defined $self->filename)
    {   my $org = $folder->organization;

        my $filename
          = $org eq 'FILE'     ? $folder->filename . '.lock'
          : $org eq 'DIRECTORY'? File::Spec->catfile($folder->directory,'.lock')
          : croak "Need lock file name for DotLock.";

        $self->filename($filename);
    }

    $self->SUPER::folder($folder);
}

sub _try_lock($)
{   my ($self, $lockfile) = @_;
    return if -e $lockfile;

    my $flags    = $^O eq 'MSWin32'
                 ?  O_CREAT|O_EXCL|O_WRONLY
                 :  O_CREAT|O_EXCL|O_WRONLY|O_NONBLOCK;

    my $lock = IO::File->new($lockfile, $flags, 0600);
    if($lock)
    {   close $lock;
        return 1;
    }

    if($! != EEXIST)
    {   $self->log(ERROR => "lockfile $lockfile can never be created: $!");
        return 1;
    }
}


sub unlock()
{   my $self = shift;
    $self->hasLock
        or return $self;

    my $lock = $self->filename;

    unlink $lock
        or $self->log(WARNING => "Couldn't remove lockfile $lock: $!");

    $self->SUPER::unlock;
    $self;
}


sub lock()
{   my $self   = shift;

    my $lockfile = $self->filename;
    if($self->hasLock)
    {   $self->log(WARNING => "Folder already locked with file $lockfile");
        return 1;
    }

    my $timeout  = $self->timeout;
    my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
    my $expire   = $self->expires/86400;  # in days for -A

    while(1)
    {
        return $self->SUPER::lock
           if $self->_try_lock($lockfile);

        if(-e $lockfile && -A $lockfile > $expire)
        {
            if(unlink $lockfile)
            {   $self->log(WARNING => "Removed expired lockfile $lockfile");
                redo;
            }
            else
            {   $self->log(ERROR =>
                   "Failed to remove expired lockfile $lockfile: $!");
                last;
            }
        }

        last unless --$end;
        sleep 1;
    }

    return 0;
}

sub isLocked() { -e shift->filename }

1;

