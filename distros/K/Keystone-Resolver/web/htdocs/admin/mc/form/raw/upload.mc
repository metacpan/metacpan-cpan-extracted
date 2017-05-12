%# $Id: upload.mc,v 1.2 2007-06-21 14:19:09 mike Exp $
<%args>
$name
$size => 40
</%args>
	 <input type="file" name="<% $name %>" size="<% $size %>"
	  value="<% defined $r->param($name) ? utf8param($r, $name) : "" %>"/>
