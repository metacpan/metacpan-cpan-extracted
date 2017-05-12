package Kwiki::Theme::ColumnLayout;
use Kwiki::Theme -Base;
use mixin 'Kwiki::Installer';
our $VERSION='0.08';
const theme_id => 'columnlayout';
const class_title => 'Column Layout Theme';

__DATA__

=head1 NAME

Kwiki::Theme::ColumnLayout - Kwiki Theme with two / three column layout.

=head1 INSTALLATION

    # kwiki -install Kwiki::Theme::ColumnLayout

=head1 DESCRIPTION

This module provide a simple column layout for your kwiki site.  It is
also suggested to install L<Kwiki::Infobox> and
L<Kwiki::NavigationToolbar>, this theme make use of this two plugin to
make kwiki kwiki site more controllable via web interface.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

Copyright (c) 2004. Kang-min Liu. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__theme/columnlayout/css/kwiki.css__
a img { border: none; }
a:link {color:#a00;}
a:visited {color:#815151;}
a:active {color:red;}
a:hover {color:red;text-decoration:underline;}

body {
       margin:0px;
       padding:0px;
       background:#ddd;
       margin-bottom:50px;
       color:#333;
       font-size:12px;
       font-family: /*"Lucida Grande", "Lucida Sans Unicode", "Gill Sans",*/ "Trebuchet MS", verdana, sans-serif;
       }


.container {
             margin-top: 32px;
	     width: 90%;
	     min-width: 600px;
             margin-right:auto;
             margin-left:auto;
             background:white;
             border-top: 1px solid black;
             border-left:1px solid black;
             border-right:1px solid black;
             border-bottom:1px solid black;
             }

#leftcontent {
               float:left;
               width:170px;
               margin-top:20px;
               }

#rightcontent {
               float:right;
               width:170px;
               margin-top:20px;
}

#centercontent {
                 padding:10px;
                 margin-left: 180px; 
                 margin-top:10px;
                 }

p, .home, h1, h2, h3, h4 {
                           margin:0px 14px 14px 14px;
                           line-height:150%;
                           }

h1 {
     font-size:18px;
     }

h2 {
     font-size:16px;
     color:#5e715e;
     }

h3 {
     font-size:14px;
     }


h1 a {
       font-weight:normal;
       text-decoration:none;
       }

.header {
          border-bottom:1px dotted #ccc;
          padding-bottom: 3px;
          padding-left: 3px;
          padding-right: 3px;
          }

.indent, .dent 	{
                  margin-left:20px;
                  margin-right:20px;
                  }
.err { color: red; }

label {
        cursor: pointer;
        cursor: hand;
        }
li {
     margin-top:10px;
     margin-bottom:10px;
     }

.pullout {
           float:right; 
           display:block;
           width:35%;
           border:1px dotted #ccc; 
           margin:10px; 
           padding:6px;
           }

pre {
      font-size: small; 
      margin-left: 30px;
      }

strong.imp {
             color: red;
             }

.breadcrumb {
              margin-bottom:0px;
              }

.crumbtrail	{
                  font-size:11px;
                  margin-bottom:30px;
                  }

.currentstep {
               border:1px solid #ccc;	
               text-align:center;
               }

dt { margin-left: 14px; font-weight: bold;}


#logo {
        width: 100%;
        height: 100%;
        vertical-align: center;
        }

#logo img {
            vertical-align: center;
            }

#leftcontent ul {
                  margin: 0px 14px 0px 14px;
                  padding-left: 0;
                  list-style: none;
                  }

#leftcontent li {
                  margin-top:0px;
                  }

#leftcontent li a {
                    width: 100%;
                    color:#5E715E;
                    }

#leftcontent li a:hover {
                          color:red;
                          text-decoration:underline;
                          }

#leftcontent h4 {
                  display: none;
                  }

th {
     font-family:Arial, sans-serif;
     font-weight:bold;
     font-size:14px;
     padding:4px;
     }

#centercontent textarea {
                          width: 100%;
                          }

h1, h2, h3, h4, h5, h6
{
  margin: 0px;
  padding: 0px;
  font-weight: bold;
  }


#centercontent {
                 margin-left: 180px; 
                 margin-right:180px;
                 margin-top:8px;
                 padding-left:10px;
                 padding-right:10px;	
                 border-right:1px dotted #ccc;
                 border-left:1px dotted #ccc;
                 }

#pullout {
           float:right;
           position:relative;
           margin-top:17px;
           padding-left:10px;
           width:180px;
           width: 190px; 
           }

h2 {margin-bottom:4px;}

td {vertical-align: top;}

div.navigation
{
    margin-top: -48px;
    margin-left: 180px;
}

div.navigation_toolbar
{
  padding-top: 6px;
}


__theme/columnlayout/template/tt2/kwiki_screen.html__
[%- INCLUDE kwiki_doctype.html %]
[% INCLUDE kwiki_begin.html %]
<div class="container">
    <div class="header">
        <div id="logo"><img src="[% logo_image %]" /></div>
	<div class="navigation">
           <div id="title_pane">
             <h1>[% screen_title || self.class_title %]</h1>
           </div>
    [%
       IF hub.have_plugin('toolbar');
          hub.toolbar.html;
       END;
       IF hub.have_plugin('navigation_toolbar');
          hub.navigation_toolbar.html;
       END;
     %]
	</div>
    </div>

[% IF hub.have_plugin('config_blocks') && hub.config_blocks.pageconf.no_left_column %]
<style type="text/css">
#centercontent {
   width: auto;
   padding:10px;
   border-left: none;
}
</style>
[% ELSE %]
<div id="leftcontent">
[% hub.widgets.html %]
[% IF hub.have_plugin('infobox'); hub.infobox.html; END; %]
</div>
[% END %]

[% IF hub.have_plugin('config_blocks') && hub.config_blocks.pageconf.show_right_column %]
<div id="rightcontent">
[% IF hub.have_plugin('infobox'); hub.infobox.right; END; %]
</div>
[% ELSE %]
<style type="text/css">
#centercontent {
    width: auto;
    margin-right:10px;
    border-right: none;
}
</style>
[% END %]

<div id="centercontent">
[% INCLUDE $content_pane %]
</div>

<br clear="all" />
<div class="footer">
</div>

</div>

[% INCLUDE kwiki_end.html %]
