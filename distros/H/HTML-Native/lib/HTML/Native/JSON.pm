package HTML::Native::JSON;

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

HTML::Native::JSON - embedded JSON data

=head1 SYNOPSIS

    use HTML::Native::JSON;

    my $json = HTML::Native::JSON->new ( {
      start => 4,
      end => 7
    } );
    print $json;
    # prints "<script type="application/json">{"start":4,"end":7}</script>"

=head1 DESCRIPTION

An L<HTML::Native::JSON> object represents a piece of inline JSON
data, usable by JavaScript code such as the jQuery metadata plugin.

=head1 METHODS

=cut

use HTML::Native;
use HTML::Native::Literal;
use JSON;
use base qw ( HTML::Native );
use mro "c3";
use strict;
use warnings;

=head2 new()

    $elem = HTML::Native::JSON->new ( <data> );

Create a new L<HTML::Native::JSON> object, representing a single C<<
<script> >> element.

=cut

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $data = shift;

  # Encode JSON data
  my $json = encode_json ( $data );

  # Force a </script> close tag, since <script ... /> is generally not
  # accepted by browsers
  $json ||= "";

  return $class->next::method ( script => { type => "application/json" },
				HTML::Native::Literal->new ( $json ) );
}

1;
