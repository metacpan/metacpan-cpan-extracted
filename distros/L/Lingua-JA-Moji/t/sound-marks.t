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

use Lingua::JA::Moji qw!join_sound_marks split_sound_marks!;

is (join_sound_marks ('か゛は゜つ゛'), 'がぱづ');
is (split_sound_marks ('がぱづ'), 'か゛は゜つ゛');
is (join_sound_marks ('カ゛ハ゜ツ゛'), 'ガパヅ');
is (split_sound_marks ('ガパヅ'), 'カ゛ハ゜ツ゛');


done_testing ();
