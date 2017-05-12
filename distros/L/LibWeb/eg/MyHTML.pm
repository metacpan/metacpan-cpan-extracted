#=============================================================================
# MyHTML -- a sample class to demonstrate how to (ISA) make a sub-class of
#           LibWeb::Themes::Default to customize the `stdout' and `stderr' HTML
#           display of LibWeb.

package MyHTML;

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

# $Id: MyHTML.pm,v 1.7 2000/07/18 06:33:30 ckyc Exp $

$VERSION = '0.02';

#-################################
# Use standard libraries.
use strict;
use vars qw($VERSION @ISA);
use Carp;

#-################################
# Use custom libraries.
require LibWeb::HTML::Default;

#-################################
# Inheritance.
@ISA = qw( LibWeb::HTML::Default );

#-################################
# Methods.
sub new {
    #
    # Params: $class, $rc_file
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $html = new MyHTML( $rc_file );
    #
    # PLEASE do not edit anything in this ``new'' method unless you know
    # what you are doing.
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;
    $self = $Class->SUPER::new( shift, bless( {}, $Class ) );
    bless( $self, $Class );
}

sub DESTROY {}

sub display {
   #
   # Overriding base class method: LibWeb::HTML::Default::display() to customize
   # the normal HTML display.
   #
   # Params: -content=>, [ -sheader=>, -lpanel=>, -rpanel=>, -header=>, -footer=> ].
   #
   # -content, -sheader, -lpanel, -rpanel, -header and -footer must be an ARRAY
   # ref. to elements which are scalar/SCALAR ref/ARRAY ref.
   # If the the elements are ARRAY ref., then the elements in that ARRAY ref. must
   # be scalar and NOT ref.
   #
   # -content default is lines read from $self->content().
   # -sheader default is lines read from $self->sheader().
   # -lpanel default is lines read from $self->lpanel().
   # -rpanel default is lines read from $self->rpanel().
   # -header default is lines read from $self->header().
   # -footer default is lines read from $self->footer().
   #
   # Return a scalar ref. to a formatted page in HTML format for display
   # to Web client.
   #
   my ($self, $content, $sheader, $lpanel, $rpanel, $header, $footer,
       $content_display, $sheader_display, $lpanel_display, $rpanel_display,
       $header_display, $footer_display);
   $self = shift;
   ($content, $sheader, $lpanel, $rpanel, $header, $footer) =
     $self->rearrange(['CONTENT', 'SHEADER', 'LPANEL', 'RPANEL', 'HEADER',
			'FOOTER'], @_);

   $content ||= $self->content();
   $sheader ||= $self->sheader();
   $lpanel ||= $self->lpanel();
   $rpanel ||= $self->rpanel();
   $header ||= $self->header();
   $footer ||= $self->footer();

   $content_display = _parse_construct($content);
   $sheader_display = _parse_construct($sheader);
   $lpanel_display = _parse_construct($lpanel);
   $rpanel_display = _parse_construct($rpanel);
   $header_display = _parse_construct($header);
   $footer_display = _parse_construct($footer);

#<!-- Begin template -->
return \<<HTML;
<!doctype html public "-//w3c//dtd html 4.0 transitional//en">
<html><head><meta name="description" content="$self->{SITE_DESCRIPTION}">
<meta name="keywords" content="$self->{SITE_KEYWORDS}">
<title>$self->{SITE_NAME}</title><link rel="stylesheet" href="$self->{CSS}"></head>
<body bgcolor="$self->{SITE_BG_COLOR}" text="$self->{SITE_TXT_COLOR}">
@$header_display
@$sheader_display
<table width="100%" cellspacing="10" cellpadding="0" border="0" bgcolor="$self->{SITE_BG_COLOR}">
<Tr>

<!-- Left panel -->
<td width="20%" valign="top">
@$lpanel_display</td><!-- end left panel -->

<!-- Content -->
<td width="60%" valign="top">
@$content_display</td><!-- end content -->

<!-- Right panel -->
<td width="20%" valign="top">
@$rpanel_display</td><!-- end right panel -->

</Tr>
</table>

@$footer_display</body></html>

HTML
#<!-- End template -->
}

