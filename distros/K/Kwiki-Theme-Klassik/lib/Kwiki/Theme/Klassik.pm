package Kwiki::Theme::Klassik;
use Kwiki::Theme -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.12';

const theme_id => 'klassik';
const class_title => 'Klassik Theme';

__DATA__

=head1 NAME 

Kwiki::Theme::Klassik - Kwiki Klassik Theme

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__theme/klassik/template/tt2/kwiki_screen.html__

[%- INCLUDE kwiki_doctype.html %]
[% INCLUDE kwiki_begin.html %]
<div id="group_1">
<div class="navigation">

<div id="logo_pane">
<img src="[% logo_image %]" align="center" alt="Kwiki Logo" title="[% site_title %]" />
</div>
<br/>

<div id="widgets_pane">
[% hub.widgets.html %]
</div>
</div><!-- navigation -->
</div><!-- group1 -->

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
[% INCLUDE kwiki_end.html -%]

__theme/klassik/css/kwiki.css__
#logo_pane {
    text-align: center;
}
    
#logo_pane img {
    width: 90px;
}
    
#group_1 {
    width: 125px;
    float: left;
}
    
#group_2 {
    float: left;
    width: 510px;
    background: #FFF;
    margin-bottom: 20px;
}

#links {
    background:#FFF;
    color:#CCC;
    margin-right:25%;
}
    
div#links div.side span a { display: inline }
div#links div.side span:after { content: " | " }
    
body {
    background:#fff;        
}

h1, h2, h3, h4, h5, h6 {
    margin: 0px;
    padding: 0px;
    font-weight: bold;
}

form.edit input { position: absolute; left: 3% }
textarea { width: auto }

/* ------------------------------------------------------------------- */

a         {text-decoration: none}
a:link    {color: #d64}
a:visited {color: #864}
a:hover   {text-decoration: underline}
a:active  {text-decoration: underline}
a.empty   {color: gray}
a.private {color: black}

.error    {color: #f00;}

div.side a { display: list-item; list-style-type: none }
div.upper-nav { }
textarea { width: 100% }
div.navigation a:visited {
    color: #d64;
}
__theme/klassik/css/.htaccess__
Allow from all
