#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::EN::Tokenizer::Offsets qw/get_tokens/;
use Test::Differences;
use utf8::all;



my ($original,$expected) = &load_strings;
my $tokens = get_tokens($original);
my $got = join "\n",@$tokens;

eq_or_diff "$got\n",  $expected,   "testing strings";


sub load_strings {
my $original = <<'END'
I'm testing'this.
Real-time PCR assays using TaqMan or Molecular
Beacon probes were developed and optimized for the
quantification of total bacteria, the nitrite-oxidizing bacteria
Nitrospira, and Nitrosomonas oligotropha-like ammonia
oxidizing bacteria (AOB) in mixed liquor suspended solids
(MLSS) from a municipal wastewater treatment plant
(WWTP) using a single-sludge nitrification process. The
targets for the real-time PCR assays were the 16S rRNA
genes (16S rDNA) for bacteria and Nitrospira spp. and
the amoA gene for N. oligotropha. A previously reported
assay for AOB 16S rDNA was also tested for its application
to activated sludge. The Nitrospira 16S rDNA, AOB 16S
rDNA, and N. oligotropha-like amoA assays were loglinear over 6 orders of magnitude and the bacterial 16S
rDNA real-time PCR assay was log-linear over 4 orders
of magnitude with DNA standards. When these real-time
PCR assays were applied to DNA extracted from MLSS,
dilution of the DNA extracts was necessary to prevent
PCR inhibition. The optimal DNA dilution range was
broad for the bacterial 16S rDNA (1000-fold) and
Nitrospira 16S rDNA assays (2500-fold) but narrow for
the AOB 16S rDNA assay (10-fold) and N. oligotrophalike amoA real-time PCR assay (5-fold). In twelve MLSS
samples collected over one year, mean cell per L
values were 4.3 ( 2.0 × 1011 for bacteria, 3.7 ( 3.2 ×
1010 for Nitrospira, 1.2 ( 0.9 × 1010 for all AOB, and
7.5 ( 6.0 × 109 for N. oligotropha-like AOB. The percent
of the nitrifying population was 1.7% N. oligotropha-like
AOB based on the N. oligotropha amoA assay, 2.9% total
AOB based on the AOB 16S rDNA assay, and 8.6% nitriteoxidizing bacteria based on the Nitrospira 16S rDNA assay.
Ammonia-oxidizing bacteria in the wastewater treatment
plant were estimated to oxidize 7.7 ( 6.8 fmol/hr/cell based
on the AOB 16S rDNA assay and 12.4 ( 7.3 fmol/hr/cell
based on the N. oligotropha amoA assay.
* Corresponding author phone: (865)974-8080; fax: (865)974-8086;
e-mail: sayler@utk.edu.
† Department of Microbiology.
‡ Department of Civil and Environmental Engineering.
§ Center for Environmental Biotechnology.
10.1021/es0257164 CCC: $25.00
Published on Web 12/04/2002

© 2003 American Chemical Society

1. Introduction
END
;

my $expected = <<'END'
I
'm
testing
'this
.
Real-time
PCR
assays
using
TaqMan
or
Molecular
Beacon
probes
were
developed
and
optimized
for
the
quantification
of
total
bacteria
,
the
nitrite-oxidizing
bacteria
Nitrospira
,
and
Nitrosomonas
oligotropha-like
ammonia
oxidizing
bacteria
(
AOB
)
in
mixed
liquor
suspended
solids
(
MLSS
)
from
a
municipal
wastewater
treatment
plant
(
WWTP
)
using
a
single-sludge
nitrification
process
.
The
targets
for
the
real-time
PCR
assays
were
the
16S
rRNA
genes
(
16S
rDNA
)
for
bacteria
and
Nitrospira
spp.
and
the
amoA
gene
for
N.
oligotropha
.
A
previously
reported
assay
for
AOB
16S
rDNA
was
also
tested
for
its
application
to
activated
sludge
.
The
Nitrospira
16S
rDNA
,
AOB
16S
rDNA
,
and
N.
oligotropha-like
amoA
assays
were
loglinear
over
6
orders
of
magnitude
and
the
bacterial
16S
rDNA
real-time
PCR
assay
was
log-linear
over
4
orders
of
magnitude
with
DNA
standards
.
When
these
real-time
PCR
assays
were
applied
to
DNA
extracted
from
MLSS
,
dilution
of
the
DNA
extracts
was
necessary
to
prevent
PCR
inhibition
.
The
optimal
DNA
dilution
range
was
broad
for
the
bacterial
16S
rDNA
(
1000-fold
)
and
Nitrospira
16S
rDNA
assays
(
2500-fold
)
but
narrow
for
the
AOB
16S
rDNA
assay
(
10-fold
)
and
N.
oligotrophalike
amoA
real-time
PCR
assay
(
5-fold
)
.
In
twelve
MLSS
samples
collected
over
one
year
,
mean
cell
per
L
values
were
4.3
(
2.0
×
1011
for
bacteria
,
3.7
(
3.2
×
1010
for
Nitrospira
,
1.2
(
0.9
×
1010
for
all
AOB
,
and
7.5
(
6.0
×
109
for
N.
oligotropha-like
AOB
.
The
percent
of
the
nitrifying
population
was
1.7
%
N.
oligotropha-like
AOB
based
on
the
N.
oligotropha
amoA
assay
,
2.9
%
total
AOB
based
on
the
AOB
16S
rDNA
assay
,
and
8.6
%
nitriteoxidizing
bacteria
based
on
the
Nitrospira
16S
rDNA
assay
.
Ammonia-oxidizing
bacteria
in
the
wastewater
treatment
plant
were
estimated
to
oxidize
7.7
(
6.8
fmol
/
hr
/
cell
based
on
the
AOB
16S
rDNA
assay
and
12.4
(
7.3
fmol
/
hr
/
cell
based
on
the
N.
oligotropha
amoA
assay
.
*
Corresponding
author
phone
:
(
865
)
974-8080
;
fax
:
(
865
)
974-8086
;
e-mail
:
sayler
@
utk.edu.
†
Department
of
Microbiology
.
‡
Department
of
Civil
and
Environmental
Engineering
.
§
Center
for
Environmental
Biotechnology
.
10.1021
/
es0257164
CCC
:
$
25.00
Published
on
Web
12
/
04
/
2002
©
2003
American
Chemical
Society
1
.
Introduction
END
;
return ($original,$expected);
}
