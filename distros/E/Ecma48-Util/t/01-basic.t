#!perl -T

use strict;
use warnings;
use Test::More tests => 36;
use Ecma48::Util qw':all :var';

is(remove_seqs("color\e[34;1mful\e[m example"), 'colorful example');
is_deeply([split_seqs "color\e[34;1mful\e[m example"],
          ['color', \"\e[34;1m", 'ful', \"\e[m", ' example']);

is(ensure_terminating_nl("color\e[34;1mfull\e[m"),"color\e[34;1mfull\e[m\n"); 
is(ensure_terminating_nl("color\e[34;1mfull\n\e[m"),"color\e[34;1mfull\n\e[m");
is(ensure_terminating_nl("color\e[34;1mfull\e[m\n"),"color\e[34;1mfull\e[m\n");

is(remove_terminating_nl("color\e[34;1mfull\e[m"),  "color\e[34;1mfull\e[m"); 
is(remove_terminating_nl("color\e[34;1mfull\n\e[m"),"color\e[34;1mfull\e[m");
is(remove_terminating_nl("color\e[34;1mfull\e[m\n"),"color\e[34;1mfull\e[m");

is(move_seqs_before_lastnl("color\e[34;1mfull\n\e[m"),"color\e[34;1mfull\e[m\n");

is(quotectrl("color\e[34;1mfull\n\e[m"),"color\\e[34;1mfull\n\\e[m");
is(do { local $PREFER_UNICODE_SYMBOLS=1; quotectrl "color\e[34;1mful\n\e[m"},
   "color\x{241B}[34;1mful\n\x{241B}[m", 'quotectrl unicode');
is(do { local $Ecma48::Util::PREFER_UNICODE_SYMBOLS=1; quotectrl "color\e[34;1mful\n\e[m"},
   "color\x{241B}[34;1mful\n\x{241B}[m", 'quotectrl unicode');

#11

is(remove_bs_bolding("A\cHA\cHAB\cHB\cHCD\cHD"),"AB\cHCD");
is(remove_bs_bolding("This was b\cHbo\cHol\cHld\cHd."),'This was bold.');
is(replace_bs_bolding("A\cHAA\cHA\cHAA\cHAbA\cHAA\cHAbbbA\cHAA\cHA",'<','>'),
                      "<AAA>b<AA>bbb<AA>");
my $tib="This is b\cHbo\cHol\cHld\cHd.";
is(replace_bs_bolding($tib,'*'),'This is *bold*.', '*bold*');
is(replace_bs_bolding($tib,''),'This is bold.');
is(replace_bs_bolding($tib,'','','_'),"This is b_o_l_d.", 'b_o_l_d');

is_deeply([sort +ctrl_chars('CSI')], [sort "\x9b", "\e\["], 'ctrl_chars');

is(closing_seq("\e[2m"), "\e[22m",   'closing_seq [2m');
is(closing_seq("\e[02m"), "\e[22m",  'closing_seq [02m');
is(closing_seq("\e[;02m"), "\e[22m", 'closing_seq [;02m');
is(closing_seq(2), "22",             'closing_seq 2');
is(closing_seq("*"), "*",            'closing_seq "*"');
is(closing_seq(">>"), "<<",          'closing_seq >>');
is(closing_seq("\x{25C4}"),"\x{25BA}");
is(closing_seq("-"), "-",            'closing_seq -');

is(closing_seq('{[('),')]}');
is(closing_seq('==>>'),'<<==');
is(closing_seq('.oO '),' Oo.');
is(closing_seq('_*/'),'/*_');
is(closing_seq("\x{25C4}<"),">\x{25BA}");
is(closing_seq("\\"),"/");
is(closing_seq("\x{2767}"),"\x{2619}");

#33

is(remove_fillchars("\00aaaa\x7F\x7F\00bbb\00cc\x7F"),'aaaabbbcc');
is(remove_fillchars("\00a\01a\x80aa\x7F\x7F\00bbb\00cc\x7F"),"a\01a\x80aabbbcc");