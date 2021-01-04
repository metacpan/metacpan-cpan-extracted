use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Parse;

my $jp = JSON::Parse->new ();
$jp->set_max_depth (1);
my $ok = eval {
    $jp->run ('[[[["should fail due to depth"]]]]');
    1;
};
ok (! $ok, "fails to parse array when max depth is set to 1");
my $md = $jp->get_max_depth ();
cmp_ok ($md, '==', 1, "got back the max depth");
$jp->set_max_depth (0);
my $mdd = $jp->get_max_depth ();
cmp_ok ($mdd, '==', 10000, "got back the default max depth");

done_testing ();
