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
use Lingua::JA::Moji 'kana_consonant';
eval {
    kana_consonant ('');
};
ok ($@ && $@ =~ /empty/i, "dies with empty input");
eval {
    kana_consonant ('猿');
};
ok ($@ && $@ =~ /not kana/i, "dies with non-kana input");
is (kana_consonant ('さる'), 's', "saru gets s"); 
is (kana_consonant ('ざる'), 's', "zaru gets s"); 
is (kana_consonant ('ある'), '', "aru gets empty string"); 
done_testing ();
