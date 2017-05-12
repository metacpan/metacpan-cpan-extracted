package Kwiki::Theme::HLB;
use strict;
use warnings;
use Kwiki::Theme '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const theme_id => 'hlb';
const class_title => 'HLB Theme';

1;
__DATA__

=head1 NAME 

Kwiki::Theme::HLB - Kwiki HLB Theme

=head1 VERSION

This document describes version 0.01 of Kwiki::Theme::HLB, released
October 12, 2004.

=head1 SYNOPSIS

    % cd /path/to/kwiki
    % kwiki -add Kwiki::Theme::HLB

=head1 DESCRIPTION

This is a port of CGI::Kwiki's F<hlb.css> into Kwiki theme format.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
__theme/hlb/template/tt2/kwiki_screen.html__
[%- INCLUDE kwiki_doctype.html %]
<!-- BEGIN kwiki_screen.html -->
[% INCLUDE kwiki_begin.html %]

<div id="group_1">
<img src="[% logo_image %]" title="[% site_title %]" alt="">
<h1>[% site_title %]</h1>
<span class="description">[% site_description %]</span>
<span style="display: none"><a href="#skip-upper-nav">&gt;&gt;</a></span>
<div id="widgets_pane">
[% hub.widgets.html %]
</div>
</div>

<div id="group_2">
<div class="navigation">
<div id="title_pane">
<h1>
[% screen_title || self.class_title %]
</h1>
</div>

<div id="toolbar_pane">
[% hub.toolbar.html %]
[% IF hub.have_plugin('user_name') %]
[% INCLUDE user_name_title.html %]
[% END %]
</div>

<div id="status_pane">
[% hub.status.html %]
</div>
</div><!-- navigation -->

<hr />
<div id="content_pane">
[% INCLUDE $content_pane %]
</div>
<hr />

<div class="navigation">
<div id="toolbar_pane_2">
[% hub.toolbar.html %]
</div>
</div><!-- navigation -->
</div><!-- group2 -->
[% INCLUDE kwiki_end.html %]
<!-- END kwiki_screen.html -->
__theme/hlb/css/kwiki.css__
#logo_pane {
    text-align: center;
}
    
#logo_pane img {
    width: 90px;
}
    
#group_1 {
    display: inline;
}

#group_1 img {
    text-align: right;
    float: right;
}

#group_2 {
    margin: 0px;
    border-top: 2px solid #666;
    border-left: 1px solid #666; 
    border-right: 1px solid #666;
    background: #fffff7;
}

#links {
    background:#FFF;
    color:#CCC;
    margin-right:25%;
}

#content_pane p { 
    margin: 15px; 
}

#toolbar_pane, #toolbar_pane2 {
    border-top: 1px solid #ccc;
    border-bottom: 1px solid #ddd;
    padding-left: 10px; 
    background: #eee;
}
    
div#links div.side span a { display: inline }
div#links div.side span:after { content: " | " }
    
body {
    color: #070707;
    background-color: #ccc;
    margin: 10px; padding: 0;
    font-family: "Palatino Linotype", Georgia, "Times New Roman", Times, serif;
}

h1, h2, h3, h4, h5, h6 {
    color: #333;
    margin: 0 10% 0 0;
    padding: 0 10px;
    border-bottom: 1px solid #666;
    text-decoration: none;
}

form.edit input { position: absolute; left: 3% }
textarea { width: auto }
pre {
    background-color: #fff;
    color: black;
    border: none;
}

/* ------------------------------------------------------------------- */

a:link { text-decoration: none; color: #930; }
a:visited { text-decoration: none; color: #600;}
a:hover { text-decoration: underline; color: #c00;}
a:active { text-decoration: none; color: #c00;}
a.empty {color: #333}
a.empty:before {
    vertical-align: top;
    font-size: xx-small;
    content: '?'
    font-style: italic;
}
a.empty:after {
    vertical-align: top;
    font-size: xx-small;
    content: '?'
    font-style: italic;
}
a.private {color: black}
.error    {color: #f00;}

div.side a { display: list-item; list-style-type: none }
div.upper-nav { }
textarea { width: 90% }

.powered {
    border: 1px solid #666;
    padding: 5px;
    background: #eee;
    font-size: xx-small;
}

__theme/hlb/css/.htaccess__
Allow from all
