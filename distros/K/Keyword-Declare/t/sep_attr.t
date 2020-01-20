use 5.012;
use warnings;
use strict;

use Test::More;

BEGIN { plan tests => 17; }


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
        return 'ok 1, "Transformation of code";';
    }

    keyword tryany (NumBlock* $numblocks :sep(Comma)) {
        for my $numblock (split /\s*,\s*/, $numblocks) {
            ok $numblock =~ $NumBlock, "$+{block} is NumBlock $+{num}";
        }
        return 'ok 1, "Transformation of code";';
    }

    keyword tryone (NumBlock $numblock) {
        ok $numblock =~ $NumBlock, "$numblock->{block} is NumBlock $numblock->{num}";
        return 'ok 1, "Transformation of code";';
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

done_testing();

