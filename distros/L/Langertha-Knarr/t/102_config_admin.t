use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use YAML::PP;

# k75: admin_key / KNARR_ADMIN_KEY and remote_config / KNARR_REMOTE_CONFIG in the
# config, and what validate says about them -- never the key itself.

BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG )} }

use Langertha::Knarr::Config;

my $ADMIN = 'admin-key-config-0123456789';
my $tmp = Path::Tiny->tempdir;

sub file_config {
  my ($data) = @_;
  my $file = $tmp->child( 'k'.int( rand 1e9 ).'.yaml' );
  $file->spew_utf8( YAML::PP->new->dump_string($data) );
  return Langertha::Knarr::Config->new( file => "$file" );
}

my %model = ( engine => 'OpenAI', api_key => 'sk-config-model-key' );

# --- admin_key ---
{
  my $c = Langertha::Knarr::Config->new( data => { admin_key => $ADMIN } );
  is( $c->admin_key, $ADMIN, 'admin_key from the config' );
  ok( $c->has_admin_key, 'has_admin_key' );
  local $ENV{KNARR_ADMIN_KEY} = 'admin-key-from-env-0123456';
  is( Langertha::Knarr::Config->new( data => {} )->admin_key, 'admin-key-from-env-0123456',
    'admin_key from KNARR_ADMIN_KEY' );
  is( Langertha::Knarr::Config->new( data => { admin_key => $ADMIN } )->admin_key, $ADMIN,
    'the config wins over the environment' );
  local $ENV{KNARR_ADMIN_KEY} = '';
  ok( !Langertha::Knarr::Config->new( data => {} )->has_admin_key, 'an empty key is no key' );
}
ok( !Langertha::Knarr::Config->new( data => {} )->has_admin_key, 'no key by default' );
is( Langertha::Knarr::Config->admin_key_min_length, 16, 'at least 16 characters' );

# --- remote_config ---
{
  is( Langertha::Knarr::Config->new( data => {} )->remote_config, 0, 'remote_config is off by default' );
  is( Langertha::Knarr::Config->new( data => { remote_config => 1 } )->remote_config, 1, 'remote_config: 1' );
  is( Langertha::Knarr::Config->new( data => { remote_config => 'false' } )->remote_config, 0, "remote_config: 'false'" );
  for my $case ( [ '1', 1 ], [ 'true', 1 ], [ '0', 0 ], [ 'off', 0 ], [ 'no', 0 ], [ '', 0 ] ) {
    local $ENV{KNARR_REMOTE_CONFIG} = $case->[0];
    is( Langertha::Knarr::Config->new( data => {} )->remote_config, $case->[1], "KNARR_REMOTE_CONFIG='$case->[0]'" );
  }
  local $ENV{KNARR_REMOTE_CONFIG} = '1';
  is( Langertha::Knarr::Config->new( data => { remote_config => 0 } )->remote_config, 0, 'the config wins over the environment' );
}

is( [ Langertha::Knarr::Config->runtime_keys ],
  [ qw( models default passthrough auto_discover proxy_api_key
        upstream_timeout upstream_stall_timeout probe_capabilities probe_timeout
        langfuse ) ],
  'the keys an admin push may set' );

# --- validate ---
sub errors_of { [ $_[0]->validate ] }

is( errors_of( file_config({ remote_config => 1, admin_key => $ADMIN, listen => [ '127.0.0.1:1' ] }) ), [],
  'remote_config without models is valid' );
is( errors_of( Langertha::Knarr::Config->new( data => { remote_config => 1, admin_key => $ADMIN } ) ), [],
  '... also without a file' );
like( errors_of( file_config({ admin_key => $ADMIN }) ), [ qr/No models configured/ ],
  'without remote_config models are still needed' );
like( errors_of( file_config({ remote_config => 1 }) ), [ qr/remote_config needs an admin_key/ ],
  'remote_config needs an admin key' );
{
  local $ENV{KNARR_ADMIN_KEY} = $ADMIN;
  is( errors_of( file_config({ remote_config => 1 }) ), [], '... KNARR_ADMIN_KEY will do' );
}
is( errors_of( file_config({ remote_config => 1, admin_key => $ADMIN, models => { m => {%model} },
    proxy_api_key => 'proxy-in-file-key' }) ), [],
  'remote_config: the file may hold models and a proxy key, they are always in effect' );
is( errors_of( file_config({ remote_config => 1, admin_key => $ADMIN, passthrough => { openai => 'https://api.openai.com' } }) ), [],
  '... or just a passthrough' );

{
  my $short = 'short-admin';
  my @e = file_config({ admin_key => $short, models => { m => {%model} } })->validate;
  like( \@e, [ qr/admin_key must be at least 16 characters/ ], 'a short admin key is refused' );
  ok( !( grep { /\Q$short\E/ } @e ), '... without naming it' );
}
{
  my @e = file_config({ admin_key => $ADMIN, proxy_api_key => $ADMIN, models => { m => {%model} } })->validate;
  like( \@e, [ qr/admin_key must differ from proxy_api_key/ ], 'admin key = proxy key is refused' );
  ok( !( grep { /\Q$ADMIN\E/ } @e ), '... without naming it' );
}
{
  local $ENV{KNARR_ADMIN_KEY} = 'same-key-0123456789abc';
  local $ENV{KNARR_API_KEY}   = 'same-key-0123456789abc';
  like( [ Langertha::Knarr::Config->new( data => {} )->admin_errors ],
    [ qr/admin_key must differ from proxy_api_key/ ], 'admin_errors checks the environment too' );
}
like( errors_of( file_config({ models => { m => { %model, api_key => [ 'x' ] } } }) ),
  bag { item qr/Model 'm': api_key must be a string/; etc },
  'an api_key that is no string is refused' );
like( errors_of( Langertha::Knarr::Config->new( data => { models => { m => {%model} }, proxy_api_key => { a => 1 } } ) ),
  [ qr/proxy_api_key must be a string/ ], 'a proxy_api_key that is no string is refused' );

done_testing;
