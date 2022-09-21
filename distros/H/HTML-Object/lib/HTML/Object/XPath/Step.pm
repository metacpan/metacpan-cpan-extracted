##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Step.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/05
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XPath::Step;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $BASE_CLASS $DEBUG $VERSION );
    use constant {
        # Full name
        TEST_QNAME       => 0,
        # NCName:*
        TEST_NCWILD      => 1,
        # *
        TEST_ANY         => 2,
        # @ns:attrib
        TEST_ATTR_QNAME  => 3,
        # @nc:*
        TEST_ATTR_NCWILD => 4,
        # @*
        TEST_ATTR_ANY    => 5,
        # comment()
        TEST_NT_COMMENT  => 6,
        # text()
        TEST_NT_TEXT     => 7,
        # processing-instruction()
        TEST_NT_PI       => 8,
        # node()
        TEST_NT_NODE     => 9,
    };
    our $BASE_CLASS = 'HTML::Object::XPath';
    our $DEBUG = 0;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    # HTML::Object::XPath class
    $self->{pp} = shift( @_ );
    $self->{axis} = shift( @_ );
    $self->{test} = shift( @_ );
    $self->{literal} = shift( @_ );
    $self->{predicates} = [];
    $self->{axis_method} = 'axis_' . $self->{axis};
    $self->{axis_method} =~ tr/-/_/;
    # my( $pp, $axis, $test, $literal) = @_;
    my $axis_method = "axis_$self->{axis}";
    $axis_method =~ tr/-/_/;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $string = $self->{axis} . '::';
    my $test = $self->{test};
    if( $test == TEST_NT_PI )
    {
        $string .= 'processing-instruction(';
        if( $self->{literal}->value )
        {
            $string .= $self->{literal}->as_string;
        }
        $string .= ')';
    }
    elsif ($test == TEST_NT_COMMENT )
    {
        $string .= 'comment()';
    }
    elsif ($test == TEST_NT_TEXT )
    {
        $string .= 'text()';
    }
    elsif ($test == TEST_NT_NODE )
    {
        $string .= 'node()';
    }
    elsif ($test == TEST_NCWILD || $test == TEST_ATTR_NCWILD )
    {
        $string .= $self->{literal} . ':*';
    }
    else
    {
        $string .= $self->{literal};
    }
    
    foreach( @{$self->{predicates}} )
    {
        next unless( defined( $_ ) );
        $string .= '[' . $_->as_string . ']';
    }
    return( $string );
}

sub as_xml
{
    my $self = shift( @_ );
    my $string = "<Step>\n";
    $string .= "<Axis>" . $self->{axis} . "</Axis>\n";
    my $test = $self->{test};
    
    $string .= "<Test>";
    
    if( $test == TEST_NT_PI )
    {
        $string .= '<processing-instruction';
        if( $self->{literal}->value )
        {
            $string .= '>';
            $string .= $self->{literal}->as_string;
            $string .= '</processing-instruction>';
        }
        else
        {
            $string .= '/>';
        }
    }
    elsif( $test == TEST_NT_COMMENT )
    {
        $string .= '<comment/>';
    }
    elsif( $test == TEST_NT_TEXT )
    {
        $string .= '<text/>';
    }
    elsif( $test == TEST_NT_NODE )
    {
        $string .= '<node/>';
    }
    elsif( $test == TEST_NCWILD || $test == TEST_ATTR_NCWILD )
    {
        $string .= '<namespace-prefix>' . $self->{literal} . '</namespace-prefix>';
    }
    else
    {
        $string .= '<nametest>' . $self->{literal} . '</nametest>';
    }
    $string .= "</Test>\n";
    
    foreach( @{$self->{predicates}} )
    {
        next unless( defined( $_ ) );
        $string .= "<Predicate>\n" . $_->as_xml() . "</Predicate>\n";
    }
    $string .= "</Step>\n";
    return( $string );
}

sub axis { return( shift->_set_get_scalar( 'axis', @_ ) ); }

sub axis_ancestor
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    my $parent = $context->getParentNode;

#     START:
#     return( $results ) unless( $parent );
#     if( $self->node_test( $parent ) )
#     {
#         $results->push( $parent );
#     }
#     $parent = $parent->getParentNode;
#     goto( START );
    while( $parent )
    {
        if( $self->node_test( $parent ) )
        {
            $results->push( $parent );
        }
        $parent = $parent->getParentNode;
    }
    return( $results );
}

