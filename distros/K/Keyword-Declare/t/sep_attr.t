use 5.012;
use warnings;
use strict;

use Test::More;

BEGIN { plan tests => 19; }


    use Keyword::Declare;

    keytype $NumBlock is /
        (?<num>   (?&PerlNumber) )
                  (?&PerlOWS)
        (?<block> (?&PerlBlock)  )
    /x;

    keyword tryall (NumBlock @numblocks :sep(Comma)) {
        ok @numblocks == 6, 'Correct number of blocks matched';
        for my $numblock (@numblocks) {
            ok $numblock =~ $NumBlock, "$numblock->{block} is NumBlock $numblock->{num}";
        }
        return 'ok 1, "tryall: transformation of code at line " . __LINE__ ;';
    }

    keyword tryany (NumBlock* $numblocks :sep(Comma)) {
        for my $numblock (split /\s*,\s*/, $numblocks) {
            ok $numblock =~ $NumBlock, "$+{block} is NumBlock $+{num}";
        }
        return 'ok 1, "tryany: transformation of code at line " . __LINE__ ;';
    }

    keyword tryone (NumBlock $numblock) {
        ok $numblock =~ $NumBlock, "$numblock->{block} is NumBlock $numblock->{num}";
        return 'ok 1, "tryone: transformation of code at line " . __LINE__ ;';
    }

    keyword trynone (NumBlock? $numblock) {
        ok $numblock eq "", "trynone empty";
        return 'ok 1, "trynone: transformation of code at line " . __LINE__ ;';
    }

    tryall
         1 { say 'one'; die   },
         2 { say 'two'; die   },
         3 { say 'three'; die },
         4 { die              },
         5 { say 'four'       },
         6 { say 'five'       };

    tryone
         7 { say 'seven'      };

    tryany
         1 { say 'one'; die   },
         2 { say 'two'; die   },
         3 { say 'three'; die },
         4 { die              },
         5 { say 'four'       },
         6 { say 'five'       };

    trynone;

done_testing();

