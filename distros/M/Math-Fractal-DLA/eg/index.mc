<%doc>
Diffusion limited aggregation (DLA) fractal

Copyright 2002 by Wolfgang Gruber

Example file for HTML::Mason
</%doc>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>Diffusion limited aggregation</title>
<!-- Content Type -->
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body>
<h1>Diffusion limited aggregation (DLA)</h1>

<%perl>
if ($generate)
{
</%perl>
<img src="dla.mc?pixels=<% $pixels %>&width=<% $width %>&height=<% $height %>&bgred=<% $bgred %>&bggreen=<% $bggreen %>&bgblue=<% $bgblue %>&colors=<% $colors %>&bsred=<% $bsred %>&bsgreen=<% $bsgreen %>&bsblue=<% $bsblue %>&ared=<% $ared %>&agreen=<% $agreen %>&ablue=<% $ablue %>&mode=<% $mode %>" width="<% $width %>" height="<% $height %>"></img>
% } else {

<form method="post">
<table>
<tr>
  <td>Number of points:</td>
  <td><input type="text" name="pixels" value="<% $pixels %>"></input></td>
  <td>&nbsp;</td>
</tr>
<tr>
  <td>Width of image:</td>
  <td><input type="text" name="width" value="<% $width %>"></input></td>
  <td>&nbsp;</td>
<tr>
  <td>Height of image:</td>
  <td><input type="text" name="height" value="<% $height %>"></input></td>
  <td>&nbsp;</td>
</tr>
<tr>
  <td>Mode:</td>
  <td>
      <select name="mode">
      <option value="0" selected>Explode</option>
	  <option value="1">Race 2 Center</option>
	  <option value="2">Surrounding</option>
	  <option value="3">Grow up</option>
	  </select>
  </td>
  <td>&nbsp;</td>
</tr>
<tr>
  <td>Number of colors:</td>
  <td><input type="text" name="colors" value="<% $colors %>"></input></td>
  <td>&nbsp;</td>
</tr>
<tr>
  <td colspan="3">Background color</td>
</tr>
<tr>
  <td>Red <input type="text" name="bgred" value="<% $bgred %>"></input></td>
  <td>Green <input type="text" name="bggreen" value="<% $bggreen %>"></input></td>
  <td>Blue <input type="text" name="bgblue" value="<% $bgblue %>"></input></td>
</tr>
<tr>
  <td colspan="3">Base color</td>
</tr>
<tr>
  <td>Red <input type="text" name="bsred" value="<% $bsred %>"></input></td>
  <td>Green <input type="text" name="bsgreen" value="<% $bsgreen %>"></input></td>
  <td>Blue <input type="text" name="bsblue" value="<% $bsblue %>"></input></td>
</tr>
<tr>
  <td colspan="3">Color value to add</td>
</tr>
<tr>
  <td>Red <input type="text" name="ared" value="<% $ared %>"></input></td>
  <td>Green <input type="text" name="agreen" value="<% $agreen %>"></input></td>
  <td>Blue <input type="text" name="ablue" value="<% $ablue %>"></input></td>
</tr>
<tr>  
  <td colspan="3" align="center">
    <input type="submit" value="Generate Fractal" name="generate"><br>
  </td>
</tr>
</table>
</form>

% }
<br clear="all">
Copyright &copy; Wolfgang Gruber<br>
All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.<br>
</body>

</html>

<%args>
$generate => undef
$pixels => 500
$mode => 0
$width => 300
$height => 300
$colors => 1
$bgred => 255
$bggreen => 255
$bgblue => 255
$bsred => 0
$bsgreen => 255 
$bsblue => 255 
$ared => 0
$agreen => 0
$ablue => 0
</%args>

<%flags>
  inherit => undef
</%flags>
