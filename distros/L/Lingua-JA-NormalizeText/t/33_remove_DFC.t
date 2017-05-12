use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/remove_DFC/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/remove_DFC/);

# Implicit Directional Formatting Characters
my $LRM = "\x{200E}";
my $RLM = "\x{200F}";
my $ALM = "\x{061C}";

# Explicit Directional Embedding and Override Formatting Characters
my $LRE = "\x{202A}";
my $RLE = "\x{202B}";
my $LRO = "\x{202D}";
my $RLO = "\x{202E}";
my $PDF = "\x{202C}";

# Explicit Directional Isolate Formatting Characters
my $LRI = "\x{2066}";
my $RLI = "\x{2067}";
my $FSI = "\x{2068}";
my $PDI = "\x{2069}";

is(remove_DFC("\x{200D}$LRM$RLM\x{2010}$ALM\x{061B}\x{061D}" x 2), "\x{200D}\x{2010}\x{061B}\x{061D}" x 2, 'Implicit Directional Formatting Characters');
is(remove_DFC("\x{2029}$LRE$RLE$LRO$RLO$PDF\x{202F}"), "\x{2029}\x{202F}", 'Explicit Directional Embedding and Override Formatting Characters');
is(remove_DFC("\x{2065}$LRI$RLI$FSI$PDI\x{206A}"), "\x{2065}\x{206A}", 'Explicit Directional Isolate Formatting Characters');

is($normalizer->normalize("$LRM$RLM$ALM$LRE$RLE$LRO$RLO$PDF$LRI$RLI$FSI$PDI" x 2), '', 'All Formatting Characters');

done_testing;
