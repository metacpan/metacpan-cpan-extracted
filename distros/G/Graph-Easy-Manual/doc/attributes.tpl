<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
 <title>Graph::Easy - Manual - Attributes</title>
 <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
 <meta name="MSSmartTagsPreventParsing" content="TRUE">
 <meta http-equiv="imagetoolbar" content="no">
 <link rel="stylesheet" type="text/css" href="../base.css">
 <link rel="stylesheet" type="text/css" href="manual.css">
 <link rel="Start" href="index.html">
 <link href="http://bloodgate.com/mail.html" rev="made">
 <!-- compliance patch for microsoft browsers -->
 <!--[if lt IE 7]><script src="http://bloodgate.com/ie7/ie7-standard-p.js" type="text/javascript"></script><![endif]-->
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
  <a class="menucur" href="attributes.html" title="All possible attributes for graphs, nodes and edges">Attributes</a>
    <a class="menuind" href="att_graphs.html" title="Graph attributes">Graphs</a>
    <a class="menuind" href="att_nodes.html" title="Node attributes">Nodes</a>
    <a class="menuind" href="att_edges.html" title="Edge attributes">Edges</a>
    <a class="menuind" href="att_groups.html" title="Group attributes">Groups</a>

    <a class="menuind" href="#class_names" title="Classes and their names">Classes</a>
    <a class="menuind" href="#labels__titles__names_and_links" title="Labels, titles, names and links">Labels</a>
    <a class="menuind" href="#links" title="Links and URLs">Links</a>
    <a class="menuind" href="#node_ranks" title="Node Ranks">Ranks</a>
    <a class="menuind" href="att_colors.html" title="Color names and values">Colors</a>
  <a class="menuext" href="faq.html" title="Frequently Asked Questions and their answers">F.A.Q.</a>
  <a class="menuext" href="tutorial.html" title="Tutorial for often used graph types and designs">Tutorial</a>
  <a class="menuext" href="editor.html" title="The interactive interface">Editor</a>
</div>

<div class="right">

<h1>Graph::Easy - Manual</h1>

<h2>Attributes</h2>

<div class="text">

<p>
If you haven't already done so, <b>please read the
<a href="syntax.html#attributes">chapter about attribute syntax</a> first</b>.
</p>

<p>
This chapter describes all the possible attributes for graphs, groups, nodes and edges.
It is generated automatically from the definitions in <code>Graph::Easy::Attributes</code>.
</p>

<p>
Please note that for compatibility reasons, as well for making it easier to remember
attribute names, the following attribute names are also accepted:
</p>

<ul>
  <li>arrow-shape, arrow-style</li>
  <li>border-color, border-style, border-width
  <li>font-size</li>
  <li>label-color, label-pos</li>
  <li>text-style, text-wrap</li>
  <li>point-style, point-shape</li>
</ul>

<hr>

<a name="Graphs">
<h3>Graphs</h3>
</a>

##graph##

<a name="Nodes">
<h3>Nodes</h3>
</a>

##node##

<a name="Edges">
<h3>Edges</h3>
</a>

##edge##

<a name="Groups">
<h3>Groups</h3>
</a>

##group##

<hr>

<a name="class_names">
<h3>Class names</h3>
</a>

<p>
Each of the primary classes <code>node</code>, <code>edge</code> and <code>group</code>
can have an arbitrary number of sub-classes. Objects can then have one of
these subclasses set via the attribute <code>class</code>.
<br>
The primary class <code>graph</code>
cannot have subclasses, and there is only one graph object and it is always
in the class <code>graph</code>. 
</p>

<p>
Class names case-insensitive, and must start with a letter (<code>[a-z]</code>), which can
be followed by any of the following: letters <code>a-z</code>, digits <code>0-9</code> or the underscore
<code>_</code>. Each subclass can have its own set of attributes.
<br>
Objects with their <code>class</code>-attributes set will use the attributes from the appropriate
subclass.
If an attribute was not defined there, they will inherit the attribute from their primary
class. In the following example the left node will have green text, the right one
will have red text. Both nodes will have a beige interieur: 
</p>

<pre class="graphtext">
node { color: green; fill: beige; }
node.cities { color: red; }

[ Green ] --> [ Red ] { class: cities; }
</pre>

<img src="img/classes.png" border=0 alt="Example of classes" title="Example of classes" style="float: left; margin-left: 1em;">

<p class="clear"></p>

<p>
<b>Note:</b> It is not yet possible to have one object belong to more than one subclass.
</p>

<h4>Class selectors</h4>

<p>
If you want to specify attributes for all objects (nodes, edges and groups) of
a specific subclass, you can use a class selector by leaving of the primary class
name, just like you would do in CSS:
</p>

<pre class="graphtext">
node { class: red }
edge { class: red }
.red { color: red; }

( Red: 
[ Red 1 ] -- red --> [ Red 2 ]
)
</pre>

<p class="clear">
This example is equivalent to:
</p>

<pre class="graphtext">
node { class: red }
edge { class: red }
node.red { color: red; }
edge.red { color: red; }

