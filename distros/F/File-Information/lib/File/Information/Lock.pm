# Copyright (c) 2024-2025 Philipp Schafft <lion@cpan.org>

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Lock;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.16;


sub new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    $self->{instance} = $self->{parent}->instance unless defined $self->{instance};

    croak 'No instance is given'    unless defined $self->{instance};
    croak 'No parent is given'      unless defined $self->{parent};
    croak 'No on_unlock is given'   unless defined $self->{on_unlock};

    return $self;
}



sub instance {
    my ($self) = @_;
    return $self->{instance};
}


sub parent {
    my ($self) = @_;
    return $self->{parent};
}

# ----------------

sub DESTROY {
    my ($self) = @_;
    my $func = $self->{on_unlock};
    $self->parent->$func($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Lock - generic module for extracting information from filesystems

=head1 VERSION

version v0.16

=head1 SYNOPSIS

    use File::Information;

    my File::Information::Lock $lock = $obj->lock;

This package is used to represent locks on resources and objects.

The lock is hold until the last reference to the object is gone.

=head1 METHODS

=head2 new

    my File::Information::Lock $lock = File::Information::Lock->new([ instance => $instance, ] parent => $parent, on_unlock => \&unlock_sub);

Returns a new lock object. Requires an instance (L<File::Information>), a parent object (what is locked), and an unlock function.
If no instance is given C<$parent-E<gt>instance> is called to obtain one.

Once this lock is gone the unlock function is called. It is normally a private method of the object that is locked.
The unlock function is responsible of handling the case with multiple lock objects being alive at the same time. So any unlock function must check
if all locks are gone before performing an actual unlock. The unlock function is called on C<$parent> and passing the lock as first argument.

=head2 instance

    my File::Information $instance = $lock->instance;

Returns the instance that was used to create this object.

=head2 parent

    my $parent = $lock->parent;

Returns the parent that was used to create this object.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
