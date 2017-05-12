use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal 0.003;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );
use Dist::Zilla::Util::EmulatePhase qw( -all );

my $zilla = Builder->from_config(
  {
    dist_root => 'invalid'
  },
  {
    add_files => {
      path('source/dist.ini') => simple_ini( 'Prereqs', 'MetaConfig', 'MakeMaker' )
    }
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;

my $prereqs;
is(
  exception {
    $prereqs = get_prereqs( { zilla => $zilla } );
  },
  undef,
  'Can get prereqs with MakeMaker'
);

done_testing;
