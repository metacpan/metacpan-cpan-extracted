##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Collection.pm
## Version v0.3.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/24
## Modified 2025/10/16
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Collection;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Array );
    use vars qw( $AUTOLOAD $VERSION );
    use Module::Generic::Null;
    use Scalar::Util ();
    use Wanted;
    use overload (
        'eq' => sub{ Scalar::Util::refaddr( $_[0] ) eq Scalar::Util::refaddr( $_[1] ) },
        '==' => sub{ Scalar::Util::refaddr( $_[0] ) eq Scalar::Util::refaddr( $_[1] ) },
        bool => sub{ $_[0] },
        fallback => 1,
    );
    our $AUTOLOAD;
    our $VERSION = 'v0.3.0';
};

use strict;
use warnings;

sub item { return( shift->index( @_ ) ); }

sub namedItem
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    for( @$self )
    {
        return( $_ ) if( $self->_can( $_ => 'id' ) && $_->id eq $name );
        return( $_ ) if( $self->_can( $_ => 'name' ) && $_->name eq $name );
    }
    if( want( 'OBJECT' ) )
    {
        return( Module::Generic::Null->new( @_ ) );
    }
    elsif( want( 'ARRAY' ) )
    {
        return( [] );
    }
    elsif( want( 'HASH' ) )
    {
        return( {} );
    }
    elsif( want( 'CODE' ) )
    {
        return( sub{ return; } );
    }
    elsif( want( 'REFSCALAR' ) )
    {
        return( \undef );
    }
    else
    {
        return;
    }
}

sub _can
{
    my $self = shift( @_ );
    no overloading;
    # Nothing provided
    return if( !scalar( @_ ) );
    return if( !defined( $_[0] ) );
    return if( !Scalar::Util::blessed( $_[0] ) );
    return( $_[0]->can( $_[1] ) );
}

# NOTE: AUTOLOAD
sub AUTOLOAD
{
    my( $meth ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    die( "No class function \"$meth\" exists in this package \"", __PACKAGE__, "\".\n" ) if( !defined( $self ) );
    return( $self->namedItem( $meth ) );
};

# To avoid being caught by AUTOLOAD
sub DESTROY {};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Collection - HTML Object DOM Collection

=head1 SYNOPSIS

    use HTML::Object::DOM::Collection;
    my $this = HTML::Object::DOM::Collection->new || die( HTML::Object::DOM::Collection->error, "\n" );

    my $html = <<EOT;
    <html>
        <head><title>Demo</title></head>
        <body>
            <form id="myForm">
                <input type="text" />
                <button>Ok</button>
            </form>
        </body>
    </html>
    EOT

    my( $elem1, $elem2 );
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html );
    # $doc->forms is an HTML::Object::DOM::Collection

    $elem1 = $doc->forms->[0];
    $elem2 = $doc->forms->item(0);

    say( $elem1 == $elem2 ); # returns: "1" (i.e. true)
    # or, similarly
    say( $elem1 eq $elem2 ); # returns: "1" (i.e. true)

    $elem1 = $doc->forms->myForm;
    $elem2 = $doc->forms->namedItem("myForm");

    say( $elem1 == $elem2 ); # returns: "1" (i.e. true)
    # or, similarly
    say( $elem1 eq $elem2 ); # returns: "1" (i.e. true)

    # This is possible under JavaScript, but not possible under perl
    # $elem1 = $doc->forms->[ 'named.item.with.periods' ];

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

The C<Collection> interface represents a generic collection (array-like object inheriting from L<Module::Generic::Array>) of a list of elements (in document order) and offers methods and properties for selecting from that list.

This is fundamentally different from L<HTML::Object::Collection>, which is used by L<HTML::Object::XQuery>

=head1 PROPERTIES

=head2 length

Returns the number of items in the collection.

=head1 METHODS

=head2 item

Provided with an integer representing an C<index> and this returns the specific L<node|HTML::Object::DOM::Node> at the given zero-based C<index> into the list. Returns C<undef> if the index is out of range.

This is also an alternative to accessing C<$collection->[$i]> (which instead returns C<undef> when C<$i> is out-of-bounds).

Example:

    my $c = $doc->images;   # This is an HTMLCollection
    my $img0 = $c->item(0); # You can use the item() method this way
    my $img1 = $c->[1];     # But this notation is easier and more common

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/item>

=head2 namedItem

Provided with a C<name> and this returns the specific L<node|HTML::Object::DOM::Node> whose C<ID> or, as a fallback, C<name> matches the string specified by C<name>. Matching by C<name> is only done as a last resort, only in HTML, and only if the referenced element supports the C<name> attribute. Returns C<undef> if no L<node|HTML::Object::DOM::Node> exists by the given C<name>.

An alternative to accessing C<$collection->[ $name ]> (which is possible in JavaScript, but not under perl).

Example:

    <div id="personal">
        <span name="title">Dr.</span>
        <span name="firstname">John</span>
        <span name="lastname">Doe</span>
    </div>

    my $container = $doc->getElementById('personal');
    # Returns the span element object with the name "title" if no such element exists undef is returned
    my $titleSpan = $container->children->namedItem('title');
    # The following variants return undefined instead of null if there's no element with a matching name or id
    # Not possible in perl!
    # my $firstnameSpan = $container->children->['firstname'];
    my $firstnameSpan = $container->children->[1];
    my $lastnameSpan = $container->children->lastname;

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/namedItem>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection>, L<HTML::Object::Collection>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
