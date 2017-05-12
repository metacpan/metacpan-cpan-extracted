package HTML::Native::Attribute::ReadOnly;

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

HTML::Native::Attribute::ReadOnly - A read-only HTML element attribute

=head1 SYNOPSIS

    use HTML::Native::Attribute::ReadOnly;

    my $attr =
	HTML::Native::Attribute::ReadOnly->new ( [ qw ( foo bar ) ] );
    print $attr;  # prints "foo bar"
    $attr->{foo} = 0;  # dies

=head1 DESCRIPTION

An L<HTML::Native::Attribute::ReadOnly> object is an
L<HTML::Native::Attribute> object that does not allow modification of
its values.

See L<HTML::Native::Attribute/"DYNAMIC GENERATION"> for further
details on when and why you might want to use an
L<HTML::Native::Attribute::ReadOnly> object.

=cut

use base qw ( HTML::Native::Attribute );
use mro "c3";
use strict;
use warnings;

sub hash {
  my $self = shift;
  my $value = $self->next::method ( @_ );

  return $self->new_readonly_hash ( $value );
}

sub array {
  my $self = shift;
  my $value = $self->next::method ( @_ );

  return $self->new_readonly_array ( $value );
}

1;
