use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my @tests = (
  {
    html_re       => ignore(),
    thumbnail_url => '//metacpan.org/static/icons/apple-touch-icon.png',
    title         => 'Search the CPAN - metacpan.org',
    url           => 'https://metacpan.org/',
  },
  {
    author_name   => 'Sebastian Riedel',
    html_re       => re(qr{Real-time web framework}),
    thumbnail_url => re(qr{/bfa97d786f12ee3381f97bc909b88e11}),
    title         => 'Mojolicious',
    url           => 'https://metacpan.org/pod/Mojolicious',
  },
  {
    html_re       => re(qr{CPAN Author}),
    thumbnail_url => re(qr{/806800a3aeddbad6af673dade958933b}),
    title         => 'Jan Henning Thorsen',
    url           => 'https://metacpan.org/author/JHTHORSEN',
  },
  {
    html_re       => re(qr{oEmbed resources and other URL}),
    thumbnail_url => re(qr{https://www\.gravatar\.com/avatar/\w+}),
    title         => 'LinkEmbedder',
    url           => 'https://metacpan.org/release/LinkEmbedder',
  },
);

for my $test (@tests) {
  my $link;
  $embedder->get_p($test->{url})->then(sub { $link = shift })->wait;
  isa_ok($link, 'LinkEmbedder::Link::Metacpan');

  cmp_deeply $link->TO_JSON,
    subhashof({
    author_name   => $test->{author_name},
    cache_age     => 0,
    html          => $test->{html_re},
    provider_name => 'Metacpan',
    provider_url  => 'https://metacpan.org',
    thumbnail_url => $test->{thumbnail_url},
    title         => $test->{title},
    type          => 'rich',
    url           => $test->{url},
    version       => '1.0',
    }),
    $test->{url}
    or note $link->_dump;
}

done_testing;
