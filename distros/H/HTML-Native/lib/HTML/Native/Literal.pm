package HTML::Native::Literal;

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

HTML::Native::Literal - literal text to be included within HTML

=head1 SYNOPSIS

    use HTML::Native::Literal;

    my $literal = HTML::Native::Literal->new ( "<p>Hello</p>" );
    print $literal;
    # prints "<p>Hello</p>"

=head1 DESCRIPTION

An L<HTML::Native::Literal> object represents a piece of text to be
included within an L<HTML::Native> tree without being subject to
entity encoding.

You can use an L<HTML::Native::Literal> object when you have some
pre-existing HTML code that you want to include verbatim within an
L<HTML::Native> tree.

=cut

use strict;
use warnings;

use overload
    '""' => sub { my $self = shift; return $self->html; },
    fallback => 1;

=head1 METHODS

=head2 new()

    $literal = HTML::Native::Literal->new ( <text> );

    $literal = HTML::Native::Literal->new ( \<text> );

Create a new L<HTML::Native::Literal> object, representing some
literal text to be included within an HTML document.  For example:

    my $literal = HTML::Native::Literal->new ( "<p>Hello</p>" )
    print $literal;
    # prints "<p>Hello</p>"

or

    my $elem = HTML::Native->new (
      div =>
      [ h1 => "Welcome" ],
      HTML::Native::Literal->new ( "<p>Hello</p>" )
    );
    print $elem;
    # prints "<div><h1>Welcome</h1><p>Hello</p></div>"

=head1 ADVANCED

=head2 MODIFIABLE LITERALS

If you pass a reference to a scalar variable, then the
L<HTML::Native::Literal> object will remain associated with the
original variable.  For example:

    my $text = "<p>Hello</p>";
    my $elem = HTML::Native->new (
      div =>
      [ h1 => "Welcome" ],
      HTML::Native::Literal->new ( \$text ),
    );
    print $elem;
    # prints "<div><h1>Welcome</h1><p>Hello</p></div>"
    $text = "<p>Goodbye</p>";
    print $elem;
    # now prints "<div><h1>Welcome</h1><p>Goodbye</p></div>"

=cut

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $data = shift;

  my $self = ( ref $data ? $data : \$data );
  bless $self, $class;

  return $self;
}

sub html {
  my $self = shift;
  my $callback = shift || sub { return shift; };

  return &$callback ( $$self );
}

1;
