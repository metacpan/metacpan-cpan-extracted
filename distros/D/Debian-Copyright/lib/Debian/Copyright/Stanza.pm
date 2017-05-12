=head1 NAME

Debian::Copyright::Stanza - single stanza of Debian copyright file

=head1 VERSION

This document describes Debian::Copyright::Stanza version 0.2 .

=head1 SYNOPSIS

    package Header;
    use base 'Debian::Copyright::Stanza';
    use constant fields => qw(
        Format_Specification
        Name
        Source
        Maintainer
        X_Comment
    );

    1;

=head1 DESCRIPTION

Debian::Copyright::Stanza is the base class for
L<Debian::Copyright::Stanza::Header>, L<Debian::Copyright::Stanza::Files> and
L<Debian::Copyright::Stanza::License> classes.

=cut

package Debian::Copyright::Stanza;

require v5.10.1;
use strict;
use base qw( Class::Accessor Tie::IxHash );
use Carp qw(croak);
use Debian::Copyright::Stanza::OrSeparated;

our $VERSION = '0.2';

=head1 FIELDS

Stanza fields are to be defined in the class method I<fields>. Typically this
can be done like:

    use constant fields => qw( Foo Bar Baz );

Fields that are to contain dependency lists (as per L</is_dependency_list>
method below) are automatically converted to instances of the
L<Debian::Dependencies> class.

=cut

use constant fields => ();

sub import {
    my( $class ) = @_;

    $class->mk_accessors( $class->fields );
}

use overload '""' => \&as_string;

=head1 CONSTRUCTOR

=head2 new( { field => value, ... } )

Creates a new L<Debian::Copyright::Stanza> object and optionally initialises it
with the supplied data. The object is hashref based and tied to L<Tie::IxHash>.

You may use dashes for initial field names, but these will be converted to
underscores:

    my $s = Debian::Copyright::Stanza::Header( {Name => "Blah"} );
    print $s->Name;

=cut

sub new {
    my $class = shift;
    my $init = shift || {};

    my $self = Tie::IxHash->new;

    bless $self, $class;

    while( my($k,$v) = each %$init ) {
        $k =~ s/-/_/g;
        $self->can($k)
            or croak "Invalid field given ($k)";
        if ( $self->is_or_separated($k) ) {
            $self->$k( Debian::Copyright::Stanza::OrSeparated->new( $v ) );
        }
        else {
            $self->$k($v);
        }
    }

    return $self;
}

=head1 METHODS

=head2 is_or_separated($field)

Returns true if the given field is to contain a 'or'-separated list of values.
This is used in stringification, when considering where to wrap long lines.

=cut

sub is_or_separated {
    my( $self, $field ) = @_;
    return 0;
}

=head2 get($field)

Overrides the default get method from L<Class::Accessor> with L<Tie::IxHash>'s
FETCH.

=cut

sub get {
    my( $self, $field ) = @_;

    $field =~ s/_/-/g;

    return $self->FETCH($field);
}

=head2 set( $field, $value )

Overrides the default set method from L<Class::Accessor> with L<Tie::IxHash>'s
STORE. 

=cut

sub set {
    my( $self, $field, $value ) = @_;

    chomp($value);

    $field =~ s/_/-/g;

    return $self->STORE( $field,  $value );
}

=head2 as_string([$width])

Returns a string representation of the object. Ready to be printed into a
real F<debian/copyright> file. Used as a stringification operator.

=cut

sub as_string
{
    my ( $self, $width ) = @_;
    $width //= 80;

    my @lines;

    $self->Reorder( map{ ( my $s = $_ ) =~ s/_/-/g; $s } $self->fields );

    for my $k ( $self->Keys ) {
        # We don't' want the internal fields showing in the output
        next if $k =~ /^-/;     # _ in field names is replaced with dashes
        my $v = $self->FETCH($k);
        next unless defined($v);

        my $line = "$k: $v";
        push @lines, $line if $line;
    }

    return join( "\n", @lines ) . "\n";
}

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 Nicholas Bamber <nicholas@periapt.co.uk>

This module is substantially based upon L<Debian::Control::Stanza>.
Copyright (C) 2009 Damyan Ivanov L<dmn@debian.org> [Portions]

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

1;
