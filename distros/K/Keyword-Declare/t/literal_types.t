use warnings;
use strict;

use Test::More;
BEGIN {
    use Keyword::Simple;
    if ($Keyword::Simple::VERSION >= 0.04 && $] < 5.018) {
        plan skip_all => "Keyword::Declare not compatible with Keyword::Simple v$Keyword::Simple::VERSION under Perl $]";
    }
}

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

