#!perl -T
use strict;
use warnings;

use Test::More tests => 7;

use EJS::Template::Test;

ejs_test('', '');
ejs_test('test', 'test');
ejs_test('<%=name%>', 'test', {name => 'test'});
ejs_test('<% print(name); %>', 'test', {name => 'test'});

ejs_test('<%= foo() + bar() %>', 'FOOBAR', {
    foo => sub {return 'FOO'},
    bar => sub {return 'BAR'},
});

ejs_test(<<__EJS__, <<__OUT__);
Begin
<% for (var i = 0; i < 6; i++) { %>
  <% if (i % 2 == 1) { %>
    * i = <%=i%>
  <% } %>
<% } %>
End
__EJS__
Begin
    * i = 1
    * i = 3
    * i = 5
End
__OUT__

ejs_test(<<__EJS__, <<__OUT__);
<table>
  <% for (var r = 1; r <= 3; r++) { %>
    <tr>
      <% for (var c = 1; c <= 3; c++) { %>
        <td><%= r, ' x ', c, ' = ', r * c %></td>
      <% } %>
    </tr>
  <% } %>
</table>
__EJS__
<table>
    <tr>
        <td>1 x 1 = 1</td>
        <td>1 x 2 = 2</td>
        <td>1 x 3 = 3</td>
    </tr>
    <tr>
        <td>2 x 1 = 2</td>
        <td>2 x 2 = 4</td>
        <td>2 x 3 = 6</td>
    </tr>
    <tr>
        <td>3 x 1 = 3</td>
        <td>3 x 2 = 6</td>
        <td>3 x 3 = 9</td>
    </tr>
</table>
__OUT__
