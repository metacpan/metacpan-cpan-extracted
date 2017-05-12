package DoWarn;

use 5.010;
use strict;
use warnings;

use Export::Lexical ':warn';

sub warn1 :ExportLexical {
    return 1;
}

sub warn2 :export_lexical {
    return 1;
}

1;
