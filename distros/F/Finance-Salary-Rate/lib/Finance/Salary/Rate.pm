use utf8;
package Finance::Salary::Rate;
our $VERSION = '0.001';
use Moo;
use Types::Standard qw(Num);
use namespace::autoclean;

# ABSTRACT: Calculate hourly rates for small businesses

has monthly_income => (
    is       => 'ro',
    isa      => Num,
    required => 1,
);

has vacation_perc => (
    is        => 'ro',
    isa       => Num,
    default   => 0,
);

has tax_perc => (
    is        => 'ro',
    isa       => Num,
    default   => 0,
);

has healthcare_perc => (
    is        => 'ro',
    isa       => Num,
    default   => 0,
);

has declarable_days_perc => (
    is        => 'ro',
    isa       => Num,
    default   => 60,
);

has working_days => (
    is        => 'ro',
    isa       => Num,
    default   => 230,
);

has expenses => (
    is        => 'ro',
    isa       => Num,
    default   => 0,
);

sub gross_income {
    my $self = shift;
    return $self->income * (1 + $self->_get_perc($self->tax_perc));
}

sub _get_perc {
    my ($self, $perc) = @_;
    return $perc / 100;
}

sub get_healthcare_fee {
    my $self = shift;
    return $self->gross_income * $self->_get_perc($self->healthcare_perc)
}

sub workable_hours {
    my $self = shift;
    return
          $self->working_days * 8
        * $self->_get_perc($self->declarable_days_perc);
}

sub required_income {
    my $self = shift;
    return $self->gross_income + $self->expenses;
}

sub hourly_rate {
    my $self = shift;
    return $self->required_income / $self->workable_hours;
}

sub vacation_pay {
    my $self = shift;
    return $self->_get_perc($self->healthcare_perc)
}

sub income {
    my $self = shift;
    my $income = $self->monthly_income * 12;
    return $income * ( 1 + $self->_get_perc($self->vacation_perc));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Salary::Rate - Calculate hourly rates for small businesses

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $rate = Finance::Salary::Rate->new(
        monthly_income       => 1750,
        vacation_perc        => 8,
        tax_perc             => 30,
        healthcare_perc      => 5.7,
        declarable_days_perc => 60,
        days                 => 230,
        expenses             => 2000,
    );

    print "My hourly rate is " . $rate->hourly_rate;

=head1 DESCRIPTION

A calculator to calculate hourly rates for small businesses and the likes.
Based on the Dutch
L<Ondernemersplein|https://ondernemersplein.kvk.nl/voorbeeld-uurtarief-berekenen/>
method.

=head1 ATTRIBUTES

=head2 income

The monthly income you want to receive. Required.

=head2 vacation_perc

The percentage of what you want to pay yourself for vacation money. Optional.

=head2 tax_perc

The percentage of taxes you need to set aside for the government. Optional.

=head2 healthcare_perc

The percentage of income you need to set aside for health care insureance.
Optional.

=head2 healthcare_perc

The percentage of income you need to set aside for health care insureance.
Optional.

=head2 declarable_days_perc

The percentage of declarable days per week. Optional and defaults to 60%.

=head2 working_days

The total amount of working days in a year. Optional and defaults to 230.

=head2 expenses

Estimated expenses per year. Optional.

=head1 METHODS

=head2 monthly_income

Returns the montly income

=head2 yearly_income

Returns the yearly income

=head2 weekly_income

Returns the weekly income

=head2

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
