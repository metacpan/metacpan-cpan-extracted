package Kwiki::Theme::CPB;
use Kwiki::Theme -Base;

const theme_id => 'cpb';
const class_title => 'CPB Theme';

our $VERSION = '0.10';

__DATA__

=head1 NAME

Kwiki::Theme::CPB - Kwiki Theme of some sort

=head1 SYNOPSIS

  kwiki -install Kwiki::Theme::CPB

=head1 DESCRIPTION

A hopefully simple and clean three column Kwiki theme for use with
Kwiki::Blog. Once it is installed you can put things in the left hand
column by changing the template_path and adding a local path:

  template_path:
  - local
  - template/tt2

In local create theme_sidebar1.html. Fill it with whatever HTML you want
to show up. I used it for images and such.

=head1 AUTHOR

Chris Dent

=head1 COPYRIGHT

Copyright (c) 2004. Chris Dent. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__theme/cpb/template/tt2/theme_screen.html__

[%- INCLUDE theme_html_doctype.html %]
[% INCLUDE theme_html_begin.html %]

<div id="header">
    [% INCLUDE theme_header_pane.html %]
</div>

<div id="notheader">
<div class="sidebar" id="sidebar1">
    [% INCLUDE theme_sidebar1.html %]
</div>

<div id="main_body">
<div class="navigation">
[% INCLUDE theme_toolbar_pane.html %]
[% INCLUDE theme_status_pane.html %]
</div>

<div id="page_content">
[% INCLUDE theme_content_pane.html %]
</div>

<div class="navigation">
[% INCLUDE theme_toolbar2_pane.html %]
</div>
</div>


<div class="sidebar" id="sidebar2">
<div class="navigation">
[% INCLUDE theme_login_pane.html %]
[% INCLUDE theme_logo_pane.html %]
[% INCLUDE theme_widgets_pane.html %]
</div>
</div>

</div>

[% INCLUDE theme_html_end.html -%]

__theme/cpb/template/tt2/theme_header_pane.html__
[% INCLUDE theme_title_pane.html %]
__theme/cpb/template/tt2/theme_toolbar_pane.html__
<!-- BEGIN theme_toolbar_pane -->
<div id="toolbar_pane">
[% hub.toolbar.html %]
</div>
<!-- END theme_toolbar_pane -->
__theme/cpb/template/tt2/theme_sidebar1.html__
<div id="badges">
</div>
__theme/cpb/css/kwiki.css__
#logo_pane {
    text-align: center;
}
    
#logo_pane img {
}
    
body {
    background:#fff;        
    font-family: sans-serif;
    position: relative;
    min-width: 600px;
    width: 100%;
    margin: 0;
    padding: 0; 
}

h1, h2, h3, h4, h5, h6 {
    margin: 0px;
    padding: 0px;
    font-weight: bold;
}

.error, .empty {
    color: #f00;
}

.navigation {
    font-size: smaller;
    padding-bottom: .5em;
}

#title_pane {
    padding-left: 1em;
}

div.navigation a:visited {
    color: #00f;
}

#header {
    min-width: 600px;
    width: 100%;
}

#sidebar1 {
    position: absolute;
    left: 0;
    width: 19%;
    margin: 1% 1% 0 0;
    padding: .5em;
}

#main_body {
    position: absolute;
    left: 20%;
    min-width: 360px;
    width: 60%;
    margin-top: 1%;

}

#sidebar2 {
    position: absolute;
    left: 80%;
    width: 19%;
    margin: 1% 0 0 1%;
    padding: .5em;
}

#page_content {
    border: thin solid black;
    margin: 0em;
    padding: .5em;
}

.badge {
    text-align: center;
    list-style: none;
}

.badges img {
    border: none;
}

