#==============================================================================
# MyTheme -- a sample class to demonstrate how to (ISA) make a sub-class of
#            LibWeb::Themes::Default

package MyTheme;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: MyTheme.pm,v 1.3 2000/07/18 06:33:30 ckyc Exp $

$VERSION = '0.02';

#-#############################
# Use standard libraries.
use strict;
use vars qw($VERSION @ISA);
use Carp;

#-#############################
# Use custom libraries.
require LibWeb::Themes::Default;

#-#############################
# Inheritance.
@ISA = qw(LibWeb::Themes::Default);

#-#############################
# Methods.
sub new {
    #
    # Params: $class [, $rc_file]
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $object = new LibWeb::HTML::Themes([$rc_file]);
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;
    
    # Inherit instance variables from the base class.
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);
}

sub DESTROY {}

sub _parse_content {
    my ($ref, @content_display);
    my $content = $_[0];
    
    eval {
	foreach (@$content) {
	    $ref = ref($_);
	    if ( $ref eq 'SCALAR' ) { push(@content_display, $$_); }
	    elsif ( $ref eq 'ARRAY' ) { push(@content_display, @$_); }
	    else { push(@content_display, $_); }
	}
    };
    croak "$@" if ($@);
    return \@content_display;
}

sub table {
    #
    # Params: -content=>, [ -bg_color=>, -align=>, -valign=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    #  scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -bg_color default is SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a  formatted table in HTML format.
    #
    my ($self, $content, $bg_color, $align, $valign, $width,
	$content_display);
    $self = shift;
    ($content, $bg_color, $align, $valign, $width)
      = $self->rearrange( ['CONTENT', 'BG_COLOR', 'ALIGN', 'VALIGN', 'WIDTH'], @_ );
    
    $content ||= [' '];
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $width ||= '100%';
    
    $content_display = _parse_content($content);
    
#<!-- start HTML for table -->
    return \<<HTML;
<table border=0 cellpadding=0 cellspacing=0 width="$width" bgcolor="$bg_color">
<Tr><td align="$align" valign="$valign">
@$content_display
</td></Tr>
</table>

HTML
#<!-- end HTML for the table -->
}

sub titled_table {
    #
    # Params: -title=>, -content=>, [ -title_space=>, -title_align=>,
    #                               -title_bg_color=>, -title_txt_color=>,
    #                               -bg_color=>, align=>, valign=>,
    #                               -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    # scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -title_space is the space (&nbsp;) prepended before (if -title_align is `left')
    #  or append after (if -title_align is `right') the title.  It's always 0 if
    #  -title_align is `center'.  Default is 2, i.e. `&nbsp;&nbsp;'.
    # -title_align default is center.
    # -title_bg_color default is SITE_1ST_COLOR.
    # -title_txt_color default is SITE_BG_COLOR.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 1.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a  formatted table in HTML format.
    #
    my ($self,
	$title, $content, $title_space, $title_align, $title_bg_color,
	$title_txt_color, $bg_color, $align, $valign, $cellpadding, $width,
	$title_spacer, $content_display);
    $self = shift;
    ($title, $content, $title_space, $title_align, $title_bg_color,
     $title_txt_color, $bg_color, $align, $valign, $cellpadding, $width)
      = $self->rearrange( ['TITLE', 'CONTENT', 'TITLE_SPACE', 'TITLE_ALIGN',
			   'TITLE_BG_COLOR', 'TITLE_TXT_COLOR', 'BG_COLOR',
			   'ALIGN', 'VALIGN', 'CELLPADDING', 'WIDTH'],
			  @_ );
    
    $title ||= " ";
    $content ||= [' '];
    $title_align ||= 'center';
    unless  ( defined($title_space) ) {
	$title_space = ( uc($title_align) eq 'CENTER' ) ? 0 : 2;
    }
    $title_spacer = '&nbsp;' x $title_space;
    if ( uc($title_align) eq 'RIGHT' ) { $title = '<b>'.$title.'</b>'.$title_spacer; }
    else { $title = $title_spacer.'<b>'.$title.'</b>'; }
    $title_bg_color ||= $self->{SITE_1ST_COLOR};
    $title_txt_color ||= $self->{SITE_BG_COLOR};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 1;
    $width ||= '100%';
    
    $content_display = _parse_content($content);
    
#<!-- start HTML for titled_table -->
    return \<<HTML;
<table border=0 cellpadding=0 cellspacing=0 width="$width" bgcolor="$bg_color">

<Tr><td>
<table border=0 cellpadding=0 cellspacing=0 width="100%" bgcolor="$title_bg_color">
<Tr><td align="$title_align" bgcolor="$title_bg_color">
<font color="$title_txt_color">$title</font>
</td></Tr></table>
</td></Tr>

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign">
@$content_display
</td></Tr></table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the titled_table -->
}

