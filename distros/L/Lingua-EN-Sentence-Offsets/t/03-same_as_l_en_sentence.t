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
We investigated ammonia-oxidizing bacteria in activated sludge collected from 12 sewage treatment systems, whose ammonia
removal and treatment processes diﬀered, during three diﬀerent seasons. We used real-time PCR quantiﬁcation to reveal total bacterial numbers and total ammonia oxidizer numbers, and used speciﬁc PCR followed by denaturing gel gradient electrophoresis,
cloning, and sequencing of 16S rRNA genes to analyze ammonia-oxidizing bacterial communities. Total bacterial numbers and total
ammonia oxidizer numbers were in the range of 1.6 · 1012–2.4 · 1013 and 1.0 · 109–9.2 · 1010 cells lÀ1, respectively. Seasonal variation was observed in the total ammonia oxidizer numbers, but not in the ammonia-oxidizing bacterial communities. Members of
the Nitrosomonas oligotropha cluster were found in all samples, and most sequences within this cluster grouped within two of the
four sequence types identiﬁed. Members of the clusters of Nitrosomonas europaea–Nitrosococcus mobilis, Nitrosomonas cryotolerans,
and unknown Nitrosomonas, occurred solely in one anaerobic/anoxic/aerobic (A2O) system. Members of the Nitrosomonas communis cluster occurred almost exclusively in association with A2O and anaerobic/aerobic systems. Solid residence time mainly inﬂuenced the total numbers of ammonia-oxidizing bacteria, whereas dissolved oxygen concentration primarily aﬀected the
ammonia-oxidizing activity per ammonia oxidizer cell.
