package DoSilent;

use 5.010;
use strict;
use warnings;

use Export::Lexical ':silent';

sub silent1 :ExportLexical {
    return 1;
}

sub silent2 :export_lexical {
    return 1;
}

1;
