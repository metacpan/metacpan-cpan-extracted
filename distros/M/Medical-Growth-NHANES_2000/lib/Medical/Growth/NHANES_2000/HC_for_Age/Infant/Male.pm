#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000::HC_for_Age::Infant::Male;

our ($VERSION) = '1.00';

use Moo::Lax;    # Vanilla Moo considered harmful

extends 'Medical::Growth::NHANES_2000::Base';

__PACKAGE__->_declare_params_LMS;

1;

# hcageinf, sex = 1

__DATA__

0	4.427825037	35.81366835	0.052172542
0.5	4.310927464	37.19361054	0.047259148
1.5	3.869576802	39.20742929	0.040947903
2.5	3.305593039	40.65233195	0.037027722
3.5	2.720590297	41.76516959	0.034364245
4.5	2.16804824	42.66116148	0.032462175
5.5	1.675465689	43.40488731	0.031064702
6.5	1.255160322	44.03609923	0.03002267
7.5	0.91054114	44.58096912	0.029242173
8.5	0.639510474	45.05761215	0.028660454
9.5	0.436978864	45.4790756	0.0282336
10.5	0.296275856	45.85505706	0.027929764
11.5	0.210107251	46.19295427	0.027725179
12.5	0.171147024	46.49853438	0.027601686
13.5	0.172393886	46.77637684	0.027545148
14.5	0.207371541	47.03017599	0.027544382
15.5	0.270226126	47.2629533	0.027590417
16.5	0.355757274	47.47720989	0.02767598
17.5	0.459407627	47.67503833	0.027795115
18.5	0.577227615	47.85820606	0.0279429
19.5	0.705826778	48.02821867	0.028115241
20.5	0.842319055	48.18636864	0.028308707
21.5	0.984266833	48.3337732	0.028520407
22.5	1.129626698	48.47140432	0.028747896
23.5	1.276691223	48.60011223	0.028989089
24.5	1.424084853	48.72064621	0.029242207
25.5	1.570621291	48.83366629	0.029505723
26.5	1.715393998	48.93976089	0.029778323
27.5	1.857652984	49.03945383	0.030058871
28.5	1.996810563	49.13321432	0.030346384
29.5	2.132411346	49.22146409	0.030640006
30.5	2.264111009	49.30458348	0.030938992
31.5	2.391658052	49.38291658	0.031242693
32.5	2.514878222	49.45677569	0.031550537
33.5	2.633661226	49.526445	0.031862026
34.5	2.747949445	49.59218385	0.03217672
35.5	2.857728375	49.65422952	0.032494231
36	2.910932095	49.68393611	0.032653934

__END__

=head1 NAME

Medical::Growth::NHANES_2000::HC_for_Age::Infant::Male

=head1 SYNOPSIS

  use Medical::Growth::NHANES_2000;
  Medical::Growth::NHANES_2000->find_measure_class(
    ages => 'Infant', sex => 'Male',
    measure => 'HC for Age')->pct_for_value($hc,$age);

=head1 DESCRIPTION

This class provides the NHANES 2000 parameters for head-circumference-for-age
tables for boys ages 0-36 months.

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
