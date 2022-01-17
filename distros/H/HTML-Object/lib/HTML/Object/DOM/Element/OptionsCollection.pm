##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/OptionsCollection.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/05
## Modified 2022/01/05
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::OptionsCollection;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Collection );
    our $VERSION = 'v0.1.0';
};

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::OptionsCollection - HTML Object DOM Options Collection

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::OptionsCollection;
    my $list = HTML::Object::DOM::Element::OptionsCollection->new || 
        die( HTML::Object::DOM::Element::OptionsCollection->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<OptionsCollection> interface represents a collection of L<option HTML elements|HTML::Object::DOM::Element::Option> (in document order) and offers methods and properties for selecting from the list as well as optionally altering its items. This object is returned only by the L<options property of select|HTML::Object::DOM::Element/options>.

=head1 INHERITANCE

    +-------------------------------+     +-----------------------------------------------+
    | HTML::Object::DOM::Collection | --> | HTML::Object::DOM::Element::OptionsCollection |
    +-------------------------------+     +-----------------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Collection>

=head2 length

Read-only.

This returns the number of options contained in the select element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionsCollection/length>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Collection>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptionsCollection>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
