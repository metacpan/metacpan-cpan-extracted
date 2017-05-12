use lib './lib';
use strict;
use warnings;

use Getopt::Simple;

# -----------------

my($opt) = Getopt::Simple -> new();

$opt->getOptions(
{
    env   => '-',
    purge =>
    {
        type    => "=i",
        default => 1,
        order   => 1,
    }
},
"$0 [options]", 1, 1);

print $$opt{'switch'}{'purge'};
