# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::VerifyBase;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.11;

use constant {
    STATUS_ERROR                => 'error',
    STATUS_PASSED               => 'passed',
    STATUS_FAILED               => 'failed',
    STATUS_NO_DATA              => 'no_data',
    STATUS_INSUFFICIENT_DATA    => 'insufficient_data',
};


sub status {
    my ($self) = @_;
    return $self->{status};
}


sub has_error {
    my ($self) = @_;
    return $self->{status} eq STATUS_ERROR;
}


sub has_passed {
    my ($self) = @_;
    return $self->{status} eq STATUS_PASSED;
}


sub has_failed {
    my ($self) = @_;
    return $self->{status} eq STATUS_FAILED;
}


sub has_no_data {
    my ($self) = @_;
    return $self->{status} eq STATUS_NO_DATA;
}


sub has_insufficient_data {
    my ($self) = @_;
    return $self->{status} eq STATUS_INSUFFICIENT_DATA;
}


#@returns File::Information::Base
sub base {
    my ($self) = @_;
    return $self->{base};
}


#@returns File::Information::Base
sub base_from {
    my ($self) = @_;
    return $self->{base_from} // $self->{base};
}


#@returns File::Information::Base
sub base_to {
    my ($self) = @_;
    return $self->{base_to} // $self->{base};
}


#@returns File::Information
sub instance {
    my ($self) = @_;
    return $self->{instance};
}


#@returns Data::URIID
sub extractor {
    my ($self, @args) = @_;
    return $self->{extractor} //= $self->instance->extractor(@args);
}

#@returns Data::TagDB
sub db {
    my ($self, @args) = @_;
    return $self->{db} //= $self->instance->db(@args);
}

# ----------------

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless(\%opts, $pkg);

    $self->{lifecycle_from} //= 'current';
    $self->{lifecycle_to}   //= 'final';

    croak 'No instance is given' unless defined $self->{instance};
    croak 'No base_from is given' unless defined($self->{base_from}) || defined($self->{base});
    croak 'No base_to is given' unless defined($self->{base_to}) || defined($self->{base});
    croak 'No lifecycle_from is given' unless defined $self->{lifecycle_from};
    croak 'No lifecycle_to is given' unless defined $self->{lifecycle_to};

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::VerifyBase - generic module for extracting information from filesystems

=head1 VERSION

version v0.11

=head1 SYNOPSIS

    use File::Information;

    my File::Information::VerifyBase $base = ...;

    my $passed = $base->is_passed;

This package contains the basic methods for verify results.
See also L<File::Information::Base/verify>.

=head1 METHODS

=head2 status

    my $status = $obj->status;

Returns the status of the test.
Most commonly one want to check for the passed state using L</has_passed>.

=head2 has_error

    my $has_error = $obj->has_error;

Returns if the status is the error status. That is the test was not performed
(likely due to an internal error or an operating system error).

B<Note:>
This is B<not> the opposite of L</has_passed>.

=head2 has_passed

    my $has_passed = $obj->has_passed;

This will return if the test was successfully passed.
That is the data is available and matched the expected value.

B<Note:>
This is B<not> the opposite of L</has_failed> or L</has_error>.

=head2 has_failed

    my $has_failed = $obj->has_failed;

Returns if the status is the failed status.
That is the test was successfully performed but the data did not match.

B<Note:>
This is B<not> the opposite of L</has_passed>.

=head2 has_no_data

    my $has_no_data = $obj->has_no_data;

Returns true if the test was not performed due to missing data.

=head2 has_insufficient_data

    my $has_insufficient_data = $obj->has_insufficient_data;

Returnes true if the test was performed but there is data missing for it to pass.
The parts that have been performed did not fail.

=head2 base

    my File::Information::Base $base = $obj->base;

Returns the base that was used to create this object.

B<Note:>
This method is deprecated and will be removed in future versions.

See also
L</base_from>,
L</base_to>.

=head2 base_from

    my File::Information::Base $base = $obj->base_from;

Returns the base object used for the I<from> side of the verify.

See also
L</base_to>.

=head2 base_to

    my File::Information::Base $base = $obj->base_from;

Returns the base object used for the I<to> side of the verify.

See also
L</base_from>.

=head2 instance

    my File::Information $instance = $obj->instance;

Returns the instance that was used to create this object.

=head2 extractor, db

    my Data::URIID $extractor = $obj->extractor;
    my Data::TagDB $db        = $obj->db;
    my ...                    = $obj->digest_info;

These methods provide access to the same data as the methods of L<File::Information>.
Arguments will be passed to said functions. However the object my cache the result.
Therefore it is only allowed to pass arguments that are compatible with caching (if any exist).

See L<File::Information/extractor>, and L<File::Information/db> for details.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