sub axis_ancestor_or_self
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    
#     START:
#     return $results unless $context;
#     if( $self->node_test( $context ) )
#     {
#         $results->push( $context );
#     }
#     $context = $context->getParentNode;
#     goto START;
    while( $context )
    {
        if( $self->node_test( $context ) )
        {
            $results->push( $context );
        }
        $context = $context->getParentNode;
    }
    return( $results );
}

sub axis_attribute
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    
    foreach my $attrib ( @{$context->getAttributes} )
    {
        if( $self->test_attribute( $attrib ) )
        {
            $results->push( $attrib );
        }
    }
}

sub axis_child
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    if( $self->debug )
    {
        my( $p, $f, $l ) = caller;
    }
    my $children = $context->getChildNodes;
    
    foreach my $node ( @{$context->getChildNodes} )
    {
        if( $self->node_test( $node ) )
        {
            $results->push( $node );
        }
    }
}

sub axis_descendant
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;

    my @stack = $context->getChildNodes;

    while( @stack )
    {
        my $node = shift( @stack );
        if( $self->node_test( $node ) )
        {
            $results->push( $node );
        }
        else
        {
        }
        unshift( @stack, $node->getChildNodes );
    }
}

sub axis_descendant_or_self
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    
    my @stack = ( $context );

    while( @stack )
    {
        my $node = shift( @stack );
        if( $self->node_test( $node ) )
        {
            $results->push( $node );
        }
        # warn "node is a ", ref( $node);
        unshift( @stack, $node->getChildNodes );
    }
}

sub axis_following 
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;

    my $elt = $context->getNextSibling || _next_sibling_of_an_ancestor_of( $context );
    while( $elt )
    {
        if( $self->node_test( $elt ) )
        {
            $results->push( $elt );
        }
        $elt = $elt->getFirstChild || $elt->getNextSibling || _next_sibling_of_an_ancestor_of( $elt );
    }
}

sub axis_following_sibling
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;

    # warn "in axis_following_sibling";
    while( $context = $context->getNextSibling )
    {
        if( $self->node_test( $context ) )
        {
            $results->push( $context );
        }
    }
}

sub axis_method { return( shift->_set_get_scalar( 'axis_method', @_ ) ); }

sub axis_namespace
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    
    return( $results ) unless( $context->isElementNode );
    foreach my $ns ( @{$context->getNamespaces} )
    {
        if( $self->test_namespace( $ns ) )
        {
            $results->push( $ns );
        }
    }
}

sub axis_parent
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    
    my $parent = $context->getParentNode;
    return( $results ) unless( $parent );
    if( $self->node_test( $parent ) )
    {
        $results->push( $parent );
    }
}

sub axis_preceding
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;

    my $elt = $context->getPreviousSibling || _previous_sibling_of_an_ancestor_of( $context );
    while( $elt )
    {
        if( $self->node_test( $elt ) )
        {
            $results->push( $elt );
        }
        $elt = $elt->getLastChild || $elt->getPreviousSibling || _previous_sibling_of_an_ancestor_of( $elt );
    }
}

sub axis_preceding_sibling
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    while( $context = $context->getPreviousSibling )
    {
        if( $self->node_test( $context ) )
        {
            $results->push( $context );
        }
    }
}

sub axis_self
{
    my $self = shift( @_ );
    my( $context, $results ) = @_;
    
    if( $self->node_test( $context ) )
    {
        $results->push( $context );
    }
}

