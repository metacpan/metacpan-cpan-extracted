use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Lingua::JA::Dakuon ':all';

is all_dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}"
                        ."あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}"),
   'あがざだなぱまゔﾊﾋﾞﾌﾞ'.'あぱぴぴがまﾊﾋﾟﾌﾟ';

done_testing;
