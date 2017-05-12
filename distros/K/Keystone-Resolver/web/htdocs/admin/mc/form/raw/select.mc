%# $Id: select.mc,v 1.2 2007-06-21 14:19:09 mike Exp $
<%args>
$name
$size => 1
$options
$extraArgs => undef
</%args>
	 <select name="<% $name %>" size="<% $size %>"
		<% defined $extraArgs ? $extraArgs : "" %>>
% foreach my $ref (@$options) {
%     my($value, $display) = @$ref;
%     my $selected = "";
%     $selected = ' selected="selected"' if utf8param($r, $name) eq $value;
	  <option value="<% $value %>"<% $selected %>><% $display %></option>
% }
	 </select>
