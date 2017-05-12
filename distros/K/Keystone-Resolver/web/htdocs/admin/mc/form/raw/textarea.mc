%# $Id: textarea.mc,v 1.2 2007-06-21 14:19:09 mike Exp $
<%args>
$name
$cols => 39
$rows => 4
</%args>
	 <textarea cols="<% $cols %>" rows="<% $rows %>" name="<% $name %>"
	  ><% defined $r->param($name) ? utf8param($r, $name) : "" %></textarea>
