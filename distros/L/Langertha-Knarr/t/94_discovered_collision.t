use strict;
use warnings;
use Log::Any::Test;
use Log::Any qw( $log );
use Test2::V0;

# Regression: when several configured endpoints list the same model id,
# discovery gave it to whichever endpoint Perl's hash order visited first --
# a different one from run to run (PERL_HASH_SEED). Since a discovered model
# listed by its protocol's passthrough upstream passes through raw, that
# decided raw passthrough vs engine and whose key answers. Now the order is
# fixed: endpoints that are a passthrough upstream come first, then the
# rest by model config name; the collision is logged at debug level.
#
# Key-free: the engines are offline LangerthaX fakes.

BEGIN {
  package LangerthaX::Engine::TestKnarrCollide;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub url { $_[0]{url} }
  sub list_models { [ 'shared-model', ( $_[0]{url} =~ /groq/ ? 'groq-only' : () ) ] }
  $INC{'LangerthaX/Engine/TestKnarrCollide.pm'} = __FILE__;
}

use Langertha::Knarr::Config;
use Langertha::Knarr::Router;

# The passthrough upstream's endpoint sorts last by name, the others would
# each win under some hash order.
my %models = (
  'a-groq'   => { engine => 'TestKnarrCollide', url => 'https://api.groq.com/openai/v1' },
  'b-x'      => { engine => 'TestKnarrCollide', url => 'https://x.example/v1' },
  'c-y'      => { engine => 'TestKnarrCollide', url => 'https://y.example/v1' },
  'z-openai' => { engine => 'TestKnarrCollide', url => 'https://api.openai.com/v1' },
);

sub owner {
  my (%data) = @_;
  my $router = Langertha::Knarr::Router->new(
    config => Langertha::Knarr::Config->new( data => { auto_discover => 1, models => \%models, %data } ) );
  return $router->discovered_url('shared-model');
}

is( owner( passthrough => { openai => 'https://api.openai.com' } ), 'https://api.openai.com/v1',
  'the passthrough upstream\'s endpoint owns a model several endpoints list' );
is( owner(), 'https://api.groq.com/openai/v1',
  'without a passthrough upstream among them: the first endpoint by config name' );
is( owner( passthrough => { openai => 'https://y.example' } ), 'https://y.example/v1',
  'whichever endpoint is the passthrough upstream' );

{
  $log->clear;
  owner( passthrough => { openai => 'https://api.openai.com' } );
  my @collisions = grep { $_->{level} eq 'debug' && $_->{message} =~ /shared-model/ && $_->{message} =~ /also listed/ }
    @{ $log->msgs };
  is( scalar @collisions, 3, 'each other endpoint listing it is logged at debug' );
  like( $collisions[0]{message}, qr/z-openai/, 'the log names the owner' );
  ok( !grep( { $_->{message} =~ /groq-only.*also listed/ } @{ $log->msgs } ),
    'a model only one endpoint lists is no collision' );
}

# The same owner under every hash order, in fresh processes.
my $script = <<'PERL';
BEGIN {
  package LangerthaX::Engine::TestKnarrCollide;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub url { $_[0]{url} }
  sub list_models { [ 'shared-model' ] }
  $INC{'LangerthaX/Engine/TestKnarrCollide.pm'} = __FILE__;
}
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
my %m = map { $_->[0] => { engine => 'TestKnarrCollide', url => $_->[1] } }
  [ 'a-groq', 'https://api.groq.com/openai/v1' ], [ 'b-x', 'https://x.example/v1' ],
  [ 'c-y', 'https://y.example/v1' ], [ 'z-openai', 'https://api.openai.com/v1' ];
my %pt = @ARGV ? ( passthrough => { openai => $ARGV[0] } ) : ();
print Langertha::Knarr::Router->new( config => Langertha::Knarr::Config->new(
  data => { auto_discover => 1, models => \%m, %pt } ) )->discovered_url('shared-model');
PERL

for my $pt ( [ 'https://api.openai.com' ], [] ) {
  my %owners;
  for my $seed ( 1 .. 12 ) {
    local $ENV{PERL_HASH_SEED} = $seed;
    local $ENV{PERL_PERTURB_KEYS} = 1;
    open my $fh, '-|', $^X, ( map { "-I$_" } @INC ), '-e', $script, @$pt
      or die "cannot run $^X: $!";
    my $out = do { local $/; <$fh> };
    close $fh;
    $owners{$out}++;
  }
  is( [ sort keys %owners ], [ @$pt ? 'https://api.openai.com/v1' : 'https://api.groq.com/openai/v1' ],
    'one owner under 12 hash seeds' . ( @$pt ? ' (passthrough upstream)' : ' (no passthrough)' ) );
}

done_testing;