sub titled_table_enlighted {
    shift->enlighted_titled_table(@_);
}

sub enlighted_titled_table {
    #
    # Params: -title=>, -content=>, [ -title_space=>, -title_align=>,
    #                               -title_bg_color=>,
    #                               -title_txt_color=>, -title_border_color=>,
    #                               -bg_color=>, -align=>, -valign=>,
    #                               -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    # scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -title_space is the space (&nbsp;) prepended before (if -title_align is `left')
    #  or append after (if -title_align is `right') the title; default is 2,
    #  i.e. `&nbsp;&nbsp;'.  It's always 0 if -title_align if `center'.
    # -title_align default is center.
    # -title_bg_color default is SITE_LIQUID_COLOR3.
    # -title_txt_color default is SITE_LIQUID_COLOR5.
    # -title_border_color default is SITE_LIQUID_COLOR5.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 1.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a  formatted table in HTML format.
    #
    my ($self,
	$title, $content, $title_space, $title_align, $title_bg_color,
	$title_txt_color, $title_border_color, $bg_color, $align, $valign,
	$cellpadding, $width,
	$title_spacer, $content_display);
    $self = shift;
    ($title, $content, $title_space, $title_align, $title_bg_color,
     $title_txt_color, $title_border_color, $bg_color, $align, $valign,
     $cellpadding, $width)
      = $self->rearrange( ['TITLE', 'CONTENT', 'TITLE_SPACE', 'TITLE_ALIGN',
			   'TITLE_BG_COLOR', 'TITLE_TXT_COLOR', 'TITLE_BORDER_COLOR',
			   'BG_COLOR', 'ALIGN', 'VALIGN', 'CELLPADDING', 'WIDTH'],
			  @_ );
    
    $title ||= " ";
    $content ||= [' '];
    $title_align ||= 'center';
    unless  ( defined($title_space) ) {
	$title_space = ( uc($title_align) eq 'CENTER' ) ? 0 : 2;
    }
    $title_spacer = '&nbsp;' x $title_space;
    if ( uc($title_align) eq 'RIGHT' ) { $title = "<b>${title}</b>${title_spacer}"; }
    else { $title = "${title_spacer}<b>${title}</b>"; }
    $title_bg_color ||= $self->{SITE_LIQUID_COLOR3};
    $title_txt_color ||= $self->{SITE_LIQUID_COLOR5};
    $title_border_color ||= $self->{SITE_LIQUID_COLOR5};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 1;
    $width ||= '100%';
    
    $content_display = _parse_content($content);
    
#<!-- start HTML for titled_table_enlighted -->
    return \<<HTML;
<table border=0 cellpadding=0 cellspacing=0 width="$width" bgcolor="$bg_color">

<Tr><td>
<table border=0 cellpadding=1 cellspacing=0 width="100%" bgcolor="$title_border_color">
<Tr><td>
<table border=0 cellpadding=0 cellspacing=0 width="100%" bgcolor="$title_bg_color">
<Tr><td bgcolor="$title_bg_color" align="$title_align">
<font color="$title_txt_color">$title</font>
</td></Tr>
</table>
</td></Tr>
</table>
</td></Tr>

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign">
@$content_display
</td></Tr>
</table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the titled_table_enlighted -->
}

sub bordered_table {
    #
    # Params: -content=>, [ -border_color=>, -bg_color=>, align=>, -valign=>,
    #                     -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    #  scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -border_color default is SITE_LIQUID_COLOR2.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 2.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a formatted table in HTML format.
    #
    my ($self,
	$content, $border_color, $bg_color, $align, $valign, $cellpadding, $width,
	$content_display);
    $self = shift;
    ($content, $border_color, $bg_color, $align, $valign, $cellpadding, $width)
      = $self->rearrange( ['CONTENT', 'BORDER_COLOR', 'BG_COLOR', 'ALIGN', 'VALIGN',
			   'CELLPADDING', 'WIDTH'], @_ );
    
    $content ||= [' '];
    $border_color ||= $self->{SITE_LIQUID_COLOR2};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 2;
    $width ||= '100%';
    
    $content_display = _parse_content($content);
    
#<!-- start HTML for bordered_table -->
    return \<<HTML;
<table border=0 cellpadding=1 cellspacing=0 bgcolor="$border_color" width="$width">

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign" bgcolor="$bg_color">
@$content_display
</td></Tr></table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the bordered_table -->
}

