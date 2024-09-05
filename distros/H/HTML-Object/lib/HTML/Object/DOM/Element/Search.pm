##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Search.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/11/05
## Modified 2023/11/05
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Search;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'search' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Search - HTML Object DOM Search Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Search;
    my $search = HTML::Object::DOM::Element::Search->new ||
        die( HTML::Object::DOM::Element::Search->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface represents a C<< <search> >> element and derives from the L<HTML::Object::DOM::Element> interface, but without implementing any additional properties or methods.

The C<< <search> >> HTML element is a container representing the parts of the document or application with form controls or other content related to performing a search or filtering operation. The C<< <search> >> element semantically identifies the purpose of the element's contents as having search or filtering capabilities. The search or filtering functionality can be for the website or application, the current web page or document, or the entire Internet or subsection thereof.

Example:

    <header>
        <h1>Movie website</h1>
        <search> 
            <form action="./search/">
                <label for="movie">Find a Movie</label> 
                <input type="search" id="movie" name="q" />
                <button type="submit">Search</button> 
            </form>
        </search> 
    </header>


=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Search |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation on search element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/search>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022-2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
