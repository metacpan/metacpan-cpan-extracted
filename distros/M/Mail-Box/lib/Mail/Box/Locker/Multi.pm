# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Locker::Multi;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Box::Locker';

use strict;
use warnings;

use Carp;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    my @use
     = exists $args->{use} ? @{delete $args->{use}}
     : $^O eq 'MSWin32'    ? qw/Flock/
     :                       qw/NFS FcntlLock Flock/;

    my (@lockers, @used);

    foreach my $method (@use)
    {   if(UNIVERSAL::isa($method, 'Mail::Box::Locker'))
        {   push @lockers, $method;
            (my $used = ref $method) =~ s/.*\:\://;
            push @used, $used;
            next;
        }

        my $locker = eval
        {   Mail::Box::Locker->new
              ( %$args
              , method  => $method
              , timeout => 1
              )
        };
        next unless defined $locker;

        push @lockers, $locker;
        push @used, $method;
    }

    $self->{MBLM_lockers} = \@lockers;
    $self->log(PROGRESS => "Multi-locking via @used.");
    $self;
}

#-------------------------------------------

sub name() {'MULTI'}

sub _try_lock($)
{   my $self     = shift;
    my @successes;

    foreach my $locker ($self->lockers)
    {
        unless($locker->lock)
        {   $_->unlock foreach @successes;
            return 0;
        }
        push @successes, $locker;
    }

    1;
}

sub unlock()
{   my $self = shift;
    $self->hasLock
		or return $self;

    $_->unlock foreach $self->lockers;
    $self->SUPER::unlock;

    $self;
}

sub lock()
{   my $self  = shift;
    return 1 if $self->hasLock;

    my $timeout = $self->timeout;
    my $end     = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;

    while(1)
    {   return $self->SUPER::lock
            if $self->_try_lock;

        last unless --$end;
        sleep 1;
    }

    return 0;
}

sub isLocked()
{   my $self     = shift;

    # Try get a lock
    $self->_try_lock($self->filename) or return 0;

    # and release it immediately
    $self->unlock;
    1;
}

#-------------------------------------------


sub lockers() { @{shift->{MBLM_lockers}} }

1;
