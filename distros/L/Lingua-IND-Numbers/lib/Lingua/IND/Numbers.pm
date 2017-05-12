package Lingua::IND::Numbers;

$Lingua::IND::Numbers::VERSION   = '0.10';
$Lingua::IND::Numbers::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Lingua::IND::Numbers - Indian Numbering System representation

=head1 VERSION

Version 0.10

=cut

use 5.006;
use Data::Dumper;

use bignum;
use Moo;
use namespace::clean;

has 'chart' => (is => 'ro', default => sub { _get_chart() });
has 'units' => (is => 'ro', default => sub { _get_units() });

=head1 DESCRIPTION

The Indian Numbering System  is  used India, Pakistan, Bangladesh, Nepal, and Sri
Lanka. It is based on the Vedic numbering system in which numbers over 9,999  are
written in two-digit groups (or a mix of two- and three-digit groups) rather than
the three-digit groups used in most other parts of the world. In Pakistan,they do
not use this numbering system in English media but only in Urdu &  other regional
languages.

The  terms  lakh  (100,000)  and crore (10,000,000) are used in Indian English to
express large numbers.

    +------------------------------------+--------------------------------------+
    | Name                               | Indian Figure                        |
    +------------------------------------+--------------------------------------+
    | Shunya (Zero)                      | 0                                    |
    | Ek (One)                           | 1                                    |
    | Das (Ten)                          | 10                                   |
    | Sau (One Hundres)                  | 100                                  |
    | Hazaar (One Thousand)              | 1,000                                |
    | Das Hazaar (Ten Thousand)          | 10,000                               |
    | Lakh (Hundred Thousand)            | 1,00,000                             |
    | Das Lakh                           | 10,00,000                            |
    | Crore                              | 1,00,00,000                          |
    | Das Crore                          | 10,00,00,000                         |
    | Arab (One Hundred Crore)           | 1,00,00,00,000                       |
    | Das Arab (One Thousand Crore)      | 10,00,00,00,000                      |
    | Kharab (Ten Thousand Crore)        | 1,00,00,00,00,000                    |
    | Das Kharab (One Lakh Crore)        | 10,00,00,00,00,000                   |
    | Neel (Ten Lakh Crore)              | 1,00,00,00,00,00,000                 |
    | Das Neel (One Crore Crore)         | 10,00,00,00,00,00,000                |
    | Padm (Ten Crore Crore)             | 1,00,00,00,00,00,00,000              |
    | Das Padm (One Hundred Crore Crore) | 10,00,00,00,00,00,00,000             |
    | Shankh (One Lakh Lakh Crore)       | 1,00,00,00,00,00,00,00,000           |
    +------------------------------------+--------------------------------------+

Source: L<wikipedia|http://en.wikipedia.org/wiki/Indian_Numbering_System>

=head1 NUMBERS

    For example, 150000 becomes Ek Lakh Pachaas Hazar.

    +------------+--------+   +------------+--------+   +----------+---------+
    | Name       | Number |   | Name       | Number |   | Name     | Number  |
    +------------+--------+   +------------+--------+   +----------+---------+
    | Ek         |    1   |   | Egyarah    |   11   |   | Ekees    |   21    |
    | Do         |    2   |   | Barah      |   12   |   | Baees    |   22    |
    | Teen       |    3   |   | Terah      |   13   |   | Teyees   |   23    |
    | Chaar      |    4   |   | Chaudah    |   14   |   | Chaubees |   24    |
    | Paanch     |    5   |   | Pandrah    |   15   |   | Pachees  |   25    |
    | Chhe       |    6   |   | Solah      |   16   |   | Chhabbis |   26    |
    | Saat       |    7   |   | Satrah     |   17   |   | Satayees |   27    |
    | Aath       |    8   |   | Attharah   |   18   |   | Atthaees |   28    |
    | Nau        |    9   |   | Unnees     |   19   |   | Untees   |   29    |
    | Das        |   10   |   | Bees       |   20   |   | Tees     |   30    |
    +------------+--------+   +------------+--------+   +----------+---------+

    +------------+--------+   +------------+--------+   +-----------+--------+
    | Name       | Number |   | Name       | Number |   | Name      | Number |
    +------------+--------+   +------------+--------+   +-----------+--------+
    | Ektees     |   31   |   | Ektalees   |   41   |   | Ekaawan   |   51   |
    | Battees    |   32   |   | Beyalees   |   42   |   | Baawan    |   52   |
    | Taitees    |   33   |   | Taitalees  |   43   |   | Tirpan    |   53   |
    | Chautees   |   34   |   | Chaualees  |   44   |   | Chauwan   |   54   |
    | Paitees    |   35   |   | Paitalees  |   45   |   | Pachpan   |   55   |
    | Chhattess  |   36   |   | Chheyalees |   46   |   | Chhappan  |   56   |
    | Saitees    |   37   |   | Saitalees  |   47   |   | Santawan  |   57   |
    | Artees     |   38   |   | Artalees   |   48   |   | Anthawan  |   58   |
    | Unchalees  |   39   |   | Unchaas    |   49   |   | Unsath    |   59   |
    | Chalees    |   40   |   | Pachaas    |   50   |   | Saath     |   60   |
    +------------+--------+   +------------+--------+   +-----------+------- +

    +------------+--------+   +------------+--------+   +-----------+--------+
    | Name       | Number |   | Name       | Number |   | Name      | Number |
    +------------+--------+   +------------+--------+   +-----------+--------+
    | Eksath     |   61   |   | Ekhattar   |   71   |   | Ekaase    |   81   |
    | Baasath    |   62   |   | Bahattar   |   72   |   | Beraase   |   82   |
    | Tirsath    |   63   |   | Tehattar   |   73   |   | Teraase   |   83   |
    | Chausath   |   64   |   | Chauhattar |   74   |   | Chauraase |   84   |
    | Paisath    |   65   |   | Pachhattar |   75   |   | Pachaase  |   85   |
    | Chheyasath |   66   |   | Chheyattar |   76   |   | Chheyaase |   86   |
    | Sarsath    |   67   |   | Satattar   |   77   |   | Sataase   |   87   |
    | Arsath     |   68   |   | Atathar    |   78   |   | Atthaase  |   88   |
    | Unhattar   |   69   |   | Unnase     |   79   |   | Nawaase   |   89   |
    | Sattar     |   70   |   | Asse       |   80   |   | Nabbe     |   90   |
    +------------+--------+   +------------+--------+   +-----------+--------+

    +------------+--------+
    | Name       | Number |
    +------------+--------+
    | Ekkaanwe   |   91   |
    | Beraanwe   |   92   |
    | Teraanwe   |   93   |
    | Chauraanwe |   94   |
    | Panchaanwe |   95   |
    | Chheyaanwe |   96   |
    | Santaanwe  |   97   |
    | Anthaanwe  |   98   |
    | Neenaanwe  |   99   |
    +------------+--------+

