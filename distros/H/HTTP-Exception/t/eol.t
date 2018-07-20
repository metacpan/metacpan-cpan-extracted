use strict;
use Test::More;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        plan( skip_all => "Author tests not required for installation" );
    }

    eval "use Test::EOL";
    plan skip_all => 'Test::EOL required for testing EOL' if $@;
}

all_perl_files_ok;