package Finance::USDX;
$Finance::USDX::VERSION = '0.03';
use parent 'Exporter';
our @EXPORT = ('usdx');

use 5.006;
use strict;
use warnings;

use Finance::Quote;

=encoding UTF-8

=head1 NAME

Finance::USDX - Compute USDX (US Dollar Index)

=head1 SYNOPSIS

    use Finance::USDX;

    # get "live" USDX using YAHOO finance values (through Finance::Quote)
    my $usdx = usdx();

    # compute USDX given specfic conversion rates
    my $usdx = usdx(eurusd => 1.2976, usdjpy => 79.846,
                    gbpusd => 1.5947, usdcad => 0.9929,
                    usdsek => 6.6491, usdchf => 0.9331);

=head1 DESCRIPTION

Just exports an 'usdx' subroutine that returns the current USDX value.

=head2 usdx

If called without arguments, returns the "current" USDX value using
data from YAHOO finance website, using Finance::Quote module.

If called with argument, then the hashtable must have six key/value
pairs, with rates for currency convertion. Note that two of the keys
are not usd->other convertions. All exact keys are required.

=cut

sub usdx {
    my ($eurusd, $usdjpy, $gbpusd, $usdcad, $usdsek, $usdchf);
    my @keys = qw(eurusd usdjpy gbpusd usdcad usdsek usdchf);
    if (@_) {
        my %values = @_;
        for my $k (@keys) {
            die "Call to 'usdx' misses key '$k'" unless exists($values{$k});
            eval "\$$k = \$values{\$k};"
        }
    } else {
        my $q = Finance::Quote->new;
        $eurusd = $q->currency('EUR' => 'USD');
        $usdjpy = $q->currency('USD' => 'JPY');
        $gbpusd = $q->currency('GBP' => 'USD');
        $usdcad = $q->currency('USD' => 'CAD');
        $usdsek = $q->currency('USD' => 'SEK');
        $usdchf = $q->currency('USD' => 'CHF');
    }
    my $usdx = 50.14348112 * $eurusd**(-0.576) * $usdjpy**(0.136) * $gbpusd**(-0.119) * $usdcad**(0.091) * $usdsek**(0.042) * $usdchf**(0.036);
    return $usdx;
}

=head1 AUTHOR

Alberto Simões, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-usdx at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-USDX>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::USDX

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-USDX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-USDX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-USDX>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-USDX/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alberto Simões.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Finance::USDX
