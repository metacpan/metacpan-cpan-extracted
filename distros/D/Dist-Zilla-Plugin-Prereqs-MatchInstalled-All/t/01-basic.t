use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini Builder );

my $zilla = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        [ 'Prereqs' => { 'Moose' => 0 } ],    #
        ['Prereqs::MatchInstalled::All'],
        ['MetaConfig'],                       #
      ),
    }
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;

ok( exists $zilla->distmeta->{prereqs}, '->prereqs' )
  and ok( exists $zilla->distmeta->{prereqs}->{runtime},                      '->prereqs/runtime' )
  and ok( exists $zilla->distmeta->{prereqs}->{runtime}->{requires},          '->prereqs/runtime/requires' )
  and ok( exists $zilla->distmeta->{prereqs}->{runtime}->{requires}->{Moose}, '->prereqs/runtime/requires/Moose' )
  and cmp_ok( $zilla->distmeta->{prereqs}->{runtime}->{requires}->{Moose}, 'ne', '0', "Moose != 0" );

note explain $zilla->distmeta;
note explain $zilla->log_messages;

done_testing;
