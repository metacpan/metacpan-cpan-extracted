%# $Id: password.mc,v 1.3 2008-01-29 14:49:01 mike Exp $
<%args>
$name
$size => 40
$maxlength => undef
</%args>
	 <input type="password" name="<% $name %>" size="<% $size %>"
% if (defined $maxlength) {
		maxlength="<% $maxlength %>"
% }
% my $val = utf8param($r, $name);
		value="<% defined $val ? $val : "" %>"/>
