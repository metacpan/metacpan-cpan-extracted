package Plack::App::Mastodon::MockServer::v1;

use strict;
use warnings;

use parent qw( Plack::Component );

use Plack::Util;
use JSON::MaybeXS qw( encode_json );

my $samples = {
  Account => {
    a => {
      acct              => 'a',
      avatar            => 'https://perl.test/path/to/image.png',
      avatar_static     => 'https://perl.test/path/to/image.png',
      created_at        => '2017-04-12T11:24:56.416Z',
      display_name      => 'Ada',
      followers_count   => 2,
      following_count   => 1,
      header            => '/headers/original/missing.png',
      header_static     => '/headers/original/missing.png',
      id                => 1,
      locked            => 0,
      note              => '',
      statuses_count    => 2,
      url               => 'https://perl.test/@a',
      username          => 'a'
    },
    b => {
      acct              => 'b',
      avatar            => 'https://perl.test/path/to/image.png',
      avatar_static     => 'https://perl.test/path/to/image.png',
      created_at        => '2015-04-12T11:24:56.416Z',
      display_name      => 'Bob',
      followers_count   => 0,
      following_count   => 1,
      header            => '/headers/original/missing.png',
      header_static     => '/headers/original/missing.png',
      id                => 2,
      locked            => 0,
      note              => '',
      statuses_count    => 0,
      url               => 'https://perl.test/@b',
      username          => 'b'
    },
    c => {
      acct              => 'c',
      avatar            => 'https://perl.test/path/to/image.png',
      avatar_static     => 'https://perl.test/path/to/image.png',
      created_at        => '2016-04-12T11:24:56.416Z',
      display_name      => 'Cid',
      followers_count   => 1,
      following_count   => 1,
      header            => '/headers/original/missing.png',
      header_static     => '/headers/original/missing.png',
      id                => 2,
      locked            => 0,
      note              => '',
      statuses_count    => 0,
      url               => 'https://perl.test/@c',
      username          => 'c'
    },
  },
  Relationship => {
    a => {
      b => {
        id          => 2,
        blocking    => 0,
        followed_by => 1,
        following   => 0,
        muting      => 0,
        requested   => 0
      },
      c => {
        id          => 3,
        blocking    => 0,
        followed_by => 1,
        following   => 1,
        muting      => 0,
        requested   => 0
      },
    },
    b => {
      a => {
        id          => 1,
        blocking    => 0,
        followed_by => 0,
        following   => 1,
        muting      => 0,
        requested   => 0
      },
      c => {
        id          => 3,
        blocking    => 0,
        followed_by => 0,
        following   => 0,
        muting      => 0,
        requested   => 0
      },
    },
    c => {
      a => {
        id          => 1,
        blocking    => 0,
        followed_by => 1,
        following   => 1,
        muting      => 0,
        requested   => 0
      },
      b => {
        id          => 2,
        blocking    => 0,
        followed_by => 0,
        following   => 0,
        muting      => 0,
        requested   => 0
      },
    },
  },
  Instance => {
    description => 'This is not a real instance',
    email       => 'admin@perl.test',
    title       => 'perl.test',
    uri         => 'https://perl.test'
  },
  Status => {
    a => [
      {
        id         => 100,
        uri        => 'tag:perl.test,2017-04-17:objectId=100:objectType=Status',
        url        => 'https://perl.test/@a/100',
        reblog     => undef,
        account    => undef, # {Account}{a}
        content    => '<p>A <a href="https://perl.test/tags/tag" class="mention hashtag">#<span>tag</span></a></p>',
        mentions   => [],
        reblogged  => undef,
        sensitive  => 0,
        visibility => 'public',
        created_at => '2017-04-17T17:32:29.772Z',
        favourited => undef,
        application            => undef,
        spoiler_text           => '',
        reblogs_count          => 0,
        in_reply_to_id         => undef,
        favourites_count       => 0,
        media_attachments      => [],
        in_reply_to_account_id => undef,
        tags => [{
          url  => 'https://perl.test/tags/tag',
          name => 'tag'
        }],
      },
      {
        id         => 101,
        uri        => 'tag:perl.test,2017-04-17:objectId=101:objectType=Status',
        url        => 'https://perl.test/@a/101',
        tags       => [],
        reblog     => undef,
        content    => '<p>Hello, <span class="h-card"><a href="https://perl.test/@c" class="u-url mention">@<span>c</span></a></span>!</p>',
        account    => undef, # {Account}{a}
        reblogged  => undef,
        sensitive  => 0,
        visibility => 'public',
        created_at => '2017-04-17T18:23:59.781Z',
        favourited => undef,
        application            => undef,
        spoiler_text           => '',
        reblogs_count          => 0,
        in_reply_to_id         => undef,
        favourites_count       => 0,
        media_attachments      => [],
        in_reply_to_account_id => undef,
        mentions => [{
          username => 'c',
          acct     => 'c',
          id       => 3,
          url      => 'https://perl.test/@c'
        }],
      },
    ],
  },
};

$samples->{Status}{a}[0]{account} = $samples->{Account}{a};
$samples->{Status}{a}[1]{account} = $samples->{Account}{a};

my $routes = {
  GET => {
    'instance' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Instance} ],
    ],
    'accounts/2' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Account}{b} ],
    ],
    'accounts/verify_credentials' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Account}{a} ],
    ],
    'accounts/1/followers' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Account}{b}, $samples->{Account}{c} ] ],
    ],
    'accounts/2/followers' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [] ],
    ],
    'accounts/1/following' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Account}{c} ] ],
    ],
    'accounts/2/following' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Account}{a} ] ],
    ],
    'accounts/1/statuses' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json $samples->{Status}{a} ],
    ],
    'accounts/2/statuses' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [] ],
    ],
    'accounts/relationships?id[]=2' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Relationship}{a}{b} ] ],
    ],
    'accounts/relationships?id[]=2&id[]=3' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [
        $samples->{Relationship}{a}{b}, $samples->{Relationship}{a}{c}
      ] ],
    ],
    'accounts/search?q=a' => [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json [ $samples->{Account}{a} ] ],
    ],
  },
};

sub call {
  my ($self, $env) = @_;

  my $uri      = $env->{REQUEST_URI};
  my $endpoint = $uri;
     $endpoint =~ s%^/api/v1/%%;
     $endpoint =~ s|%5B%5D|[]|g;
  my $return = $routes->{$env->{REQUEST_METHOD}}{$endpoint} //
    [
      404,
      [ 'Content-Type' => 'text/plain' ],
      [ '' ],
    ];

  return $return;
}

1;
