%# $Id: textbox.mc,v 1.3 2008-01-29 14:49:01 mike Exp $
<%args>
$id => undef
$name
$size => 40
$maxlength => undef
</%args>
	 <input type="text" name="<% $name %>" size="<% $size %>"
% if (defined $maxlength) {
		maxlength="<% $maxlength %>"
% }
% if (defined $id) {
		id="<% $id %>"
% }
% my $val = utf8param($r, $name);
		value="<% defined $val ? $val : "" %>"/>
