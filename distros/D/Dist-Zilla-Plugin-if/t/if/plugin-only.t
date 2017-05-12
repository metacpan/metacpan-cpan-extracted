
use strict;
use warnings;

use Test::More tests => 2;

# ABSTRACT: A basic test

use Test::DZil qw( simple_ini Builder );

my $files = { 'source/dist.ini' => simple_ini( ['MetaConfig'], [ 'if' => { dz_plugin => 'GatherDir' } ] ) };
my $zilla = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
$zilla->chrome->logger->set_debug(1);
$zilla->build;
is_deeply(
  [
    map  { $_->{class} }
    grep { $_->{class} ne 'Dist::Zilla::Plugin::FinderCode' } @{ $zilla->distmeta->{x_Dist_Zilla}->{plugins} }
  ],
  [ 'Dist::Zilla::Plugin::MetaConfig', 'Dist::Zilla::Plugin::GatherDir', 'Dist::Zilla::Plugin::if', ],
  "Expected plugins",
);
ok( -e ( $zilla->tempdir . q[/build/dist.ini] ), 'dist.ini built' );
