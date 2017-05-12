#!perl

use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling."
    if $@;
plan skip_all => 'Author tests.' unless ( $ENV{RELEASE_TESTING} );
add_stopwords(qw/DSES DStaal DSTAAL Staal postfix timestamp todo Postfix
				STDERR bz gz bufferable tgz unix refaddr logline parsable/);
all_pod_files_spelling_ok();