sub display_error {
   #
   # Overriding base class method: LibWeb::HTML::Default::display_error() to
   # customize the error message display.
   #
   # Params: $caller, $error_msg, $error_input, $help_msg
   #
   # $caller is the object calling this method.
   # All other parameters are scalars except $help_msg which must be a
   # SCALAR ref.
   #
   my ($caller, $error_msg, $error_input, $err_input_display, $help_msg);
   shift;
   $caller = shift;
   ($error_msg, $error_input, $help_msg) = @_;
   croak "-helpMsg must be a SCALAR reference."
     unless ( ref($help_msg) eq 'SCALAR' );
    $err_input_display = ($error_input ne ' ') ?
                         "<b><big>The erroneous input:</big></b>".
                         "<p><font color=\"red\">$error_input</font>" : 
			 ' ';

# Customize the error/help message display here.
return \<<HTML;
<html><head><title>$caller->{SITE_NAME}</title>
<link rel="stylesheet" href="$caller->{CSS}"></head>
<body bgcolor="$caller->{SITE_BG_COLOR}" text="$caller->{SITE_TXT_COLOR}">
<center>
<a href="/"><img src="$caller->{SITE_LOGO}" border="0" alt="$caller->{SITE_NAME}"></a>
<table border=0 cellpadding=0 cellspacing=0 width="65%" bgcolor="$caller->{SITE_BG_COLOR}">

<Tr><td>
<table border=0 cellpadding=1 cellspacing=0 width="100%" bgcolor="$caller->{SITE_LIQUID_COLOR5}">
<Tr><td>
<table border=0 cellpadding=0 cellspacing=0 width="100%" bgcolor="$caller->{SITE_LIQUID_COLOR3}">
<Tr><td bgcolor="$caller->{SITE_LIQUID_COLOR3}" align="center">
<font color="$caller->{SITE_TXT_COLOR}"><b>Error</b></font>
</td></Tr></table>
</td></Tr></table>
</td><Tr>

<Tr><td>
<table border=0 cellpadding=7 cellspacing=0 width="100%" bgcolor="$caller->{SITE_BG_COLOR}"><Tr><td>
<p><b><big>The following error has occurred:</big></b>
<p>$error_msg
<p>$err_input_display
<p><b><big>Suggested help:</big></b>
<p>$$help_msg
</td></Tr></table>
</td></Tr>

</table><br>
<table border=0 width="60%"><Tr><td align="center"><hr size=1>
Copyright&nbsp;&copy;&nbsp;$caller->{SITE_YEAR}&nbsp;$caller->{SITE_NAME}.  All rights reserved.<br>
<a href="$caller->{TOS}">Terms of Services.</a> &nbsp;
<a href="$caller->{PRIVACY_POLICY}">Privacy Policy.</a>
</td></Tr></table>
</center>
</body></html>
HTML
}

#-###############################################
# Private method.
sub _parse_construct {
    my ($ref, @construct_display);
    my $construct = $_[0];
    
    eval {
	foreach (@$construct) {
	    $ref = ref($_);
	    if ( $ref eq 'SCALAR' ) { push(@construct_display, $$_); }
	    elsif ( $ref eq 'ARRAY' ) { push(@construct_display, @$_); }
	    else { push(@construct_display, $_); }
	}
    };
    croak "$@" if ($@);

    return \@construct_display;
}

#-##########################################################
# Begin implementation for site's default header, sub header,
# left panel, right panel, content, footer and possibly other
# HTML constructs.  Make sure each of the constructs return
# an ARRAY reference.  header() and footer() have been
# implemented here as examples.
sub header {
    my $self = shift;

my $header = \<<HTML;
<center>
<a href="$self->{URL_ROOT}"><img src="$self->{SITE_LOGO}" border="0" alt="$self->{SITE_NAME}"></a>
</center>
HTML

    return [ $header ];   
}

sub sheader {
    return [' '];
}

sub lpanel {
    return [' '];
}

sub content {
    return [' '];
}

sub rpanel {
    return [' '];
}

sub footer {
    my $self = shift;

my $footer = \<<HTML;
<center><table border=0 width="60%"><Tr><td align="center"><hr size=1>
Copyright&nbsp;&copy;&nbsp;$self->{SITE_YEAR}&nbsp;$self->{SITE_NAME}.  All rights reserved.<br>
<a href="$self->{TOS}">Terms of Service.</a> &nbsp;
<a href="$self->{PRIVACY_POLICY}">Privacy Policy.</a>
</td></Tr></table></center>
HTML

    return [ $footer ];
}

#-####################################################################
# Overriding LibWeb::HTML::Default's error messages (i.e. LibWeb's
# built-in error+help messages).  Make sure each of the methods return
# a SCALAR reference.
#
# For example:
sub cookie_error {
return \<<HTML;
# Put your own implementation of HTML help/error message for cookie_error here.
HTML
}

sub you_own_error_msg {
return \<<HTML;
# Put your implementation here.
HTML
}

1;
__END__
