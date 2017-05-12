use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::Warnings 'warning';

use Mastodon::Types qw( to_Entity to_Instance );

# Test data uses only minimum arguments for entity constructors
# These were set as required only to aid in automatic detection,
# which makes blind coercion possible
#
my $samples = {
  Account => {
    acct => 'username',
    avatar => 'https://example.tld/image.png',
  },
  Application => {
    website => 'https://website.xyz',
  },
  Attachment => {
    preview_url => 'https://example.tld/image.png',
  },
  Card => {
    description => 'A card',
    url => 'https://website.xyz',
  },
  Context => {
    ancestors => [],
    descendants => [],
  },
  Error => {
    error => 'An error',
  },
  Instance => {
    uri => 'mastodon.social',
  },
  Mention => {
    acct => 'username@instance.xyz',
    username => 'tester',
  },
  Relationship => {
    muting => 0,
  },
  Report => {
    action_taken => 0,
  },
  Results => {
    hashtags => [ 'tag '],
  },
  Tag => {
    url => 'https://website.xyz',
  }
};

$samples->{Status} = {
  account => $samples->{Account},
  visibility => 'public',
  favourites_count => 123,
  application => $samples->{Application},
  media_attachments => [
    $samples->{Attachment},
    $samples->{Attachment},
  ],
  mentions => [
    $samples->{Mention},
    $samples->{Mention},
  ],
};

$samples->{Notification} = {
  status => $samples->{Status},
};

foreach my $name (keys %{$samples}) {
  ok my $e = to_Entity($samples->{$name}), 'Coercion succeeds';
  isa_ok $e, "Mastodon::Entity::$name";
}

ok my $e = to_Instance('mastodon.social'),
  'Coercion of instance from string succeeds';
isa_ok $e, 'Mastodon::Entity::Instance';

like $e->uri, qr/https/, 'Instance defaults to HTTPS';

done_testing();
