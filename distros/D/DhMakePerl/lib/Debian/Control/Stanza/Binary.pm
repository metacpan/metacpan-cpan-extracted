=head1 NAME

Debian::Control::Stanza::Binary - binary stanza of Debian source package control file

=head1 SYNOPSIS

    my $bin = Debian::Control::Stanza::Binary->new(\%data);
    print $bin;                         # auto-stringification
    print $bin->Depends;                # Debian::Dependencies object

=head1 DESCRIPTION

Debian::Control::Stanza::Binary can be used for representation and manipulation
of C<Package:> stanza of Debian source package control files in an
object-oriented way. Converts itself to a textual representation in string
context.

=head1 FIELDS

The supported fields for binary stanzas are listed below. For more information
about each field's meaning, consult the section named C<Source package control
files -- debian/control> of the Debian Policy Manual at
L<http://www.debian.org/doc/debian-policy/>

Note that real control fields may contain dashes in their names. These are
replaced with underscores.

=over

=item Package

=item Architecture

=item Section

=item Priority

=item Essential

=item Depends

=item Recommends

=item Suggests

=item Enhances

=item Replaces

=item Pre_Depends

=item Conflicts

=item Breaks

=item Provides

=item Description

=back

C<Depends>, C<Conflicts> C<Breaks>, C<Recommends>, C<Suggests>, C<Enhances>,
C<Replaces>, and C<Pre_Depends> fields are converted to objects of
L<Debian::Dependencies> class upon construction.

Two more accessor methods are provided for easier handling of package's short
and long description.

=over

=item short_description

=item long_description

=back

Setting them transparently modifies I<Description>. Note that the value of
I<long_description> is "unmangled", that is without leading spaces, and empty
lines are empty. I<Description> on the other hand is just as it looks in a
regular debian/control file - the long part is indented with a single space and
empty lines are replaced with dots.

=cut

package Debian::Control::Stanza::Binary;

use strict;
use warnings;

our $VERSION = '0.77';

use base 'Debian::Control::Stanza';

use constant fields => qw(
    Package Architecture Section Priority Essential Depends Recommends Suggests
    Enhances Replaces Pre_Depends Conflicts Breaks Provides Description
    _short_description _long_description
);

=head1 CONSTRUCTOR

=over

=item new

=item new( { field => value, ... } )

Creates a new L<Debian::Control::Stanza::Binary> object and optionally
initializes it with the supplied data.

=back

=head1 SEE ALSO

Debian::Control::Stanza::Source inherits most of its functionality from
L<Debian::Control::Stanza>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009, 2010 Damyan Ivanov L<dmn@debian.org>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

sub set {
    my ( $self, $field, @value ) = @_;

    my $res = $self->SUPER::set( $field, @value );

    # re-split description in it was set
    if ( $field eq 'Description' ) {
        $self->_split_description;
    }
    elsif ( $field eq '_short_description' or $field eq '_long_description' ) {
        $self->_format_description;
    }

    $res;
}

sub short_description {
    shift->_short_description(@_);
}

sub long_description {
    shift->_long_description(@_);
}

sub _format_description {
    my $self = shift;

    my $short = $self->_short_description;
    my $long  = $self->_long_description;

    if( defined($long) ) {
        $long =~ s/\n\n/\n.\n/sg;       # add spacing between paragraphs
        $long =~ s/^/ /mg;              # prepend every line with a space
    }

    # use SUPER::set to not trigger our implementation, which would cause
    # endless loop (setting short_description updates Description, which is
    # then split)
    $self->SUPER::set( 'Description',
        join( "\n", map { $_ // () } ( $short, $long ) ) );
}

sub _split_description {
    my $self = shift;

    my ( $short, $long ) = split( /\n/, $self->Description, 2 );

    $long =~ s/^ //mg;
    $long =~ s/^ \.$//mg;

    # use SUPER::set to not trigger our implementation, which would cause
    # endless loop (setting short_description updates Description, which is
    # then split)
    $self->SUPER::set( '_short_description', $short );
    $self->SUPER::set( '_long_description', $long );
}

1;
