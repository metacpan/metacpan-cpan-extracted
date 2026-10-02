use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use YAML::PP;

use Langertha::Knarr::Config;

# docker-compose.yml passes the knarr service only the variables Knarr reads
# (k68): .env also holds the Langfuse server secrets, so an env_file: .env
# would hand them to Knarr. This keeps that list in step with the code.

my $compose = path('docker-compose.yml');
plan skip_all => 'no docker-compose.yml' unless $compose->is_file;

my $services = YAML::PP->new->load_string( $compose->slurp_utf8 )->{services};
my $knarr    = $services->{knarr};

ok( !exists $knarr->{env_file}, 'knarr gets no env_file' );

my %passed = map { /\A([^=]+)/ ? ( $1 => 1 ) : () } @{ $knarr->{environment} };

for my $secret (qw( LANGFUSE_DB_PASSWORD LANGFUSE_NEXTAUTH_SECRET LANGFUSE_SALT LANGFUSE_INIT_USER_PASSWORD )) {
  ok( !$passed{$secret}, "knarr does not get $secret" );
}

# Every provider key --from-env scans (without the TEST_ names, which
# knarr start --from-env ignores)
my @keys = grep { !/\ATEST_/ } map { @{ $_->{vars} } } @{ Langertha::Knarr::Config->engine_catalog };
ok( $passed{$_}, "knarr gets $_" ) for @keys;

# Every KNARR_* / LANGFUSE_* variable the code reads; LANGFUSE_URL is set,
# which makes LANGFUSE_BASE_URL moot
my %read;
path('lib')->visit( sub {
  my ($file) = @_;
  return unless $file->is_file && $file =~ /\.pm\z/;
  $read{$_} = 1 for $file->slurp_utf8 =~ /\$ENV\{((?:KNARR|LANGFUSE)_\w+)\}/g;
}, { recurse => 1 } );
$read{$_} = 1 for path('bin/knarr')->slurp_utf8 =~ /\$ENV\{((?:KNARR|LANGFUSE)_\w+)\}/g;
delete $read{LANGFUSE_BASE_URL};
ok( scalar( keys %read ) >= 10, 'found the variables the code reads' );
ok( $passed{$_}, "knarr gets $_" ) for sort keys %read;

like( $services->{langfuse}{ports}, [ qr/\A\$\{LANGFUSE_BIND:-127\.0\.0\.1\}:3000:3000\z/ ],
  'Langfuse publishes 3000 on loopback unless LANGFUSE_BIND says otherwise' );

done_testing;
