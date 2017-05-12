#!/usr/bin/perl 

use 5.10.0;

use strict;
use warnings;

use Escape::Houdini;
use HTML::Escape;
use URI::Escape::XS;

use Benchmark qw/ cmpthese /;

{
    say "Unescape URI";

    my $uri = "http://www.google.co.jp/search?q=%E5%B0%8F%E9%A3%BC%E5%BC%BE";

    cmpthese( -10, {
        "houdini unescape_html"        => sub { bench_houdini_unescape_url($uri) },
        "URI::Escape::XS uri_unescape" => sub { bench_uri_unescape($uri) },
    });

}
{
    say "URI escape";

    my $uri =
    "http://babyl.ca/mailman/admin/banana/members/add?foo=bar&baz=nar";

    cmpthese( -10, {
        "houdini escape_html"        => sub { bench_houdini_escape_url($uri) },
        "URI::Escape::XS uri_escape" => sub { bench_uri_escape($uri) },
    });
}


{

say my $input = "<hello>world</hello>";

cmpthese( -10, {
    "houdini escape_html"      => sub { bench_houdini_escape_html($input) },
    "HTML::Escape escape_html" => sub { bench_html_escape($input) },
});

}

my $input = do { local $/ = <DATA> };

say "random webpage";

say "escape_html(random webpage)";

cmpthese( -10, {
    "houdini escape_html" => sub { bench_houdini_escape_html($input) },
    "HTML::Escape escape_html" => sub { bench_html_escape($input) },
});


sub bench_houdini_escape_html {
    my $escaped = Escape::Houdini::escape_html($_[0]);
}

sub bench_html_escape {
    my $escaped = HTML::Escape::escape_html($_[0]);
}

sub bench_houdini_escape_url {
    my $escaped = Escape::Houdini::escape_url($_[0]);
}

sub bench_houdini_unescape_url {
    my $escaped = Escape::Houdini::unescape_url($_[0]);
}

sub bench_uri_escape {
    my $escaped = URI::Escape::XS::uri_escape($_[0]);
}

sub bench_uri_unescape {
    my $escaped = URI::Escape::XS::uri_unescape($_[0]);
}


__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
    <title>Hacking Thy Fearful Symmetry - MetaCPAN JavaScript API</title>
    <link rel="shortcut icon" href="http://babyl.ca/techblog/static/favicon.png?v=0.6.0" />

    <link rel="alternate" 
          type="application/atom+xml" 
          title="Recent Entries" 
          href="http://babyl.ca/techblog/atom.xml" />



<link rel="stylesheet" type="text/css" href="http://babyl.ca/techblog/css/galuga.css" />
<style type="text/css">


</style>
<script type="text/javascript" 
    src="http://babyl.ca/techblog/static/jquery/jquery-1.5.1.min.js?v=0.6.0"></script>

<script type="text/javascript" 
    src="http://babyl.ca/techblog/static/jquery/tagcloud/scripts/jquery.tagcloud.min.js?v=0.6.0">
    </script>




<!-- Include required JS files -->
<script type="text/javascript" src="http://babyl.ca/techblog/static/syntax_highlight/scripts/shCore.js?v=0.6.0"></script>
 
<script type="text/javascript" src="http://babyl.ca/techblog/static/syntax_highlight/scripts/shBrushPerl.js?v=0.6.0"></script>
 
<!-- Include *at least* the core style and default theme -->
<link href="http://babyl.ca/techblog/static/syntax_highlight/styles/shCore.css?v=0.6.0" rel="stylesheet" type="text/css" />
<link href="http://babyl.ca/techblog/static/syntax_highlight/styles/shThemeDefault.css?v=0.6.0" rel="stylesheet" type="text/css" />



</head>
<body>
<div class="header">
<div class="header-inner">
<h1><a href="http://babyl.ca/techblog/">Hacking Thy Fearful Symmetry</a></h1>
<div class="tagline">Hacker, hacker coding bright.</div>
</div>
</div>
<div class="main_body">

<div class="left_column">
    <div class="widget">
<h3>Recent entries</h3>
<ul>
<li>
<a href="http://babyl.ca/techblog/entry/metacpan-js">MetaCPAN JavaScript API</a>
</li>
<li>
<a href="http://babyl.ca/techblog/entry/flattr">Flattr your CPAN Stack</a>
</li>
<li>
<a href="http://babyl.ca/techblog/entry/metacpan-recommendations">MetaCPAN Recommendations: A Proposed Battleplan</a>
</li>
<li>
<a href="http://babyl.ca/techblog/entry/tmux-got-laziness">App::GitGot, tmux and Lotsa Laziness</a>
</li>
<li>
<a href="http://babyl.ca/techblog/entry/caribou-update">Showing Off Template::Caribou</a>
</li>
</ul>

<div style="text-align:right;margin: 0px">
<a href="http://babyl.ca/techblog/entries">all entries</a>
</div>

</div>

    

<div class="widget tags_listing">
 <h3>Recent tags</h3>
 <ul id="recent_tags">
  <li value="1" title="App::GitGot">
   <a href="http://babyl.ca/techblog/tag/App::GitGot">App::GitGot</a>
  </li>
  <li value="1" title="Flattr">
   <a href="http://babyl.ca/techblog/tag/Flattr">Flattr</a>
  </li>
  <li value="3" title="MetaCPAN">
   <a href="http://babyl.ca/techblog/tag/MetaCPAN">MetaCPAN</a>
  </li>
  <li value="3" title="perl">
   <a href="http://babyl.ca/techblog/tag/perl">perl</a>
  </li>
  <li value="153" title="Perl">
   <a href="http://babyl.ca/techblog/tag/Perl">Perl</a>
  </li>
  <li value="3" title="Template::Caribou">
   <a href="http://babyl.ca/techblog/tag/Template::Caribou">Template::Caribou</a>
  </li>
 </ul>
 <div style="text-align:right;">
  <a href="http://babyl.ca/techblog/tags">all tags</a>
 </div>
