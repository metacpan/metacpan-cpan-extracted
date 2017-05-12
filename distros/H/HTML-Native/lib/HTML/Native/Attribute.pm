package HTML::Native::Attribute;

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

HTML::Native::Attribute - An HTML element attribute

=head1 SYNOPSIS

    use HTML::Native;

    my $elem = HTML::Native->new (
      a => { class => "active", href => "/home" },
      "Home"
    );
    my $attr = $elem->{class};
    $attr->{default} = 1;
    print $attr;
    # prints "active default"


    use HTML::Native::Attribute;

    my $attr = HTML::Native::Attribute->new ( [ qw ( active default ) ] );
    $attr->{default} = 0;
    print $attr;
    # prints "active"

=head1 DESCRIPTION

An L<HTML::Native::Attribute> object represents an HTML element
attribute belonging to an L<HTML::Native> object.  It will be created
automatically by L<HTML::Native> as necessary; you probably do B<not>
ever need to manually create an L<HTML::Native::Attribute> object.

You can treat an L<HTML::Native::Attribute> object as a magic variable
that provides access to the attribute value as either a string:

    "active default"

or as an array:

    [ "active", "default" ]

or as a hash

    { active => 1, default => 1 }

This allows you to always use the most natural way of accessing the
attribute value.

The underlying stored value for the attribute will be converted
between a scalar, a hash and an array as required.

=cut

use HTML::Entities;
use Scalar::Util qw ( blessed );
use Carp;
use HTML::Native::Attribute::ReadOnlyHash;
use HTML::Native::Attribute::ReadOnlyArray;
use strict;
use warnings;

use overload
    '""' => sub { my $self = shift; return $self->stringify; },
    '%{}' => sub { my $self = shift; return $self->hash; },
    '@{}' => sub { my $self = shift; return $self->array; },
    fallback => 1;

sub new {
  my $old = shift;
  my $class = ref $old || $old;
  my $value = shift;

  my $self = sub { \$value; };
  bless $self, $class;
  return $self;
}

=head2 GENERATED HTML (STRINGIFICATION)

You can treat the L<HTML::Native::Attribute> object as a string in
order to obtain the generated HTML.  For example:

    my $elem = HTML::Native->new (
      a => { class => [ qw ( active default ) ], href => "/home" },
      "Home"
    );
    my $attr = $elem->{class};
    print $attr;
    # prints "active default"

=head3 FROM A SCALAR

If the attribute is currently stored as a scalar, then it will be used
verbatim as the stringified value.

=head3 FROM AN ARRAY

If the attribute is currently stored as an array, then the stringified
value will be the space-separated members of the array.  For example,
if the attribute is currently stored as

    [ active default ]

then the stringified value will be

    "active default"

=head3 FROM A HASH

If the attribute is currently stored as a hash, then the stringified
value will be the sorted, space-separated keys of the hash
corresponding to true values.  For example, if the attribute is
currently stored as

    { active => 1, default => 1, error => 0 }

then the stringified value will be

    "active default"

=cut

sub stringify {
  my $self = shift;
  my $class = ref $self || $self;

  # Retrieve current value
  my $ref = &$self;
  my $value = $$ref;

  # Value is a code block: execute it and use the result
  if ( ref $value eq "CODE" ) {
    $value = &$value;
    # If generated value is an object, let it stringify itself
    return $value."" if blessed ( $value );
  }

  # Convert value to a scalar if necessary
  if ( ref $value ) {
    if ( ref $value eq "ARRAY" ) {
      # Value is an array: use a space-separated list of array members
      $value = join ( " ", @$value );
    } elsif ( ref $value eq "HASH" ) {
      # Value is a hash: return a space-separated list of sorted hash
      # keys with true values
      $value = join ( " ", sort grep { $value->{$_} } keys %$value );
    } else {
      croak "Cannot convert ".( ref $value )." attribute to SCALAR";
    }
  }

  return ( defined $value ? encode_entities ( $value ) : "" );
}

=head2 ACCESS AS A HASH

You can treat the L<HTML::Native::Attribute> object as a hash in order
to test or set individual values within the attribute.  For example:

    if ( $elem->{class}->{error} ) {
       ...
    }

    $elem->{class}->{fatal} = 1;

This makes sense only for attributes such as C<class> which consist of
a set of individual values.  It does not make sense to treat an
attribute such as C<href> or C<onclick> as a hash.

=head3 FROM A SCALAR

If the attribute is currently stored as a scalar, then it will be
converted into a hash using the current value as the hash key.  For
example, if the attribute is currently stored as

    "active"

then it will be converted to the hash

    { active => 1 }

=head3 FROM AN ARRAY

If the attribute is currently stored as an array, then it will be
converted into a hash using the array members as the hash keys.  For
example, if the attribute is currently stored as

    [ "active", "default" ]

then it will be converted to the hash

    { active => 1, default => 1 }

Note that this conversion is potentially B<destructive>, since it will
lose information about the order of the array members and will
implicitly eliminate any duplicates.  You should therefore only use
hash access for attributes such as C<class> for which the order of
individual values is irrelevant.

=cut

