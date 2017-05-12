#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000::Length_for_Age::Infant::Female;

our ($VERSION) = '1.00';

use Moo::Lax;    # Vanilla Moo considered harmful

extends 'Medical::Growth::NHANES_2000::Base';

__PACKAGE__->_declare_params_LMS;

1;

# lenageinf, sex = 2

__DATA__

0	-1.295960857	49.28639612	0.05008556
0.5	-0.809249882	51.68358057	0.046818545
1.5	-0.050782985	55.28612813	0.0434439
2.5	0.476851407	58.09381906	0.041716103
3.5	0.843299612	60.45980763	0.040705173
4.5	1.097562257	62.53669656	0.040079765
5.5	1.272509641	64.40632762	0.039686845
6.5	1.390428859	66.11841553	0.039444555
7.5	1.466733925	67.70574419	0.039304738
8.5	1.512301976	69.19123614	0.03923711
9.5	1.534950767	70.59163924	0.039221665
10.5	1.540390875	71.91961673	0.039244672
11.5	1.532852892	73.1850104	0.03929642
12.5	1.51550947	74.39564379	0.039369875
13.5	1.490765028	75.5578544	0.039459832
14.5	1.460458255	76.67685871	0.039562382
15.5	1.426006009	77.75700986	0.039674542
16.5	1.388507095	78.80198406	0.03979401
17.5	1.348818127	79.81491852	0.039918994
18.5	1.307609654	80.79851532	0.040048084
19.5	1.265408149	81.75512092	0.040180162
20.5	1.222627732	82.6867881	0.04031434
21.5	1.179594365	83.59532461	0.040449904
22.5	1.136564448	84.48233206	0.040586283
23.5	1.093731947	85.34923624	0.040723015
24.5	1.051272912	86.1973169	0.040859727
25.5	1.041951175	87.09026318	0.041142161
26.5	1.012592236	87.95714182	0.041349399
27.5	0.970541909	88.7960184	0.041500428
28.5	0.921129988	89.6055115	0.041610508
29.5	0.868221392	90.38476689	0.041691761
30.5	0.81454413	91.13341722	0.04175368
31.5	0.761957977	91.8515436	0.041803562
32.5	0.711660228	92.5396352	0.041846882
33.5	0.664323379	93.19854429	0.041887626
34.5	0.620285102	93.82945392	0.041928568
35.5	0.57955631	94.43382278	0.041971514

__END__

=head1 NAME

Medical::Growth::NHANES_2000::Length_for_Age::Infant::Female

=head1 SYNOPSIS

  use Medical::Growth::NHANES_2000;
  Medical::Growth::NHANES_2000->find_measure_class(
    ages => 'Infant', sex => 'Female',
    measure => 'Length for Age')->pct_for_value($len,$age);

=head1 DESCRIPTION

This class provides the NHANES 2000 parameters for length-for-age
tables for girls ages 0-36 months.

Length values are expressed in centimeters, and ages in months.

For details of the methods provided to operate on observations, please see
L<Medical::Growth::NHANES_2000::Base>.  For overall information on use of
the NHANES 2000 system, please see L<Medical::Growth::NHANES_2000>.

=head1 VERSION

version 1.00

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2014 Charles Bailey.

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=head1 ACKNOWLEDGMENT

The code incorporated into this package was originally written with
United States federal funding as part of research work done by the
author at the Children's Hospital of Philadelphia.

=cut

