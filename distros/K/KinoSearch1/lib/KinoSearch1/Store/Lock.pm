package KinoSearch1::Store::Lock;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        invindex  => undef,
        lock_name => undef,
        timeout   => 0,
    );
}

use constant LOCK_POLL_INTERVAL => 1000;

# Attempt to aquire lock once per second until the timeout has been reached.
sub obtain {
    my $self = shift;

    # calculate maximum seconds to sleep
    my $sleepcount = $self->{timeout} / LOCK_POLL_INTERVAL;

    # keep trying to obtain lock until timeout is reached
    my $locked = $self->do_obtain;
    while ( !$locked ) {
        croak("Couldn't get lock using '$self->{lock_name}'")
            if $sleepcount-- <= 0;
        sleep 1;
        $locked = $self->do_obtain;
    }

    return $locked;
}

=begin comment

    my $locked = $lock->do_obtain;

Do the actual work to aquire the lock and return a boolean reflecting
success/failure.

=end comment
=cut

sub do_obtain { shift->abstract_death }

=begin comment

    $lock->release;

Release the lock.

=end comment
=cut

sub release { shift->abstract_death }

=begin comment

    my $locked_or_not = $lock->is_locked;

Return true if the resource is locked, false otherwise.

=end comment
=cut

sub is_locked { shift->abstract_death }

# Getter for lock_name.
sub get_lock_name { shift->{lock_name} }

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Store::Lock - mutex lock on an invindex

==head1 SYNOPSIS

    # abstract base class, but here's typical usage:
    
    my $lock = $invindex->make_lock(
        lock_name => COMMIT_LOCK_NAME,
        timeout   => 5000,
    );

==head1 DESCRIPTION

The Lock class produces an interprocess mutex lock.  It does not rely on
flock().

Lock must be subclassed, and instances must be constructed using the
C<make_lock> factory method of KinoSearch1::Store::InvIndex.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut


