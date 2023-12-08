package GDPR::IAB::TCFv2::RangeConsent;
use strict;
use warnings;
use integer;
use bytes;

use Carp qw<croak>;

sub new {
    my ( $klass, %args ) = @_;

    croak "missing field 'start'" unless defined $args{start};
    croak "missing field 'end'"   unless defined $args{end};

    my $start = $args{start};
    my $end   = $args{end};

    croak "field 'start' should be a non zero, positive integer"
      if $start <= 0;

    croak "ops start should not be bigger than end" if $start > $end;

    my $self = {
        start => $start,
        end   => $end,
    };

    bless $self, $klass;

    return $self;
}

sub contains {
    my ( $self, $id ) = @_;

    return $self->{start} <= $id && $id <= $self->{end};
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::RangeConsent - Transparency & Consent String version 2 range consent pair

=head1 SYNOPSIS

    my $range = GDPR::IAB::TCFv2::RangeConsent->new(
        start => 10,
        end   => 20,
    );

    die "ops" unless $range->contains(15);

=head1 CONSTRUCTOR

Receive 2 parameters: start and end.

Will die if any parameter is missing.

Will die if start is bigger than end.

=head1 METHODS

=head2 contains

Return true if the id is present on the range [start, end]

    my $ok = $range->contains(15);
