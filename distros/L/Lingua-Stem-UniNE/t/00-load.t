use utf8;
use strict;
use warnings;
use English;
use Test::More tests => 1;

BEGIN { use_ok 'Lingua::Stem::UniNE' }

diag join ', ' => (
    "Lingua::Stem::UniNE v$Lingua::Stem::UniNE::VERSION",
    "Moo v$Moo::VERSION",
    "Perl $PERL_VERSION ($EXECUTABLE_NAME)",
);
