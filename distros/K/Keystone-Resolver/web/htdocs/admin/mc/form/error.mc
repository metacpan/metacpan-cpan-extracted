%# $Id: error.mc,v 1.2 2007-06-13 13:31:22 mike Exp $
<%args>
$submitted => 1	# if true, then the form was submitted, so emit errors
$cond
$msg
</%args>
% if ($submitted && $cond) {
       <tr>
	<td></td>
	<td>
<& /mc/error.mc, %ARGS &>
	</td>
       </tr>
% }
