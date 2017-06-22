use warnings;
use strict;

use Test::More;

use Keyword::Declare;

keyword regex (/from/ $f, /to/? $t, /plus|minus/*? @plus_minus, /end/i) {
    "note qq{\nregex $f $t @plus_minus end};"
  . "is '$f', 'from', 'from';"
  . ($t ? "is '$t', 'to', 'to';" : "")
  . join( "", map { "like '$_', qr/^(?:plus|minus)\$/, 'plus/minus';" } @plus_minus );
}

regex from end;
regex from to end;
regex from to plus END;
regex from to plus plus minus plus end;
regex from plus plus plus minus end;

done_testing();