sub titled_bordered_table {
    shift->bordered_titled_table(@_);
}

sub bordered_titled_table {
    #
    # Params: -title=>, -content=>, [ -title_space=>, -title_align=>,
    #                               -border_color=>,
    #                               -title_txt_color=>,
    #                               -bg_color=>, -align=>, -valign=>,
    #                               -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    #  scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -title_space is the space (&nbsp;) prepended before (if -title_align is `left')
    #  or append after (if -title_align is `right') the title; default is 2, i.e.
    #  `&nbsp;&nbsp;'.  If -title_align is `center', -title_space is always 0.
    # -title_align default is center.
    # -border_color default is SITE_1ST_COLOR.
    # -title_txt_color default is SITE_BG_COLOR.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 1.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a formatted table in HTML format.
    #
    my ($self,
	$title, $content, $title_space, $title_align, $border_color,
	$title_txt_color, $bg_color, $align, $valign, $cellpadding, $width,
	$title_spacer, $content_display);
    $self = shift;
    ($title, $content, $title_space, $title_align, $border_color,
     $title_txt_color, $bg_color, $align, $valign, $cellpadding, $width)
      = $self->rearrange( ['TITLE', 'CONTENT', 'TITLE_SPACE', 'TITLE_ALIGN',
			   'BORDER_COLOR', 'TITLE_TXT_COLOR',
			   'BG_COLOR', 'ALIGN', 'VALIGN', 'CELLPADDING', 'WIDTH'],
			  @_ );
    
    $title ||= " ";
    $content ||= [' '];
    $title_align ||= 'center';
    unless  ( defined($title_space) ) {
	$title_space = ( uc($title_align) eq 'CENTER' ) ? 0 : 2;
    }
    $title_spacer = '&nbsp;' x $title_space;
    if ( uc($title_align) eq 'RIGHT' ) { $title = '<b>'.$title.'</b>'.$title_spacer; }
    else { $title = $title_spacer.'<b>'.$title.'</b>'; }
    $border_color ||= $self->{SITE_1ST_COLOR};
    $title_txt_color ||= $self->{SITE_BG_COLOR};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 1;
    $width ||= '100%';
    
    $content_display = _parse_content($content);
    
#<!-- start HTML for titled_bordered_table -->
    return \<<HTML;
<table border=0 cellpadding=1 cellspacing=0 bgcolor="$border_color" width="$width">

<Tr><td>
<table width="100%" border=0 cellspacing=0 cellpadding=0 bgcolor="$border_color">
<Tr><td align="$title_align" bgcolor="$border_color">
<font color="$title_txt_color">$title</font>
</td></Tr></table>
</td></Tr>

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign" bgcolor="$bg_color">
@$content_display
</td></Tr></table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the titled_bordered_table -->
}

