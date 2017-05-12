package HTML::Native::Comment;

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

HTML::Native::Comment - HTML::Native comment

=head1 SYNOPSIS

    use HTML::Native::Comment;

    my $comment = HTML::Native::Comment->new ( "This is a comment" );
    print $comment;
    # prints "<!-- This is a comment -->"

=head1 DESCRIPTION

An L<HTML::Native::Comment> object represents an HTML comment.  It can
safely be included within an L<HTML::Native> tree without being
subject to entity encoding.

=cut

use Carp;
use base qw ( HTML::Native::Literal );
use mro "c3";
use strict;
use warnings;

=head1 METHODS

=head2 new()

    $comment = HTML::Native::Comment->new ( <text> );

Create a new L<HTML::Native::Comment> object, representing a single
HTML comment.  For example:

    my $comment = HTML::Native::Comment->new ( "This is a comment" );
    print $comment;
    # prints "<!-- This is a comment -->"

or

    my $elem = HTML::Native->new (
      div =>
      [ h1 => "Welcome" ],
      "Hello world!",
      HTML::Native::Comment->new ( "Hide this" ),
    );
    print $elem;
    # prints "<div><h1>Welcome</h1>Hello world!<!-- Hide this --></div>"

=cut

sub html {
  my $self = shift;
  my $html = "";
  my $callback = shift || sub { $html .= shift; };

  &$callback ( "<!" );
  $self->next::method ( sub {
    my $comment = shift;
    $comment =~ s/--/-\\-/g; # Escape any -- sequences
    $comment =~ s/>/&gt;/g; # Escape any >
    &$callback ( "-- ".$comment." --" );
  } );
  &$callback ( ">" );

  return $html;
}

1;