sub evaluate
{
    my $self = shift( @_ );
    # context nodeset
    my $from = shift( @_ );

    if( $from && !$from->isa( 'HTML::Object::XPath::NodeSet' ) )
    {
        my $from_nodeset = $self->new_nodeset();
        $from_nodeset->push( $from );
        $from = $from_nodeset;
    }
    # warn "Step::evaluate called with ", $from->size, " length nodeset\n";
    
    my $saved_context = $self->{pp}->_get_context_set;
    my $saved_pos = $self->{pp}->_get_context_pos;
    $self->{pp}->_set_context_set( $from );
    
    my $initial_nodeset = $self->new_nodeset();
    
    # See spec section 2.1, paragraphs 3,4,5:
    # The node-set selected by the location step is the node-set
    # that results from generating an initial node set from the
    # axis and node-test, and then filtering that node-set by
    # each of the predicates in turn.
    
    # Make each node in the nodeset be the context node, one by one
    for( my $i = 1; $i <= $from->size; $i++ )
    {
        $self->{pp}->_set_context_pos( $i );
        if( $self->debug )
        {
            my $this_node = $from->get_node( $i );
        }
        $initial_nodeset->append( $self->evaluate_node( $from->get_node( $i ) ) );
    }
    
    # warn "Step::evaluate initial nodeset size: ", $initial_nodeset->size, "\n";
    
    $self->{pp}->_set_context_set( $saved_context );
    $self->{pp}->_set_context_pos( $saved_pos );
    return( $initial_nodeset );
}

# Evaluate the step against a particular node
sub evaluate_node
{
    my $self = shift( @_ );
    my $context = shift( @_ );
    # warn "Evaluate node: $self->{axis}\n";
    # warn "Node: ", $context->[node_name], "\n";
    my $method = $self->{axis_method};
    
    my $results = $self->new_nodeset();
    no strict 'refs';
    eval{ $self->$method( $context, $results ); };
    if( $@ )
    {
        die( "axis $method not implemented [$@]\n" );
    }
    
    # warn("results: ", join('><', map {$_->string_value} @$results), "\n");
    # filter initial nodeset by each predicate
    foreach my $predicate ( @{$self->{predicates}} )
    {
        $results = $self->filter_by_predicate( $results, $predicate );
    }
    return( $results );
}

sub filter_by_predicate
{
    my $self = shift( @_ );
    my( $nodeset, $predicate ) = @_;
    
    # See spec section 2.4, paragraphs 2 & 3:
    # For each node in the node-set to be filtered, the predicate Expr
    # is evaluated with that node as the context node, with the number
    # of nodes in the node set as the context size, and with the
    # proximity position of the node in the node set with respect to
    # the axis as the context position.
    # use ref because nodeset has a bool context
    if( !ref( $nodeset ) )
    {
        die( "No nodeset!!!" );
    }
    
    # warn "Filter by predicate: $predicate\n";
    
    my $newset = $self->new_nodeset();

    for( my $i = 1; $i <= $nodeset->size; $i++ )
    {
        # set context set each time 'cos a loc-path in the expr could change it
        $self->{pp}->_set_context_set( $nodeset );
        $self->{pp}->_set_context_pos( $i );
        my $result = $predicate->evaluate( $nodeset->get_node( $i ) );
        if( $result->isa( 'HTML::Object::XPath::Boolean' ) )
        {
            if( $result->value )
            {
                $newset->push( $nodeset->get_node( $i ) );
            }
        }
        elsif( $result->isa( 'HTML::Object::XPath::Number' ) )
        {
            if( $result->value == $i )
            {
                $newset->push( $nodeset->get_node( $i ) );
                last;
            }
        }
        else
        {
            if( $result->to_boolean->value )
            {
                $newset->push( $nodeset->get_node( $i ) );
            }
        }
    }
    return( $newset );
}

sub literal { return( shift->_set_get_scalar( 'literal', @_ ) ); }

sub new_nodeset { return( shift->_class_for( 'NodeSet' )->new( @_ ) ); }

