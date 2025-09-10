# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::VerifyTestResult;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::VerifyBase';

use Carp;

our $VERSION = v0.12;

use constant {
    CLASS_METADATA  => 'meatdata',
    CLASS_WEAK      => 'weak',
    CLASS_STRONG    => 'strong',
};

my %supported_tests = (
    (map {
            'get_'.$_ => {
                class   => CLASS_METADATA,
                cb      => \&_test_get,
                key     => $_,
            },
        } qw(size mediatype)),
    (map {
            'digest_'.($_ =~ tr/-/_/r) => {
                class   => CLASS_STRONG,
                cb      => \&_test_digest,
                digest  => $_,
            },
        } grep {$_ ne 'sha-2-512'} map {'sha-2-'.$_, 'sha-3-'.$_} qw(224 256 384 512)), # all of SHA-2 and SHA-3 but SHA-2-512
    (map {
            'digest_'.($_ =~ tr/-/_/r) => {
                class   => CLASS_WEAK,
                cb      => \&_test_digest,
                digest  => $_,
            },
        } qw(md-4-128 md-5-128 sha-1-160 ripemd-1-160 tiger-1-192 tiger-2-192)), # all the others basically
    inode => {
        class   => CLASS_STRONG,
        cb      => \&_test_inode,
    },
);

# ----------------

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts);
    my $test = $supported_tests{$opts{test}} // croak 'Unsupported test';
    my $res;

    $self->{status} = $res = eval {$test->{cb}->($self, $test)} // $pkg->STATUS_ERROR;

    if (ref($res) && $res->isa('File::Information::VerifyBase')) {
        return $res;
    }

    if (defined(my $digest = $test->{digest}) && $test->{class} eq CLASS_STRONG) {
        my $info = $self->instance->digest_info($digest);
        $self->{class} = CLASS_WEAK if $info->{unsafe};
    }

    return $self;
}

sub _supported_tests {
    return keys %supported_tests;
}

sub _class {
    my ($self) = @_;
    return $self->{class} // $supported_tests{$self->{test}}{class};
}

sub _test_get {
    my ($self, $test) = @_;
    my $key  = $test->{key};
    my $from = $self->base_from->get($key, lifecycle => $self->{lifecycle_from}, default => undef, as => 'Data::Identifier');
    my $to   = $self->base_to->get($key, lifecycle => $self->{lifecycle_to},   default => undef, as => 'Data::Identifier');

    if (defined($from) && defined($to)) {
        #warn sprintf('key=<%s>, %s -> %s: from=<%s>, to=<%s>', $test->{key}, $self->{lifecycle_from}, $self->{lifecycle_to}, $from // '', $to // '') if $key eq 'mediatype';
        return $self->STATUS_PASSED if $from->eq($to);
    }

    $from = $self->base_from->get($key, lifecycle => $self->{lifecycle_from}, default => undef, as => 'raw');
    $to   = $self->base_to->get($key, lifecycle => $self->{lifecycle_to},   default => undef, as => 'raw');

    #warn sprintf('key=<%s>, %s -> %s: from=<%s>, to=<%s>', $test->{key}, $self->{lifecycle_from}, $self->{lifecycle_to}, $from // '', $to // '') if $key eq 'mediatype';

    return $self->STATUS_NO_DATA unless defined($from) && defined($to);
    return $from eq $to ? $self->STATUS_PASSED : $self->STATUS_FAILED;
}

sub _test_digest {
    my ($self, $test) = @_;
    my $from = $self->base_from->digest($test->{digest}, lifecycle => $self->{lifecycle_from}, default => undef, as => 'hex');
    my $to   = $self->base_to->digest($test->{digest}, lifecycle => $self->{lifecycle_to},   default => undef, as => 'hex');

    return $self->STATUS_NO_DATA unless defined($from) && defined($to);
    #warn sprintf('key=<%s>, %s -> %s: from=<%s>, to=<%s>', $test->{digest}, $self->{lifecycle_from}, $self->{lifecycle_to}, $from // '', $to // '');
    return $from eq $to ? $self->STATUS_PASSED : $self->STATUS_FAILED;
}

sub _test_inode {
    my ($self, $test) = @_;
    my $base_from  = $self->base_from;
    my $base_to    = $self->base_to;
    my $inode_from = $base_from->can('inode') ? $base_from->inode : $base_from->isa('File::Information::Remote') ? $base_from : undef;
    my $inode_to   = $base_to->can('inode')   ? $base_to->inode   : $base_to->isa('File::Information::Remote')   ? $base_to   : undef;

    if (defined($inode_from) && defined($inode_to)) {
        if ($base_from != $inode_from || $base_to != $inode_to) {
            return $inode_from->verify(lifecycle_from => $self->{lifecycle_from}, lifecycle_to => $self->{lifecycle_to}, base_to => $inode_to);
        }
    }
    return $self->STATUS_NO_DATA;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::VerifyTestResult - generic module for extracting information from filesystems

=head1 VERSION

version v0.12

=head1 SYNOPSIS

    use File::Information;

    my File::Information::Inode $inode = ...;

    my File::Information::VerifyResult $result = $inode->verify;

    my $passed = $base->has_passed;

This package inherits from L<File::Information::VerifyBase>.

=head1 METHODS

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
