package Format::Util::Numbers;

use 5.006;
use strict;
use warnings FATAL => 'all';

use base 'Exporter';
our @EXPORT_OK = qw/commas to_monetary_number_format roundnear roundcommon financialrounding formatnumber get_min_unit/;

use Carp qw(cluck);
use Scalar::Util qw(looks_like_number);
use POSIX qw(ceil);
use YAML::XS;
use File::ShareDir;
use Math::BigFloat lib => 'Calc';

=head1 NAME

Format::Util::Numbers - Miscellaneous routines to do with manipulating number format!

=cut

our $VERSION = '0.15';    ## VERSION

=head1 SYNOPSIS

    use Format::Util::Numbers qw( commas to_monetary_number_format roundnear formatnumber financialrounding);
    ...

=head1 EXPORT

=head2 roundnear

Round a number near the precision of the supplied one.

    roundnear( 0.01, 12345.678) => 12345.68

=cut

{
    #cf. Math::Round
    my $halfdec = do {
        my $halfhex = unpack('H*', pack('d', 0.5));
        if (substr($halfhex, 0, 2) ne '00' && substr($halfhex, -2) eq '00') {
            substr($halfhex, -4) = '1000';
        } else {
            substr($halfhex, 0, 4) = '0010';
        }
        unpack('d', pack('H*', $halfhex));
    };

    sub roundnear {
        my ($targ, $input) = @_;

        return $input if (not defined $input);

        my $rounded = $input;
        # rounding to 0, doesnt really make sense, but viewing it as a limit process
        # it means do not round at all
        if ($targ != 0) {
            $rounded =
                ($input >= 0)
                ? $targ * int(($input + $halfdec * $targ) / $targ)
                : $targ * ceil(($input - $halfdec * $targ) / $targ);
        }
        # Avoid any possible -0 rounding situations.
        return 1 * $rounded;
    }
}

