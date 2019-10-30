use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

my $link;
my $embedder = LinkEmbedder->new;
isa_ok($embedder->ua, 'Mojo::UserAgent');

$embedder->get_p->then(sub { $link = shift })->wait;
is ref($link), 'LinkEmbedder::Link', 'LinkEmbedder::Link';
is_deeply $link->error, {code => 400, message => 'Invalid URL'}, 'invalid url';

$embedder->get_p('mailto:jhthorsen@cpan.org')->then(sub { $link = shift })->wait;
is ref($link), 'LinkEmbedder::Link', 'LinkEmbedder::Link';
is_deeply $link->error, {code => 400, message => 'Could not find LinkEmbedder::Link::Mailto'}, 'mailto';
is $link->html, qq(<a class="le-link" href="mailto:jhthorsen\@cpan.org" title="">mailto:jhthorsen\@cpan.org</a>\n),
  'html';
is_deeply $link->TO_JSON, {cache_age => 0, type => 'link', url => 'mailto:jhthorsen@cpan.org', version => '1.0'},
  'json';

$link->url(Mojo::URL->new('https://<script>evil("code")</script>'));
is $link->html,
  qq(<a class="le-link" href="https://%3Cscript%3Eevil(%22code%22)%3C/script%3E" title="">https://&lt;script&gt;evil(&quot;code&quot;)&lt;/script&gt;</a>\n),
  'evil html';

$link = undef;
$embedder->get('mailto:jhthorsen@cpan.org', sub { $link = $_[1]; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $link->error->{message}, 'Could not find LinkEmbedder::Link::Mailto', 'get()';

done_testing;
