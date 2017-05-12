package Kwiki::Theme::JustContent;
use Kwiki::Theme -Base;
our $VERSION = '0.10';

const theme_id => 'just_content';
const class_title => 'JustContent Theme';

sub register {
    my $register = shift;
    $register->add(preload => 'theme', priority => 1);
}

__DATA__

=head1 NAME 

Kwiki::Theme::JustContent - Kwiki JustContent Theme

=head1 DESCRIPTION

This theme makes your kwiki site looks not even like a wiki. It
pulls on toolbar, widgets, status, even logo.  Leaves only the
content pane.

The use of this theme would be in conjunction with a fully function
theme in the sub-view. For example.  One could configure the main
view of a kwiki to have these plugins:

   Kwiki::Theme::JustContent
   Kwiki::Display

While in the "admin" subview, add these plugins:

   +Kwiki::Edit
   +Kwiki::Revisions
   +Kwiki::Archive::Rcs
   -Kwiki::Theme::JustContent
   +Kwiki::Toolbar
   +Kwiki::Status
   +Kwiki::Widgets
   +Kwiki::Theme::Basic

For such configuration, one could have a front-end that looks like
normal web page, while the content of those pages are managed inside
admin/ subview.  It provides a very primitive start for people who
want to play Kwiki as a minimalist content-management system.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

Copyright (c) 2005. Kang-min Liu.. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__theme/just_content/template/tt2/kwiki_screen.html__

[%- INCLUDE kwiki_doctype.html %]
[% INCLUDE kwiki_begin.html %]
<div id="content_pane">
[% INCLUDE $content_pane %]
</div>
[% INCLUDE kwiki_end.html -%]

__theme/just_content/css/kwiki.css__
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
