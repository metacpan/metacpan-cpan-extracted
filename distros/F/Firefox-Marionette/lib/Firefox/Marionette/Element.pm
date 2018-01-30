package Firefox::Marionette::Element;

use strict;
use warnings;

our $VERSION = '0.30';

sub new {
    my ( $class, $browser, %parameters ) = @_;
    my $element = bless {
        browser => $browser,
        %parameters
    }, $class;
    return $element;
}

sub uuid {
    my ($self) = @_;
    return $self->{ELEMENT};
}

sub browser {
    my ($self) = @_;
    return $self->{browser};
}

sub click {
    my ($self) = @_;
    return $self->browser()->click($self);
}

sub clear {
    my ($self) = @_;
    return $self->browser()->clear($self);
}

sub text {
    my ($self) = @_;
    return $self->browser()->text($self);
}

sub tag_name {
    my ($self) = @_;
    return $self->browser()->tag_name($self);
}

sub rect {
    my ($self) = @_;
    return $self->browser()->rect($self);
}

sub send_keys {
    my ( $self, $text ) = @_;
    return $self->browser()->send_keys( $self, $text );
}

sub attribute {
    my ( $self, $name ) = @_;
    return $self->browser()->attribute( $self, $name );
}

sub property {
    my ( $self, $name ) = @_;
    return $self->browser()->property( $self, $name );
}

sub css {
    my ( $self, $property_name ) = @_;
    return $self->browser()->css( $self, $property_name );
}

sub switch_to_frame {
    my ($self) = @_;
    return $self->browser()->switch_to_frame($self);
}

sub switch_to_shadow_root {
    my ($self) = @_;
    return $self->browser()->switch_to_shadow_root($self);
}

sub selfie {
    my ( $self, %extra ) = @_;
    return $self->browser()->selfie( $self, %extra );
}

sub is_enabled {
    my ($self) = @_;
    return $self->browser()->is_enabled($self);
}

sub is_selected {
    my ($self) = @_;
    return $self->browser()->is_selected($self);
}

sub is_displayed {
    my ($self) = @_;
    return $self->browser()->is_displayed($self);
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Firefox::Marionette::Element - Represents a Firefox element retrieved using the Marionette protocol

=head1 VERSION

Version 0.30

=head1 SYNOPSIS

    use Firefox::Marionette();
    use v5.10;

    my $firefox = Firefox::Marionette->new()->go('https://metacpan.org/');

    my $element = $firefox->find_element('//input[@id="search-input"]');

    $element->send('Test::More');

=head1 DESCRIPTION

This module handles the implementation of a Firefox Element using the Marionette protocol

=head1 SUBROUTINES/METHODS

=head2 new

returns a new L<element|Firefox::Marionette::Element>.

=head2 uuid

returns the browser generated UUID connected with this L<element|Firefox::Marionette::Element>.

=head2 browser

returns the L<browser|Firefox::Marionette> connected with the L<element|Firefox::Marionette::Element>.

=head2 click

sends a 'click' to the L<element|Firefox::Marionette::Element>.  The browser will wait for any page load to complete or the session's L<page timeout|Firefox::Marionette::Timeouts#page_load> duration to elapse before returning.

=head2 clear

clears any user supplied input from the L<element|Firefox::Marionette::Element>

=head2 text

returns the text that is contained by that L<element|Firefox::Marionette::Element> (if any)

=head2 tag_name

returns the relevant tag name.  For example 'a' or 'input'.

=head2 rect

returns the current L<position and size|Firefox::Marionette::Element::Rect> of the L<element|Firefox::Marionette::Element>

=head2 send_keys

accepts a scalar string as a parameter.  It sends the string to this L<element|Firefox::Marionette::Element>, such as filling out a text box. This method returns L<the browser|Firefox::Marionette> to aid in chaining methods.

=head2 switch_to_shadow_root

switches to this element's L<shadow root|https://www.w3.org/TR/shadow-dom/>

=head2 switch_to_frame

switches to this frame within the current window.

=head2 attribute 

accepts a scalar name a parameter.  It returns the initial value of the attribute with the supplied name. Compare with the current value returned by L<property|Firefox::Marionette::Element#property> method.

=head2 property

accepts a scalar name a parameter.  It returns the current value of the property with the supplied name. Compare with the initial value returned by L<attribute|Firefox::Marionette::Element#attribute> method.

=head2 css

accepts a scalar CSS property name as a parameter.  It returns the value of the computed style for that property.

=head2 selfie

returns a L<File::Temp|File::Temp> object containing a lossless PNG image screenshot of the L<element|Firefox::Marionette::Element>.

accepts the following optional parameters as a hash;

=over 4

=item * hash - return a SHA256 hex encoded digest of the PNG image rather than the image itself

=item * full - take a screenshot of the whole document unless the first L<element|Firefox::Marionette::Element> parameter has been supplied.

=item * scroll - scroll to the L<element|Firefox::Marionette::Element> supplied

=item * highlights - a reference to a list containing L<elements|Firefox::Marionette::Element> to draw a highlight around

=back

=head2 is_enabled

returns true or false if the element is enabled.

=head2 is_selected

returns true or false if the element is selected.

=head2 is_displayed

returns true or false if the element is displayed.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Firefox::Marionette::Element requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-firefox-marionette@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

David Dick  C<< <ddick@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018, David Dick C<< <ddick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic/perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