# format of precsion should be
# TYPE:
#   CURRENCY: PRECISION
my $precisions = YAML::XS::LoadFile($ENV{FORMAT_UTIL_PRECISION} // File::ShareDir::dist_file('Format-Util', 'precision.yml'));
my $floating_point_regex = qr/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/;

=head2 commas

Produce a more human readbale number with a provided number of decimal points

    commas(12345.679, 1) => 12,345.7

=cut

sub commas {
    my ($x, $decimal_point) = @_;

    my $output = $x;
    return $output if not looks_like_number($x);

    if ($x < 0) {
        $output = '-' . commas(-1 * $x, $decimal_point);
    } else {
        # Split non-decimal and decimal value
        $x = $x * 1;
        $x =~ /^(\d*)(\.?\d*)/;
        $x = $1;
        my $last_num = $2;

        my @segments;
        while ($x =~ s/(\d{3})$//) {
            unshift @segments, $1;
        }
        if ($x) {
            unshift @segments, $x;
        } elsif (not scalar @segments) {
            unshift @segments, 0;
        }
        if ($decimal_point) {
            my $format = '%.' . int($decimal_point) . 'f';
            $last_num = sprintf $format, $last_num;
            $last_num =~ s/^0//;
        } elsif (defined $decimal_point) {
            $segments[-1]++ if $last_num && $last_num > 0.5;
            $last_num = '';
        }
        $output = (join ',', @segments) . $last_num;
    }

    return $output;
}

=head2 to_monetary_number_format

Produce a nice human readable number which looks like a currency

    to_monetary_number_format(123456789) => 123,456,789.00

=cut

sub to_monetary_number_format {
    # This routine is adjusted for our system, but the basic algorithm
    # is from Perl Cookbook, 1st Ed, Recipe 2.17
    my ($text, $remove_decimal_for_ints) = @_;

    $text //= 0;

    if (looks_like_number($text)) {
        $text = reverse sprintf "%.2f", $text;
        $text =~ s/(\d{3})/$1,/g;
        $text =~ s/^,|,$//g;
        $text =~ s/,-$/-/g;
        $text = scalar reverse $text;
        $text =~ s/\.00$// if ($remove_decimal_for_ints);
    }

    return $text;
}

=head2 formatnumber

This sub is used to format number as per precision defined
per currency.

Use this sub only for formatting not for rounding, i.e
use this in modules which are used for display purpose
only i.e client facing.

DON'T USE THIS FOR CALCULATION, COMPARISON OF NUMBERS
DON'T USE THIS FOR QUANTITATIVE ANALYSIS

This sub accepts type i.e whether its price or amount
- price e.g. ask price, bid price
- amount e.g. balance, deposit/withdraw amount

and takes currency to calculate precision defined per
currency.

this subs takes precision defined per currency in config file passed by
ENV{FORMAT_UTIL_PRECISION}, else it defaults to precision.yml

Returns string

    formatnumber('price', 'USD', 10) => 10.00

=cut

sub formatnumber {
    my ($type, $currency, $val) = @_;

    # return val if any one of value, currency or type is invalid
    return $val
        if ((
            not defined $val
            or $val !~ $floating_point_regex
        )
        or not defined $precisions->{$type // 'unknown-type'}
        or not defined $precisions->{$type}->{$currency // 'unknown-type'});

    return sprintf('%0.0' . $precisions->{$type}->{$currency} . 'f', $val);
}

=head2 financialrounding

This sub is used to round number as per precision defined
per currency.

Use this sub only for rounding numbers thats are related
to currency like price, amount, balance etc

USE THIS WHEN YOU WANT TO COMPARE NUMBERS RELATED TO CURRENCY
USE THIS FOR QUANTITATIVE ANALYSIS FOR NUMBER RELATED TO CURRENCY

This sub accepts type i.e whether its price or amount
- price e.g. ask price, bid price
- amount e.g. balance, deposit/withdraw amount

and takes currency to calculate precision defined per
currency.

this subs takes precision defined per currency in config file passed by
ENV{FORMAT_UTIL_PRECISION}, else it defaults to precision.yml

Returns string

    financialrounding('amount', 'USD', 10.345) => '10.35'

=cut

sub financialrounding {
    my ($type, $currency, $val) = @_;

    # return val if any one of value, currency or type is invalid
    return $val
        if ((
            not defined $val
            or $val !~ $floating_point_regex
        )
        or not defined $precisions->{$type // 'unknown-type'}
        or not defined $precisions->{$type}->{$currency // 'unknown-type'});

    return _round_to_precison($precisions->{$type}->{$currency}, $val);
}

=head2 roundcommon

This sub rounds number as per precision passed, this sub
should be used for numbers not related to currencies like
probabilities, percentages etc

This sub use round away from zero technique, same as
financial rounding, the only difference is it acccepts
precision as shown below and has no currency precision

Acceptable precision values format example:

0
1
1e-4
0.0001

This sub only supports rounding to one tenths, hundredths,
thousandths and so on. It does not support rounding to two,
three tenths, hundredths or so, use roundnear for that.

This sub is created as replacement for roundnear as roundnear
for small numbers it does round away from zero,
for numbers with more significant digits it's sort-of random

Returns string

    roundcommon(0.01, 10.234) => '10.23'

=cut

sub roundcommon {
    my ($precision, $val) = @_;

    return $val
        if ((
            not defined $val
            or $val !~ $floating_point_regex
        )
        or (not defined $precision or $precision !~ /^(?:1(?:[eE][-]?[0-9]+)?|0(?:\.0*1)?)$/ or $precision == 0));

    # get the number of decimal places needed by BigFloat
    $precision = log(1 / $precision) / log(10);

    return _round_to_precison($precision, $val);
}

=head2 get_precision_config

This is used get complete currency precision config.

=cut

sub get_precision_config {
    return $precisions;
}

=head2 get_min_unit

Given a currency, this subroutine obtains the smallest possible unit of a currency using the currency's pip size.

For example, if the currency requested is USD, this function will return 0.01.

Everything returned in this function is considered a price.

=cut

sub get_min_unit {

    my $currency = shift;

    die "Currency $currency and/or its precision is not defined."
        if ((not defined $currency)
        or not defined $precisions->{price}->{$currency // 'unknown-type'});

    # For cases where the precision is 0, we return 1 as the smallest denomination
    return 1 if $precisions->{price}->{$currency} == 0;

    return formatnumber('price', $currency, 1 / 10**($precisions->{price}->{$currency}));
}

# common sub used by roundcommon and financialrounding
sub _round_to_precison {
    my ($precision, $val) = @_;

    my $x = Math::BigFloat->bzero();
    $x->badd($val)->bfround('-' . $precision, 'common');

    return $x->bstr();
}

=head1 AUTHOR

binary.com, C<< <rakesh at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-format-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Format-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Format::Util::Numbers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Format-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Format-Util>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Format-Util>

=item * Search CPAN

L<http://search.cpan.org/dist/Format-Util/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;    # End of Format::Util::Numbers
