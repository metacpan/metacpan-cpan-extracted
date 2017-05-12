%# $Id: checkbox.mc,v 1.2 2008-01-29 14:49:01 mike Exp $
<%args>
$name
$label
</%args>
	 <input type="checkbox" id="<% $name %>" name="<% $name %>" value="1"
	   <% defined utf8param($r, $name) ? qq[checked="checked"] : "" %>/>
	 <label for="<% $name %>"><% $label %></label>
