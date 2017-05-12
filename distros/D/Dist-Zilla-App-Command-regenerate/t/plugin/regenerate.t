use strict;
use warnings;

use Test::More;
use Dist::Zilla::App::Tester;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini );
use Test::TempDir::Tiny qw( tempdir );

my $wd = tempdir("Scratch");

path( $wd, 'dist.ini' )->spew_raw(
  simple_ini(
    ['MetaConfig'],    #
    ['MetaJSON'],      #
    [ 'Regenerate', { filenames => ['META.json'] } ],    #
  )
);

my $result = test_dzil( $wd, ['regenerate'] );
ok( ref $result, "self-test executed" );
is( $result->error,     undef, "no errors" );
is( $result->exit_code, 0,     "exit = 0" );
note $result->stdout;
ok( path( $result->{tempdir}, 'source', 'META.json' )->exists, "META.json written to source dir" );

done_testing;
