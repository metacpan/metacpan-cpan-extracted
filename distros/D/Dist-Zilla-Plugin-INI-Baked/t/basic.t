use strict;
use warnings;

use Test::More;
use Test::Requires {
  'Dist::Zilla::Util::ExpandINI' => '0.003000',    # Comment copying
};

use Test::DZil qw( simple_ini Builder );
use Path::Tiny;

# ABSTRACT: Test basic thing

my $ini = simple_ini( ['@Basic'], ['INI::Baked'], );
my $new_ini;

subtest "Pass one" => sub {

  my $zilla = Builder->from_config( { dist_root => 'invalid', }, { add_files => { 'source/dist.ini' => $ini, }, } );
  $zilla->chrome->logger->set_debug(1);
  $zilla->build;
  my $nini = path( $zilla->tempdir, 'build', 'dist.ini.baked' );
  ok( -e $nini, "New baked INI path exists" );
  is( ( scalar grep { /;/ } $nini->lines_raw( { chomp => 1 } ) ), 3, 'Three comment lines' );
  ok( ( scalar grep { /Dist::Zilla::PluginBundle::Basic/ } $nini->lines_raw( { chomp => 1 } ) ), 'Expanded lines' );
  ok( ( scalar grep { /INI::Baked/ } $nini->lines_raw( { chomp => 1 } ) ), 'Baked entry' );
  $new_ini = $nini->slurp_raw;
};
subtest "Pass Two" => sub {
  my $zilla = Builder->from_config( { dist_root => 'also-invalid', }, { add_files => { 'source/dist.ini' => $new_ini }, } );
  $zilla->chrome->logger->set_debug(1);
  $zilla->build;

  my $nini = path( $zilla->tempdir, 'build', 'dist.ini.baked' );
  ok( -e $nini, "New baked INI path exists" );
  is( ( scalar grep { /;/ } $nini->lines_raw( { chomp => 1 } ) ), 6, 'Three comment lines' );
  ok( ( scalar grep { /Dist::Zilla::PluginBundle::Basic/ } $nini->lines_raw( { chomp => 1 } ) ), 'Expanded lines' );
  ok( ( scalar grep { /INI::Baked/ } $nini->lines_raw( { chomp => 1 } ) ), 'Baked entry' );
};

done_testing;
