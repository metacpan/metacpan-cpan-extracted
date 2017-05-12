use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL qw( dztest );

# FILENAME: 02-basic-dztest.t
# ABSTRACT: Make sure dztest works

plan tests => 9;

my $test = dztest;
$test->add_file( 'dist.ini', simple_ini( ['GatherDir'] ) );
$test->build_ok;
$test->prereqs_deeply( {} );
$test->has_messages(
  'Simple message check',
  [
    [ qr/beginning\s*to\s*build/imsx, 'Got build log note' ],         ###
    [ qr/writing.*in/imsx,            'Saw \'Writing in\' note' ],    ###
  ],
);
$test->has_message( qr/beginning\s*to\s*build/imsx, 'Got build log note' );
$test->meta_path_deeply( '/prereqs', [ {} ], 'Simple prereqs using dpath' );
$test->meta_path_deeply( '/author/*/*', ['E. Xavier Ample <example@example.org>'], );
$test->test_has_built_file('dist.ini');

ok( -e ( my $file  = $test->source_file('dist.ini') ), 'source file exists' );
ok( -e ( my $xfile = $test->built_file('dist.ini') ),  'built file exists' );
done_testing;

