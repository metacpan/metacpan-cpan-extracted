##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Root.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/04
## Modified 2021/12/04
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XPath::Root;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $BASE_CLASS = 'HTML::Object::XPath';
    our $DEBUG = 0;
    our $VERSION = 'v0.1.0';
};

sub new
{
    my $this = shift( @_ );
    my $str  = shift( @_ );
    return( bless( \$str => ( ref( $this ) || $this ) ) );
}

sub as_string { return; }

sub as_xml { return( "<Root/>\n" ); }

sub evaluate
{
    my $self = shift( @_ );
    my $nodeset = shift( @_ );
    
    # must only ever occur on 1 node
    die "Can't go to root on > 1 node!" unless $nodeset->size == 1;
    # return( $self->error( "Can't go to root on > 1 node!" ) ) unless( $nodeset->size == 1 );
    
    my $newset = $self->new_nodeset;
    $self->message( 3, "Calling ", overload::StrVal( $nodeset ), "->get_node(1)->getRootNode()" );
    # $newset->push($nodeset->get_node(1)->getRootNode());
    my $node = $nodeset->get_node(1);
    $self->message( 3, "Node retrieved is '$node' (", $node->as_string, "), calliing getRootNode() with it." );
    # $self->message( 3, "Node retrieved is '$node', calliing getRootNode() with it." );
    # $node->debug(4);
    $self->message( 3, "Does $node have a getRootNode method? ", $node->can( 'getRootNode' ) ? 'yes' : 'no' );
    my $rootNode = $node->getRootNode();
    $self->message( 3, "Root node is '$rootNode' (", $rootNode->as_string, ")" );
    $newset->push( $rootNode );
    $self->message( 3, "Returning new set '$newset' (", overload::StrVal( $newset ), ")" );
    return( $newset );
}

sub new_nodeset { return( shift->_class_for( 'NodeSet' )->new( @_ ) ); }

sub _class_for
{
    my( $self, $mod ) = @_;
    eval( "require ${BASE_CLASS}\::${mod};" );
    die( $@ ) if( $@ );
    ${"${BASE_CLASS}\::${mod}\::DEBUG"} = $DEBUG;
    return( "${BASE_CLASS}::${mod}" );
}

1;

__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath::Root - HTML Object

=head1 SYNOPSIS

    use HTML::Object::XPath::Root;
    my $root = HTML::Object::XPath::Root->new || 
        die( HTML::Object::XPath::Root->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module represents a root element, which is the top element.

=head1 CONSTRUCTOR

=head2 new

Provided with a string, and this returns a new L<HTML::Object::XPath::Root> object.

=head1 METHODS

=head2 as_string

Returns C<undef> in scalar context and an empty list in list context.

=head2 as_xml

Returns C<<Root/>>

=head2 evaluate

Provided with a L<node set|HTML::Object::XPath::NodeSet> object and this the first element in the node set, get its root node and return a new L<set|HTML::Object::XPath::NodeSet> with the node as its sole element.

=head2 new_nodeset

Returns a new L<HTML::Object::XPath::NodeSet> passing it whatever argument was provided.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
