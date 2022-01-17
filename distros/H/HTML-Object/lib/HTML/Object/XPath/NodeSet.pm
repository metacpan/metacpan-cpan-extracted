##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/NodeSet.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/05
## Modified 2021/12/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XPath::NodeSet;
BEGIN
{
    use strict;
    use warnings;
    # use parent qw( Module::Generic );
    use parent qw( Module::Generic::Array );
    use HTML::Object::XPath::Boolean;
    use overload (
        '""'   => \&to_literal,
        'bool' => \&to_boolean,
    );
    our $TRUE  = HTML::Object::XPath::Boolean->True;
    our $FALSE = HTML::Object::XPath::Boolean->False;
    our $BASE_CLASS = 'HTML::Object::XPath';
    our $DEBUG = 0;
    our $VERSION = 'v0.1.0';
};

sub new
{
    my $this = shift( @_ );
    return( bless( [] => ( ref( $this ) || $this ) ) );
}

sub append
{
    my $self = CORE::shift( @_ );
    my( $nodeset ) = @_;
    return( CORE::push( @$self, $nodeset->get_nodelist ) );
}

# uses array index starting at 1, not 0
sub get_node
{
    my $self = CORE::shift( @_ );
    my( $pos ) = @_;
    # $self->message( 3, "Returning value at $pos - 1 -> '", $self->[$pos-1], "' (", overload::StrVal( $self->[$pos-1] ), ")" ) if( $XML::XPathEngine::DEBUG );
    return( $self->[ $pos - 1 ] );
}

sub get_nodelist { return( @{$_[0]} ); }

sub getChildNodes
{
    my $self = CORE::shift( @_ );
    return( map{ $_->getChildNodes } @$self );
}

sub getElementById
{
    my $self = CORE::shift( @_ );
    return( map{ $_->getElementById } @$self );
}
       
sub getRootNode
{
    my $self = CORE::shift( @_ );
    return( $self->[0]->getRootNode );
}

sub new_literal { return( shift->_class_for( 'Literal' )->new( @_ ) ); }

sub new_number { return( shift->_class_for( 'Number' )->new( @_ ) ); }

sub pop
{
    my $self = CORE::shift( @_ );
    return( CORE::pop( @$self ) );
}

sub prepend
{
    my $self = CORE::shift( @_ );
    my( $nodeset ) = @_;
    return( CORE::unshift( @$self, $nodeset->get_nodelist ) );
}

sub push
{
    my $self = CORE::shift( @_ );
    my( @nodes ) = @_;
    return( CORE::push( @$self, @nodes ) );
}

sub remove_duplicates
{
    my $self = CORE::shift( @_ );
    my @unique;
    my $last_node = 0;
    foreach my $node ( @$self )
    { 
        CORE::push( @unique, $node ) unless( $node == $last_node );
        $last_node = $node;
    }
    @$self = @unique; 
    return( $self );
}

sub reverse
{
    my $self = CORE::shift( @_ );
    @$self = reverse( @$self );
    return( $self );
}

sub shift
{
    my $self = CORE::shift( @_ );
    return( CORE::shift( @$self ) );
}

sub size
{
    my $self = CORE::shift( @_ );
    return( scalar( @$self ) );
}

sub sort
{
    my $self = CORE::shift( @_ );
    @$self = CORE::sort { $a->cmp( $b ) } @$self;
    return( $self );
}

sub string_value
{
    my $self = CORE::shift( @_ );
    return( '' ) unless( @$self );
    return( $self->[0]->string_value );
}

sub string_values
{
    my $self = CORE::shift( @_ );
    return( map{ $_->string_value } @$self );
}

sub to_boolean
{
    my $self = CORE::shift( @_ );
    return( ( @$self > 0 ) ? $TRUE : $FALSE );
}

sub to_final_value
{
    my $self = CORE::shift( @_ );
    return( join( '', map{ $_->string_value } @$self ) );
}

sub to_literal
{
    my $self = CORE::shift( @_ );
    return( $self->new_literal( join( '', map{ $_->string_value } @$self ) ) );
}

sub to_number
{
    my $self = CORE::shift( @_ );
    return( $self->new_number( $self->to_literal ) );
}

sub unshift
{
    my $self = CORE::shift( @_ );
    my( @nodes ) = @_;
    return( CORE::unshift( @$self, @nodes ) );
}

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

HTML::Object::XPath::NodeSet - HTML Object XPath Node Set

=head1 SYNOPSIS

    use HTML::Object::XPath::NodeSet;
    my $set = HTML::Object::XPath::NodeSet->new || 
        die( HTML::Object::XPath::NodeSet->error, "\n" );

    my $results = $xp->find( '//someelement' );
    if( !$results->isa( 'HTML::Object::XPath::NodeSet' ) )
    {
        print( "Found $results\n" );
        exit;
    }
    
    foreach my $context ( $results->get_nodelist )
    {
        my $newresults = $xp->find( './other/element', $context );
        # ...
    }

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module contains an ordered list of L<nodes|HTML::Object::Element>. The nodes each take the same format as described in L<HTML::Object::XPath>.

=head1 METHODS

=head2 new

You should never have to create a new NodeSet object, as it is all done for you by L<HTML::Object::XPath>.

=head2 append

Given a C<nodeset>, this appends the list of nodes in C<nodeset> to the end of the current list.

=head2 get_node

Provided with an integer representing a C<position> and this returns the node at C<position>.

The node position in XPath is based at 1, not 0.

=head2 get_nodelist

Returns a list of nodes. See L<HTML::Object::XPath> for the format of the nodes.

=head2 getChildNodes

Returns a list of all elements' own child nodes by calling C<getChildNodes> on each one of them.

=head2 getElementById

Returns a list of all elements' own id by calling C<getElementById> on each one of them.

=head2 getRootNode

Returns the first element's value of C<getRootNode>

=head2 new_literal

Returns a new L<HTML::Object::XPath::Literal> object, passing it whatever arguments was provided.

=head2 new_number

Returns a new L<HTML::Object::XPath::Number> object, passing it whatever arguments was provided.

=head2 pop

Equivalent to perl's L<perlfunc/pop> function. This removes the last element from our stack and returns it.

=head2 prepend

Given a C<nodeset>, prepends the list of nodes in C<nodeset> to the front of the current list.

=head2 push

Provided with a list of nodes and this will add them to the stack in this object.

Equivalent to perl's L<perlfunc/push> function.

=head2 remove_duplicates

This removes any duplicates there might be in our internal list of elements.

=head2 reverse

This method reverse the order of the elements in our internal list of elements.

=head2 shift

Equivalent to perl's L<perlfunc/shift> function.

=head2 size

Returns the number of nodes in the L<HTML::Object::XPath::NodeSet>.

=head2 sort

This method sorts all the elements by comparing them to one another using C<cmp>

=head2 string_value

Returns the string-value of the first node in the list.

See the L<HTML::Object::XPath> specification for what "string-value" means.

=head2 string_values

Returns a list of the string-values of all the nodes in the list.

=head2 to_boolean

Returns L<true|HTML::Object::XPath::Boolean> if there are elements in our internal array of elements, or L<false|HTML::Object::XPath::Boolean> otherwise.

=head2 to_final_value

Returns a string resulting from the concatenation of each elements' string value.

=head2 to_literal

Returns the concatenation of all the string-values of all the nodes in the list.

=head2 to_number

Returns a new L<number object|HTML::Object::XPath::Number> from the value returned from L</to_literal>

=head2 unshift

Provided with a list of nodes and this will add them at the top of the stack in this object.

Equivalent to perl's L<perlfunc/unshift> function.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
