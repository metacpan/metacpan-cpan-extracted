<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta name="MSSmartTagsPreventParsing" content="TRUE">
<meta http-equiv="imagetoolbar" content="no">
<title>Example.com - spam statistics</title>
<link rel="stylesheet" type="text/css" href="spam.css">
</head>
<body bgcolor="#ffffff">

<h1>Example.com - spam statistics</h1>

<h2>Table of Contents</h2>

<ul>
<li><a href="#intro">Introduction</a>
<li><a href="#stats">Statistics</a>
<li><a href="#graphs">Graphs</a>:
  <ul>
  <li><a href="#last_x_days">The last 60 days</a>
  <li><a href="#daily">##items## daily</a>
  <li><a href="#monthly">##items## monthly</a>
  <li><a href="#yearly">##items## yearly</a>
  <li><a href="#hour">##items## per hour of the day</a>
  <li><a href="#dow">##items## per day of the week</a>
  <li><a href="#day">##items## per day of the month</a>
  <li><a href="#month">##items## per month</a>
  <li><a href="#toplevel">##items## per toplevel domain</a>
  <li><a href="#rule">##items## per spam filter rule</a>
  <li><a href="#target">##items## per target address</a>
  <li><a href="#domain">##items## per target domain</a>
  <li><a href="#histogram">SpamAssassin score histogram</a>
  </ul>
</ul>

<h2>Introduction</h2>
<a name="intro">
</a>

<p>
This page is an attempt to visualize the spam amounts I get. 
</p>

<h2>Statistics</h2>
<a name="stats">
</a>

<table border=0 cellpadding=2 cellspacing=0>

<tr><td class="left">
##Items## in archive:
</td><td class="right">
##items_processed##
</td></tr>

<tr><td class="left">
Archive size (compressed):
</td><td class="right">
##size_compressed##
</td></tr>

<tr><td class="left">
Archive size (uncompressed):
</td><td class="right">
##size_uncompressed##
</td></tr>

<tr><td class="left">
##Items## skipped:
</td><td class="right">
##items_skipped##
</td></tr>

<tr><td class="left">
##Items## in the last 24 hours:
</td><td class="right">
##last_24_hours##
</td></tr>

<tr><td class="left">
##Items## in the last 7 days:
</td><td class="right">
##last_7_days##
</td></tr>

<tr><td class="left">
##Items## in the last 30 days:
</td><td class="right">
##last_30_days##
</td></tr>

</table>

<p>
Spams are skipped due to two reasons:
</p>

<ul>
<li>Either they have a garbled <code>From</code> line, like an invalid date
<li>or they are double-bounces, e.g. a bounce from the mailer-daemon to notify
the sender of the alleged spam bounced again back with an error message.
Most of the times the spammers use invalid or forged addresses, and usually
the other side is quickly filled with all the bounces and complains, thus
double-bounces occur frequently.
</ul>

<h2>Graphs</h2>
<a name="graphs">
</a>

<p class="head">
<a name="last_x_days">
The last 60 days
</a>
</p>

<p class="stat">
<img src="last_x_days.png" border=0 alt="The last 60 days">
</p>

<p></p>

<p class="head">
<a name="daily">
Daily
</a>
</p>

<p class="stat">
<img src="daily.png" border=0 alt="##Items## per day">
</p>

<p></p>

<p class="head">
<a name="monthly">
Monthly
</a>
</p>

<p class="stat">
<img src="monthly.png" border=0 alt="##Items## per month">
</p>

<p></p>

<p class="head">
<a name="yearly">
Yearly
</a>
</p>

<p class="stat">
<img src="yearly.png" border=0 alt="##Items## per Year">
</p>

<p></p>

<p class="head">
<a name="hour">
Per Hour of the Day
</a>
</p>

<p class="stat">
<img src="hour.png" border=0 alt="##Items## per Hour of the Day">
</p>

<p></p>

<p class="head">
<a name="dow">
Per Day of the Week
</a>
</p>

<p class="stat">
<img src="dow.png" border=0 alt="##Items## per Day of the Week">
</p>

<p></p>

<p class="head">
<a name="day">
Per Day of the Month
</a>
</p>

<p class="stat">
<img src="day.png" border=0 alt="##Items## per Day of the Month">
</p>

<p></p>

<p class="head">
<a name="month">
Per Month
</a>
</p>

<p class="stat">
<img src="month.png" border=0 alt="##Items## per Month of the Year">
</p>

<p></p>

<p class="head">
<a name="toplevel">
Per Top-level Domain
</a>
</p>

<p class="stat">
<img src="toplevel.png" border=0 alt="##Items## per top-level Domain">
</p>

<p></p>

<p class="head">
<a name="rule">
Per Filter Rule
</a>
</p>

<p class="stat">
<img src="rule.png" border=0 alt="##Items## per rule">
</p>

<p></p>

<p class="head">
<a name="target">
Per Target Address
</a>
</p>

<p class="stat">
<img src="target.png" border=0 alt="##Items## per target address">
</p>

<p></p>

<p class="head">
<a name="domain">
Per Target Domain
</a>
</p>

<p class="stat">
<img src="domain.png" border=0 alt="##Items## per target domain">
</p>

<p></p>

<p class="head">
<a name="histogram">
SpamAssassin Score Histogram
</a>
</p>

<p class="stat">
<img src="score_histogram.png" border=0 alt="SpamAssassin Score Histogram">
</p>


<table border=0 class="bottom" width="100%">
  <tr><td>
  Made with <a href="http://search.cpan.org/search?dist=Mail-Graph">Mail::Graph</a> v##version##
  <br>
  Last regenerated: ##generated##, took ##took## seconds
  <td align=right>
  <a href="http://validator.w3.org/check/referer"><img
     src="w3c.png" height="31" width="88"
     align=right border="0" alt="Valid HTML 4.01!"></a>
</td></tr></table>

</body>
</html>
