#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::EN::Sentence qw/get_sentences/;
use Lingua::EN::Sentence::Offsets qw/get_sentences/;
use Data::Dump qw/dump/;

my $text = join '',<DATA>;
my $expected_s1 = Lingua::EN::Sentence::get_sentences($text);
my $got_s2      = Lingua::EN::Sentence::Offsets::get_sentences($text);

is_deeply($got_s2,$expected_s1,"L::EN::S::O vs L::EN::S");


__DATA__
Abstract
We investigated ammonia-oxidizing bacteria in activated sludge collected from 12 sewage treatment systems, whose ammonia
removal and treatment processes diﬀered, during three diﬀerent seasons. We used real-time PCR quantiﬁcation to reveal total bacterial numbers and total ammonia oxidizer numbers, and used speciﬁc PCR followed by denaturing gel gradient electrophoresis,
cloning, and sequencing of 16S rRNA genes to analyze ammonia-oxidizing bacterial communities. Total bacterial numbers and total
ammonia oxidizer numbers were in the range of 1.6 · 1012–2.4 · 1013 and 1.0 · 109–9.2 · 1010 cells lÀ1, respectively. Seasonal variation was observed in the total ammonia oxidizer numbers, but not in the ammonia-oxidizing bacterial communities. Members of
the Nitrosomonas oligotropha cluster were found in all samples, and most sequences within this cluster grouped within two of the
four sequence types identiﬁed. Members of the clusters of Nitrosomonas europaea–Nitrosococcus mobilis, Nitrosomonas cryotolerans,
and unknown Nitrosomonas, occurred solely in one anaerobic/anoxic/aerobic (A2O) system. Members of the Nitrosomonas communis cluster occurred almost exclusively in association with A2O and anaerobic/aerobic systems. Solid residence time mainly inﬂuenced the total numbers of ammonia-oxidizing bacteria, whereas dissolved oxygen concentration primarily aﬀected the
ammonia-oxidizing activity per ammonia oxidizer cell.

2. Materials and methods
2.1. Samples of sewage activated sludge and description of
sewage treatment systems
Activated sludge samples were collected from the aeration tanks of 12 sewage treatment systems. These systems are in use in eight sewage treatment plants in
Tokyo, which are run by the Bureau of Sewerage, Tokyo

Metropolitan Government, Japan. The 12 systems differed in ammonia removal and were operated with different treatment processes: anaerobic/anoxic/aerobic
(A2O); anaerobic/aerobic (AO); and conventional activated sludge (AS) processes. Samples were collected
from the 12 systems during three diﬀerent seasons: summer (August 2001); autumn (November 2001); and winter (February 2002). Mixed-liquor suspended solids
(MLSS) concentrations were determined on the day of
sampling. The sludge from approximately 2 mg of
MLSS was transferred into a 1.7-ml Eppendorf tube
and centrifuged at 14,000g for 10 min. The supernatant
was removed, and the pellet was kept at À20 °C until
analysis.
Details of the treatment processes, inﬂuent and eﬄuent characteristics, removal eﬃciencies, and operational
parameters of the 12 systems are listed in Table 1. Systems B1, B2, and B3, systems F1 and F2, and systems
G1 and G2 were located in plants B, F, and G, respectively. Plant B received sewage from a single sewer line,
and the sewage was split among systems B1, B2, and B3
for treatment. In contrast, multiple sewer lines entered
plants F and G; as a result, the various systems in both
plants received diﬀerent sewage. However, the characteristics of the inﬂuents were expected to be similar because the areas from which the sewages were collected
were near each other. The treatment processes of the
12 systems varied: systems A and B1 are A2O processes;
systems B2, C, D, and E are AO processes; and systems
B3, F1, F2, G1, G2, and H are AS processes.
Biological oxygen demand (BOD) in the inﬂuents
ranged from 34 to 141 mg lÀ1, while ammonium concentrations were between 12 and 30 mg N lÀ1. The characteristics of the inﬂuents did not vary notably among
the systems, except for system A. This system was associated with inﬂuent ammonia concentrations of
26–30 mg N lÀ1 and chloride concentrations that were
double those of other systems. These diﬀerences arose
because system A received sewage mostly from commercial areas without rainwater, whereas the other systems
served household areas and received combined sewage.
In addition, the location of system A, an artiﬁcial island
in the sea, might tend to increase the chloride concentration in the inﬂuent of this system.
BOD removal eﬃciencies were excellent (P95%) in
all systems; however, ammonia removal eﬃciencies differed among them. Completed ammonia removal was
achieved in systems A, B1, B2, D, F2, and G1. Ammonia removal was poor in systems G2 and H, possibly because of insuﬃcient oxygen. Ammonia concentrations in
the eﬄuents varied according to the diﬀerence of ammonia removal among the systems. Nitrite concentrations
in the eﬄuents were less than 2 mg N lÀ1 and pH were
maintained between 6.2 and 7.4 in all systems.
Temperature in the 12 systems ranged from 14 to
22 °C in winter to 27 to 31 °C in summer. No marked
