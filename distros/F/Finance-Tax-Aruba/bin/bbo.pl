#!/usr/bin/perl
use warnings;
use strict;

# PODNAME: bbo.pl
# ABSTRACT: A BBO (Aruba turnover tax) calculator

use DateTime;
use Finance::Tax::Aruba::BBO;
use Getopt::Long;
use Pod::Usage;
use Text::Table;

my %opts = (
    domestic => 0,
    import   => 0,
    export   => 0,
    help     => 0,
    'customs-bbo-paid'   => [],
    'customs-bbo-seller' => [],
);

{
    local $SIG{__WARN__};
    my $ok = eval {
        GetOptions(\%opts, qw(
            help
            year=i
            rate=f
            domestic=f
            import=f
            export=f
            customs-bbo-paid=f@
            customs-bbo-seller=f@
        ));
    };
    if (!$ok) {
        die($@);
    }
}

pod2usage(0) if $opts{help};

$opts{year} //= DateTime->now->year;

my $calc = Finance::Tax::Aruba::BBO->tax_year(
    $opts{year},
    exists $opts{rate} ? (rate => $opts{rate}) : (),
);

my @customs = (
    (map { { amount => $_, held => 1 } } @{ $opts{'customs-bbo-paid'} }),
    (map { { amount => $_, held => 0 } } @{ $opts{'customs-bbo-seller'} }),
);

sub _p { return sprintf('%.2f', shift) }

my @rows = (
    ['Domestic sales',       _p($opts{domestic})],
    [sprintf('BBO (%s%%)', $calc->bbo_rate * 100), _p($calc->domestic_tax_bbo($opts{domestic}))],
    [sprintf('BAZV (%s%%)', $calc->bazv_rate * 100), _p($calc->domestic_tax_bazv($opts{domestic}))],
    ['Domestic BBO owed',    _p($calc->domestic_tax($opts{domestic}))],
    ['Domestic net (kept)',  _p($calc->domestic_net($opts{domestic}))],
    ['-', '-'],
    ['Imports',              _p($opts{import})],
    ['Estimated customs BBO', _p($calc->import_tax($opts{import}))],
    ['Customs BBO offset',   _p($calc->customs_offset(\@customs))],
    ['Customs BBO not forwarded', _p($calc->customs_not_forwarded(\@customs))],
    ['-', '-'],
    ['Exports (zero-rated)', _p($opts{export})],
    ['BBO on exports',       _p($calc->export_tax($opts{export}))],
    ['-', '-'],
    ['Net BBO payable',      _p($calc->net_payable(domestic => $opts{domestic}, customs => \@customs))],
);

my $tb = Text::Table->new('What', 'AWG');
$tb->load(@rows);
print $tb;

__END__

=pod

=encoding UTF-8

=head1 NAME

bbo.pl - A BBO (Aruba turnover tax) calculator

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    bbo.pl OPTIONS

    bbo.pl --domestic 2000 --customs-bbo-paid 70 --customs-bbo-seller 35

=head1 DESCRIPTION

Calculate BBO (Belasting op Bedrijfsomzetten), Aruba's turnover tax, for a
filing period, including the import credit against domestic BBO owed.

The BBO owed is the BBO part (4%) and the BAZV part (3%) combined, 7% in total.

=head1 OPTIONS

=over

=item --domestic

Total domestic sales for the period (BBO-inclusive billed amount).
Defaults to C<0>.

=item --import

Total value of goods imported for the period, used to estimate the customs BBO.
Defaults to C<0>.

=item --customs-bbo-paid

The amount of a customs BBO invoice paid either by you or by the seller, where
you hold the invoice (the seller forwarded it). Repeatable. It offsets the
domestic BBO owed.

=item --customs-bbo-seller

The amount of a customs BBO invoice paid by the seller, who did not forward the
invoice to you. Repeatable. It cannot be offset and is only reported.

=item --export

Total value billed to clients outside Aruba. Zero-rated -- shown for
reference only, has no effect on the BBO owed. Defaults to C<0>.

=item --year

The tax year to calculate for -- selects the rate and rules (see
L<Finance::Tax::Aruba::BBO>). Defaults to the current year.

=item --rate

Override the tax year's own BBO rate, as a decimal (e.g. C<0.07> for 7%).
Rarely needed -- normally left to whatever C<--year> implies.

=back

=head1 SEE ALSO

L<Finance::Tax::Aruba::BBO>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