sub tabber {
    #
    # Params:
    #
    # -tabs=>, -active=> [, -active_color=>, -fade_color=>,
    #                       -tab_padding=>, -tab_width=>,
    #                       -gap_width=>, -total_width=>,
    #                       -base=>, -base_height=>, -left_stub=>,
    #                       -right_stub=>, -left_stub_align=>,
    #                       -right_stub_align=>, -left_stub_width=>,
    #                       -right_stub_width=> ]
    #
    # Pre:
    # - -tabs is an ARRAY reference to scalar/SCALAR reference
    # - -active is a number indicating which tab is currently active (count from 0)
    # - -active_color is the color for the active tab; default is SITE_1ST_COLOR
    # - -fade_color is the color for non-active tabs; default is SITE_LIQUID_COLOR3
    # - -tab_padding is the distance between a tab's content to its border, either
    #   in pixel or percentage; default is 0
    # - -tab_width is the width of each tab, either in pixel or percentage; default
    #   is ( total_width / (2 * number of tabs) )
    # - -gap_width is the distance between two adjacent tabs, either in pixel or
    #   percentage; default if 1%
    # - -total_width is the width of the whole tabber, either in pixel or percentage;
    #   default is 100%
    # - -base is a SCALAR reference to HTML to be put under the tabs
    # - -base_height is the height of -base, either in pixel or percentage; default
    #   is 5.  You do not want to specify this if you specify -base
    # - base_align default is `left'
    # - -left_stub is a SCALAR reference to HTML to be put to the left of the tabs
    # - -right_stub is a SCALAR reference to HTML to be put to the right of the tabs
    # - -left_stub_align is 'left', 'center' or 'right'; default is 'left'
    # - -right_stub_align is 'left', 'center' or 'right'; default is 'right'
    # - -left_stub_width is either in pixel or percentage, you may want to specify
    #   this if you specify -left_stub
    # - -right_stub_width is either in pixel or percentage
    #
    # Post:
    #
    # Return a SCALAR ref. to a formatted tabbing navigation bar in HTML format.
    #
    my (
	$self,
	$tabs, $active, $active_color, $fade_color, $tab_padding, $tab_width,
	$gap_width, $total_width, $base, $base_height, $base_align, $left_stub,
	$right_stub, $left_stub_align, $right_stub_align, $left_stub_width,
	$right_stub_width,
	$num_tabs, $num_elements, $tabs_html, $count
       );
    $self = shift;
    (
     $tabs, $active, $active_color, $fade_color, $tab_padding, $tab_width,
     $gap_width, $total_width, $base, $base_height, $base_align, $left_stub,
     $right_stub, $left_stub_align, $right_stub_align, $left_stub_width,
     $right_stub_width
    ) = $self->rearrange(
			 [
			  'TABS','ACTIVE','ACTIVE_COLOR','FADE_COLOR','TAB_PADDING',
			  'TAB_WIDTH','GAP_WIDTH','TOTAL_WIDTH','BASE','BASE_HEIGHT',
			  'BASE_ALIGN','LEFT_STUB','RIGHT_STUB','LEFT_STUB_ALIGN',
			  'RIGHT_STUB_ALIGN','LEFT_STUB_WIDTH','RIGHT_STUB_WIDTH'
			 ], @_
			);

    $active ||= 0;
    $active_color ||= $self->{SITE_1ST_COLOR};
    $fade_color ||= $self->{SITE_LIQUID_COLOR3};
    $tab_padding ||= '0';
    $gap_width = '1%' unless ( defined $gap_width );
    $total_width ||= '100%';
    $base_height ||= '5';
    $base_align ||= 'left';
    $base ||= \ ("<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><Tr><td height=\"$base_height\"></td></Tr></table>");
    $tabs_html = '';
    
    # Determine how many columns the base should span.
    eval { $num_tabs = scalar @{$tabs}; };
    croak "$@" if ($@);    
    $num_elements = 2 * $num_tabs + ( ($left_stub || $left_stub_width) ? 1 : 0 ) + 1;

    # Determine the width for individual tab.
    if ( $total_width =~ m:(.*)\%$: ) {
	$tab_width ||= int ( $1 / (2*$num_tabs) ) . '%';
    } else {
	$tab_width ||= int ( $total_width / (2*$num_tabs) );
    }
    
    eval {

	# Prepend the left stub.
	if ($left_stub || $left_stub_width) {
	    $left_stub ||= \('');
	    $left_stub_align ||= 'left';
	    $left_stub_width ||=  ( $tab_width =~ m:(.*)\%$: ) ?
	                          int( (100 - $1 * $num_tabs)/2 ).'%' :
				  int( $total_width - $num_tabs * $tab_width);
	    $tabs_html .=
	      "<td width=\"$left_stub_width\" align=\"$left_stub_align\">&nbsp;$${left_stub}&nbsp;</td>\n";
	}
	
	# Create the tabs.
	$count = 0;
	foreach ( @{$tabs} ) {	    
	    my $the_tab;
	    my $color = ($count == $active) ? $active_color : $fade_color;
	    if ( ref $_ ) {
		$the_tab = $$_;
	    } else {
		$the_tab = $_;
	    }
	    
	    $tabs_html .=
	      "<td align=\"center\" bgcolor=\"$color\" width=\"$tab_width\"><table bgcolor=\"$color\" border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"$tab_padding\"><Tr align=\"center\"><td>".
		"&nbsp;${the_tab}&nbsp;</td></Tr></table></td>";
	    $tabs_html .= "<td width=\"$gap_width\">&nbsp;</td>\n" if ($gap_width);

	    $count++;	    
	}

	# Append the right stub.
	$right_stub ||= \('');
	$right_stub_align ||= 'right';
	$right_stub_width ||= ( 100 - $num_tabs ) . '%';
	$tabs_html .= "<td width=\"$right_stub_width\" align=\"$right_stub_align\">&nbsp;$${right_stub}&nbsp;</td>\n";
    };
    croak "$@" if ($@);

return \<<HTML;
<table border="0" width="$total_width" cellspacing="0" cellpadding="0">
<Tr>$tabs_html</Tr>
<Tr><td width="100%" colspan="$num_elements">
<table border="0" cellspacing="0" cellpadding="0" width="100%"><Tr><td bgcolor="$active_color" align="$base_align">$$base</td></Tr></table>
</td></Tr>
</table>
HTML
}

1;
__DATA__

1;
__END__
