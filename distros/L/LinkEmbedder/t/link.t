use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

my $link;
my $embedder = LinkEmbedder->new;
isa_ok($embedder->ua, 'Mojo::UserAgent');

$link = $embedder->get;
is ref($link), 'LinkEmbedder::Link', 'LinkEmbedder::Link';
is_deeply $link->error, {code => 400, message => 'Invalid URL'}, 'invalid url';

$link = $embedder->get('mailto:jhthorsen@cpan.org');
is ref($link), 'LinkEmbedder::Link', 'LinkEmbedder::Link';
is_deeply $link->error, {code => 400, message => 'Could not find LinkEmbedder::Link::Mailto'}, 'mailto';
is $link->html, qq(<a class="le-link" href="mailto:jhthorsen\@cpan.org" title="">mailto:jhthorsen\@cpan.org</a>\n),
  'html';
is_deeply $link->TO_JSON, {cache_age => 0, type => 'link', url => 'mailto:jhthorsen@cpan.org', version => '1.0'},
  'json';

$link->url(Mojo::URL->new('http://<script>evil("code")</script>'));
is $link->html,
  qq(<a class="le-link" href="http://%3Cscript%3Eevil(%22code%22)%3C/script%3E" title="">http://&lt;script&gt;evil(&quot;code&quot;)&lt;/script&gt;</a>\n),
  'evil html';

done_testing;
