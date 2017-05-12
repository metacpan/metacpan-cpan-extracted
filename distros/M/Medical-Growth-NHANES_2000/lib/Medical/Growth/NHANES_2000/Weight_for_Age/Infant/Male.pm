#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000::Weight_for_Age::Infant::Male;

our ($VERSION) = '1.00';

use Moo::Lax;    # Vanilla Moo considered harmful

extends 'Medical::Growth::NHANES_2000::Base';

__PACKAGE__->_declare_params_LMS;

1;

# wtageinf, sex = 1

__DATA__

0	1.815151075	3.530203168	0.152385273
0.5	1.547523128	4.003106424	0.146025021
1.5	1.068795548	4.879525083	0.136478767
2.5	0.695973505	5.672888765	0.129677511
3.5	0.41981509	6.391391982	0.124717085
4.5	0.219866801	7.041836432	0.121040119
5.5	0.077505598	7.630425182	0.1182712
6.5	-0.02190761	8.162951035	0.116153695
7.5	-0.0894409	8.644832479	0.114510349
8.5	-0.1334091	9.081119817	0.113217163
9.5	-0.1600954	9.476500305	0.11218624
10.5	-0.17429685	9.835307701	0.111354536
11.5	-0.1797189	10.16153567	0.110676413
12.5	-0.179254	10.45885399	0.110118635
13.5	-0.17518447	10.7306256	0.109656941
14.5	-0.16932268	10.97992482	0.109273653
15.5	-0.1631139	11.20955529	0.10895596
16.5	-0.15770999	11.4220677	0.108694678
17.5	-0.15402279	11.61977698	0.108483324
18.5	-0.15276214	11.80477902	0.108317416
19.5	-0.15446658	11.9789663	0.108193944
20.5	-0.15952202	12.14404334	0.108110954
21.5	-0.16817926	12.30154103	0.108067236
22.5	-0.1805668	12.45283028	0.108062078
23.5	-0.19670196	12.59913494	0.108095077
24.5	-0.21650121	12.74154396	0.108166005
25.5	-0.23979048	12.88102276	0.108274705
26.5	-0.26631585	13.01842382	0.108421024
27.5	-0.29575496	13.1544966	0.108604769
28.5	-0.32772936	13.28989667	0.108825681
29.5	-0.36181746	13.42519408	0.109083423
30.5	-0.39756808	13.56088113	0.109377581
31.5	-0.43452025	13.69737858	0.109707646
32.5	-0.47218875	13.83504622	0.110073084
33.5	-0.51012309	13.97418199	0.110473238
34.5	-0.54788557	14.1150324	0.1109074
35.5	-0.5850701	14.25779618	0.111374787
36	-0.60333785	14.32994444	0.111620652

__END__

=head1 NAME

Medical::Growth::NHANES_2000::Weight_for_Age::Infant::Male

=head1 SYNOPSIS

  use Medical::Growth::NHANES_2000;
  Medical::Growth::NHANES_2000->find_measure_class(
    ages => 'Infant', sex => 'Male',
    measure => 'Weight for Age')->pct_for_value($wt,$age);

=head1 DESCRIPTION

This class provides the NHANES 2000 parameters for weight-for-age
tables for boys ages 0-36 months.

Weight values are expressed in kilograms, and ages in months.

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
