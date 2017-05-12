#!perl -T
use strict;
use warnings;

use Test::More tests => 6;

use EJS::Template::Test;

ejs_test(<<EJS, <<OUT, undef, {escape => 'raw'});
expr: <%= "x > y" %>
EJS
expr: x > y
OUT

ejs_test(<<EJS, <<OUT, undef, {escape => 'html'});
<span><%= "x > y" %></span>
EJS
<span>x &gt; y</span>
OUT

ejs_test(<<EJS, <<OUT, undef, {escape => 'html'});
<span title='<%= "'x > y'" %>'>test</span>
EJS
<span title='&#39;x &gt; y&#39;'>test</span>
OUT

ejs_test(<<EJS, <<OUT, {url => 'http://example.com?test'}, {escape => 'html'});
<a href="?redirect=<%:uri= url %>">Redirect</a>
EJS
<a href="?redirect=http%3A%2F%2Fexample.com%3Ftest">Redirect</a>
OUT

ejs_test(<<EJS, <<OUT, {message => '<p>Hello World</p>'}, {escape => 'html'});
<div>
  <%:raw= message %>
</div>
EJS
<div>
  <p>Hello World</p>
</div>
OUT

ejs_test(<<EJS, <<OUT, {message => 'Hello "World"'}, {escape => 'html'});
<script>
var message = "<%:quote= message %>";
</script>
EJS
<script>
var message = "Hello \\"World\\"";
</script>
OUT
