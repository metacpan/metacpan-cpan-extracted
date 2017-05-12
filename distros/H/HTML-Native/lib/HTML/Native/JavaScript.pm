package HTML::Native::JavaScript;

# Copyright (C) 2011 Michael Brown <mbrown@fensystems.co.uk>.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 NAME

HTML::Native::JavaScript - embedded JavaScript code

=head1 SYNOPSIS

    use HTML::Native::JavaScript;

    my $external_js =
        HTML::Native::JavaScript->new ( { src => "script.js" } );
    print $external_js;
    # prints "<script src="script.js" type="text/javascript"></script>"

    my $inline_js = HTML::Native::JavaScript->new ( <<'EOF' );
    document.write("<b>Hello World</b>");
    EOF
    print $inline_js;
    # prints:
    #   <script type="text/javascript">//<![CDATA[
    #   document.write("<b>Hello World</b>");
    #   //]]></script>

=head1 DESCRIPTION

An L<HTML::Native::JavaScript> object represents a piece of JavaScript
code, either external or inline.  It generates the C<< <script> >>
tag, and will wrap inline JavaScript code inside C<< //<![CDATA[ >>
and C<< //]]> >> markers to ensure correct interpretation by both HTML
and XHTML parsers.

=head1 METHODS

=cut

use HTML::Native qw ( is_html_attributes );
use HTML::Native::Literal;
use base qw ( HTML::Native );
use mro "c3";
use strict;
use warnings;

=head2 new()

    $elem = HML::Native::JavaScript->new();

    $elem = HML::Native::JavaScript->new ( { <attributes> } );

    $elem = HML::Native::JavaScript->new ( <inline script> );

    $elem = HML::Native::JavaScript->new ( { <attributes> },
					   <inline script> );

Create a new L<HTML::Native::JavaScript> object, representing a single
C<< <script> >> element.

The attribute C<< type="text/javascript" >> will be added
automatically if not explicitly specified.

=cut

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $attributes = ( ( ( ref $_[0] eq "HASH" ) || is_html_attributes ( $_[0] ) )
		     ? shift : {} );
  my @script = map { HTML::Native::Literal->new ( $_ ) } @_;

  # Always set type="text/javascript"
  $attributes->{type} ||= "text/javascript";

  # Force a </script> close tag, since <script ... /> is generally not
  # accepted by browsers
  push @script, "" unless @script;

  return $class->next::method ( script => $attributes, @script );
}

sub new_children {
  my $self = shift;
  my $children = shift;

  return HTML::Native::JavaScript::Inline->new ( @$children );
}

package HTML::Native::JavaScript::Inline;

use Carp::Clan qr/^HTML::Native::JavaScript/;
use HTML::Native;
use base qw ( HTML::Native::List );
use strict;
use warnings;

sub html {
  my $self = shift;
  $self = tied ( @$self ) // $self if ref $self;
  my $html = "";
  my $callback = shift || sub { $html .= shift; };

  # Test to see if we have any inline content
  my $inline = ( ( @$self > 1 ) || $self->[0] );

  # Mark inline scripts as CDATA to ensure correct parsing under XHTML
  &$callback ( "//<![CDATA[\n" ) if $inline;
  $self->next::method ( sub {
    my $text = shift;
    # The sequence "]]>" will end the CDATA section.  Under XHTML, we
    # could replace this with "]]]]><![CDATA[>" to obtain the desired
    # result, but this won't work under HTML.  In the unlikely event
    # that a script body includes this sequence, throw a fatal error
    # (using "confess" since we are inside several anonymous subs at
    # this point).
    confess ( "JavaScript body may not contain the \"]]>\" CDATA end marker" )
	if $text =~ /\]\]>/;
    &$callback ( $text );
  } );
  &$callback ( "\n//]]>" ) if $inline;

  return $html;
}

sub new_element {
  croak "Cannot embed elements within JavaScript";
}

1;
