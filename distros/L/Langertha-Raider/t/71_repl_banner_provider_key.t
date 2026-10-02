#!/usr/bin/env perl
# ABSTRACT: the REPL banner's api key line under --provider: the key is set, never shown (k135)
use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
clear_engine_env();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;

my $root = Path::Tiny->tempdir;
my $SECRET = 'sk-banner-secret-123';

sub banner_text {
  my ( %app_args ) = @_;
  my $app = Langertha::Raider::CLI->new( root => "$root", trace => 0, mission => 'M', %app_args );
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  Langertha::Raider::CLI::REPL->new(
    app    => $app,
    output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
    in     => do { open my $in, '<', \'' or die $!; $in },
  )->banner('none');
  $fh->flush;
  return decode_utf8($buf);
}

my %provider = (
  provider_id => 'example-provider', engine_name => 'openai', engine_class => 'Langertha::Engine::OpenAI',
  url => 'https://provider.example/v1', model => 'm1',
);

subtest 'endpoint with an auth_ref and -k' => sub {
  my $text = banner_text( provider => { %provider, auth => 'api' }, api_key => $SECRET );
  like( $text, qr/^api key:  auth api \(set\)$/m, 'the key is reported as set' );
  unlike( $text, qr/no API key required/, 'not claimed to need none' );
  unlike( $text, qr/\Q$SECRET\E/, 'the key itself is never printed' );
};

subtest 'endpoint without an auth_ref' => sub {
  my $text = banner_text( provider => { %provider, auth => undef } );
  like( $text, qr/^api key:  \(no API key required\)$/m, 'needs none' );
};

subtest 'without --provider' => sub {
  my $text = banner_text( engine => 'openai', api_key => $SECRET );
  like( $text, qr/^api key:  OPENAI_API_KEY \(missing\)$/m, 'env var status as before' );
  unlike( $text, qr/\Q$SECRET\E/, 'no key printed' );
};

done_testing;
