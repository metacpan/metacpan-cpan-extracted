package Math::Business::BlackScholes::Binaries::Greeks;
use strict;
use warnings;

# ABSTRACT: calculate the sensitivity of the price of binary options

our $VERSION = '0.06';

1;

__END__

=head1 NAME

Math::Business::BlackScholes::Binaries::Greeks

=head1 SYNOPSIS

    use Math::Business::BlackScholes::Binaries::Greeks::Delta;
    use Math::Business::BlackScholes::Binaries::Greeks::Gamma;

    # get the Delta for a call option
    my $delta_call =
        Math::Business::BlackScholes::Binaries::Greeks::Delta::call(
            1.35,       # stock price
            1.36,       # barrier
            (7/365),    # time
            0.002,      # payout currency interest rate (0.05 = 5%)
            0.001,      # quanto drift adjustment (0.05 = 5%)
            0.11,       # volatility (0.3 = 30%)
        );

    # get the Gamma for a put option
    my $gamma_put =
        Math::Business::BlackScholes::Binaries::Greeks::Gamma::put(
            1.35,       # stock price
            1.36,       # barrier
            (7/365),    # time
            0.002,      # payout currency interest rate (0.05 = 5%)
            0.001,      # quanto drift adjustment (0.05 = 5%)
            0.11,       # volatility (0.3 = 30%)
        );

=head1 DESCRIPTION

The Greeks modules calculate the sensitivity of the price of binary options to a
change in the underlying parameters of the financial asset.

B<First-order Greeks>

=over 4

=item * Math::Business::BlackScholes::Binaries::Greeks::Delta

=item * Math::Business::BlackScholes::Binaries::Greeks::Vega

=item * Math::Business::BlackScholes::Binaries::Greeks::Theta

=back

B<Second-order Greeks>

=over 4

=item * Math::Business::BlackScholes::Binaries::Greeks::Gamma

=item * Math::Business::BlackScholes::Binaries::Greeks::Vanna

=item * Math::Business::BlackScholes::Binaries::Greeks::Volga

=back

=head1 SUBROUTINES

These can be called for each of the six Greeks modules

=head2 vanilla_call

    USAGE
    my $sensitivity = vanilla_call($S, $K, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $K => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 vanilla_put

    USAGE
    my $sensitivity = vanilla_put($S, $K, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $K => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 call

    USAGE
    my $sensitivity = call($S, $K, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $K => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 put

    USAGE
    my $sensitivity = put($S, $K, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $K => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 expirymiss

    USAGE
    my $sensitivity = expirymiss($S, $U, $D, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $U => barrier
    $D => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 expiryrange

    USAGE
    my $sensitivity = expiryrange($S, $U, $D, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $U => barrier
    $D => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 onetouch

    USAGE
    my $sensitivity = onetouch($S, $U, $D, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $U => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 notouch

    USAGE
    my $sensitivity = notouch($S, $U, $D, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $U => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

=cut

=head2 upordown

    USAGE
    my $sensitivity = upordown($S, $U, $D, $t, $r_q, $mu, $sigma, $w)

    PARAMS
    $S stock price
    $U barrier
    $D barrier
    $t time (1 = 1 year)
    $r_q payout currency interest rate (0.05 = 5%)
    $mu quanto drift adjustment (0.05 = 5%)
    $sigma volatility (0.3 = 30%)
    $w payout at hit=0, at end=1

=cut

=head2 range

    USAGE
    my $sensitivity = range($S, $U, $D, $t, $r_q, $mu, $sigma, $w)

    PARAMS
    $S stock price
    $t time (1 = 1 year)
    $U barrier
    $D barrier
    $r_q payout currency interest rate (0.05 = 5%)
    $mu quanto drift adjustment (0.05 = 5%)
    $sigma volatility (0.3 = 30%)
    $w payout at hit=0, at end=1

=cut

=head1 DEPENDENCIES

=over 4

=item L<Math::CDF>

=item L<Math::Trig>

=item L<Math::Business::BlackScholesMerton>

=back

=head1 SOURCE CODE

L<Github|https://github.com/binary-com/perl-Math-Business-BlackScholes-Binaries-Greeks>

=head1 REFERENCES

L<Wikipedia|http://en.wikipedia.org/wiki/Greeks_(finance)>

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-business-blackscholes-binaries-greeks at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Business-BlackScholes-Binaries-Greeks>.
We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Business::BlackScholes::Binaries::Greeks


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Business-BlackScholes-Binaries-Greeks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Business-BlackScholes-Binaries-Greeks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Business-BlackScholes-Binaries-Greeks>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Business-BlackScholes-Binaries-Greeks/>

=back


=cut

