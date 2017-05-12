# -*- cperl -*-

use Test::More;

our @CGIs = qw!cgis/nat-dict.cgi
               cgis/nat-search.cgi
               cgis/nat-matrix.cgi
               cgis/nat-about.cgi
               cgis/nat-ntd-browse.cgi
               cgis/nat-ngrams.cgi!;

plan tests => scalar(@CGIs);

like(`$^X -c $_ 2>&1`, qr/syntax OK/) for @CGIs;

