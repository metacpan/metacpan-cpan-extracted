#!perl -T

BEGIN {
    if( $ENV{PERL_CORE} ) {
        @INC = ('../../lib', '../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use Test::More;

if ( !$ENV{AUTHOR_TESTING} ) {
    plan skip_all => "Skipping author tests. Set AUTHOR_TESTING=1 to run them.";
}
if ( !eval "use Test::Pod 1.14; 1" ) {
    plan skip_all => "Test::Pod 1.14 is required for testing POD";
}

all_pod_files_ok();
