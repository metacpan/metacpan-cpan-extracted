use strict;
use warnings;

use Test::More;

# ABSTRACT: Test [MetaProvides] barfs

use Test::DZil qw( simple_ini Builder );

my %FILES = ( 'dist.ini' => simple_ini( ['MetaProvides'], ), );
my $error;
my $died = 1;

local $@;
eval {
  my $builder = Builder->from_config(
    { dist_root => 'invalid' },                                               #
    { add_files => { map { 'source/' . $_ => $FILES{$_} } keys %FILES } },    #
  );
  $died = 0;
};
$error = $@;

ok( $died,  '[MetaProvides] as-is errors' );
ok( $error, "Got an exception" );
like( $error, qr/is merely a/, 'Death message is the expected one' ) or diag explain $error;

done_testing;

