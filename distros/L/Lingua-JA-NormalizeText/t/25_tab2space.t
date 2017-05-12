use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/tab2space/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/tab2space/);

my $tab   = "\x{0009}";
my $space = "\x{0020}";

is(tab2space("\t"), ' ');
is($normalizer->normalize($tab x 10), $space x 10);
is($normalizer->normalize("あ${tab}${space}い" x 2), "あ${space}${space}い" x 2);

done_testing;
