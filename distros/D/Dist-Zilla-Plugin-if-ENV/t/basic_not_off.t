
use strict;
use warnings;

use Test::More tests => 1;
use Test::DZil qw( simple_ini Builder );

# ABSTRACT: Test basic loading

$ENV{AIRPLANE} = 0;    # This should Load.

my $zilla = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      'source/sample.txt' => q[],
      'source/dist.ini'   => simple_ini(
        ['MetaConfig'],
        [
          'if::not::ENV',
          {
            key       => 'AIRPLANE',
            dz_plugin => 'GatherDir',
          }
        ]
      )
    }
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;
isnt( -e ( $zilla->tempdir . '/build/sample.txt' ), undef, 'sample.txt gathers without airplane mode' );
note explain $zilla->log_messages;
note explain [ grep { $_->{class} !~ /FinderCode/ } @{ $zilla->distmeta->{x_Dist_Zilla}->{plugins} } ];
