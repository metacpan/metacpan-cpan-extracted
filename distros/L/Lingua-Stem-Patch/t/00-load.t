use utf8;
use strict;
use warnings;
use English;
use Test::More tests => 1;

BEGIN { use_ok 'Lingua::Stem::Patch' }

diag join ', ' => (
    "Lingua::Stem::Patch v$Lingua::Stem::Patch::VERSION",
    "Perl $PERL_VERSION ($EXECUTABLE_NAME)",
);
