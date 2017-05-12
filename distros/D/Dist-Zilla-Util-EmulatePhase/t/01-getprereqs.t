use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal 0.003;

use Test::DZil qw( simple_ini Builder );
use Path::Tiny qw( path );
use Dist::Zilla::Util::EmulatePhase qw( -all );

my $zilla = Builder->from_config(
  {
    dist_root => 'invalid'
  },
  {
    add_files => {
      path('source/dist.ini') => simple_ini(
        [ 'Prereqs' => { 'foopackage' => 0 } ],    #
        'MetaConfig',                              #
        [ 'MetaResources' => { homepage => 'http://example.org' } ],
      ),
    },
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;

my @plugins;
my $prereqs;

is(
  exception {
    @plugins = get_plugins(
      {
        zilla => $zilla,
        with  => [qw( -PrereqSource )],
      }
    );
  },
  undef,
  'get_plugins does not fail'
);

is(
  exception {
    $prereqs = get_prereqs( { zilla => $zilla } );
  },
  undef,
  'get_prereqs does not fail'
);

isa_ok( $prereqs, 'Dist::Zilla::Prereqs' );

my $rundeps;

is(
  exception {
    $rundeps = $prereqs->requirements_for( 'runtime', 'requires' );
  },
  undef,
  'requirements_for runs'
);

my $isobj  = ref $rundeps and $rundeps->can('isa');
my $is_CMR = $rundeps->isa('CPAN::Meta::Requirements');
my $is_VR  = $rundeps->isa('Version::Requirements');

ok( ( $is_CMR or $is_VR ), 'ISA CPAN::Meta::Requirements / Version::Requirements' );

if ( not $is_CMR and $is_VR ) {
  diag "WARNING: You still have the deprecated Version::Requirements, upgrading to CPAN::Meta::Requirements is recommended";
}

isa_ok( $rundeps->as_string_hash, 'HASH' );
ok( defined $rundeps->as_string_hash->{foopackage}, 'foopackage dep exists' );
is( $rundeps->as_string_hash->{foopackage}, 0, 'foopackage depend is on v 0' );

done_testing;
