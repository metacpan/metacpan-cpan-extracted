use utf8;
use strict;
use warnings;
use English;
use Test::More tests => 1;

BEGIN { use_ok 'Lingua::Stem::Any' }

diag join ', ' => (
    "Lingua::Stem::Any v$Lingua::Stem::Any::VERSION",
    "Moo v$Moo::VERSION",
    "Perl $PERL_VERSION ($EXECUTABLE_NAME)",
);
