%# $Id: cookies.mc,v 1.1 2007-05-16 12:41:15 mike Exp $
<%args>
$cookies
</%args>
% my $n = scalar(keys %$cookies);
  <div class="debug">
% if ($n == 0) {
   There are no cookies.
% } else {
   There <% $n == 1 ? "is" : "are" %> <% $n %> cookie<% $n == 1 ? "" : "s" %>:
   <ul>
%   foreach my $key (sort keys %$cookies) {
%     my $cookie = $cookies->{$key};
%     my $domain = $cookie->domain();
%     my $path = $cookie->path();
%     my $expires = $cookie->expires();
    <li>
     <% $key %>='<% $cookie->value() %>'
%   if (defined $domain) {
     domain=<% $domain %>
%   }
%   if (defined $path) {
     path=<% $path %>
%   }
%   if (defined $expires) {
     expires=<% $expires %>
%   }
    </li>
%   }
   </ul>
% }
  </div>
