use 5.012;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use_ok 'FASTX::sw';

my $align = FASTX::sw->new( 'gatttttttcgg',
                            'gattttcccgg');

my ($top,$middle,$bottom) = $align->pads;


ok($top eq 'gatttttttcgg', "Top alignment is correct: $top");
ok($bottom eq 'gattttcccgg-', "Bottom alignment is correct: $bottom");
ok($middle eq '||||||    | ', "Middle identity bars are correct: $middle");

done_testing();
