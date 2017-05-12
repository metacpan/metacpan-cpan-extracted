#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::EN::Sentence qw/get_sentences/;
use Lingua::EN::Sentence::Offsets qw/get_sentences/;
use Data::Dump qw/dump/;

my ($text,$expected,$got);

$text = "ammonia-oxidizing activity per ammonia oxidizer cell.\n\n2. Materials and methods\n2.1. Samples of sewage activated sludge and description of\nsewage treatment systems";
$expected = Lingua::EN::Sentence::get_sentences($text);
$got      = Lingua::EN::Sentence::Offsets::get_sentences($text);
is_deeply($got,$expected,"Section numbers");


__END__
$text = "\f206\n\nT. Limpiyakorn et al. / FEMS Microbiology Ecology 54 (2005) 205\x{2013}217\n\ngradient gel electrophoresis (DGGE), the application of\n";
$expected = Lingua::EN::Sentence::get_sentences($text);
$got      = Lingua::EN::Sentence::Offsets::get_sentences($text);
is_deeply($got,$expected,"Slash");
