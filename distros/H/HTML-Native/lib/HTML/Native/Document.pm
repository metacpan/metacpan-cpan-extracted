package HTML::Native::Document;

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

HTML::Native::Document - HTML::Native document-level element

=head1 SYNOPSIS

    use HTML::Native::Document;

    my $doc = HTML::Native::Document::XHTML10::Strict->new ( "Home" );
    my $body = $doc->body;
    push @$body, (
      [ h1 => "Welcome" ],
      "Hello world!"
    );
    print $doc;
    # prints:
    #   <?xml version="1.0" encoding="UTF-8"?>
    #   <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    #             "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    #   < html xmlns="http://www.w3.org/1999/xhtml">
    #   <head><title>Home</title></head>
    #   <body><h1>Welcome</h1>Hello world!</body>
    #   </html>

=head1 DESCRIPTION

L<HTML::Native::Document> provides several predefined HTML document
types:

=over 4

=item  HTML::Native::Document::XHTML10::Strict - XHTML 1.0 Strict

=item  HTML::Native::Document::XHTML10::Transitional - XHTML 1.0 Transitional

=item  HTML::Native::Document::XHTML10::Frameset - XHTML 1.0 Frameset

=item  HTML::Native::Document::XHTML11 - XHTML 1.1

=item  HTML::Native::Document::HTML401::Strict - HTML 4.01 Strict

=item  HTML::Native::Document::HTML401::Transitional - HTML 4.01 Transitional

=item  HTML::Native::Document::HTML401::Frameset - HTML 4.01 Frameset

=back

These can be used as the root element for an L<HTML::Native> document
tree.

=cut

use List::Util qw ( first );
use HTML::Native qw ( is_html_element );
use base qw ( HTML::Native );
use mro "c3";
use strict;
use warnings;

=head1 METHODS

=head2 new()

    $doc = HTML::Native::Document::<subclass>->new ( <title> )

Create a new L<HTML::Native> object representing an HTML document.
For example:

    my $doc = HTML::Native::Document::HTML401::Strict->new ( "Hello" );

=cut

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";
  my $doctype = shift || "";

  # Construct self
  my $self = $class->next::method ( html =>
				    "\n",
				    [ head => [ title => $title ] ],
				    "\n",
				    [ body => ],
				    "\n" );

  # Create bookmarks
  $self->head ( first { is_html_element ( $_, "head" ) } @$self );
  $self->body ( first { is_html_element ( $_, "body" ) } @$self );
  $self->title ( first { is_html_element ( $_, "title" ) } @{$self->head} );

  # Store document type
  &$self->{doctype} = $doctype;

  return $self;
}

=head2 head()

    $head = $doc->head();

Retrieve the L<HTML::Native> object representing the C<< <head> >>
element.  For example:

    my $head = $doc->head();    
    push @$head, [ link => { type => "text/css", rel => "Stylesheet",
			     href => "default.css" } ];

=cut

sub head {
  my $self = shift;
  return $self->bookmark ( "head", @_ );
}

=head2 body()

    $body = $doc->body();

Retrieve the L<HTML::Native> object representing the C<< <body> >>
element.  For example:

    my $body = $doc->body();
    push @$body, [ p => "Hello world" ];

=cut

sub body {
  my $self = shift;
  return $self->bookmark ( "body", @_ );
}

=head2 title()

    $title = $doc->title();

Retrieve the L<HTML::Native> object representing the C<< <title> >>
element.  For example:

    my $title = $doc->title();
    @$title = ( "Home" );

=cut

sub title {
  my $self = shift;
  return $self->bookmark ( "title", @_ );
}

sub html {
  my $self = shift;
  my $html = "";
  my $callback = shift || sub { $html .= shift; };

  # Prepend document type
  &$callback ( &$self->{doctype} );
  $self->next::method ( $callback );

  return $html;
}

package HTML::Native::Document::XHTML10::Strict;

use base qw ( HTML::Native::Document );
use mro "c3";
use strict;
use warnings;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";

  my $self = $class->next::method ( $title,
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".
    "<!DOCTYPE html PUBLIC ".
    "\"-//W3C//DTD XHTML 1.0 Strict//EN\" ".
    "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n" );
  $self->{xmlns} = "http://www.w3.org/1999/xhtml";
  return $self;
}

package HTML::Native::Document::XHTML10::Transitional;

use base qw ( HTML::Native::Document );
use mro "c3";
use strict;
use warnings;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";

  my $self = $class->next::method ( $title,
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".
    "<!DOCTYPE html PUBLIC ".
    "\"-//W3C//DTD XHTML 1.0 Transitional//EN\" ".
    "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n" );
  $self->{xmlns} = "http://www.w3.org/1999/xhtml";
  return $self;
}

package HTML::Native::Document::XHTML10::Frameset;

use base qw ( HTML::Native::Document );
use mro "c3";
use strict;
use warnings;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";

  my $self = $class->next::method ( $title,
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".
    "<!DOCTYPE html PUBLIC ".
    "\"-//W3C//DTD XHTML 1.0 Frameset//EN\" ".
    "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd\">\n" );
  $self->{xmlns} = "http://www.w3.org/1999/xhtml";
  return $self;
}

package HTML::Native::Document::XHTML11;

use base qw ( HTML::Native::Document );
use mro "c3";
use strict;
use warnings;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";

  my $self = $class->next::method ( $title,
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".
    "<!DOCTYPE html PUBLIC ".
    "\"-//W3C//DTD XHTML 1.1//EN\" ".
    "\"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n" );
  $self->{xmlns} = "http://www.w3.org/1999/xhtml";
  return $self;
}

package HTML::Native::Document::HTML401::Strict;

use base qw ( HTML::Native::Document );
use mro "c3";
use strict;
use warnings;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";

  my $self = $class->next::method ( $title,
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" ".
    "\"http://www.w3.org/TR/html4/strict.dtd\">\n" );
  return $self;
}

package HTML::Native::Document::HTML401::Transitional;

use base qw ( HTML::Native::Document );
use mro "c3";
use strict;
use warnings;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";

  my $self = $class->next::method ( $title,
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" ".
    "\"http://www.w3.org/TR/html4/loose.dtd\">\n" );
  return $self;
}

package HTML::Native::Document::HTML401::Frameset;

use base qw ( HTML::Native::Document );
use mro "c3";
use strict;
use warnings;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $title = shift || "";

  my $self = $class->next::method ( $title,
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Frameset//EN\" ".
    "\"http://www.w3.org/TR/html4/frameset.dtd\">\n" );
  return $self;
}

1;
