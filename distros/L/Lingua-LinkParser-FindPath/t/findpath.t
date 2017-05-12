use Test::More tests => 5;

use strict;
use Data::Dumper;
use  Lingua::LinkParser::FindPath;
my $f = new Lingua::LinkParser::FindPath;
$f->sentence('This study investigated DHEA modulation of LPS-induced monocyte cytotoxicity .');

my @i = $f->find('study' => 'DHEA');
#print Dumper \@i;

is($i[0], 'study.n');
is($i[3], 'Os');
is($i[-1], 'DHEA');
my $str = $f->find_as_string('this' => 'cytotoxicity');
like($str, qr(\Qtudy.n <Ss> investigated.v <Os> modulation.n\E));
my $str = $f->find_as_string('modulation' => 'monocyte');
like($str, qr(\Q<Jp> cytotoxicity[?].n <A> monocyte\E));
