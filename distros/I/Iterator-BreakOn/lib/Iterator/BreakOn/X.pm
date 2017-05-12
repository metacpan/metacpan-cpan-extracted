package Iterator::BreakOn::X;
use strict;
use warnings;
use Carp;

our $VERSION = '0.2';

use Exception::Class(
    'Iterator::BreakOn::X' => {
        description =>  'Parent class',
    },
    'Iterator::BreakOn::X::datasource' => {
        isa         =>  'Iterator::BreakOn::X',
        description =>  'fatal error in next method of datasource',
    },

    'Iterator::BreakOn::X::missing' => {
        isa         =>  'Iterator::BreakOn::X',
        description =>  'missing required parameter',
        fields      =>  [ 'parameter' ],
    },

    'Iterator::BreakOn::X::getmethod' => {
        isa         =>  'Iterator::BreakOn::X',
        description =>  "object can't use the user supplied get method",
        fields      =>  [ 'get_method' ],
    },

    'Iterator::BreakOn::X::invalid_event' => {
        isa         =>  'Iterator::BreakOn::X',
        description =>  'received an invalid name for an event',
        fields      =>  [ 'name' ],
    },        

    'Iterator::BreakOn::X::csvfail' => {
        isa         =>  'Iterator::BreakOn::X',
        description =>  'fatal error in Text::CSV package',
    },

);

sub full_message {
    my  $self   =   shift;
    my  $msg    =      $self->message() 
                    || $self->description() 
                    || 'unknown error';

    return "fatal error: ${msg}";
}

1;
__END__
=pod

=head1 NAME

Iterator::BreakOn::X - Declare exception classes for Iterator::BreakOn

=head1 SYNOPSIS

	package Iterator::BreakOn;

    use Iterator::BreakOn::Exceptions;

    do {
        Iterator::BreakOn::X->thrown('unknown error' );
    } if ($fatal_error);

=head1 DESCRIPTION

This module declare a exception classes hierarchies for use on the
Iterator::BreakOn package.

=head1 DIAGNOSTICS

This is the list of exceptions:

=over

=item Iterator::BreakOn::X::missing

Raise when a required parameter (i.e. datasource) is missing. Not recoverable.

=item Iterator::BreakOn::X::datasource 

Raise when the next method fails.

=item Iterator::BreakOn::X::getmethod

Raise when the user supplied get method is not valid.

=item Iterator::BreakOn::X::invalid_event

Raise when an event object receives a invalid name.

=item Iterator::BreakOn::X::csvfail

Detected a fatal error in C<Text::CSV> package.

=back

=head1 DEPENDENCIES

=over

=item L<Exception::Class>

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author.
Patches are welcome.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 <Victor Moral>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