( Red: 
[ Red 1 ] -- red --> [ Red 2 ]
)
</pre>

<h4 class="clear">Class selector lists</h4>

<p>
It is also possible to list class names and class selectors in a list:
</p>

<pre class="graphtext">
node, edge, .red { class: red; color: red; }

( Red: 
[ Red 1 ] -- red --> [ Red 2 ]
)
</pre>

<a name="labels__titles__names_and_links">
<h3 class="clear">Labels, Titles and Names</h3>
</a>

<p>
The <code>label</code> is the text displayed for the node, edge etc. It can be different from the name of the object.
</p>

<p>
<code>Edges</code> do not have a name, but they can have a label. If you try to access the name
of an edge, for instance via the <code>autotitle: name;</code> attribute, than the
optional edge label will be used instead.
<p>

<p>
Apart from setting a label manually via the <code>label: Foo;</code> attribute, you can
also set labels for entire classes, or use the <code>autolabel:</code> attribute. The
latter has the advantage that it can shorten the label automaticall to sane values.
See <a href="att_graphs.html#graph_autolabel">this graph for an example.
<p>

<a name="links">
<h3>Links and URLs</h3>
</a>

<p>
Links are constructed from two parts, by concatenating the <code>linkbase</code> attribute and
the <code>link</code> attribute:
</p>

<pre class="graphtext">
node { linkbase: http://bloodgate.com/perl/; }

[ Graph ] { link: graph/; }
 --> [ Manual ] { link: graph/manual/; }
</pre>

<map id="NAME" name="NAME">
<area shape="rect" href="http://bloodgate.com/perl/graph/" title="Graph" alt="Graph" coords="17,7,89,54" />
<area shape="rect" href="http://bloodgate.com/perl/graph/manual/" title="Manual" alt="Manual" coords="137,7,209,54" />
</map>

<img USEMAP="#NAME" src="img/links.png" border=0 title="Example of links" style="float: left; margin-left: 1em;">

<p class="clear">
<code>linkbase</code> is ignored unless you also have <code>link</code> or <code>autolink</code>.
You can use <code>autolink</code> to automatically set the link attribute to the
name, label, or titel of the object:
</p>

<pre class="graphtext">
node { linkbase: http://bloodgate.com/perl/; autolink: name; }

[ graph ] --> [ graph/manual ]
</pre>

<map id="NAME2" name="NAME2">
<area shape="rect" href="http://bloodgate.com/perl/graph" title="graph" alt="graph" coords="17,7,89,54" />
<area shape="rect" href="http://bloodgate.com/perl/graph/manual" title="graph/manual" alt="graph/manual" coords="137,7,244,54" />
</map>

<img USEMAP="#NAME2" src="img/linkbase.png" border=0 alt="Example of links" title="Example of links" style="float: left; margin-left: 1em;">

<p class="clear">
Note that <code>link</code> has precedence over <code>autolink</code>, the latter
will not override a <code>link</code> attribute on the object itself.
<br>
Also, <code>linkbase</code> is only prepended for relativ links, e.g. ones that do not
start with <code>/[a-z]{3,4}://</code>. In the following example the first node
will not have the name autolinked, and the second node will ignore the linkbase:
</p>

<pre class="graphtext">
node { linkbase: http://bloodgate.com/perl/; autolink: name; }

[ graph ] { link: index.html; } 
  --> [ graph/manual ] { link: http://bloodgate.com; }
</pre>

<map id="GRAPH_0" name="GRAPH_0">
<area shape="rect" href="http://bloodgate.com/perl/index.html" title="graph" alt="graph" coords="17,7,89,54" />
<area shape="rect" href="http://bloodgate.com" title="graph/manual" alt="graph/manual" coords="137,7,244,54" />
</map>

<img USEMAP="#GRAPH_0" src="img/link_linkbase.png" border=0 alt="Example of lins" title="Example of links" style="float: left; margin-left: 1em;">

<div class="clear"></div>

<p>
Of course you can also attach a link to an edge, group or graph label.
</p>

<a name="node_ranks">
<h3>Ranks</h3>
</a>

<p>
The rank of a node or group determines the order in which nodes/groups are placed by the
layouter, as well as their position relatively to each other.
</p>

<p>
When set to <code>auto</code>, which is also the default, the rank will be determined automatically
prior to generating the layout. Starting with the root node, or nodes with no incoming edge,
nodes will get increasing ranks until all nodes have a rank set.
</p>

<p>
When setting the rank to <code>same</code> for all nodes in list, these nodes will all get the same,
automatically determined (random) rank. These nodes will also be put into an anonymous
collection so that they are laid out in the same row (or column, depending on graph flow).
</p>

<a name="color_names_and_values">
<h3>Color Names and Values</h3>
</a>

<p>
Please see the page <a href="att_colors.html">about colorschemes and color names</a>.
</p>

<div class="footer">
Page created automatically at <span class="date">##time##</span> in ##took##.
Contact: <a href="http://bloodgate.com/mail.html">Tels</a>.
</div>

</div> <!-- end of right cell -->

</body>
</html>
