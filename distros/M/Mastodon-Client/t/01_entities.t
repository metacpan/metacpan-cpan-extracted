use Test2::V0;

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
    uri => 'botsin.space',
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

my ($account, $status);

test($_) foreach qw(
  Account Instance Application Attachment Card Context
  Mention Relationship Report Results Error Tag
);

$samples->{Status} = {
  account => $account,
  visibility => 'public',
  favourites_count => 123,
};

test('Status');

$samples->{Notification} = {
  status => $status,
};

test('Notification');

sub test {
  my $name = shift;

  eval "use Mastodon::Entity::$name";
  ok my $e = "Mastodon::Entity::$name"->new($samples->{$name}),
    "$name constructor succeeds";

  $account = $e if $name eq 'Account';
  $status  = $e if $name eq 'Status';

  isa_ok $e, "Mastodon::Entity::$name";
}

done_testing();
