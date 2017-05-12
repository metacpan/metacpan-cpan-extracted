package IkiWiki::Plugin::syntax::gettext;
use base qw(Exporter);
use strict;
use warnings;
use Carp;
use utf8;

our $VERSION    =   '0.1';
our @EXPORT     =   qw(gettext);

sub import {
    my  $package    =   (caller) [0];

    # try to export a gettext function into the caller's namespace
    eval "${package}::gettext('')";

    if ($@) {
        __PACKAGE__->export_to_level(1, $package, @EXPORT);
    }
}

sub gettext {
    return shift;
}

1;
__END__

=head1 NAME

IkiWiki::Plugin::syntax::gettext - Fake gettext function 

=head1 VERSION

This documentation refers to IkiWiki::Plugin::syntax::gettext version 0.1

=head1 SYNOPSIS

    package IkiWiki::Plugin::syntax:XXXX;

    use IkiWiki;
	use IkiWiki::Plugin::syntax::gettext;

    ....
        my $text = gettext('Hola');

=head1 DESCRIPTION

This module provides a fake gettext function in case of use a IkiWiki old version.

=head1 SUBROUTINES/METHODS

=head2 gettext( )

This function returns the first parameter received.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author.
Patches are welcome.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 "Víctor Moral" <victor@taquiones.net>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or any later version.


This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.


You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 US

