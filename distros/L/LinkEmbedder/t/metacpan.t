use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my $embedder = LinkEmbedder->new;

my @tests = (
  {
    html          => qr{<h3>Search the CPAN},
    thumbnail_url => '//metacpan.org/static/icons/apple-touch-icon.png',
    title         => 'Search the CPAN - metacpan.org',
    url           => 'https://metacpan.org/',
  },
  {
    author_name   => 'Sebastian Riedel',
    html          => qr{Real-time web framework},
    thumbnail_url => qr{/bfa97d786f12ee3381f97bc909b88e11},
    title         => 'Mojolicious',
    url           => 'https://metacpan.org/pod/Mojolicious',
  },
  {
    author_name   => 'Jan Henning Thorsen',
    html          => qr{CPAN Author},
    thumbnail_url => qr{/806800a3aeddbad6af673dade958933b},
    title         => 'Jan Henning Thorsen',
    url           => 'https://metacpan.org/author/JHTHORSEN',
  },
  {
    author_name   => 'Jan Henning Thorsen',
    html          => qr{oEmbed resources and other URL},
    thumbnail_url => qr{https://www\.gravatar\.com/avatar/\w+},
    title         => 'LinkEmbedder',
    url           => 'https://metacpan.org/release/LinkEmbedder',
  },
);

for my $test (@tests) {
  LinkEmbedder->new->test_ok(
    $test->{url} => {
      isa           => 'LinkEmbedder::Link::Metacpan',
      author_name   => $test->{author_name},
      cache_age     => 0,
      html          => $test->{html},
      provider_name => 'Metacpan',
      provider_url  => 'https://metacpan.org',
      thumbnail_url => $test->{thumbnail_url},
      title         => $test->{title},
      type          => 'rich',
      url           => $test->{url},
      version       => '1.0',
    }
  );
}

done_testing;
