package Finance::Tax::Aruba::Role::BBO::TaxYear;
our $VERSION = '0.016';
use Moose::Role;

# ABSTRACT: A role that implements BBO (turnover tax) logic

requires qw(
    is_year
);

# The 7% is made up of BAZV (3%), BBO (2.5%) and BAVP (1.5%). rate is their
# sum, and can be overridden as a whole.
has bazv_rate => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.03,
);

has bbo_rate => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.025,
);

has bavp_rate => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.015,
);

has rate => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_rate',
);

sub _build_rate {
    my $self = shift;
    return sprintf('%.4f',
        $self->bazv_rate + $self->bbo_rate + $self->bavp_rate) + 0;
}

# Whether import BBO (paid to Customs at the border) is creditable
# against domestic BBO owed for this tax year -- see net_payable. This
# distinction changed at some point (the rule and/or the rate for
# imports specifically), which is the whole reason this is a per-year
# plugin the same as Income:: is, rather than one flat rate. Each year
# class overrides this via `has '+bbo_at_border' => (default => ...)`.
has bbo_at_border => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

# Unlike VAT/BTW, BBO isn't added on top of a price -- the amount you
# bill a domestic customer already contains the tax you owe on it, so
# the tax owed is simply the billed amount times the rate.
sub domestic_tax {
    my ($self, $amount) = @_;
    return $self->_round($amount * $self->rate);
}

# The BAZV and BAVP parts of the domestic tax. The BBO part is the
# remainder, so the three always add up to domestic_tax.
sub domestic_tax_bazv {
    my ($self, $amount) = @_;
    return $self->_round($amount * $self->bazv_rate);
}

sub domestic_tax_bavp {
    my ($self, $amount) = @_;
    return $self->_round($amount * $self->bavp_rate);
}

sub domestic_tax_bbo {
    my ($self, $amount) = @_;
    return $self->_round(
        $self->domestic_tax($amount)
        - $self->domestic_tax_bazv($amount)
        - $self->domestic_tax_bavp($amount));
}

# What you actually keep from a domestic sale once BBO is set aside.
sub domestic_net {
    my ($self, $amount) = @_;
    return $self->_round($amount - $self->domestic_tax($amount));
}

# BBO paid to Customs on an imported good, at the border, at the same
# rate as a domestic sale.
sub import_tax {
    my ($self, $amount) = @_;
    return $self->_round($amount * $self->rate);
}

# A service billed to a client outside Aruba is zero-rated: BBO is a
# tax on local turnover, so it doesn't apply "across the border" the
# other way either. Kept as its own method (rather than just always
# being 0 inline at the call site) so the exemption is a documented,
# named rule instead of an implicit absence.
sub export_tax {
    return 0;
}

# Customs invoices the BBO on an import separately. The seller or the
# importer pays it. It only offsets domestic BBO when the invoice is held
# by the importer (held => 1), e.g. the seller paid and forwarded it.
sub customs_offset {
    my ($self, $invoices) = @_;
    return $self->_round($self->_customs_sum($invoices, 1));
}

sub customs_not_forwarded {
    my ($self, $invoices) = @_;
    return $self->_round($self->_customs_sum($invoices, 0));
}

sub _customs_sum {
    my ($self, $invoices, $held) = @_;
    my $sum = 0;
    foreach (@{ $invoices // [] }) {
        $sum += $_->{amount} if !!$_->{held} == !!$held;
    }
    return $sum;
}

# A negative result is a credit carried forward, not an error. Customs
# invoices only offset for a tax year where bbo_at_border is true.
sub net_payable {
    my ($self, %args) = @_;
    my $domestic = $args{domestic} // 0;

    my $domestic_tax = $self->domestic_tax($domestic);
    return $domestic_tax unless $self->bbo_at_border;

    return $self->_round($domestic_tax - $self->customs_offset($args{customs}));
}

sub _round {
    my ($self, $amount) = @_;
    return sprintf('%.2f', $amount) + 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba::Role::BBO::TaxYear - A role that implements BBO (turnover tax) logic

=head1 VERSION

version 0.016

=head1 DESCRIPTION

Shared BBO (turnover tax) calculation logic, composed into a per-tax-year
class the same way L<Finance::Tax::Aruba::Role::Income::TaxYear> is --
see L<Finance::Tax::Aruba::BBO> for the year-dispatching factory.

=head1 REQUIRED METHODS

=head2 is_year

Year selector method, same contract as
L<Finance::Tax::Aruba::Role::Income::TaxYear/is_year>.

=head1 ATTRIBUTES

=head2 rate

The total rate, as a decimal: C<bazv_rate> plus C<bbo_rate> plus
C<bavp_rate>, so 7%.

=head2 bazv_rate

The BAZV part of the rate, 3%.

=head2 bbo_rate

The BBO part of the rate, 2.5%.

=head2 bavp_rate

The BAVP part of the rate, 1.5%.

=head2 bbo_at_border

Whether import BBO is creditable against domestic BBO owed for this tax
year. Defaults to false; a year class overrides this once it's known which
years this applies to.

=head1 METHODS

=head2 domestic_tax($amount)

=head2 domestic_tax_bazv($amount)

=head2 domestic_tax_bavp($amount)

=head2 domestic_tax_bbo($amount)

The BAZV, BAVP and BBO parts of C<domestic_tax>. They always add up to it.

=head2 domestic_net($amount)

=head2 import_tax($amount)

An estimate of the BBO Customs will invoice. The actual customs invoice is what
is offset.

=head2 export_tax($amount)

=head2 net_payable(domestic => $domestic, customs => \@invoices)

Each customs invoice is C<< { amount => 70, held => 1 } >>. Only held invoices
offset the domestic BBO owed. An invoice the seller paid without forwarding it
to you has C<< held => 0 >> and cannot be offset.

=head2 customs_offset(\@invoices)

The sum of the held customs invoices.

=head2 customs_not_forwarded(\@invoices)

The sum of the invoices not forwarded to you, which cannot be offset.

See L<Finance::Tax::Aruba::BBO> for the full description of each.

=head1 SEE ALSO

L<Finance::Tax::Aruba::BBO>, L<Finance::Tax::Aruba::Role::Income::TaxYear>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
