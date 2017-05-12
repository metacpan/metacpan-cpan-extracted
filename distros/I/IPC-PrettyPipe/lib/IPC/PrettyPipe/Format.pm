# --8<--8<--8<--8<--
#
# Copyright (C) 2014 Smithsonian Astrophysical Observatory
#
# This file is part of IPC::PrettyPipe
#
# IPC::PrettyPipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package IPC::PrettyPipe::Format;

## no critic (ProhibitAccessOfPrivateData)

use Moo::Role;
use Try::Tiny;
use Module::Load;

with 'MooX::Attributes::Shadow::Role';

requires 'copy_into';

# IS THIS REALLY NEEDED?????  this will convert an attribute with a
# an undef value into a switch.
#
# undefined values are the same as not specifying a value at all
if ( 0 ) {
around BUILDARGS => sub {

    my ( $orig, $class )  = ( shift, shift );

    my $attrs = $class->$orig( @_ );

    delete @{$attrs}{ grep { ! defined $attrs->{$_} } keys %$attrs };

    return $attrs;
};
}

sub _copy_attrs {

    my ( $from, $to ) = ( shift, shift );

    for my $attr ( @_ ) {


        next unless $from->${\"has_$attr"};

        try {
            if ( defined( my $value = $from->$attr ) ) {

                $to->$attr( $value );

            }

            else {

                $to->${\"clear_$attr"}

            }
        }
        catch {

            croak(
                "unable to copy into or clear attribute $attr in object of type ",
                ref $to,
                ": $_\n"
            );
        };

    }

    return;
}


sub copy_from {

    $_[1]->copy_into( $_[0] );

    return;
}


sub clone {

    my $class = ref($_[0]);
    load $class;

    my $clone = $class->new;

    $_[0]->copy_into( $clone );

    return $clone;
}

sub new_from_attrs {

    my $class = shift;
    load $class;

    return $class->new( $class->xtract_attrs( @_ ) );
}

sub new_from_hash {

    my $contained = shift;
    my $hash = pop;

    my $container = shift || caller();

    load $contained;

    my $shadowed = $contained->shadowed_attrs( $container );

    my %attr;
    while( my ( $alias, $orig ) = each %{ $shadowed } ) {

	$attr{$orig} = $hash->{$alias} if exists $hash->{$alias};

    }

    return $contained->new( \%attr );
}

1;