=head1 METHODS

=head2 to_string($number)

It returns the number represented in the Indian Numbering System.

    use strict; use warnings;
    use Lingua::IND::Numbers;

    my $number = Lingua::IND::Numbers->new;
    my $input  = 123456;

    print "[$input]: ", $number->to_string($input), "\n";

=cut

sub to_string {
    my ($self, $arg) = @_;

    die "ERROR: Undefined number.\n"      unless defined $arg;
    die "ERROR: Invalid number [$arg].\n" unless ($arg =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
    die "ERROR: Only positive number.\n"  unless ($arg >= 0);

    return 'Shunya' if ($arg == 0);

    my $chart   = $self->chart;
    my $units   = $self->units;
    my $number  = ($arg + 0)->bstr();
    die "ERROR: No decimal number [$arg].\n" if ($number =~ /\./);
    my $size    = length($number);
    die "ERROR: No representation in Indian Numbering System.\n" if ($size > 18);

    my @digits  = split //, $number;
    my $string  = '';
    my $index   = 0;

    while ($size >= 1) {
        if ($size > 3) {
            if ($size % 2 == 0) {
                $index   = $digits[0];
                $string .= sprintf("%s %s ", $chart->[$index], $units->{$size});
                $number  = (join '', @digits[1..($size-1)]) + 0;
            }
            else {
                $index   = sprintf("%d%d"  , $digits[0], $digits[1]);
                $string .= sprintf("%s %s ", $chart->[$index], $units->{$size});
                $number  = (join '', @digits[2..($size-1)]) + 0;
            }
        }
        elsif ($size == 3) {
            $string .= sprintf("%s %s ", $chart->[$digits[0]], $units->{$size});
            $number  = (join '', @digits[1..2]) + 0;
        }
        else {
            ($size == 2)
            ?
            ($index  = sprintf("%d%d", $digits[0], $digits[1]))
            :
            ($index  = sprintf("%d", $digits[0]));
            $string .= sprintf("%s", $chart->[$index]);

            return $string;
        }

        if ($number > 0) {
            @digits = split //,$number;
            $size   = scalar(@digits);
        }
        else {
            $string =~ s/\s+$//;
            return $string;
        }
    }
}

#
#
# PRIVATE METHODS

sub _get_chart {

    return [
        '',
        qw/Ek       Do       Teen      Chaar      Paanch     Chhe       Saat      Aath      Nau       Das
           Egyarah  Barah    Terah     Chaudah    Pandrah    Solah      Satrah    Attharah  Unnees    Bees
           Ekees    Baees    Teyees    Chaubees   Pachees    Chhabbees  Satayees  Atthaees  Untees    Tees
           Ektees   Battees  Taithees  Chautees   Paitees    Chhattees  Saitees   Artees    Unchalees Chalees
           Ektalees Beyalees Taitalees Chaualees  Paitalees  Chheyalees Saitalees Artalees  Unchaas   Pachaas
           Ekaawan  Baawan   Tirpan    Chauwan    Pachpan    Chhappan   Santawan  Anthawan  Unsath    Saath
           Eksath   Baasath  Tirsath   Chausath   Paisath    Chheyasath Sarsath   Arsath    Unhattar  Sattar
           Ekhattar Bahattar Tehattar  Chauhattar Pachhattar Chheyattar Satattar  Atathar   Unnase    Asse
           Ekaase   Beraase  Teraase   Chauraase  Pachaase   Chheyaasee Sataase   Atthaase  Nawaase   Nabbe
           Ekkaanwe Beraanwe Teraanwe  Chauraanwe Panchaanwe Chheyaanwe Santaanwe Anthaanwe Neenaanwe/];
}

sub _get_units {

    return {
        18 => 'Shankh', 17 => 'Padm'  , 16 => 'Padm'  , 15 => 'Neel',
        14 => 'Neel'  , 13 => 'Kharab', 12 => 'Kharab', 11 => 'Arab',
        10 => 'Arab'  ,  9 => 'Crore' ,  8 => 'Crore' ,  7 => 'Lakh',
         6 => 'Lakh'  ,  5 => 'Hazaar',  4 => 'Hazaar',  3 => 'Sau' };
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Lingua-IND-Numbers>

=head1 BUGS

Please report any bugs/feature requests to C<bug-lingua-ind-numbers at rt.cpan.org>  or
through the web interface at  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-IND-Numbers>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::IND::Numbers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-IND-Numbers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-IND-Numbers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-IND-Numbers>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-IND-Numbers/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Lingua::IND::Numbers
