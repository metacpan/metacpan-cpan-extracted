#!perl -T
use strict;
use warnings;

use Test::More tests => 7;

use EJS::Template::Test;

ejs_test(<<EJS, <<OUT);
--begin--
  <% var x; %>\t
--end--
EJS
--begin--
--end--
OUT

ejs_test(<<EJS, <<OUT);
--begin--
  <%
    var x;
    var y;
  %>\t
--end--
EJS
--begin--
--end--
OUT

ejs_test(<<EJS, <<OUT);
--begin--
  <% if (true) { %>text<% } %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT

ejs_test(<<EJS, <<OUT);
--begin--
  <%
    var x = 0;
    if (x != 1 && x != 2) {
      %>text<% } %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT

ejs_test(<<EJS, <<OUT);
--begin--
  <% print("   text\\t\\t\\n"); %>\t
--end--
EJS
--begin--
   text\t\t
--end--
OUT

ejs_test(<<EJS, <<OUT);
--begin--
  <%= "text" %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT

ejs_test(<<EJS, <<OUT);
--begin--
  <%=
    "text"
  %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT
