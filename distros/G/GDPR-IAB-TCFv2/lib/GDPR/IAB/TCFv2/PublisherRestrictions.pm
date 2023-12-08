package GDPR::IAB::TCFv2::PublisherRestrictions;
use strict;
use warnings;

use Carp qw<croak>;

sub new {
    my ( $klass, %args ) = @_;

    my $restrictions = $args{restrictions}
      or croak "missing field 'restrictions'";

    my $self = {
        restrictions => $restrictions,
    };

    bless $self, $klass;

    return $self;
}

sub check_publisher_restriction {
    my ( $self, $purpose_id, $restrict_type, $vendor ) = @_;

    return 0
      unless exists $self->{restrictions}->{$purpose_id}->{$restrict_type};

    return $self->{restrictions}->{$purpose_id}->{$restrict_type}
      ->contains($vendor);
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::PublisherRestrictions - Transparency & Consent String version 2 publisher restriction

=head1 SYNOPSIS

    my $range = GDPR::IAB::TCFv2::PublisherRestrictions->new(
        restrictions => {
            purpose id => {
                restriction type => instance of GDPR::IAB::TCFv2::RangeSection
            },
        },
    );

    die "there is publisher restriction on purpose id 1, type 0 on vendor 284"
        if $range->contains(1, 0, 284);

=head1 CONSTRUCTOR

Receive 1 parameters: restrictions. Hashref.

Will die if it is undefined.

=head1 METHODS

=head2 contains

Return true for a given combination of purpose id, restriction type and vendor 

    my $purpose_id = 1;
    my $restriction_type = 0;
    my $vendor = 284;
    $ok = $range->contains($purpose_id, $restriction_type, $vendor);