sub node_test
{
    my $self = shift( @_ );
    my $node = shift( @_ );
    my $test_types = [qw( TEST_QNAME TEST_NCWILD TEST_ANY TEST_ATTR_QNAME TEST_ATTR_NCWILD TEST_ATTR_ANY TEST_NT_COMMENT TEST_NT_TEXT TEST_NT_PI TEST_NT_NODE )];
    
    # if node passes test, return true
    my $test = $self->{test};

    return(1) if( $test == TEST_NT_NODE );

    if( $test == TEST_ANY )
    {
        return(1) if( $node->isElementNode && defined( $node->getName ) );
    }
        
    # local $^W;
    if( $test == TEST_NCWILD )
    {
        return unless( $node->isElementNode );
        return( $self->_match_ns( $node ) );
    }
    elsif( $test == TEST_QNAME )
    {
        return unless( $node->isElementNode );
        if( $self->{literal} =~ /:/ || $self->{pp}->{strict_namespaces} )
        {
            my( $prefix, $name ) = _name2prefix_and_local_name( $self->{literal} );
            return(1) if( ( $name eq $node->getLocalName ) && $self->_match_ns( $node ) );
        }
        else
        {
            return(1) if( $node->getName eq $self->{literal} );
        }
    }
    elsif( $test == TEST_NT_TEXT )
    {
        return(1) if( $node->isTextNode );
    }
    elsif( $test == TEST_NT_COMMENT )
    {
        return(1) if( $node->isCommentNode );
    }
    elsif( $test == TEST_NT_PI && !$self->{literal} )
    {
        return(1) if( $node->isPINode );
    }
    elsif( $test == TEST_NT_PI )
    {
        return unless( $node->isPINode );
        if( my $val = $self->{literal}->value )
        {
            return(1) if( $node->getTarget eq $val );
        }
        else
        {
            return(1);
        }
    }
    # fallthrough returns false
    return;
}

sub test { return( shift->_set_get_scalar( 'test', @_ ) ); }

sub test_attribute
{
    my $self = shift( @_ );
    my $node = shift( @_ );
    my $test = $self->{test};
    return(1) if( ( $test == TEST_ATTR_ANY ) || ( $test == TEST_NT_NODE ) );

    if( $test == TEST_ATTR_NCWILD )
    {
        return(1) if( $self->_match_ns( $node ) );
    }
    elsif( $test == TEST_ATTR_QNAME )
    {
        if( $self->{literal} =~ /:/ )
        {
            my( $prefix, $name ) = _name2prefix_and_local_name( $self->{literal} );
            return(1) if( ( $name eq $node->getLocalName ) && ( $self->_match_ns( $node ) ) );
        }
        else
        {
            return(1) if( $node->getName eq $self->{literal} );
        }
    }
    # fallthrough returns false
    return;
}

sub test_namespace
{
    my $self = shift( @_ );
    my $node = shift( @_ );
    # Not sure if this is correct. The spec seems very unclear on what
    # constitutes a namespace test... bah!
    my $test = $self->{test};
    # True for all nodes of principal type
    return(1) if( $test == TEST_ANY );
    
    if( $test == TEST_ANY )
    {
        return(1);
    }
    elsif( $self->{literal} eq $node->getExpanded )
    {
        return(1);
    }
    return;
}

