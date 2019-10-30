#!/usr/bin/env perl
use Mojolicious::Lite;

use lib 'lib';
use LinkEmbedder;

# These pastebin provides expire
$ENV{TEST_FEDORA}    ||= 'TdDtYw1YSaEDqIOqVYlWbw';
$ENV{TEST_PERLBOT}   ||= 'xogtbq';
$ENV{TEST_SHADOWCAT} ||= '586840';

helper embedder => sub { state $e = LinkEmbedder->new };

get '/'       => 'index';
get '/oembed' => sub {
  my $c   = shift;
  my $url = $c->param('url');

  if ($c->stash('restricted') and !grep { $_ eq $url } @{$c->stash('predefined')}) {
    return $c->render(json => {error => "LINK_EMBEDDER_RESTRICTED is set."});
  }

  $c->embedder->serve($c);
};

app->defaults(
  restricted => $ENV{LINK_EMBEDDER_RESTRICTED} ? 1 : 0,
  predefined => [
    "https://xkcd.com/927",
    "https://catoverflow.com/cats/r4cIt4z.gif",
    "https://www.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight",
    "https://imgur.com/gallery/ohL3e",
    "https://www.aftenposten.no",
    "https://www.instagram.com/p/BSRYg_Sgbqe/",
    "http://ix.io",
    "http://ix.io/fpW",
    "https://catoverflow.com/",
    "https://open.spotify.com/artist/4HV7yKF3SRpY6I0gxu7hm9",
    "https://gist.github.com/jhthorsen/3738de6f44f180a29bbb",
    "https://whereby.com/link-embedder-demo",
    "https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t",
    "https://metacpan.org/pod/Mojolicious",
    "https://pastebin.com/V5gZTzhy",
    "https://paste.fedoraproject.org/paste/$ENV{TEST_FEDORA}",
    "https://perlbot.pl/p/$ENV{TEST_PERLBOT}",
    "https://paste.opensuse.org/2931429",
    "https://twitter.com",
    "https://www.youtube.com/watch?v=OspRE1xnLjE",
    "https://twitter.com/jhthorsen/status/786688349536972802",
    "https://vimeo.com/154038415",
    "http://paste.scsys.co.uk/$ENV{TEST_SHADOWCAT}",
    "https://travis-ci.org/Nordaaker/convos/builds/47421379",
    "https://git.io/aKhMuA",
    "https://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html",
    "spotify:track:0aBi2bHHOf3ZmVjt3x00wv",
    "https://www.nhl.com/video/top-10-of-2018-19-ovechkin/t-277350912/c-68680503",
  ]
);

$ENV{X_REQUEST_BASE} and hook before_dispatch => sub {
  my $c = shift;
  return unless my $base = $c->req->headers->header('X-Request-Base');
  $c->req->url->base(Mojo::URL->new($base));
};

app->start;

__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>oEmbed example server</title>
  %= stylesheet 'https://cdnjs.cloudflare.com/ajax/libs/pure/0.6.2/pure-min.css'
  <style>
.container { max-width: 40rem; margin: 3rem auto; }
a { color: #0078e7; }
ol.predefined { display: none; }
pre.data { color: #999; margin-top: 3rem; padding-top: 1rem; border-top: 1px solid #ddd; }
[name="url"] { width: 100%; }

.le-card {
  overflow: hidden;
  border: 1px solid #ccc;
  border-radius: 5px;
  padding: 1rem;
  margin: 0;
}

.le-image-card h3,
.le-image-card p,
.le-image-card .le-meta {
  margin-left: calc(100px + 1rem);
}

.le-card h3 {
  margin-top: 0;
}

.le-card .le-meta,
.le-card .le-meta a {
  font-size: 0.9rem;
  color: #333;
}

.le-card .le-thumbnail,
.le-card .le-thumbnail-placeholder {
  float: left;
}

.le-card .le-thumbnail img,
.le-card .le-thumbnail-placeholder img {
  width: 100px;
}

.le-card .le-meta .le-goto-link a:before {
  content: "Read more";
}

.le-provider-link ~ .le-goto-link:before,
.le-author-link ~ .le-goto-link:before {
  content: "\2013\00a0";
}

.le-goto-link span {
  display: none;
}

.le-paste {
  background-color: #f8f8f8;
}

.le-paste pre {
  max-height: 300px;
  overflow: auto;
}

.le-paste .le-meta {
  background-color: #dfdfdf;
  padding: 0.2em 0.5rem;
}

.le-paste pre {
  padding: 0.5rem;
}

.le-paste .le-provider-link:before {
  content: "Hosted by ";
}
</style>
</head>
<body>
<a href="https://github.com/jhthorsen/linkembedder"><img style="position: absolute; top: 0; left: 0; border: 0;" src="https://camo.githubusercontent.com/567c3a48d796e2fc06ea80409cc9dd82bf714434/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f6c6566745f6461726b626c75655f3132313632312e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_left_darkblue_121621.png"></a>

<div class="container">
  <h1>oEmbed / LinkEmbedder example server</h1>

  %= form_for '/oembed', class => 'pure-form pure-form-stacked', begin
    % if ($restricted) {
      <p>
        <button type="button" class="pure-button pure-button-primary predefined">Render predefined</button>
      </p>
    % } else {
      <label for="form_url">URL</label>
      %= text_field 'url', value => 'https://git.io/aKhMuA', id => 'form_url'
      <span class="pure-form-message">Enter any URL, and see how it renders below</span>
      <p>
        <button type="submit" class="pure-button pure-button-primary">Render URL</button>
        <button type="button" class="pure-button pure-button-secondary predefined">Render predefined</button>
      </p>
    % }
  % end

  <h2 class="url">&nbsp;</h2>
  <div class="html">Enter an URL and hit <i>Render!</i> to see the HTML snippet here.</div>
  <pre class="data"></pre>
  <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
  <script async src="//platform.instagram.com/en_US/embeds.js"></script>
  %= javascript begin
var form = document.querySelector("form");

var url = location.href.match(/url=([^\&]+)/);
var predefined = <%== Mojo::JSON::to_json($predefined) %>;
var predefined_index = location.href.match(/\#(\d+)/);
predefined_index = predefined_index ? predefined_index[1] : -1;

function embed(e, url) {
  if (e.preventDefault) e.preventDefault();
  var req = new XMLHttpRequest();
  req.open("GET", form.action + "?url=" + encodeURIComponent(url));
  document.querySelector("h2.url").innerHTML = "Fetching " + url + "...";
  req.onload = function(e) {
    var oembed = JSON.parse(this.responseText);
    document.querySelector("h2.url").innerHTML = url;
    document.querySelector("div.html").innerHTML = oembed.html;
    console.log(oembed.html);
    delete oembed.html;
    document.querySelector("pre.data").innerHTML = JSON.stringify(oembed, undefined, 2);
    if (oembed.provider_name == 'Twitter') twttr.widgets.load();
    if (oembed.provider_name == 'Instagram') instgrm.Embeds.process();
  };
  req.send();
}

form.addEventListener("submit", function(e) { embed(e, form.elements.url.value); });

document.querySelector("button.predefined").addEventListener("click", function(e) {
  location.hash = ++predefined_index;
  if (!predefined[predefined_index]) predefined_index = 0;
  embed(e, predefined[predefined_index]);
});

if (predefined_index >= 0) {
  embed({}, predefined[predefined_index]);
}
else if(url) {
  embed({}, decodeURIComponent(url[1]));
}
  % end
</div>
</body>
</html>
