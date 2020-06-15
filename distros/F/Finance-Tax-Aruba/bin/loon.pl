#!/usr/bin/perl
use warnings;
use strict;

# PODNAME: loon.pl
# ABSTRACT: A salary cost calculator

use Text::Table;
use Finance::Tax::Aruba::Income;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

my %opts = (
    months => 12,
    help   => 0,
    cur    => 'awg',
    year   => 2020,
);

{
    local $SIG{__WARN__};
    my $ok = eval { GetOptions(\%opts, qw(help cur=s months=i rate=f from year=s)); };
    if (!$ok) {
        die($@);
    }
}

pod2usage(0) if ($opts{help});
pod2usage(1) if !$ARGV[0];

$opts{cur} = lc($opts{cur});

sub to_awg {
    my $cur = shift;
    return $cur if $opts{cur} eq 'awg';

    $opts{rate} ||= 1.79 if $opts{cur} eq 'usd';
    $opts{rate} ||= 2;

    return $cur * $opts{rate} if $opts{from};
    return $cur;
}

sub to_cur {
    my $cur = shift;
    return $cur if $opts{cur} eq 'awg';
    return $cur / $opts{rate};
}

my $maandloon = to_awg($ARGV[0]);
my $months    = $opts{months};

my $calc = Finance::Tax::Aruba::Income->tax_year(
    $opts{year},
    income => $maandloon,
    months => $opts{months},
);

sub _p {
    my $val = shift;
    my $decimal = shift // 2;
    return sprintf("%.${decimal}f", $val);
}

my @header = qw(what awg/y awg/m);

if ($opts{cur} ne 'awg') {
    push(@header, 'conv', "$opts{cur}/y", "$opts{cur}/m");
}

my @order = qw(
    -
    bruto
    werving
    jaarloon
    -
    azv
    aov
    -
    zuiver
    tabelinkomen
    taxed
    rate
    effective_rate
    fixed
    var
    total
    -
    free
    netto
    netto_inc
    -
    azv_employer
    aov_employer
    pensioen
    cost_employer
    azv_total
    aov_total
);

my $jaarloon_bruto = $calc->yearly_income_gross;
my $jaarloon       = $calc->yearly_income;

my $vakantiegeld = $jaarloon - ($jaarloon / 1.08);
my $ziekgeld     = $jaarloon - ($jaarloon / 1.03);

my $pensioen = $calc->get_cost($jaarloon, 6);
my $tax_free = $calc->taxfree_amount;

my $netto = $jaarloon
    - $calc->income_tax
    - $calc->aov_employee
    - $calc->azv_employee
    - $calc->taxfree_amount;

my $payable = $netto + $tax_free;

my $company_pays = $jaarloon + $calc->aov_employer + $calc->azv_employer + $pensioen;

my $effective_rate = 100 - (($payable / $jaarloon) * 100);

my %year = (
    bruto          => $calc->yearly_income_gross,
    jaarloon       => $calc->yearly_income,
    netto          => $netto,
    werving        => $calc->wervingskosten,
    azv            => $calc->azv_employee,
    aov            => $calc->aov_employee,
    zuiver         => $calc->zuiver_jaarloon,
    tabelinkomen   => $calc->taxable_wage,
    taxed          => $calc->taxable_amount,
    fixed          => $calc->tax_fixed,
    var            => $calc->tax_variable,
    total          => $calc->income_tax,
    rate           => $calc->tax_rate,
    azv_employer   => $calc->azv_employer,
    aov_employer   => $calc->aov_employer,
    conv_rate      => $opts{rate},
    free           => $calc->taxfree_amount,
    netto_inc      => $payable,
    pensioen       => $pensioen,
    cost_employer  => $company_pays,
    effective_rate => $effective_rate,
    azv_total      => $calc->azv_employee + $calc->azv_employer,
    aov_total      => $calc->aov_employee + $calc->aov_employer,
);

my %mapping = (
    bruto          => 'Bruto',
    jaarloon       => 'Jaarloon',
    netto          => 'Netto',
    werving        => 'Wervingskosten',
    azv            => sprintf('AZV (%s%%)', $calc->azv_percentage_employee),
    azv_employer   => sprintf('AZV (%s%%)', $calc->azv_percentage_employer),
    aov            => sprintf('AOV/AWW (%s%%)', $calc->aov_percentage_employee),
    aov_employer   => sprintf('AOV/AWW (%s%%)', $calc->aov_percentage_employer),
    zuiver         => 'Zuiver jaarloon',
    tabelinkomen   => 'Tabelinkomen',
    taxed          => 'Belastbaar inkomen',
    fixed          => 'Vaste belasting',
    var            => 'Variable belasting',
    total          => 'Totale belastingen',
    rate           => 'Belastingtarief',
    effective_rate => 'Effectief belastingtarief',
    $opts{rate} ? (conv_rate => "$opts{rate}awg/1eur") : (),
    free           => "Belastingvrije voet",
    netto_inc      => "Uit te betalen loon",
    pensioen       => "Pensioenkosten (6%)",
    cost_employer  => "Totale loonkosten bedrijf",

    azv_total => sprintf('AZV Totaal (%s%%)',
        $calc->azv_percentage_employee + $calc->azv_percentage_employer),

    aov_total => sprintf('OAV/AWW Totaal (%s%%)',
        $calc->aov_percentage_employee + $calc->aov_percentage_employer)
);

my ($longest) = sort { length($b) <=> length($a) } values %mapping;
my $l = length($longest);
$mapping{'-'} = '-' x $l;

my @rows;

foreach (@order) {
    if ($_ eq '-') {
        push(@rows, [$mapping{$_}, map { '---------' } (0 .. 4)]);
    }
    elsif ($_ eq 'rate' || $_ eq 'effective_rate') {
        push(
            @rows,
            [
                $mapping{$_}, _p($year{$_}), _p($year{$_}),
                $opts{cur} ne 'awg' ? ('', _p($year{$_}), _p($year{$_})) : (),
            ]
        );
    }
    else {
        die "$_ is missing\n" if !defined $year{$_};
        push(
            @rows,
            [
                $mapping{$_},
                _p($year{$_}),
                _p($year{$_} / $months),
                $opts{cur} ne 'awg'
                ? (
                    _p($opts{rate}, 4), _p(to_cur($year{$_})),
                    _p(to_cur($year{$_} / $months))
                    )
                : (),
            ]
        );
    }
}

my $tb = Text::Table->new(@header);

print $tb->load(@rows);

__END__

=pod

=encoding UTF-8

=head1 NAME

loon.pl - A salary cost calculator

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    loon.pl OPTIONS <monthly amount>

=head1 DESCRIPTION

Calculate salary costs based on gross monthly income.

=head1 OPTIONS

=over

=item --cur

Currency, mainly used for display reasons. Defaults to C<awg>.

=item --rate

Conversion rate from Aruban Guilder to the used currency. 

When using USD as a currency the default becomes C<1.79>. When using other
currencies the default becomes C<2>.

=item --months

Define the amount of months. Defaults to C<12>.

=item --from

The monthly amount is in the currency used by the C<--cur> option. The

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