sub _class_for
{
    my( $self, $mod ) = @_;
    eval( "require ${BASE_CLASS}\::${mod};" );
    die( $@ ) if( $@ );
    # ${"${BASE_CLASS}\::${mod}\::DEBUG"} = $DEBUG;
    eval( "\$${BASE_CLASS}\::${mod}\::DEBUG = " . ( $DEBUG // 0 ) );
    return( "${BASE_CLASS}::${mod}" );
}

sub _match_ns
{
    my( $self, $node ) = @_;
    my $pp = $self->{pp};
    my $prefix = _name2prefix( $self->{literal} );
    my( $match_ns, $node_ns );
    if( $pp->{uses_namespaces} || $pp->{strict_namespaces} )
    {
        $match_ns = $pp->get_namespace( $prefix );
        if( $match_ns || $pp->{strict_namespaces} )
        {
            $node_ns = $node->getNamespace->getValue;
        }
        # non-standard behaviour: if the query prefix is not declared
        # compare the 2 prefixes
        else
        {
            $match_ns = $prefix;
            $node_ns  = _name2prefix( $node->getName );
        }
    }
    else
    {
        $match_ns = $prefix;
        $node_ns  = _name2prefix( $node->getName );
    }
    return( $match_ns eq $node_ns );
}

sub _name2prefix
{
    my $name = shift( @_ );
    if( $name =~ m{^(.*?):} )
    {
        return( $1 );
    }
    else
    {
        return( '' );
    }
}

sub _name2prefix_and_local_name
{
    my $name = shift( @_ );
    return( $name =~ /:/ ? split( ':', $name, 2 ) : ( '', $name ) );
}

sub _next_sibling_of_an_ancestor_of
{
    my $elt = shift( @_ );
    # NOTE: return 0 instead of undef ?
    $elt = $elt->getParentNode || return;
    my $next_elt;
    while( !( $next_elt= $elt->getNextSibling ) )
    {
        $elt= $elt->getParentNode;  
        return unless( $elt && $elt->can( 'getNextSibling' ) );
    }
    return( $next_elt );
}

sub _previous_sibling_of_an_ancestor_of
{
    my $elt = shift( @_ );
    # NOTE: Should we return 0 instead of undef ?
    $elt = $elt->getParentNode || return;
    my $next_elt;
    while( !( $next_elt = $elt->getPreviousSibling ) )
    {
        $elt = $elt->getParentNode;
        # so we do not have to write a getPreviousSibling 
        return unless( $elt->getParentNode );
    }
    return( $next_elt );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath::Step - HTML Object XPath Step

=head1 SYNOPSIS

    use HTML::Object::XPath::Step;
    my $this = HTML::Object::XPath::Step->new || die( HTML::Object::XPath::Step->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module represents a XPath step.

=head1 CONSTRUCTOR

=head2 new

It takes a L<HTML::Object::XPath> object, an C<axis>, a C<test> name and a C<literal> and returns a new L<HTML::Object::XPath::Step> object.

=head1 METHODS

=head2 as_string

Returns a string representation of the step.

=head2 as_xml

Returns a string representation of the step as xml.

=head2 axis

Set or get the axis.

=head2 axis_ancestor

Provided with a L<context|HTML::Object::Element> and a L<HTML::Object::XPath::NodeSet> object, and this will add each parent until there are none found anymore, to the resulting node set and returns it.

=head2 axis_ancestor_or_self

This performs a similar function as L</axis_ancestor>, except it test each node and add it to the result, before going up to the next parent.

=head2 axis_attribute

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will add each of its attribute object to the resulting node set and returns it.

=head2 axis_child

Provided with a L<context|HTML::Object::Element> and a L<HTML::Object::XPath::NodeSet> object, and this will add each of the children's node and returns the resulting set.

=head2 axis_descendant

Provided with a L<context|HTML::Object::Element> and a L<HTML::Object::XPath::NodeSet> object, and this will add each of the children's node and its children after that until there is none and returns the resulting set.

=head2 axis_descendant_or_self

This performs a similar function as L</axis_ancestor>, except it test each node and add it to the result, before going down to the next children's nodes.

=head2 axis_following

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will get all the first child in the tree of the element's next sibling.

=head2 axis_following_sibling

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will add its next sibling to the resulting node set and its sibling sibling and so forth. It returns the resulting node set.

=head2 axis_method

Set or get the axis method.

=head2 axis_namespace

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will add each namespace of the C<context> into the result.

=head2 axis_parent

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will psh to the result array the context's parent, if any. It returns the resulting node set.

=head2 axis_preceding

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will get all the last child of the previous sibling hierarchy. It returns the resulting node set.

=head2 axis_preceding_sibling

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will all the previous siblings recursively. It returns the resulting node set.

=head2 axis_self

Provided with a L<context|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will return the node set with the provided C<context> added to it.

=head2 evaluate

Provided with a L<node set|HTML::Object::XPath::NodeSet> or a L<node|HTML::Object::Element> and this will evaluate each element of the nod set by calling L</evaluate_node> for each of them and adding the result to a new node set and returns it.

=head2 evaluate_node

Provided with a L<context|HTML::Object::Element> and this will evaluate the context, by calling the method set in L</axis_method> and passing it the C<context> and a new L<node set|HTML::Object::XPath::NodeSet>. It returns the new node set.

=head2 filter_by_predicate

Provided with a L<node set|HTML::Object::XPath::NodeSet> and a predicate and this will evaluate each element in the node set with the predicate. Based on the result, it will add the node evaluated to a new node set that is returned.

=head2 literal

Set or get the literal value.

=head2 new_nodeset

Returns a new L<node set object|HTML::Object::XPath::NodeSet> passing it whatever arguments was provided.

=head2 node_test

Provided with a L<node|HTML::Object::Element> and this will test it based on the test set for this step and return a certain value; most of the time a simple true value.

=head2 test

Set or get the test name (or actually number) to be performed.

=head2 test_attribute

Provided with a L<node|HTML::Object::Element> and this will test its attribute.

=head2 test_namespace

Provided with a L<node|HTML::Object::Element> and this will test its name space.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
