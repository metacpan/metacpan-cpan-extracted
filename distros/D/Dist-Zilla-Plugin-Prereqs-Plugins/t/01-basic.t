use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini Builder );

my $zilla = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      'source/dist.ini' => simple_ini( ['Prereqs::Plugins'], ['GatherDir'], ),
    },
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;

ok( exists $zilla->distmeta->{prereqs},                        "->prereqs ok" );
ok( exists $zilla->distmeta->{prereqs}->{develop},             "->prereqs->develop ok" );
ok( exists $zilla->distmeta->{prereqs}->{develop}->{requires}, "->prereqs->develop->requires ok" );
is_deeply(
  $zilla->distmeta->{prereqs}->{develop}->{requires},
  {
    'Dist::Zilla'                           => '0',
    'Dist::Zilla::Plugin::GatherDir'        => '0',
    'Dist::Zilla::Plugin::Prereqs::Plugins' => '0',
  },
  "develop deps added"
);
note explain $zilla->log_messages;
note explain $zilla->distmeta;

done_testing;

