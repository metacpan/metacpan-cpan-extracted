<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
 <title>Graph::Easy - Manual - Attributes - Color schemes and names</title>
 <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
 <meta name="MSSmartTagsPreventParsing" content="TRUE">
 <meta http-equiv="imagetoolbar" content="no">
 <link rel="stylesheet" type="text/css" href="../base.css">
 <link rel="stylesheet" type="text/css" href="manual.css">
 <link rel="Start" href="index.html">
 <link href="http://bloodgate.com/mail.html" rev="made">
 <!-- compliance patch for microsoft browsers -->
 <!--[if lt IE 7]><script src="http://bloodgate.com/ie7/ie7-standard-p.js" type="text/javascript"></script><![endif]-->
 <style type="text/css">
   <!-- 
    h4 { margin-bottom: 0em; padding-left: 1em; }
    td, td.w { padding-left: 0.4em; padding-right: 0.4em; width: 3em; text-align: center; font-size: 80%; }
    td.w { color: white; }
   -->
 </style>
</head>
<body bgcolor=white text=black>

<a name="top"></a>

<div class="menu">
  <a class="menubck" href="index.html" title="Back to the manual index">Index</a>
  <p style="height: 0.2em">&nbsp;</p>

  <a class="menuext" href="overview.html" title="How everything fits together">Overview</a>
  <a class="menuext" href="layouter.html" title="How the layouter works">Layouter</a>
  <a class="menuext" href="hinting.html" title="Generating specific layouts">Hinting</a>
  <a class="menuext" href="output.html" title="Output formats and their limitations">Output</a>
  <a class="menuext" href="syntax.html" title="Syntax rules for the text format">Syntax</a>
  <a class="menuext" href="attributes.html" title="All possible attributes for graphs, nodes and edges">Attributes</a>
    <a class="menuind" href="att_graphs.html" title="Graph attributes">Graphs</a>
    <a class="menuind" href="att_nodes.html" title="Node attributes">Nodes</a>
    <a class="menuind" href="att_edges.html" title="Edge attributes">Edges</a>
    <a class="menuind" href="att_groups.html" title="Group attributes">Groups</a>

    <a class="menuind" href="attributes.html#class_names" title="Classes and their names">Classes</a>
    <a class="menuind" href="attributes.html#labels__titles__names_and_links" title="Labels, titles, names and links">Labels</a>
    <a class="menuind" href="attributes.html#links" title="Links and URLs">Links</a>
    <a class="menuind" href="attributes.html#node_ranks" title="Node Ranks">Ranks</a>
    <a class="menucin" href="#color_names_and_values" title="Color names and values">Colors</a>
  <a class="menuext" href="faq.html" title="Frequently Asked Questions and their answers">F.A.Q.</a>
  <a class="menuext" href="tutorial.html" title="Tutorial for often used graph types and designs">Tutorial</a>
  <a class="menuext" href="editor.html" title="The interactive interface">Editor</a>
</div>

<div class="right">

<h1>Graph::Easy - Manual</h1>

<h2>Color Schemes and Names</h2>

<div class="text">

<p>
For all colors you can use one of the following notations:
</p>

<ul>
  <li>Hex: <code>#ff0080</code> (#rrggbb)
  <li>Hex: <code>#f08</code> (#rgb)
  <li>RGB: <code>rgb(255,0,128)</code> (0 .. 255, 0 .. 255, 0 .. 255)
  <li>HSV: <code>hsv(0.5, 0, 1.0)</code> (0 .. 1.0, 0 .. 1.0, 0 .. 1.0)
  <li>HSL: <code>hsl(300, 0.5, 0.5)</code> (0 .. 359.9999, 0 .. 1.0, 0 .. 1.0)
  <li>Name or index: <code>red</code> or <code>1</code> (see below for colorscheme info)
  <li>Special: <code>inherit</code>, <code>transparent</code> (color will be inherited from containing object)
</ul>

<p>
Note that mixing the different ways to express the RGB, HSL or HSV channels
via absolute value, percentage value or a partial value from 0..1.0 is possible,
and whitespaces are allowed, so <code>rgb(0, 50%,0.5)</code>
is a valid color.
<br>
All color values (except #RGB) take an optional alpha value.
<br>
Any color that has <code>grey</code> in it's name will also be accepted with the alternative
spelling of <code>gray</code>.
<p>

<p>
The following list shows all the color schemes recognized by <code>Graph::Easy</code>,
as well as the colors they contain and their corrosponding hex value.
<br>
Note that the <code>w3c</code> scheme is exactly the same as
the <a href="http://www.w3.org/TR/SVG/types.html#ColorKeywords">one published</a> by
<a href="">W3C</a>. So do not blame me for silly things
like <font style="color: white; background: darkseagreen">darkseagreen</font>
being lighter than <font style="color: white; background: seagreen">seagreen</font> ...
</p>

<h3>Supported color schemes:</h3>

<ul>
  <li><a href="#w3c">w3c</a></li>
  <li><a href="#x11">x11</a></li>
  <li><a href="#colorbrewer">Color Brewer</a></li>
</ul>

##colors##

</div>

<div class="footer">
Page created automatically at <span class="date">##time##</span> in ##took##.
Contact: <a href="http://bloodgate.com/mail.html">Tels</a>.
</div>

</div> <!-- end of right cell -->

</body>
</html>
