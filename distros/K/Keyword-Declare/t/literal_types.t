use warnings;
use strict;

use Test::More;

use Keyword::Declare;

keyword literal ('from' $f, 'to'? $t, 'plus'*? @plus, 'end') {
    "note qq{\nliteral $f $t @plus end};"
  . "is '$f', 'from', 'from';"
  . ($t ? "is '$t', 'to', 'to';" : "")
  . join( "", map { "is '$_', 'plus', 'plus';" } @plus );
}

literal from end;
literal from to end;
literal from to plus end;
literal from to plus plus plus plus end;
literal from plus plus plus plus end;


done_testing();

