package DoFatal;

use 5.010;
use strict;
use warnings;

use Export::Lexical;

sub fatal1 :ExportLexical {
    return 1;
}

sub fatal2 :export_lexical {
    return 1;
}

1;
