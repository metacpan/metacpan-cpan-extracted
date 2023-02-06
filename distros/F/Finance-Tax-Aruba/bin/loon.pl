#!/usr/bin/perl
use warnings;
use strict;

# PODNAME: loon.pl
# ABSTRACT: A salary cost calculator

use Data::Dumper;
use DateTime;
use Finance::Tax::Aruba::Income;
use Getopt::Long;
use Pod::Usage;
use Text::Table;

my %opts = (
    months => 12,
    help   => 0,
    cur    => 'awg',
    yearly => 0,
);

{
    local $SIG{__WARN__};
    my $ok = eval {
        GetOptions(\%opts, qw(
                help
                cur=s
                months=i
                rate=f
                from
                year=s
                yearly
            ),
            'pension-employee=f',
            'pension-employer=f',
            'tax-free=f',
            'bonus=f',
            'year=i',
            'fringe=f',
        );
    };
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

$opts{'tax-free'} = ($opts{'tax-free'} // 0) * $months;
$opts{'fringe'} //= 0;

if ($opts{yearly}) {
    $maandloon = $maandloon / $months;
}

$opts{year} //= DateTime->now->year;

my $calc = Finance::Tax::Aruba::Income->tax_year(
    $opts{year},
    income => $maandloon,
    months => $opts{months},
    exists $opts{'pension-employee'}
        ? (pension_employee_perc => $opts{'pension-employee'})
        : (),
    exists $opts{'pension-employer'}
        ? (pension_employer_perc => $opts{'pension-employer'})
        : (),

    exists $opts{'bonus'}
        ? (bonus => $opts{'bonus'})
        : (),
    $opts{'fringe'}
        ? (fringe => $opts{'fringe'})
        : (),
    $opts{'tax-free'}
        ? (tax_free => $opts{'tax-free'})
        : (),

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
    fringe
    bonus
    werving
    jaarloon
    -
    pensioen_employee
    azv
    aov
    -
    zuiver
    tabelinkomen
    taxed
    rate
    fixed_tax
    var_tax
    total_tax
    -
    free
    netto
    tax_free
    wage
    -
    azv_employer
    aov_employer
    pensioen_employer
    -
    azv_total
    aov_total
    pensioen
    cost_employer
    -
    gov_gets
    effective_rate
);

my $jaarloon_bruto = $calc->yearly_income_gross;
my $jaarloon       = $calc->yearly_income;

my $pensioen = $calc->pension_total;
my $tax_free = $calc->taxfree_amount;

my $azv_total = $calc->azv_premium;
my $aov_total = $calc->aov_premium;

my $gov_gets = $calc->income_tax + $azv_total + $aov_total;

my $effective_rate = $gov_gets / $jaarloon * 100;

my %year = (
    bruto          => $calc->yearly_income_gross,
    jaarloon       => $calc->yearly_income,
    netto          => $calc->tax_free_wage,
    werving        => $calc->wervingskosten,
    azv            => $calc->azv_employee,
    aov            => $calc->aov_employee,
    zuiver         => $calc->zuiver_jaarloon,
    tabelinkomen   => $calc->taxable_wage,
    taxed          => $calc->taxable_amount,
    fixed_tax      => $calc->tax_fixed,
    var_tax        => $calc->tax_variable,
    total_tax      => $calc->income_tax,
    rate           => $calc->tax_rate,
    azv_employer   => $calc->azv_employer,
    aov_employer   => $calc->aov_employer,
    conv_rate      => $opts{rate},
    free           => $calc->taxfree_amount,
    wage           => $calc->net_income,
    pensioen_employee => $calc->pension_employee,
    pensioen_employer => $calc->pension_employer,
    pensioen       => $calc->pension_total,
    cost_employer  => $calc->company_costs,
    effective_rate => $effective_rate,
    gov_gets       => $gov_gets,
    azv_total      => $calc->azv_premium,
    aov_total      => $calc->aov_premium,
    tax_free       => $calc->tax_free,
    bonus          => $calc->bonus,
    fringe         => $calc->fringe,
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
    fixed_tax      => 'Vaste belasting',
    var_tax        => 'Variable belasting',
    total_tax      => 'Totale belastingen',
    rate           => 'Belastingtarief',
    effective_rate => 'Effectief belastingtarief',
    $opts{rate} ? (conv_rate => "$opts{rate}awg/1eur") : (),
    free           => "Belastingvrije voet",
    tax_free       => "Onbelastbaar inkomen",
    wage           => "Uit te betalen loon",
    pensioen_employee => sprintf('Pension (%s%%)', $calc->pension_employee_perc),
    pensioen_employer => sprintf('Pension (%s%%)', $calc->pension_employer_perc),
    pensioen       => sprintf('Pension Totaal (%s%%)',
        $calc->pension_employee_perc + $calc->pension_employer_perc),
    cost_employer  => "Totale loonkosten bedrijf",

    azv_total => sprintf('AZV Totaal (%s%%)',
        $calc->azv_percentage_employee + $calc->azv_percentage_employer),

    aov_total => sprintf('OAV/AWW Totaal (%s%%)',
        $calc->aov_percentage_employee + $calc->aov_percentage_employer),

    gov_gets       => "Social premiums and taxes",
    bonus          => "Bonus",
    fringe         => "Fringe benefits"
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

version 0.006

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

The monthly amount is in the currency used by the C<--cur> option.

=item --pension-employee

The mandatory pension percentage paid by the employee

=item --pension-employer

The mandatory pension percentage paid by the employer

=item --tax-free

Add the amount of tax free income to your paycheck

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