</div>
<script type="text/javascript">$(function(){
    $('#recent_tags').tagcloud({ 
        type: "list",
        colormin: "AB0404",
        colormax: "AB0404"
    }).find('li').css('padding-right', '3px' );
});
</script>



<div class="widget" style="text-align:center;">
<a href="http://github.com/yanick/galuga">
    <img src="http://babyl.ca/techblog/static/galuga_button.png?v=0.6.0" style="border:0;"
    alt="Powered by a Gamboling Beluga"/>
</a></div>

</div>


<div class="middle_column">


<div class="blog_entry">
<h2><a href="http://babyl.ca/techblog/entry/metacpan-js">MetaCPAN JavaScript API</a></h2>

<div class="entry_info">
<div style="float: right">
created: Sun, Apr 14 2013</div>
</div>


<div><p>Sometimes, it's humongous revolutions. Most of the time, it's itsy bitsy
evolution steps. Today's hack definitively sits in the second category, 
but I have the feeling it's a little dab of abstraction that is going to 
provide a lot of itch relief.</p>

<p>You see, <a href="https://metacpan.org">MetaCPAN</a> does not only have a pretty face,
but also has a <a href="https://github.com/CPAN-API/cpan-api/wiki/Beta-API-docs">smashing backend</a> 
that can be used <a href="http://explorer.metacpan.org/">straight-up</a> for fun and
profit.</p>

<p>Accessing REST endpoints is not hard, but it's a little bit of a low-level
chore.  In Perl space, there is already <a href='http://search.cpan.org/dist/MetaCPAN-API'>MetaCPAN::API</a> to 
abstract</p>

<pre class="brush: perl">my $ua = LWP::UserAgent;
my $me = decode_json( 
    $ua-&gt;get( 'https://api.metacpan.org/author/YANICK'
)-&gt;content;
</pre>

<p>into</p>

<pre class="brush: perl">my $mcpan = MetaCPAN::API;
my $me = $mcpan-&gt;author('YANICK');
</pre>

<p>In JavaScript-land? Well, there was jQuery, of course:</p>

<pre><code>$.get('https://api.metacpan.org/author/YANICK').success( function(data) {
    alert( 'hi there ' + data.name );
});
</code></pre>

<p>But now there is also <a href="https://github.com/yanick/metacpan.js">metacpan.js</a>: </p>

<pre><code>$.metacpan().author('YANICK').success( function(data) {
    alert( 'hi there ' + data.name );
});
</code></pre>

<p>The plugin is still very simple and only implements <code>author()</code>, <code>module()</code>,
<code>release()</code> and <code>file()</code>. And each of those methods is nothing but a glorified
wrapper around the underlying <code>$.ajax()</code> calls. But, then again, isn't the road to
heaven paved with glorified wrappers? (which could be more of an indication of
the terrible littering habits of angels than anything else, mind you) </p>

<p>Enjoy (and/or fork, depending on how much the current code is already
scratching your own itch)!</p>
</div>

<script type="text/javascript">
   SyntaxHighlighter.all();
</script>


<div class="tags">
<b>tags: </b>
<a href='http://babyl.ca/techblog/tag/MetaCPAN'>MetaCPAN</a>, <a href='http://babyl.ca/techblog/tag/Perl'>Perl</a></div>





<div id="disqus_thread"></div>
<script type="text/javascript">
  /**
    * var disqus_identifier; [Optional but recommended: Define a unique identifier (e.g. post id or slug) for this thread] 
    */


var disqus_identifier = 'metacpan-js';
  (function() {
   var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
   dsq.src = 'http://hackingthyfearfulsymmetry.disqus.com/embed.js';
   (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
  })();
</script>
<noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript=hackingthyfearfulsymmetry">comments powered by Disqus.</a></noscript>
<a href="http://disqus.com" class="dsq-brlink">blog comments powered by <span class="logo-disqus">Disqus</span></a>

<script type="text/javascript">
var disqus_shortname = 'hackingthyfearfulsymmetry';
(function () {
  var s = document.createElement('script'); s.async = true;
  s.src = 'http://disqus.com/forums/hackingthyfearfulsymmetry/count.js';
  (document.getElementsByTagName('HEAD')[0] || document.getElementsByTagName('BODY')[0]).appendChild(s);
}());
</script>


</div>


</div>

<div class="right_column">




<div class="widget ironman">
 <h3>
  <a href="http://ironman.enlightenedperl.org/">Perl Iron Man Challenge</a>
 </h3>
 <div align="center">
  <img alt="Perl Iron Man Challenge badge" src="http://ironman.enlightenedperl.org/munger/mybadge/male/.png" />
 </div>
</div>



<script src="http://widgets.twimg.com/j/2/widget.js" type="text/javascript">
</script>
<script type="text/javascript">
new TWTR.Widget({
  version: 2,
  type: 'profile',
  rpp: 4,
  interval: 6000,
  width: 190,
  height: 300,
  theme: {
    shell: {
      background: '#333333',
      color: '#ffffff'
    },
    tweets: {
      background: '#000000',
      color: '#ffffff',
      links: '#4aed05'
    }
  },
  features: {
    scrollbar: true,
    loop: false,
    live: false,
    hashtags: true,
    timestamp: true,
    avatars: false,
    behavior: 'all'
  }
}).render().setUser('yenzie').start();
</script>


</div>


</div>


<div class="footer" style="clear: both">
</div>

</body>
</html>




