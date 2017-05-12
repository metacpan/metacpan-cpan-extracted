#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000::Length_for_Age::Infant::Male;

our ($VERSION) = '1.00';

use Moo::Lax;    # Vanilla Moo considered harmful

extends 'Medical::Growth::NHANES_2000::Base';

__PACKAGE__->_declare_params_LMS;

1;

# lenageinf, sex = 1

__DATA__

0	1.267004226	49.98888408	0.053112191
0.5	0.511237696	52.6959753	0.048692684
1.5	-0.45224446	56.62842855	0.04411683
2.5	-0.990594599	59.60895343	0.041795583
3.5	-1.285837689	62.07700027	0.040454126
4.5	-1.43031238	64.2168641	0.039633879
5.5	-1.47657547	66.1253149	0.039123813
6.5	-1.456837849	67.8601799	0.038811994
7.5	-1.391898768	69.45908458	0.038633209
8.5	-1.29571459	70.94803912	0.038546833
9.5	-1.177919048	72.34586111	0.038526262
10.5	-1.045326049	73.6666541	0.038553387
11.5	-0.902800887	74.92129717	0.038615501
12.5	-0.753908107	76.11837536	0.038703461
13.5	-0.601263523	77.26479911	0.038810557
14.5	-0.446805039	78.36622309	0.038931784
15.5	-0.291974772	79.4273405	0.039063356
16.5	-0.13784767	80.45209492	0.039202382
17.5	0.014776155	81.44383603	0.039346629
18.5	0.165304169	82.40543643	0.039494365
19.5	0.313301809	83.33938063	0.039644238
20.5	0.458455471	84.24783394	0.039795189
21.5	0.600544631	85.13269658	0.039946388
22.5	0.739438953	85.9956488	0.040097181
23.5	0.875000447	86.8381751	0.04024706
24.5	1.00720807	87.66160934	0.040395626
25.5	0.837251351	88.45247282	0.040577525
26.5	0.681492975	89.22326434	0.040723122
27.5	0.538779654	89.97549228	0.040833194
28.5	0.407697153	90.71040853	0.040909059
29.5	0.286762453	91.42907762	0.040952433
30.5	0.174489485	92.13242379	0.04096533
31.5	0.069444521	92.82127167	0.040949976
32.5	-0.029720564	93.49637946	0.040908737
33.5	-0.124251789	94.15846546	0.040844062
34.5	-0.215288396	94.80822923	0.040758431
35.5	-0.30385434	95.44636981	0.040654312

__END__

=head1 NAME

Medical::Growth::NHANES_2000::Length_for_Age::Infant::Male

=head1 SYNOPSIS

  use Medical::Growth::NHANES_2000;
  Medical::Growth::NHANES_2000->find_measure_class(
    ages => 'Infant', sex => 'Male',
    measure => 'Length for Age')->pct_for_value($len,$age);

=head1 DESCRIPTION

This class provides the NHANES 2000 parameters for length-for-age
tables for boys ages 0-36 months.

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
