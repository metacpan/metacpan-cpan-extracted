use strict;
use warnings;
use Test::More tests => 4;

use Dezi::Indexer::Config;

my $config  = Dezi::Indexer::Config->new;
my $config2 = Dezi::Indexer::Config->new;

$config->MetaNames(qw/ foo bar baz /);
$config->AbsoluteLinks('yes');
$config->FileInfoCompression(1);

ok(my $file = $config->write2, "temp config written");

ok(my $parsed = $config2->read2($file), "temp config read");

is($config->FileInfoCompression->[0], $config2->FileInfoCompression->[0],
    "before matches after");
is($config->FileInfoCompression->[0], $parsed->{FileInfoCompression},
    "before REALLY matches after");

