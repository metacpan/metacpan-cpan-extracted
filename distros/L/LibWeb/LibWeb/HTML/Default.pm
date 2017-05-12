#=============================================================================
# LibWeb::HTML::Default -- `stdout' HTML display for libweb applications.

package LibWeb::HTML::Default;

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

# $Id: Default.pm,v 1.6 2000/07/19 20:31:57 ckyc Exp $

$VERSION = '0.02';

#-################################
# Use standard libraries.
use strict;
use Carp;
use vars qw($VERSION @ISA);

#-################################
# Use custom libraries.
require LibWeb::HTML::Standard;
require LibWeb::HTML::Error;
require LibWeb::Themes::Default;

#-################################
# Inheritance.
# Order of ISA is important here!
@ISA = qw( LibWeb::HTML::Standard LibWeb::Themes::Default LibWeb::HTML::Error );

#-################################
# Methods.
sub new {
    #
    # Params: _class_, _rc_file_ [, _error_obj_]
    #
    # - _class_ is the class/package name of this package, be it a string
    #   or a reference.
    # - _rc_file_ is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $html = new LibWeb::HTML::Default( _rc_file_ );
    #
    # PLEASE do not edit anything in this ``new'' method unless you know
    # what you are doing.
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;
    $self = $Class->SUPER::new( shift, shift || bless( {}, $Class ) );
    bless( $self, $Class );
}

sub DESTROY {}

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

#==================================================================================
# ISA this class (LibWeb::HTML::Default) and override the following method to
# customize normal display.  To customize error message display, ISA this class
# (LibWeb::HTML::Default) and override LibWeb::Error::display_error().
#
sub display {
   #
   # Implementing base class method: LibWeb::HTML::Standard::display().
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
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
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

#=================================================================================
# Begin implementation for site's default header, sub header, left panel,
# right panel, content, footer and possibly other HTML constructs.
sub header {
    return [' '];
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
    return [' '];
}

1;
__DATA__

1;
__END__

=head1 NAME

LibWeb:: - HTML display for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

No non-standard Perl's library is required.

=back

=head1 ISA

=over 2

=item *

LibWeb::HTML::Standard

=item *

LibWeb::HTML::Error

=item *

LibWeb::Themes::Default

=back

=head1 SYNOPSIS

  use LibWeb::HTML::Default;

  my $rc_file = '/absolute/path/to/dot_lwrc';
  my $html = new LibWeb::HTML::Default($rc_file);

  $html->fatal(
                -msg =>
                  'You have not typed in the stock symbol.',
                -alertMsg =>
                  'Try to view stock quotes without a symbol.',
                -helpMsg =>
                  $html->hit_back_and_edit()
              )
      unless ($stock_symbol);

  my $display =
      $html->display(
                      -content =>
                        [ $news, $stock_quotes, $weather ],
                      -sheader=> [ $tabbed_navigation_bar ],
                      -lpanel=> [ $banner_ad ],
                      -rpanel=> [ $back_issues, $downloads ],
                      -header=> undef,
                      -footer=> undef
                    );

  print "Content-Type: text/html\n\n";
  print $$display;

I pass the absolute path to my LibWeb's rc (config) file to
C<LibWeb::HTML::Default::new()> so that LibWeb can do things according
to my site's preferences.  A sample rc file is included in the eg
directory, if you could not find that, go to the following address
to down load a standard distribution of LibWeb,

  http://libweb.sourceforge.net

This synopsis also demonstrated how I have handled error by calling
the C<fatal()> method.  For the C<display()> call, I passed C<undef>
to C<-header> and C<-footer> to demonstrate how to tell the display to
use default header and footer.

Finally, I de-referenced C<$display> (by appending C<$> in front of
the variable) to print out the HTML page.  Please see the synopsis of
L<LibWeb::Themes::Default> to see how I have prepared C<$news,
$weather, $stock_quotes, $back_issues and $tabbed_navigation_bar>.

If I would like to customize the HTML display of LibWeb, I would have
ISAed LibWeb::HTML::Default, say a class called C<MyHTML> and I just
have to replace the following two lines,

  use LibWeb::HTML::Default;
  my $html = new LibWeb::HTML::Default( $rc_file );

with

  use MyHTML;
  my $html = new MyHTML( $rc_file );

A sample MyHTML.pm is included in the distribution for your hacking
pleasure.

=head1 ABSTRACT

This class is a sub-class of LibWeb::HTML::Standard,
LibWeb::HTML::Error and LibWeb::Themes::Default and therefore it
handles both standard and error display (HTML) for a LibWeb
application.  To customize the behavior of C<display()>, C<display_error()>
and built-in error/help messages, you can make a sub-class of
LibWeb::HTML::Default (an example can be found in the eg directory.
If you could not find it, download a standard distribution from the
following address).  In the sub-class you made, you can also add
your own error messages.  You may want to take a look at
L<LibWeb::HTML::Error> to see what error messages are built into
LibWeb.  To override the standard error messages, you re-define them
in the sub-class you made.

The current version of LibWeb::HTML::Default is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

All `error/help messages' mentioned can be found at
L<LibWeb::HTML::Error> and they can be customized by ISA (making a
sub-class of) LibWeb::HTML::Default.  Error/help messages are used
when you call LibWeb::Core::fatal, see L<LibWeb::Core> for details.
Method's parameters in square brackets means optional.

=head1 DESCRIPTION

B<new()>

Params:

=over 2

=item I<class>, I<rc_file>

=back

Usage:

  my $html = new LibWeb::HTML::Default( $rc_file );

Pre:

=over 2

=item *

I<class> is the class/package name of this package, be it a string or
a reference.

=item *

I<rc_file> is the absolute path to the rc file for LibWeb.

=back

B<display()>

This implements the base class method: LibWeb::HTML::Standard::display().

Params:

  -content=>, [ -sheader=>, -lpanel=>, -rpanel=>,
                -header=>, -footer=> ]

Pre:

=over 2

=item *

C<-content>, C<-sheader>, C<-lpanel>, C<-rpanel>, C<-header> and
C<-footer> each must be an ARRAY reference to elements which are
scalars/SCALAR references/ARRAY references,

=item *

if the elements are ARRAY references, then the elements in those
ARRAY references must be scalars and NOT references,

=item *

C<-content> default is C<content()>,

=item *

C<-sheader> stands for ``sub header'' and default is C<sheader()>,

=item *

C<-lpanel> default is C<lpanel()>,

=item *

C<-rpanel> default is C<rpanel()>,

=item *

C<-header> default is C<header()>,

=item *

C<-footer> default is C<footer()>.

=back

Post:

=over 2

=item *

Return a SCALAR reference to a formatted HTML page suitable for
display to a Web browser.

=back

Each of the following methods return an ARRAY reference to partial
HTML.  These are the defaults used by the C<display()> method.

B<header()>

B<sheader()>

B<lpanel()>

B<content()>

B<rpanel()>

B<footer()>

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::Core>, L<LibWeb::HTML::Error>, L<LibWeb::HTML::Standard>,
L<LibWeb::Themes::Default>.

=cut
