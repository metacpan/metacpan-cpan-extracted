use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 3;
use JavaScript::Minifier::XS qw(minify);

my $results;

###############################################################################
# Minifying down to "nothing" shouldn't segfault.
#
# RT #36557 described this for CSS::Minifier::XS, but we exhibit the same bug
# here too.
$results = minify( "/* */" );
ok( !defined $results, "minified block comment to nothing" );

$results = minify( "// foo" );
ok( !defined $results, "minified line comment to nothing" );

$results = minify( q{} );
ok( !defined $results, "minified empty string to nothing" );
