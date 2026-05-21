use Test::More;
use strict;
use warnings;

use ExtUtils::CFeatureTest;

my $ctest= ExtUtils::CFeatureTest->new();

ok( $ctest->compile_and_run(<<END_C), 'simple int main program' );
int main() { return 0; }
END_C

ok( !$ctest->compile_and_run(<<END_C), 'program returns error' );
int main() { return 1; }
END_C

ok( !$ctest->compile_and_run(<<END_C), 'link failure' );
extern int missing_external_function();
int main() { return missing_external_function(); }
END_C

ok( !$ctest->compile_and_run(<<END_C), 'compile failure' );
int main() { return syntax error!; }
END_C

# Likely no C implementation that ever existed would lack this one...

ok( $ctest->header('string.h'), 'add <string.h> header' );
like( $ctest->config_includes, qr/\Q#include <string.h>\E\n/, 'added to config_includes' );
ok( $ctest->config_include_set->{'string.h'}, 'added to %config_include_set' );
like( $ctest->config_header_text, qr/\Q#include <string.h>\E\n/, 'added to config_header_text' );

ok( $ctest->feature(HAVE_STRLEN => 'strlen'), 'found strlen function' );
ok( $ctest->config_macros->{HAVE_STRLEN}, 'added HAVE_STRLEN macro' );

# now test some negatives

ok( !$ctest->header('nonexistent_standard_functions.h'), 'nonexistent_standard_functions.h' );
unlike( $ctest->config_includes, qr/nonexistent_standard_function/, 'header not added' );
ok( !$ctest->config_include_set->{'nonexistent_standard_functions.h'}, 'header not registered' );
ok( $ctest->config_include_set->{'string.h'}, 'previous header still registered' );

ok( !$ctest->feature(HAVE_NONEXISTENT_STANDARD_FUNCTION => 'nonexistent_standard_function'),
   'nonexistent function not found' );

done_testing;
