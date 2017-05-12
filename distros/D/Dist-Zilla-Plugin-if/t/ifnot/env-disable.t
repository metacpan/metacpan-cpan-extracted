
use strict;
use warnings;

use Test::More tests => 2;

# ABSTRACT: A basic test

use Test::DZil qw( simple_ini Builder );

my (@conditions) = '!$ENV{dometa}';

sub mktest {
  my $files = {
    'source/dist.ini' => simple_ini(
      [
        'if::not' => {
          dz_plugin  => 'MetaConfig',
          conditions => \@conditions
        }
      ],
    )
  };
  my $zilla = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
  $zilla->chrome->logger->set_debug(1);
  $zilla->build;
  return $zilla;
}

{
  delete local $ENV{dometa};
  my $zilla = mktest();
  ok( !exists $zilla->distmeta->{x_Dist_Zilla}, 'no x_Dist_Zilla key w/ env=off' );
}
{
  local $ENV{dometa} = 1;
  my $zilla = mktest();
  is_deeply(
    [
      map  { $_->{class} }
      grep { $_->{class} ne 'Dist::Zilla::Plugin::FinderCode' } @{ $zilla->distmeta->{x_Dist_Zilla}->{plugins} }
    ],
    [ 'Dist::Zilla::Plugin::MetaConfig', 'Dist::Zilla::Plugin::if::not', ],
    "Expected plugins w/ env=on",
  );
}
