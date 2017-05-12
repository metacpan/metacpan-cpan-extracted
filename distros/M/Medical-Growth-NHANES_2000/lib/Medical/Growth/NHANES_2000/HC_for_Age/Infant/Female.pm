#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000::HC_for_Age::Infant::Female;

our ($VERSION) = '1.00';

use Moo::Lax;    # Vanilla Moo considered harmful

extends 'Medical::Growth::NHANES_2000::Base';

__PACKAGE__->_declare_params_LMS;

1;

# hcageinf, sex = 2

__DATA__

0	-1.298749689	34.7115617	0.046905108
0.5	-1.440271514	36.03453876	0.042999604
1.5	-1.581016348	37.97671987	0.038067862
2.5	-1.593136386	39.3801263	0.035079612
3.5	-1.521492427	40.46773733	0.033096443
4.5	-1.394565915	41.34841008	0.03170963
5.5	-1.231713389	42.0833507	0.030709039
6.5	-1.046582628	42.71033603	0.029974303
7.5	-0.848932692	43.25428882	0.029430992
8.5	-0.645779124	43.73249646	0.029030379
9.5	-0.442165412	44.15742837	0.028739112
10.5	-0.24163206	44.53836794	0.028533537
11.5	-0.046673786	44.88240562	0.028396382
12.5	0.141031094	45.19507651	0.028314722
13.5	0.320403169	45.48078147	0.028278682
14.5	0.490807133	45.74307527	0.028280585
15.5	0.65193505	45.98486901	0.028314363
16.5	0.803718086	46.20857558	0.028375159
17.5	0.946259679	46.41621635	0.028459033
18.5	1.079784984	46.60950084	0.028562759
19.5	1.204602687	46.78988722	0.028683666
20.5	1.321076285	46.95862881	0.028819525
21.5	1.429602576	47.11681039	0.028968459
22.5	1.530595677	47.26537682	0.029128879
23.5	1.624475262	47.40515585	0.029299426
24.5	1.71165803	47.53687649	0.029478937
25.5	1.792551616	47.66118396	0.029666406
26.5	1.867550375	47.77865186	0.02986096
27.5	1.93703258	47.8897923	0.030061839
28.5	2.001358669	47.99506422	0.030268375
29.5	2.060870301	48.09488048	0.030479985
30.5	2.115889982	48.18961365	0.03069615
31.5	2.16672113	48.2796011	0.030916413
32.5	2.21364844	48.36514917	0.031140368
33.5	2.256943216	48.44653703	0.031367651
34.5	2.296844024	48.52401894	0.031597939
35.5	2.333589434	48.59782828	0.031830942
36	2.350847202	48.63342328	0.031948378

__END__

=head1 NAME

Medical::Growth::NHANES_2000::HC_for_Age::Infant::Female

=head1 SYNOPSIS

  use Medical::Growth::NHANES_2000;
  Medical::Growth::NHANES_2000->find_measure_class(
    ages => 'Infant', sex => 'Female',
    measure => 'HC for Age')->pct_for_value($hc,$age);

=head1 DESCRIPTION

This class provides the NHANES 2000 parameters for head-circumference-for-age
tables for girls ages 0-36 months.

Head circimference values are expressed in centimeters, and ages in months.

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
