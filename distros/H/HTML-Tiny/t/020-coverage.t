use strict; use warnings;
use Test::More;
use HTML::Tiny;

# We have 100% coverage without these tests. Consider these extra
# security against something getting twisted out of shape.

my %schedule;

BEGIN {
  my @common_schedule = (
    {
      "expect_list" => [
        "<a href=\"http://hexten.net\">Hexten</a>",
        "<a href=\"http://search.cpan.org\">CPAN Search</a>"
      ],
      "args" => [
        { "href" => "http://hexten.net" },
        "Hexten",
        { "href" => "http://search.cpan.org" },
        "CPAN Search"
      ],
      "expect_scalar" =>
       "<a href=\"http://hexten.net\">Hexten</a><a href=\"http://search.cpan.org\">CPAN Search</a>",
      "method" => "a"
    },
    {
      "expect_list" => [ "<abbr>one</abbr>", "<abbr>two</abbr>" ],
      "args"        => [ "one",              "two" ],
      "expect_scalar" => "<abbr>one</abbr><abbr>two</abbr>",
      "method"        => "abbr"
    },
    {
      "expect_list" =>
       [ "<acronym>one</acronym>", "<acronym>two</acronym>" ],
      "args" => [ {}, "one", { x => 1 }, { x => undef }, "two" ],
      "expect_scalar" => "<acronym>one</acronym><acronym>two</acronym>",
      "method"        => "acronym"
    },
    {
      "expect_list" =>
       [ "<address>onetwo</address>", "<address>threefour</address>" ],
      "args" => [ [ "one", "two" ], [ "three", "four" ] ],
      "expect_scalar" =>
       "<address>onetwo</address><address>threefour</address>",
      "method" => "address"
    },
    {
      "expect_list"   => ["<one>two</one>"],
      "args"          => [ "one", "two" ],
      "expect_scalar" => "<one>two</one>",
      "method"        => "auto_tag"
    },
    {
      "expect_list"   => [ "<b>one</b>", "<b>two</b>" ],
      "args"          => [ "one",        "two" ],
      "expect_scalar" => "<b>one</b><b>two</b>",
      "method"        => "b"
    },
    {
      "expect_list" => [ "<bdo>one</bdo>", "<bdo>two</bdo>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<bdo>one</bdo><bdo>two</bdo>",
      "method"        => "bdo"
    },
    {
      "expect_list" => [ "<big>one</big>", "<big>two</big>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<big>one</big><big>two</big>",
      "method"        => "big"
    },
    {
      "expect_list" => [
        "<blockquote>one</blockquote>",
        "<blockquote>two</blockquote>"
      ],
      "args" => [ "one", "two" ],
      "expect_scalar" =>
       "<blockquote>one</blockquote><blockquote>two</blockquote>",
      "method" => "blockquote"
    },
    {
      "expect_list" => [ "<body>one</body>\n", "<body>two</body>\n" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<body>one</body>\n<body>two</body>\n",
      "method"        => "body"
    },
    {
      "expect_list" =>
       [ "<button>one</button>", "<button>two</button>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<button>one</button><button>two</button>",
      "method"        => "button"
    },
    {
      "expect_list" =>
       [ "<caption>one</caption>", "<caption>two</caption>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<caption>one</caption><caption>two</caption>",
      "method"        => "caption"
    },
    {
      "expect_list" => [ "<cite>one</cite>", "<cite>two</cite>" ],
      "args"        => [ "one",              "two" ],
      "expect_scalar" => "<cite>one</cite><cite>two</cite>",
      "method"        => "cite"
    },
    {
      "expect_list"   => ["</tag>"],
      "args"          => ["tag"],
      "expect_scalar" => "</tag>",
      "method"        => "close"
    },
    {
      "expect_list" => [ "<code>one</code>", "<code>two</code>" ],
      "args"        => [ "one",              "two" ],
      "expect_scalar" => "<code>one</code><code>two</code>",
      "method"        => "code"
    },
    {
      "expect_list" =>
       [ "<colgroup>one</colgroup>", "<colgroup>two</colgroup>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" =>
       "<colgroup>one</colgroup><colgroup>two</colgroup>",
      "method" => "colgroup"
    },
    {
      "expect_list"   => [ "<dd>one</dd>", "<dd>two</dd>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<dd>one</dd><dd>two</dd>",
      "method"        => "dd"
    },
    {
      "expect_list" => [ "<del>one</del>", "<del>two</del>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<del>one</del><del>two</del>",
      "method"        => "del"
    },
    {
      "expect_list" => [ "<dfn>one</dfn>", "<dfn>two</dfn>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<dfn>one</dfn><dfn>two</dfn>",
      "method"        => "dfn"
    },
    {
      "expect_list" => [ "<div>one</div>\n", "<div>two</div>\n" ],
      "args"        => [ "one",              "two" ],
      "expect_scalar" => "<div>one</div>\n<div>two</div>\n",
      "method"        => "div"
    },
    {
      "expect_list"   => [ "<dl>one</dl>", "<dl>two</dl>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<dl>one</dl><dl>two</dl>",
      "method"        => "dl"
    },
    {
      "expect_list"   => [ "<dt>one</dt>", "<dt>two</dt>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<dt>one</dt><dt>two</dt>",
      "method"        => "dt"
    },
    {
      "expect_list"   => [ "<em>one</em>", "<em>two</em>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<em>one</em><em>two</em>",
      "method"        => "em"
    },
    {
      "expect_list"   => ["one"],
      "args"          => [ "one", "two" ],
      "expect_scalar" => "one",
      "method"        => "entity_encode"
    },
    {
      "expect_list" =>
       [ "<fieldset>one</fieldset>", "<fieldset>two</fieldset>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" =>
       "<fieldset>one</fieldset><fieldset>two</fieldset>",
      "method" => "fieldset"
    },
    {
      "expect_list" => [ "<form>one</form>", "<form>two</form>" ],
      "args"        => [ "one",              "two" ],
      "expect_scalar" => "<form>one</form><form>two</form>",
      "method"        => "form"
    },
    {
      "expect_list" =>
       [ "<frameset>one</frameset>", "<frameset>two</frameset>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" =>
       "<frameset>one</frameset><frameset>two</frameset>",
      "method" => "frameset"
    },
    {
      "expect_list"   => [ "<h1>one</h1>", "<h1>two</h1>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<h1>one</h1><h1>two</h1>",
      "method"        => "h1"
    },
    {
      "expect_list"   => [ "<h2>one</h2>", "<h2>two</h2>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<h2>one</h2><h2>two</h2>",
      "method"        => "h2"
    },
    {
      "expect_list"   => [ "<h3>one</h3>", "<h3>two</h3>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<h3>one</h3><h3>two</h3>",
      "method"        => "h3"
    },
    {
      "expect_list"   => [ "<h4>one</h4>", "<h4>two</h4>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<h4>one</h4><h4>two</h4>",
      "method"        => "h4"
    },
    {
      "expect_list"   => [ "<h5>one</h5>", "<h5>two</h5>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<h5>one</h5><h5>two</h5>",
      "method"        => "h5"
    },
    {
      "expect_list"   => [ "<h6>one</h6>", "<h6>two</h6>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<h6>one</h6><h6>two</h6>",
      "method"        => "h6"
    },
    {
      "expect_list" => [ "<head>one</head>\n", "<head>two</head>\n" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<head>one</head>\n<head>two</head>\n",
      "method"        => "head"
    },
    {
      "expect_list" => [ "<html>one</html>\n", "<html>two</html>\n" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<html>one</html>\n<html>two</html>\n",
      "method"        => "html"
    },
    {
      "expect_list"   => [ "<i>one</i>", "<i>two</i>" ],
      "args"          => [ "one",        "two" ],
      "expect_scalar" => "<i>one</i><i>two</i>",
      "method"        => "i"
    },
    {
      "expect_list" =>
       [ "<mark>one</mark>", "<mark>two</mark>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<mark>one</mark><mark>two</mark>",
      "method"        => "mark"
    },
    {
      "expect_list" => [ "<ins>one</ins>", "<ins>two</ins>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<ins>one</ins><ins>two</ins>",
      "method"        => "ins"
    },
    {
      "expect_list"   => ["[{},{},null,{\"x\":1}]"],
      "args"          => [ [ {}, {}, undef, { x => 1 } ] ],
      "expect_scalar" => "[{},{},null,{\"x\":1}]",
      "method"        => "json_encode"
    },
    {
      "expect_list" => [ "<kbd>one</kbd>", "<kbd>two</kbd>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<kbd>one</kbd><kbd>two</kbd>",
      "method"        => "kbd"
    },
    {
      "expect_list" => [ "<label>one</label>", "<label>two</label>" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<label>one</label><label>two</label>",
      "method"        => "label"
    },
    {
      "expect_list" =>
       [ "<legend>one</legend>", "<legend>two</legend>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<legend>one</legend><legend>two</legend>",
      "method"        => "legend"
    },
    {
      "expect_list"   => [ "<li>one</li>", "<li>two</li>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<li>one</li><li>two</li>",
      "method"        => "li"
    },
    {
      "expect_list" => [ "<map>one</map>", "<map>two</map>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<map>one</map><map>two</map>",
      "method"        => "map"
    },
    {
      "expect_list" =>
       [ "<noframes>one</noframes>", "<noframes>two</noframes>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" =>
       "<noframes>one</noframes><noframes>two</noframes>",
      "method" => "noframes"
    },
    {
      "expect_list" =>
       [ "<noscript>one</noscript>", "<noscript>two</noscript>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" =>
       "<noscript>one</noscript><noscript>two</noscript>",
      "method" => "noscript"
    },
    {
      "expect_list" =>
       [ "<object>one</object>", "<object>two</object>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<object>one</object><object>two</object>",
      "method"        => "object"
    },
    {
      "expect_list"   => [ "<ol>one</ol>", "<ol>two</ol>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<ol>one</ol><ol>two</ol>",
      "method"        => "ol"
    },
    {
      "args"          => ['pie'],
      "expect_scalar" => "<pie>",
      "method"        => "open"
    },
    {
      "expect_list" =>
       [ "<optgroup>one</optgroup>", "<optgroup>two</optgroup>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" =>
       "<optgroup>one</optgroup><optgroup>two</optgroup>",
      "method" => "optgroup"
    },
    {
      "expect_list" =>
       [ "<option>one</option>", "<option>two</option>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<option>one</option><option>two</option>",
      "method"        => "option"
    },
    {
      "expect_list"   => [ "<p>one</p>\n", "<p>two</p>\n" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<p>one</p>\n<p>two</p>\n",
      "method"        => "p"
    },
    {
      "expect_list" => [ "<pre>one</pre>", "<pre>two</pre>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<pre>one</pre><pre>two</pre>",
      "method"        => "pre"
    },
    {
      "expect_list"   => [ "<q>one</q>", "<q>two</q>" ],
      "args"          => [ "one",        "two" ],
      "expect_scalar" => "<q>one</q><q>two</q>",
      "method"        => "q"
    },
    {
      "args" => [ { spaces => '   ', '&' => '>' } ],
      "expect_scalar" => "%26=%3e&spaces=+++",
      "method"        => "query_encode"
    },
    {
      "expect_list" => [ "<samp>one</samp>", "<samp>two</samp>" ],
      "args"        => [ "one",              "two" ],
      "expect_scalar" => "<samp>one</samp><samp>two</samp>",
      "method"        => "samp"
    },
    {
      "expect_list" =>
       [ "<script>one</script>", "<script>two</script>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<script>one</script><script>two</script>",
      "method"        => "script"
    },
    {
      "expect_list" =>
       [ "<select>one</select>", "<select>two</select>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<select>one</select><select>two</select>",
      "method"        => "select"
    },
    {
      "expect_list" => [ "<small>one</small>", "<small>two</small>" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<small>one</small><small>two</small>",
      "method"        => "small"
    },
    {
      "expect_list" => [ "<span>one</span>", "<span>two</span>" ],
      "args"        => [ "one",              "two" ],
      "expect_scalar" => "<span>one</span><span>two</span>",
      "method"        => "span"
    },
    {
      "expect_list" =>
       [ "<strong>one</strong>", "<strong>two</strong>" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<strong>one</strong><strong>two</strong>",
      "method"        => "strong"
    },
    {
      "expect_list" => [ "<style>one</style>", "<style>two</style>" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<style>one</style><style>two</style>",
      "method"        => "style"
    },
    {
      "expect_list" => [ "<sub>one</sub>", "<sub>two</sub>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<sub>one</sub><sub>two</sub>",
      "method"        => "sub"
    },
    {
      "expect_list" => [ "<sup>one</sup>", "<sup>two</sup>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<sup>one</sup><sup>two</sup>",
      "method"        => "sup"
    },
    {
      "expect_list" =>
       [ "<table>one</table>\n", "<table>two</table>\n" ],
      "args" => [ "one", "two" ],
      "expect_scalar" => "<table>one</table>\n<table>two</table>\n",
      "method"        => "table"
    },
    {
      "expect_list"   => ["<one>two</one>"],
      "args"          => [ "one", "two" ],
      "expect_scalar" => "<one>two</one>",
      "method"        => "tag"
    },
    {
      "expect_list" => [ "<tbody>one</tbody>", "<tbody>two</tbody>" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<tbody>one</tbody><tbody>two</tbody>",
      "method"        => "tbody"
    },
    {
      "expect_list"   => [ "<td>one</td>", "<td>two</td>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<td>one</td><td>two</td>",
      "method"        => "td"
    },
    {
      "expect_list" => [
        "<textarea>one</textarea>",
        "<textarea cols=\"20\">two</textarea>"
      ],
      "args" => [ "one", { cols => 20 }, "two" ],
      "expect_scalar" =>
       "<textarea>one</textarea><textarea cols=\"20\">two</textarea>",
      "method" => "textarea"
    },
    {
      "expect_list" => [ "<tfoot>one</tfoot>", "<tfoot>two</tfoot>" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<tfoot>one</tfoot><tfoot>two</tfoot>",
      "method"        => "tfoot"
    },
    {
      "expect_list"   => [ "<th>one</th>", "<th>two</th>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<th>one</th><th>two</th>",
      "method"        => "th"
    },
    {
      "expect_list" => [ "<thead>one</thead>", "<thead>two</thead>" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<thead>one</thead><thead>two</thead>",
      "method"        => "thead"
    },
    {
      "expect_list" => [ "<title>one</title>", "<title>two</title>" ],
      "args"        => [ "one",                "two" ],
      "expect_scalar" => "<title>one</title><title>two</title>",
      "method"        => "title"
    },
    {
      "expect_list" => [ "<tr>one</tr>\n", "<tr>two</tr>\n" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<tr>one</tr>\n<tr>two</tr>\n",
      "method"        => "tr"
    },
    {
      "expect_list"   => [ "<tt>one</tt>", "<tt>two</tt>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<tt>one</tt><tt>two</tt>",
      "method"        => "tt"
    },
    {
      "expect_list"   => [ "<ul>one</ul>", "<ul>two</ul>" ],
      "args"          => [ "one",          "two" ],
      "expect_scalar" => "<ul>one</ul><ul>two</ul>",
      "method"        => "ul"
    },
    {
      "expect_list"   => ["   !"],
      "args"          => ['++%20%21'],
      "expect_scalar" => "   !",
      "method"        => "url_decode"
    },
    {
      "expect_list"   => ['+++%21'],
      "args"          => ['   !'],
      "expect_scalar" => '+++%21',
      "method"        => "url_encode"
    },
    {
      "expect_list" => [ "<var>one</var>", "<var>two</var>" ],
      "args"        => [ "one",            "two" ],
      "expect_scalar" => "<var>one</var><var>two</var>",
      "method"        => "var"
    }
  );

  my @schedule_xml = (
    @common_schedule,
    {
      "args"          => [ { name => 'foo' } ],
      "expect_scalar" => "<area name=\"foo\" />",
      "expect_list"   => ["<area name=\"foo\" />"],
      "method"        => "area"
    },
    {
      "args" => [ { href => 'http://hexten.net/' } ],
      "expect_scalar" => "<base href=\"http://hexten.net/\" />",
      "expect_list"   => ["<base href=\"http://hexten.net/\" />"],
      "method"        => "base"
    },
    {
      "args"          => [],
      "expect_scalar" => "<br />",
      "method"        => "br"
    },
    {
      "args"          => ['frob'],
      "expect_scalar" => "<frob />",
      "method"        => "closed"
    },
    {
      "args"          => [],
      "expect_scalar" => "<col />",
      "method"        => "col"
    },
    {
      "args"          => [],
      "expect_scalar" => "<frame></frame>",
      "method"        => "frame"
    },
    {
      "args"          => [],
      "expect_scalar" => "<iframe></iframe>",
      "method"        => "iframe"
    },
    {
      "args"          => [],
      "expect_scalar" => "<hr />",
      "method"        => "hr"
    },
    {
      # This is correct according to our hash merging rules
      "args" => [ { src => 'logo.png' }, { src => 'header.png' } ],
      "expect_list"   => ['<img src="header.png" />'],
      "expect_scalar" => '<img src="header.png" />',
      "method"        => "img"
    },
    {
      "args" => [ { type => 'text' }, { name => 'widget' } ],
      "expect_scalar" => "<input name=\"widget\" type=\"text\" />",
      "method"        => "input"
    },
    {
      "args" => [ { href => 'http://foo.net/' } ],
      "expect_scalar" =>  '<link href="http://foo.net/" />' ,
      "method"        => "link"
    },
    {
      "args"          => [],
      "expect_scalar" => "<meta />",
      "method"        => "meta"
    },
    {
      "args"          => [ { value => 1 } ],
      "expect_scalar" => "<param value=\"1\" />",
      "method"        => "param"
    },
  );

  my @schedule_html = (
    @common_schedule,
    {
      "args"          => [ { name => 'foo' } ],
      "expect_scalar" => "<area name=\"foo\">",
      "expect_list"   => ["<area name=\"foo\">"],
      "method"        => "area"
    },
    {
      "args" => [ { href => 'http://hexten.net/' } ],
      "expect_scalar" => "<base href=\"http://hexten.net/\">",
      "expect_list"   => ["<base href=\"http://hexten.net/\">"],
      "method"        => "base"
    },
    {
      "args"          => [],
      "expect_scalar" => "<br>",
      "method"        => "br"
    },
    {
      "args"          => ['frob'],
      "expect_scalar" => "<frob>",
      "method"        => "closed"
    },
    {
      "args"          => [],
      "expect_scalar" => "<col>",
      "method"        => "col"
    },
    {
      "args"          => [],
      "expect_scalar" => "<frame></frame>",
      "method"        => "frame"
    },
    {
      "args"          => [],
      "expect_scalar" => "<iframe></iframe>",
      "method"        => "iframe"
    },
    {
      "args"          => [],
      "expect_scalar" => "<hr>",
      "method"        => "hr"
    },
    {
      # This is correct according to our hash merging rules
      "args" => [ { src => 'logo.png' }, { src => 'header.png' } ],
      "expect_list"   => ['<img src="header.png">'],
      "expect_scalar" => '<img src="header.png">',
      "method"        => "img"
    },
    {
      "args" => [ { type => 'text' }, { name => 'widget' } ],
      "expect_scalar" => "<input name=\"widget\" type=\"text\">",
      "method"        => "input"
    },
    {
      "args" => [ { href => 'http://foo.net/' } ],
      "expect_scalar" =>  '<link href="http://foo.net/">' ,
      "method"        => "link"
    },
    {
      "args"          => [],
      "expect_scalar" => "<meta>",
      "method"        => "meta"
    },
    {
      "args"          => [ { value => 1 } ],
      "expect_scalar" => "<param value=\"1\">",
      "method"        => "param"
    },
  );

  plan tests => ( @schedule_xml + @schedule_html ) * 3 * 4;
  @schedule{qw(xml html)} = ( \@schedule_xml, \@schedule_html );
}

sub apply_test {
  my ( $h, $test ) = @_;

  my $method = $test->{method};
  can_ok $h, $method;

  my $got = $h->$method( @{ $test->{args} } );
  is_deeply $got, $test->{expect_scalar},
   "$method: scalar result matches";

  my $expect_list = $test->{expect_list}
   || [ $test->{expect_scalar} ];
  my @got = $h->$method( @{ $test->{args} } );
  is_deeply \@got, $expect_list, "$method: list result matches";
}

for my $mode ( qw(xml html) ) {
  my @schedule = @{ $schedule{$mode} };

  # Run the tests three times, forwards and backwards to make sure they
  # don't interfere with each other.
  {
    my $h = HTML::Tiny->new( mode => $mode );
    apply_test( $h, $_ ) for @schedule, reverse @schedule, @schedule;
  }

  # And once again, this time with a fresh HTML::Tiny for each test
  apply_test( HTML::Tiny->new( mode => $mode ), $_ ) for @schedule;
}

