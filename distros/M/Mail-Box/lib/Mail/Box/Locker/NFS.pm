# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Locker::NFS;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Box::Locker';

use strict;
use warnings;

use Sys::Hostname;
use IO::File;
use Carp;


sub name() {'NFS'}

#-------------------------------------------

# METHOD nfs
# This hack is copied from the Mail::Folder packages, as written
# by Kevin Jones.  Cited from his code:
#    Whhheeeee!!!!!
#    In NFS, the O_CREAT|O_EXCL isn't guaranteed to be atomic.
#    So we create a temp file that is probably unique in space
#    and time ($folder.lock.$time.$pid.$host).
#    Then we use link to create the real lock file. Since link
#    is atomic across nfs, this works.
#    It loses if it's on a filesystem that doesn't do long filenames.

my $hostname = hostname;

sub _tmpfilename()
{   my $self = shift;
    $self->{MBLN_tmp} ||= $self->filename . $$;
}

sub _construct_tmpfile()
{   my $self    = shift;
    my $tmpfile = $self->_tmpfilename;

    my $fh      = IO::File->new($tmpfile, O_CREAT|O_WRONLY, 0600)
        or return undef;

    $fh->close;
    $tmpfile;
}

sub _try_lock($$)
{   my ($self, $tmpfile, $lockfile) = @_;

    return undef
        unless link $tmpfile, $lockfile;

    my $linkcount = (stat $tmpfile)[3];

    unlink $tmpfile;
    $linkcount == 2;
}

sub _unlock($$)
{   my ($self, $tmpfile, $lockfile) = @_;

    unlink $lockfile
        or warn "Couldn't remove lockfile $lockfile: $!\n";

    unlink $tmpfile;

    $self;
}

#-------------------------------------------


sub lock()
{   my $self     = shift;
    my $folder   = $self->folder;

    if($self->hasLock)
    {   $self->log(WARNING => "Folder $folder already locked over nfs");
        return 1;
    }

    my $lockfile = $self->filename;
    my $tmpfile  = $self->_construct_tmpfile or return;
    my $timeout  = $self->timeout;
    my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
    my $expires  = $self->expires / 86400;  # in days for -A

    if(-e $lockfile && -A $lockfile > $expires)
    {   if(unlink $lockfile)
             { $self->log(WARNING => "Removed expired lockfile $lockfile.") }
        else { $self->log(ERROR =>
                        "Unable to remove expired lockfile $lockfile: $!") }
    }

    while(1)
    {   return $self->SUPER::lock
			if $self->_try_lock($tmpfile, $lockfile);

        last unless --$end;
        sleep 1;
    }

    return 0;
}

#-------------------------------------------

sub isLocked()
{   my $self     = shift;
    my $tmpfile  = $self->_construct_tmpfile or return 0;
    my $lockfile = $self->filename;

    my $fh = $self->_try_lock($tmpfile, $lockfile) or return 0;

    close $fh;
    $self->_unlock($tmpfile, $lockfile);
    $self->SUPER::unlock;

    1;
}

#-------------------------------------------

sub unlock($)
{   my $self   = shift;
    return $self unless $self->hasLock;

    $self->_unlock($self->_tmpfilename, $self->filename);
    $self->SUPER::unlock;
    $self;
}

#-------------------------------------------

1;
