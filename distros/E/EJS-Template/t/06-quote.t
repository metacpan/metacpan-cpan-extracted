#!perl -T
use strict;
use warnings;

use Test::More tests => 4;

use EJS::Template::Test;

ejs_test(<<EJS, <<OUT);
outer: ' \\' " \\"
"[ <%= "inner: ' \\' \\" signs" %> ]"
EJS
outer: ' \\' " \\"
"[ inner: ' ' " signs ]"
OUT

ejs_test(<<EJS, <<OUT);
outer: ' \\' " \\"
'[ <%= 'inner: " \\" \\' signs' %> ]'
EJS
outer: ' \\' " \\"
'[ inner: " " ' signs ]'
OUT

ejs_test(<<EJS, <<OUT);
print tags <%= "<", "%...%", "> and <", "%=...%", ">" %>
EJS
print tags <%...%> and <%=...%>
OUT

ejs_test(<<EJS, <<OUT);
print tags <% print('<', '%...%', '> and <', '%=...%', '>'); %>
EJS
print tags <%...%> and <%=...%>
OUT
