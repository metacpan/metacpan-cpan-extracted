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


