package Kwiki::Theme::TabNav;
use strict;
use warnings;
use Kwiki::Theme '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = 0.01;

const theme_id => 'tabnav';
const class_title => 'tabbed toolbar navigation';
1;

__DATA__

=head1 NAME

Kwiki::Theme::TabNav - A simple kwiki theme that looks beest using Kwiki::Toolbar::List

=head1 SYNOPSIS

     $ cpan Kwiki::Theme::TabNav
     $ cd /path/to/kwiki
     $ kwiki -remove Kwiki::Theme::MyCurrentTheme
     $ kwiki -add Kwiki::Theme::TabNav

=head1 DESCRIPTION

A simple, minimalistic theme that provides a different look and feel to a kwiki site.

This theme can be used with Kwiki::Toolbar, but looks better when used with
Kwiki::Toolbar::List.

Note that when using Kwiki::Icons::Gnome, the tabs will be offset slightly in IE - in firefox
it looks fine.  Also, it looks like Kwiki::Revisions places uses the pipe delimiter somewhere
in that code.

=head1 AUTHOR

Dave Mabe <dmabe@runningland.com>

=head1 COPYRIGHT

Copyright (c) 2004. Dave Mabe. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__theme/tabnav/template/tt2/kwiki_screen.html__
[%- INCLUDE kwiki_doctype.html %]
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <title>
[% IF hub.action == 'display' || hub.action == 'edit' || hub.action ==
'revisions' %]
  [% hub.cgi.page_id %] -
[% END %]
[% IF hub.action != 'display' %]
  [% self.class_title %] - 
[% END %]
  [% site_title %]</title>
[% FOR css_file = hub.css.files -%]
  [% IF css_file == 'theme/tabnav/css/kwiki.css' AND hub.have_plugin('icons') %][% css_file = 'theme/tabnav/css/kwiki.with.icons.css' %][% END -%]
  <link rel="stylesheet" type="text/css" href="[% css_file %]" />
[% END -%]
[% FOR javascript_file = hub.javascript.files -%]
  <script type="text/javascript" src="[% javascript_file %]"></script>
[% END -%]
  <link rel="shortcut icon" href="" />
  <link rel="start" href="index.cgi" title="Home" />
</head>
<body>
<div id="entire">
<div id="title_pane">
<img src="[% logo_image %]" align="center" alt="Kwiki Logo" title="[% site_title %]" />
<span>
<h1>
[% screen_title || self.class_title %]
</h1>
</span>
</div>

[% hub.toolbar.html %]

[% IF hub.have_plugin('user_name') %]
[% INCLUDE user_name_title.html %]
[% END %]

<div id="status_pane">
[% hub.status.html %]
</div>

<div id="content_pane">
[% INCLUDE $content_pane %]
</div>

<div id="widgets_pane">
[% hub.widgets.html %]
</div>

[% INCLUDE kwiki_end.html %]
<!-- END kwiki_screen.html -->
__theme/tabnav/css/.htaccss__
Allow from all
__theme/tabnav/css/kwiki.css__
body {
background: #ccc;
font-family: verdana;
font-size: .9em;
}

body * {
position: relative;
}

h1, h2, h3, h4, h5, h6 {
margin: 0;
padding: 0;
font-weight: bold;
color: #000;
}

a:hover {
text-decoration: none;
}

.error, .empty {
color: #f00;
}

#title_pane {
margin: 5px;
border: none;
}

#title_pane h1 a {
color: #000;
position: relative;
}

#title_pane img,#title_pane h1 {
display: inline;
}

.toolbar {
margin-top: -25px;
clear: left;
padding-left: 100px;
border-bottom: 1px #000 solid;
}

.toolbar a {
text-decoration: none;
}

.toolbar form {
float: left;
margin: 0;
}

.toolbar input {
font-size: 8pt;
float: left;
margin: 0;
}

#nav {
padding: 6px 0;
margin: 0;
clear: left;
}

#nav li {
list-style-type: none;
display: inline;
margin: 0;
}

#nav li a {
padding: 5px 5px 6px 5px;
text-decoration: none;
background-color: #fff;
border: #000 1px solid;
font-family: arial;
font-size: 0.8em;
margin-left: 5px;
border-bottom: none;
}

#nav li a:hover {
background-color: #ccc;
}

#entire {
border: 1px #000 solid;
background-color: #fff;
margin: 25px;
}

#content_pane {
margin: 20px;
}
__theme/tabnav/css/kwiki.with.icons.css__
body {
background:#ccc;
font-family: verdana;
font-size: .9em;
}

body * {
position: relative;
}

h1, h2, h3, h4, h5, h6 {
margin: 0px;
padding: 0px;
font-weight: bold;
}

a:hover {
text-decoration: none;
}

.error, .empty {
color: #f00;
}

#title_pane {
margin: 5px;
border: none;
}

#title_pane h1,#title_pane h1 a {
color: #000;
position: relative;
}

#title_pane img,#title_pane h1 {
display: inline;
}

.toolbar {
margin-top: -25px;
padding-left: 100px;
clear: left;
border-bottom: 1px #000 solid;
}

.toolbar a {
text-decoration: none;
}

.toolbar form {
float: left;
margin: 0;
}

.toolbar input {
font-size: 8pt;
float: left;
margin: 0;
}

#nav {
padding: 6px 0;
margin: 0;
clear: left;
}

#nav li {
list-style-type: none;
display: inline;
margin: 0;
}

#nav li a {
padding: 5px 5px 8px 5px;
text-decoration: none;
background-color: #fff;
border: #000 1px solid;
font-family: arial;
font-size: 0.8em;
margin-left: 5px;
border-bottom: none;
}

#nav li a:hover {
background-color: #ccc;
}

#entire {
border: 1px #000 solid;
background-color: #fff;
margin: 25px;
}

#content_pane {
margin: 20px;
}
