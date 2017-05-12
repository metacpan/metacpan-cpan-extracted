use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/remove_spaces/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/remove_spaces/);

my $space             = "\x{0020}";
my $ideographic_space = "\x{3000}";
my $em_space          = "\x{2003}";

is(remove_spaces("$space$ideographic_space$em_space"), "$em_space");
is($normalizer->normalize("$em_space$space$ideographic_space$ideographic_space$em_space"), "$em_space$em_space");

done_testing;