sub hash {
  my $self = shift;
  my $class = ref $self || $self;

  # Retrieve current value
  my $ref = &$self;
  my $value = $$ref;

  # Value is a code block: execute it and use the result as a
  # read-only value
  if ( ref $value eq "CODE" ) {
    $value = &$value;
    # If generated value is an object, let it convert itself to a hash
    return \%$value if blessed ( $value );
    # Prevent modification of current value (i.e. treat result as
    # read-only)
    undef $ref;
  }

  # Convert value to a hash if necessary
  if ( ref $value ne "HASH" ) {
    if ( ! defined $value ) {
      # Value is undefined: use an empty hash
      $value = {};
    } elsif ( ! ref $value ) {
      # Value is a scalar: use as a hash key with a true value
      $value = { $value => 1 };
    } elsif ( ref $value eq "ARRAY" ) {
      # Value is an array: use elements as hash keys with true values
      $value = { map { $_ => 1 } @$value };
    } else {
      croak "Cannot convert ".( ref $value )." attribute to HASH";
    }
    # Rewrite the current value as the hash (unless read-only)
    $$ref = $value if $ref;
  }

  # Convert to a read-only hash if applicable
  $value = $self->new_readonly_hash ( $value ) unless $ref;

  return $value;
}

sub new_readonly_hash {
  my $self = shift;
  my $value = shift;

  return HTML::Native::Attribute::ReadOnlyHash->new ( $value );
}

=head2 ACCESS AS AN ARRAY

You can treat the L<HTML::Native::Attribute> object as an array.  For
example:

    push @{$elem->{onclick}},
	"alert('Clicked');",
	"return false;"

    push @{$elem->{class}}, "active";

=head3 FROM A SCALAR

If the attribute is currently stored as a scalar, then it will be
converted into an array using the current value as the array member.
For example, if the attribute is currently stored as

    "active"

then it will be converted to the array

    [ "active" ]

=head3 FROM A HASH

If the attribute is currently stored as a hash, then it will be
converted into an array of the sorted keys of the hash corresponding
to true values.  For example, if the attribute is currently stored as

    { active => 1, default => 1, error => 0 }

then it will be converted to the array

    [ "active", "default" ]

=cut

sub array {
  my $self = shift;

  # Retrieve current value
  my $ref = &$self;
  my $value = $$ref;

  # Value is a code block: execute it and use the result as a
  # read-only value
  if ( ref $value eq "CODE" ) {
    $value = &$value;
    # If generated value is an object, let it convert itself to an array
    return \@$value if blessed ( $value );
    # Prevent modification of current value (i.e. treat result as
    # read-only)
    undef $ref;
  }

  # Convert value to an array if necessary
  if ( ref $value ne "ARRAY" ) {
    if ( ! defined $value ) {
      # Value is undefined: use an empty array
      $value = [];
    } elsif ( ! ref $value ) {
      # Value is a scalar: use as an array element
      $value = [ $value ];
    } elsif ( ref $value eq "HASH" ) {
      # Value is a hash: use sorted hash keys with true values
      $value = [ sort grep { $value->{$_} } keys %$value ];
    } else {
      croak "Cannot convert ".( ref $value )." attribute to ARRAY";
    }
    # Rewrite the current value as the array (unless read-only)
    $$ref = $value if $ref;
  }

  # Convert to a read-only array if applicable
  $value = $self->new_readonly_array ( $value ) unless $ref;

  return $value;
}

sub new_readonly_array {
  my $self = shift;
  my $value = shift;

  return HTML::Native::Attribute::ReadOnlyArray->new ( $value );
}

=head1 NOTES

For attributes such as C<class> that you may want to access as a hash,
you should avoid directly storing the value as a space-separated
string.  For example, do not use:

    $elem->{class} = "active default";

since that would end up being converted into the hash

    { "active default" => 1 }

rather than

    { active => 1, default => 1 }

To store multiple values, use either an array:

    $elem->{class} = [ qw ( active default ) ];

or a hash

    $elem->{class} = { active => 1, default => 1 };

=head1 ADVANCED

=head2 DYNAMIC GENERATION

You can use anonymous subroutines (closures) to dynamically generate
attribute values.  For example:

    my $url;
    my $elem = HTML::Native->new (
      a => {
	class => "active",
	href => sub { return $url; },
      },
      "Home"
    );
    $url = "/home";
    print $elem;
    # prints "<a class="active" href="/home">Home</a>"

The subroutine can return either a fully-constructed
L<HTML::Native::Attribute> object, or a value that could be passed to
C<< HTML::Native::Attribute->new() >>.  For example:

    sub {
      return HTML::Native::Attribute::ReadOnly->new (
	[ active default ]
      );
    }

or

    sub {
      return ( [ active default ] );
    }

A dynamically generated attribute value can still be accessed as a
hash or as an array.  For example:

    my $elem = HTML::Native->new (
      a => {
	class => sub { return ( [ active default ] ) },
	href => "/home",
      },
      "Home"
    );
    print "Active" if $elem->{class}->{active};   # prints "Active"

L<HTML::Native::Attribute> has no way to inform the anonymous
subroutine that its returned value should change.  For example:

    my $attr = HTML::Native::Attribute->new ( sub {
      my @classes = ( qw ( active default ) );
      return [ @classes ];
    } );

    print $attr;  # prints "active default"
    $attr->{active} = 0;  # <-- PROBLEM!

The dynamically generated attribute will therefore be marked as a
read-only hash or array:

    $attr->{active} = 0;  # will die with an error message

B<If> your anonymous subroutine returns a fully-constructed
L<HTML::Native::Attribute> object, then it should probably use
L<HTML::Native::Attribute::ReadOnly> to ensure this behaviour.  For
example:

    sub {
      return HTML::Native::Attribute::ReadOnly->new (
	[ active default ]
      );
    }

=cut

1;
