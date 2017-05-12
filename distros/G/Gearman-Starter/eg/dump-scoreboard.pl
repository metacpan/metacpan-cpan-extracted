use strict;
use warnings;
use Parallel::Scoreboard;
use Gearman::Starter::Util;

my $path = shift || die "Usage: $0 /path/to/scoreboard";
my $board = Parallel::Scoreboard->new(base_dir => $path);
print Gearman::Starter::Util::display_scoreboard($board);
