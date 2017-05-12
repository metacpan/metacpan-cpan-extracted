=head1 NAME

Debian::Control::Stanza - single stanza of Debian source package control file

=head1 SYNOPSIS

    package Binary;
    use base 'Debian::Control::Stanza';
    use constant fields => qw( Package Depends Conflicts );

    1;

=head1 DESCRIPTION

Debian::Control::Stanza ins the base class for
L<Debian::Control::Stanza::Source> and L<Debian::Control::Stanza::Binary>
classes.

=cut

package Debian::Control::Stanza;

require v5.10.0;

use strict;
use warnings;

our $VERSION = '0.71';

use base qw( Class::Accessor Tie::IxHash );

use Carp qw(croak);
use Debian::Control::Stanza::CommaSeparated;
use Debian::Dependencies;

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

=over

=item new

=item new( { field => value, ... } )

Creates a new L<Debian::Control::Stanza> object and optionally initializes it
with the supplied data. The object is hashref based and tied to L<Tie::IxHash>.

You may use dashes for initial field names, but these will be converted to
underscores:

    my $s = Debian::Control::Stanza::Source( {Build-Depends => "perl"} );
    print $s->Build_Depends;

=back

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
        $self->$k($v);
    }

    # initialize any dependency lists with empty placeholders
    # same for comma-separated lists
    for( $self->fields ) {
        if ( $self->is_dependency_list($_) and not $self->$_ ) {
            $self->$_( Debian::Dependencies->new );
        }
        elsif ( $self->is_comma_separated($_) and not $self->$_ ) {
            $self->$_( Debian::Control::Stanza::CommaSeparated->new );
        }
    }


    return $self;
}

=head1 METHODS

=over

=item is_dependency_list($field)

Returns true if I<$field> contains a list of dependencies. By default returns true for the following fields:

=over

=item Build_Depends

=item Build_Depends_Indep

=item Build_Conflicts

=item Build_Conflicts_Indep

=item Depends

=item Conflicts

=item Enhances

=item Replaces

=item Breaks

=item Pre_Depends

=item Recommends

=item Suggests

=back

=cut

our %dependency_list = map(
    ( $_ => 1 ),
    qw( Build-Depends Build-Depends-Indep Build-Conflicts Build-Conflicts-Indep
    Depends Conflicts Enhances Replaces Breaks Pre-Depends Recommends Suggests ),
);

sub is_dependency_list {
    my( $self, $field ) = @_;

    $field =~ s/_/-/g;

    return exists $dependency_list{$field};
}

=item is_comma_separated($field)

Returns true if the given field is to contain a comma-separated list of values.
This is used in stringification, when considering where to wrap long lines.

By default the following fields are flagged to contain such lists:

=over

=item All fields that contain dependencies (see above)

=item Uploaders

=item Provides

=back

=cut

our %comma_separated = map(
    ( $_ => 1 ),
    keys %dependency_list,
    qw( Uploaders Provides ),
);

sub is_comma_separated {
    my( $self, $field ) = @_;

    $field =~ s/_/-/g;

    return exists $comma_separated{$field};
}

=item get($field)

Overrides the default get method from L<Class::Accessor> with L<Tie::IxHash>'s
FETCH.

=cut

sub get {
    my( $self, $field ) = @_;

    $field =~ s/_/-/g;

    return $self->FETCH($field);
}

=item set( $field, $value )

Overrides the default set method from L<Class::Accessor> with L<Tie::IxHash>'s
STORE. In the process, converts I<$value> to an instance of the
L<Debian::Dependencies> class if I<$field> is to contain dependency list (as
determined by the L</is_dependency_list> method).

=cut

sub set {
    my( $self, $field, $value ) = @_;

    chomp($value);

    $field =~ s/_/-/g;

    $value = Debian::Dependencies->new($value)
        if not ref($value) and $self->is_dependency_list($field);

    $value = Debian::Control::Stanza::CommaSeparated->new($value)
        if not ref($value) and $self->is_comma_separated($field);

    return $self->STORE( $field,  $value );
}

=item as_string([$width])

Returns a string representation of the object. Ready to be printed into a
real F<debian/control> file. Used as a stringification operator.

Fields that are comma-separated use one line per item, except if they are like
C<${some:Field}>, in which case they are wrapped at I<$width>th column.
I<$width> defaults to 80.

=cut

use Text::Wrap ();

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
        next if $self->is_dependency_list($k) and "$v" eq "";
        next if $self->is_comma_separated($k) and "$v" eq "";

        my $line;

        if ( $self->is_comma_separated($k) ) {
            # FIXME: this relies on $v being sorted
            my ( @pre_dollar, @dollar, @post_dollar );
            for ( @$v ) {
                if ( /^\$\{.+}$/ ) {
                    push @dollar, $_;
                }
                elsif (@dollar) {
                    push @post_dollar, $_;
                }
                else {
                    push @pre_dollar, $_;
                }
            }

            if ( @pre_dollar ) {
                $line = "$k: " . join( ",\n ", @pre_dollar );
                local $Text::Warp::break = qr/, /;
                local $Text::Warp::columns = $width;
                local $Text::Wrap::separator = ",\n";
                local $Text::Wrap::huge = 'overflow';
                $line .= Text::Wrap::wrap( ' ', ' ', join( ', ', @dollar ) );
            }
            else {
                local $Text::Warp::break = qr/, /;
                local $Text::Warp::columns = $width;
                local $Text::Wrap::separator = ",\n";
                local $Text::Wrap::huge = 'overflow';
                $line
                    = Text::Wrap::wrap( "$k: ", ' ', join( ', ', @dollar ) );
            }

            $line = join( ",\n ", $line, @post_dollar );
        }
        else {
            $line = "$k: $v";
        }

        push @lines, $line if $line;
    }

    return join( "\n", @lines ) . "\n";
}

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Damyan Ivanov L<dmn@debian.org>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

1;
