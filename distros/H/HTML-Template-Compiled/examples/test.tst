===test.html 1==========================================
name: <%= $name%> look ma: ~
name with "": <%= $name%>
INCLUDE: (((<%= $tmpl->include("examples/included.tst") %>)))
---------------
loop a:
<% for my $ix (0..$#$loopa) {
local $_ = $loopa->[$ix]; %>
first?<%= $ix == 0 %> or last? <%= $ix == $#$loopa %>
-----num:<%= $ix+1 %>
 item: <%= $_->{a} %>
<% } %>
loop b:<% for my $ix (0..$#$loopb) {
my $item = $loopb->[$ix]; %>item: ROOT:<%= $item->{inner} %>
<% } %>
loop c
---------------
<% for my $ix (0..$#$c) {
my $item = $c->[$ix]; %>----num:<%= $ix %>
<%for my $ix (0..$#{$item->{d}}) {
my $i_item = $item->{d}->[$ix]; %>
*<% if ($ix == 0) { %>first<% } %><% if ($ix == $#{$item->{d}}) { %>last <% } %><%
 if ($ix != 0 && $ix != $#{$item->{d}}) { %>inner<% } %> item: <%= $i_item->{F} %><% if (($ix+1) % 2) { %>odd<% } %>
<% } %>
<% } %>
---------------------
<% if ($if2) { %>if.if2!<% } %> <% if ($if3) { %>if.if3!  <% } else { %>no if.if3!<% } %> <% unless ($if3) { %>no if.if3!!<% } %>
===test.html ende==========================================
