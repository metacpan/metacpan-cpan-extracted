#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000::Weight_for_Age::Infant::Female;

our ($VERSION) = '1.00';

use Moo::Lax;    # Vanilla Moo considered harmful

extends 'Medical::Growth::NHANES_2000::Base';

__PACKAGE__->_declare_params_LMS;

1;

# wtageinf, sex = 2

__DATA__

0	1.509187507	3.39918645	0.142106724
0.5	1.357944315	3.79752846	0.138075916
1.5	1.105537708	4.544776513	0.131733888
2.5	0.902596648	5.230584214	0.126892697
3.5	0.734121414	5.859960798	0.123025182
4.5	0.590235275	6.437587751	0.119840911
5.5	0.464391566	6.967850457	0.117166868
6.5	0.352164071	7.454854109	0.11489384
7.5	0.250497889	7.902436186	0.112949644
8.5	0.15724751	8.314178377	0.11128469
9.5	0.070885725	8.693418423	0.109863709
10.5	-0.00968493	9.043261854	0.10866078
11.5	-0.085258	9.366593571	0.10765621
12.5	-0.15640945	9.666089185	0.106834517
13.5	-0.22355869	9.944226063	0.106183085
14.5	-0.28701346	10.20329397	0.105691242
15.5	-0.34699919	10.4454058	0.105349631
16.5	-0.40368918	10.67250698	0.105149754
17.5	-0.45721877	10.88638558	0.105083666
18.5	-0.50770077	11.08868151	0.105143752
19.5	-0.55523599	11.28089537	0.105322575
20.5	-0.59992113	11.46439708	0.10561278
21.5	-0.64185418	11.64043402	0.106007025
22.5	-0.6811381	11.81013895	0.106497957
23.5	-0.71788283	11.97453748	0.107078197
24.5	-0.75220617	12.13455528	0.107740346
25.5	-0.78423359	12.2910249	0.108477009
26.5	-0.81409743	12.44469237	0.109280822
27.5	-0.8419355	12.59622335	0.110144488
28.5	-0.86788939	12.74620911	0.111060814
29.5	-0.89210264	12.89517218	0.112022758
30.5	-0.91471881	13.04357164	0.113023466
31.5	-0.93587966	13.19180827	0.114056316
32.5	-0.95572344	13.34022934	0.115114952
33.5	-0.97438101	13.48913357	0.116193337
34.5	-0.99198075	13.63877446	0.11728575
35.5	-1.00864074	13.78936547	0.118386847
36	-1.01665314	13.86507382	0.118939087

__END__

=head1 NAME

Medical::Growth::NHANES_2000::Weight_for_Age::Infant::Female

=head1 SYNOPSIS

  use Medical::Growth::NHANES_2000;
  Medical::Growth::NHANES_2000->find_measure_class(
    ages => 'Infant', sex => 'Female',
    measure => 'Weight for Age')->pct_for_value($wt,$age);

=head1 DESCRIPTION

This class provides the NHANES 2000 parameters for weight-for-age
tables for girls ages 0-36 months.

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
