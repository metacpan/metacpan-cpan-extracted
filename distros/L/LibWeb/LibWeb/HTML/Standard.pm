#==============================================================================
# LibWeb::HTML::Standard -- An interface defining HTML display for libweb
#                           applications.

package LibWeb::HTML::Standard;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: Standard.pm,v 1.2 2000/07/19 20:31:57 ckyc Exp $

$VERSION = '0.02';

#-##############################
#  Use standard libraries.
use strict; 
use vars qw($VERSION @ISA);

#-##############################
# Use custom libraries.
require LibWeb::Core;

#-##############################
# Inheritance.
@ISA = qw(LibWeb::Core);

#-##############################
# Methods.
sub new {
    #
    # Params: $class , $rc_file, $error_object
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    # - $error_object is a reference to a perl object for printing out
    #   error/help message to users when error occurs.
    #
    # Usage: No, you don't use or ISA this class directly.  Use or ISA
    #        LibWeb::HTML::Default instead.
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;

    # Inherit instance variables from the base class.
    $self = $Class->SUPER::new( shift, shift );
    bless($self, $Class);
}

sub DESTROY {}

sub display {
    #
    # This is an interface describing how to implement this method.
    # Implementation is done at LibWeb::HTML::Default.
    #
    # Override base class method: LibWeb::Core::display().
    # Params: -content=>, [ -sheader=>, -lpanel=>, -rpanel=>, -header=>, -footer=> ].
    #
    # -content, -sheader, -lpanel, -rpanel, -header and -footer must be an ARRAY
    # ref. to elements which are scalar/SCALAR ref/ARRAY ref.
    # If the the elements are ARRAY ref., then the elements in that ARRAY ref. must
    # be scalar and NOT ref.
    #
    # -content default is lines read from $self->content().
    # -sheader default is lines read from $self->sheader().
    # -lpanel default is lines read from $self->lpanel().
    # -rpanel default is lines read from $self->rpanel().
    # -header default is lines read from $self->header().
    # -footer default is lines read from $self->footer().
    #
    # Return a scalar ref. to a formatted page in HTML format for display
    # to Web client.
    #
    return \("You should use or ISA LibWeb::HTML::Default instead.\n");
}

#================================================================================
# Site's HTML constructs: header, sub header, left panel, right panel and footer.
# They are interfaces and therefore not implemented.  LibWeb::HTML::Default
# implements these HTML constructs.

sub header {
    return [' '];
}

sub sheader {
    return [' '];
}

sub content {
    return [' '];
}

sub lpanel {
    return [' '];
}

sub rpanel {
    return [' '];
}

sub footer {
    return [' '];
}

1;
__DATA__

1;
__END__

=head1 NAME

LibWeb::HTML::Standard - An interface defining HTML display for libweb
applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

No non-standard Perl's library is required.

=back

=head1 ISA

=over 2

=item *

LibWeb::Core

=back

=head1 SYNOPSIS

This is an interface and actual implementation is done by
LibWeb::HTML::Default.

=head1 ABSTRACT

This is an interface describing how a HTML page should be displayed.
Please see L<LibWeb::HTML::Default> for the actual implementation.

The current version of LibWeb::HTML::Standard is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and are
available at

   http://leaps.sourceforge.net

=head1 DESCRIPTION

See L<LibWeb::HTML::Default>.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::HTML::Default>, L<LibWeb::HTML::Error>

=cut
