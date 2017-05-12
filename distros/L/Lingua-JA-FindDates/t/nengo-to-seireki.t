#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Test::More;
use Lingua::JA::FindDates 'nengo_to_seireki';
use utf8;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
my $in = <<EOF;
1989年1月1日
1989年10月10日



昭和64年1月1日
平成1年10月10日
EOF

my $out = <<EOF;
1989年1月1日
1989年10月10日



1989年1月1日
1989年10月10日
EOF

is (nengo_to_seireki ($in), $out);

done_testing ();
