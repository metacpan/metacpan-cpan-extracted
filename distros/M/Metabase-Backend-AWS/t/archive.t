use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Net::Amazon::Config;
use Metabase::Archive::S3;
use Metabase::Test::Archive;

# help us clean up our database
local $SIG{INT} = sub { warn "Got SIGINT"; exit 1 };

# a profile name in a Net::Amazon::Config file
my $profile_env = "PERL_METABASE_TEST_AWS_PROFILE";
unless ( $ENV{$profile_env} ) {
  plan skip_all => "No \$ENV{$profile_env} provided for testing";
}

has amazon_config => (
  is => 'ro',
  isa => 'Net::Amazon::Config',
  default => sub { Net::Amazon::Config->new },
);

has 'profile' => (
  is      => 'ro',
  isa     => 'Net::Amazon::Config::Profile',
  lazy_build    => 1,
  handles => [ qw/access_key_id secret_access_key/ ],
);
 
has 'test_bucket' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

has 'test_prefix' => (
  is => 'ro',
  isa => 'Str',
  default => 's3-test',
);


sub _build_test_bucket {
  return "test.metabase.cpantesters.metabase.org." . int(rand(2**31));
}

sub _build_profile {
  my $self = shift;
  die "No \$ENV{$profile_env}\n" unless $ENV{$profile_env};
  return $self->amazon_config->get_profile( $ENV{$profile_env} );
}

sub _build_archive {
  my $self = shift;
  return Metabase::Archive::S3->new(
      access_key_id     => $self->access_key_id,
      secret_access_key => $self->secret_access_key,
      bucket            => $self->test_bucket,
      prefix            => $self->test_prefix,
  );
}

before clear_archive => sub {
  my $self = shift;
  my $bucket = $self->archive->s3_bucket;
  my $stream = $bucket->list;
  until ($stream->is_done) {
    for my $item ( $stream->items ) {
      $item->delete;
    }
  }
  $bucket->delete;
};

sub DEMOLISH { my $self = shift; $self->clear_archive; }

run_tests(
  "Run archive tests on Metabase::Archive::S3",
  ["main", "Metabase::Test::Archive"],
);

done_testing;
