# Test calc of Coltheart Boolean (are_orthons):

use strict;
use warnings;

use Test::More tests => 2;
use Lingua::Orthon;

my $orthon = Lingua::Orthon->new(match_level => 1);

my $test_str = 'BANG';
my @samples = (qw/BAND COCO BING RANG BONG SONG/);

my $onc = $orthon->onc(test => $test_str, sample => \@samples);
ok($onc == 4, "Count of orthons expected = 4, observed = $onc");

my $aref = $orthon->list_orthons(test => $test_str, sample => \@samples);
$onc = scalar @{$aref};
ok($onc == 4, "Count of orthons expected = 4, observed = $onc");

1;