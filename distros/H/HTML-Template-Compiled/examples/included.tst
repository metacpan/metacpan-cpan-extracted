-----INCLUDED!!!
inc: <%= $bubber%>
-----INCLUDED END!!!
loop a:
<% for my $ix (0..$#$loopa) {
local $_ = $loopa->[$ix]; %>
 item: <%= $_->{a} %>
<% } %>

