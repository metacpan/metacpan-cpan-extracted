#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 3;

use Device::Inverter::KOSTAL::PIKO::Status;

my $module;
BEGIN { use_ok( $module = 'Device::Inverter::KOSTAL::PIKO::Status' ) }

isa_ok my $status = $module->new( html => do { local $/; <DATA> } ), $module;
is $status->total_energy, 69423;

__DATA__
<!DOCtype HTML PUBLIC "-//W3C//Dtd HTML 4.0 Transitional//EN">
<html>
<head>
<meta HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=ISO-8859-1">
<meta name="Generator" CONTENT="ChrisB">
<title>PV Webserver</title>
</head>
<body nof="(MB=(DefaultMasterborder, 65, 60, 150, 10), L=(HomeLayout, 700, 600))" bgcolor="#EAF7F7" text="#000000" link="#0033CC" vlink="#990099" alink="#FF0000" topmargin=0 leftmargin=0 marginwidth=0 marginheight=0>
<form method="post" action="">
<table cellspacing="0" cellpadding="0" width="770" nof="ly">
<tr><td height="5"></td></tr>
<tr><td width="190" height="55"></td>
<td width="400">
  <font face="Arial,Helvetica,Geneva,Sans-serif,sans-serif" size="+3">
  PIKO 8.3
<br><font size="+1">                 
  piko (255)
</font>
</font>
</td>
<td><img alt="Logo" height="42" width="130" src="KSE.gif"></td>
</tr>
</table>

<font face="Arial,Helvetica,Geneva,Sans-serif,sans-serif">
<table Border="0" width="100%"><tr>
<td width="150"></td>
<td> <hr> </td>
</tr></table>
<table cellspacing="0" cellpadding="0" width="770">
<tr><td></td></tr>
<tr>
<td width="190"></td>
<td colspan="2">
  <b>AC power</b></td>
<td>&nbsp</td>
<td>
  <b>energy</b></td></tr>
<tr><td height="10"></td></tr>

<tr>
<td width="190"></td>
<td width="100">
  current</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  3150</td>
<td width="140">&nbsp W</td>
<td width="100">
  total energy</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  69423</td>
<td width="50">&nbsp kWh</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  &nbsp</td>
<td width="70" align="right">
  &nbsp</td>
<td width="140">&nbsp</td>
<td width="100">
  daily energy</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  13.77</td>
<td width="50">&nbsp kWh</td>
<td>&nbsp</td></tr>
<tr height="5"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  status</td>
<td colspan="4">
  supply MPP</td>
<td>&nbsp</td></tr>
<tr height="8"><td></td></tr>
<tr><td colspan="7">
<table align="top" width="100%"><tr>
<td width="182"></td>
<td><hr size="1"></font></td></tr>
<tr><td height="5"></td></tr></table>
</td></tr>
<tr>
<td width="190"></td>
<td colspan="2">
  <b>PV generator</b></td>
<td width="140">&nbsp</td>
<td colspan="2">
  <b>output power</b></td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr><td height="10"></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  <u>String 1</u></td>
<td width="70">&nbsp</td>
<td width="140">&nbsp</td>
<td width="95">
  <u>L1</u></td>
<td width="70">&nbsp</td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr>
<td width="190"></td>
<td width="100">
  voltage</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  467</td>
<td width="140">&nbsp V</td>
<td width="100">
  voltage</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  223</td>
<td width="30">&nbsp V</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr valign="top" align="left">
<td width="190">&nbsp</td>
<td width="100">
  current</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  3.56</td>
<td width="140">&nbsp A</td>
<td width="100">
  power</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  1049</td>
<td width="30">&nbsp W</td>
<td>&nbsp</td></tr>
<tr height="22"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  <u>String 2</u></td>
<td width="70">&nbsp</td>
<td width="140">&nbsp</td>
<td width="100">
  <u>L2</u></td>
<td width="70">&nbsp</td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr>
<td width="190"></td>
<td width="100">
  voltage</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  472</td>
<td width="140">&nbsp V</td>
<td width="100">
  voltage</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  223</td>
<td width="30">&nbsp V</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr valign="top" align="left">
<td width="190">&nbsp</td>
<td width="100">
  current</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  3.59</td>
<td width="140">&nbsp A</td>
<td width="100">
  power</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  1060</td>
<td width="30">&nbsp W</td>
<td>&nbsp</td></tr>
<tr height="22"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  <u> </u></td>
<td width="70">&nbsp</td>
<td width="140">&nbsp</td>
<td width="100">
  <u>L3</u></td>
<td width="70">&nbsp</td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr>
<td width="190"></td>
<td width="100">
   </td>
<td width="70" align="right" bgcolor="#EAF7F7">
   </td>
<td width="140">&nbsp
   </td>
<td width="95">
  voltage</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  223</td>
<td width="30">&nbsp V</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr valign="top" align="left">
<td width="190">&nbsp</td>
<td width="95">
   </td>
<td width="70" align="right" bgcolor="#EAF7F7">
   </td>
<td width="140">&nbsp
 </td>
<td width="95">
  power</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  1041</td>
<td width="30">&nbsp W</td>
<td>&nbsp</td></tr>

<tr><td height="15"></td></tr>
<tr><td colspan="7">
<table align="top" width="100%">
<tr><td width="182"></td>
<td><hr size="1"></font></td>
</tr><tr><td height="5"></td></tr></table>
</td></tr></table>
<table cellspacing="0" cellpadding="0" width="770">
<tr><td width="190"></td>
<td><font face="Arial,Helvetica,Geneva,Sans-serif">
<b>RS485 communication</b></td></tr>
<tr><td height="8"></td></tr>
<tr><td width="190"></td>
<td><font face="Arial,Helvetica,Geneva,Sans-serif">
inverter&nbsp
<input type="Text" name="edWrNr" value="255" size="3" maxlength="3">
<input type="submit" value="display/update">
</td></tr><tr><td height="10"></td></tr>
</table>
</td></tr></table></font>

<hr>
<table cellspacing="0" cellpadding="0" width="770">
<tr><td height="5"></td></tr>
<tr><td width="190"></td>
<td width="330">
<font face="Arial,Helvetica,Geneva,Sans-serif,sans-serif">
<a href="LogDaten.dat">history</a>
&nbsp &nbsp &nbsp
<a href="Info.fhtml">info page</a></font></td>
<td align="right">
<font face="Arial,Helvetica,Geneva,Sans-serif,sans-serif">
<a href="Solar2.fhtml">settings</a></font></td>
<td width="50"></td>
</tr></table></font>
</form>
</body>
</html>

