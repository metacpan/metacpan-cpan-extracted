#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require IO::Iron::Common;

diag(   'Testing IO::Iron::Common '
      . ( $IO::Iron::Common::VERSION ? "($IO::Iron::Common::VERSION)" : '(no version)' )
      . ", Perl $], $^X" );

ok( IO::Iron::Common::contains_rfc_3986_res_chars(q{ ! }), 'Contains reserved character !.' );

ok( IO::Iron::Common::contains_rfc_3986_res_chars(q{ ? }), 'Contains reserved character ?.' );

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
ok( IO::Iron::Common::contains_rfc_3986_res_chars(q{ ab$cd }), 'Contains reserved character $.' );

ok( IO::Iron::Common::contains_rfc_3986_res_chars('ab/cd'), 'contains reserved character /.' );

ok( IO::Iron::Common::contains_rfc_3986_res_chars(q{ #[]@ }), 'contains reserved characters #[]@.' );

is( IO::Iron::Common::contains_rfc_3986_res_chars(q{}), 0, 'Contains no reserved characters (empty string).' );

is( IO::Iron::Common::contains_rfc_3986_res_chars('abcdeöäåvwxyz'), 0, 'Contains no reserved characters (scandinavian alfabets).' );

is( IO::Iron::Common::contains_rfc_3986_res_chars('abcdevwxyz'), 0, 'Contains no reserved characters (alfabets).' );

done_testing();

