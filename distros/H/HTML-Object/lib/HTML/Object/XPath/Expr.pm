##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Expr.pm
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
package HTML::Object::XPath::Expr;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $TRUE $FALSE $BASE_CLASS $DEBUG $VERSION );
    use HTML::Object::XPath::Boolean;
    our $TRUE  = HTML::Object::XPath::Boolean->True;
    our $FALSE = HTML::Object::XPath::Boolean->False;
    our $BASE_CLASS = 'HTML::Object::XPath';
    our $DEBUG = 0;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    # XPath Parser -> HTML::Object::XPath
    my $pp   = shift( @_ );
    $self->{pp} = $pp;
    $self->{predicates} = [];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    # Use of uninitialized value! grrr
    # local $^W;
    my $string = '(' . $self->{lhs}->as_string;
    $string .= ' ' . $self->{op} . ' ' if( defined( $self->{op} ) );
    $string .= $self->{rhs}->as_string if( defined( $self->{rhs} ) );
    $string .= ')';
    foreach my $predicate ( @{$self->{predicates}} )
    {
        $string .= '[' . $predicate->as_string . ']';
    }
    return( $string );
}

sub as_xml
{
    my $self = shift( @_ );
    # Use of uninitialized value! grrr
    # local $^W;
    my $string;
    if( defined( $self->{op} ) )
    {
        $string .= $self->op_xml();
    }
    else
    {
        $string .= $self->{lhs}->as_xml();
    }
    foreach my $predicate ( @{$self->{predicates}} )
    {
        $string .= "<Predicate>\n" . $predicate->as_xml() . "</Predicate>\n";
    }
    return( $string );
}

sub evaluate
{
    my $self = shift( @_ );
    # HTML::Object::XPath::NodeSet
    my $node = shift( @_ );
    
    # If there's an op, result is result of that op.
    # If no op, just resolve Expr
    
#    warn "Evaluate Expr: ", $self->as_string, "\n";
    
    my $results;
    
    if( $self->{op} )
    {
        die( "No RHS of ", $self->as_string ) unless( $self->{rhs} );
        $results = $self->op_eval( $node );
    }
    else
    {
        # HTML::Object::XPath::LocationPath
        $results = $self->{lhs}->evaluate( $node );
    }
    
    if( !$self->predicates->is_empty )
    {
        if( !$self->_is_a( $results => 'HTML::Object::XPath::NodeSet' ) )
        {
            die( "Can't have predicates execute on object type: " . ref( $results ) );
        }
        
        # filter initial nodeset by each predicate
        foreach my $predicate ( @{$self->{predicates}} )
        {
            $results = $self->filter_by_predicate( $results, $predicate );
        }
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
    
#    warn "Filter by predicate: $predicate\n";
    
    my $newset = $self->new_nodeset->new();
    
    for( my $i = 1; $i <= $nodeset->size; $i++ )
    {
        # set context set each time 'cos a loc-path in the expr could change it
        $self->{pp}->_set_context_set( $nodeset );
        $self->{pp}->_set_context_pos( $i );
        my $result = $predicate->evaluate( $nodeset->get_node( $i ) );
        if( $self->_is_a( $result => 'HTML::Object::XPath::Boolean' ) )
        {
            if( $result->value )
            {
                $newset->push( $nodeset->get_node( $i ) );
            }
        }
        elsif( $self->_is_a( $result => 'HTML::Object::XPath::Number' ) )
        {
            if( $result->value == $i )
            {
                $newset->push( $nodeset->get_node( $i ) );
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

sub get_lhs { return( $_[0]->{lhs} ); }

sub get_rhs { return( $_[0]->{rhs} ); }

sub get_op { return( $_[0]->{op} ); }

sub new_literal { return( shift->_class_for( 'Literal' )->new( @_ ) ); }

sub new_nodeset { return( shift->_class_for( 'NodeSet' )->new( @_ ) ); }

sub new_number { return( shift->_class_for( 'Number' )->new( @_ ) ); }

sub op_and
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    if( ! $lhs->evaluate( $node )->to_boolean->value )
    {
        return( $FALSE );
    }
    else
    {
        return( $rhs->evaluate( $node )->to_boolean );
    }
}

sub op_div
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );

    my $result = eval{ $lh_results->to_number->value / $rh_results->to_number->value; };
    if( $@ )
    {
        # assume divide by zero
        # This is probably a terrible way to handle this! 
        # Ah well... who wants to live forever...
        return( $self->new_literal( 'Infinity' ) );
    }
    return( $self->new_number( $result ) );
}

sub op_equals
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;

    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    
    if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) &&
        $rh_results->isa( 'HTML::Object::XPath::NodeSet' ) )
    {
        # True if and only if there is a node in the
        # first set and a node in the second set such
        # that the result of performing the comparison
        # on the string-values of the two nodes is true.
        foreach my $lhnode ( $lh_results->get_nodelist )
        {
            foreach my $rhnode ( $rh_results->get_nodelist )
            {
                if( $lhnode->string_value eq $rhnode->string_value )
                {
                    return( $TRUE );
                }
            }
        }
        return( $FALSE );
    }
    elsif( ( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ||
             $rh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) &&
           ( !$lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ||
             !$rh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) )
    {
        # (that says: one is a nodeset, and one is not a nodeset)
        my( $nodeset, $other );
        if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) )
        {
            $nodeset = $lh_results;
            $other = $rh_results;
        }
        else
        {
            $nodeset = $rh_results;
            $other = $lh_results;
        }
        
        # True if and only if there is a node in the
        # nodeset such that the result of performing
        # the comparison on <type>(string_value($node))
        # is true.
        if( $self->_is_a( $other => 'HTML::Object::XPath::Number' ) )
        {
            foreach my $node ( $nodeset->get_nodelist )
            {
                if( $node->string_value == $other->value )
                {
                    return( $TRUE );
                }
            }
        }
        elsif( $self->_is_a( $other => 'HTML::Object::XPath::Literal' ) )
        {
            foreach my $node ( $nodeset->get_nodelist )
            {
                if( $node->string_value eq $other->value )
                {
                    return( $TRUE );
                }
            }
        }
        elsif( $self->_is_a( $other => 'HTML::Object::XPath::Boolean' ) )
        {
            if( $nodeset->to_boolean->value == $other->value )
            {
                return( $TRUE );
            }
        }
        return( $FALSE );
    }
    # Neither is a nodeset
    else
    {
        if( $lh_results->isa( 'HTML::Object::XPath::Boolean' ) ||
            $rh_results->isa( 'HTML::Object::XPath::Boolean' ) )
        {
            # if either is a boolean
            if( $lh_results->to_boolean->value == $rh_results->to_boolean->value )
            {
                return( $TRUE );
            }
            return( $FALSE );
        }
        elsif( $lh_results->isa( 'HTML::Object::XPath::Number' ) ||
               $rh_results->isa( 'HTML::Object::XPath::Number' ) )
        {
            # if either is a number
            # 'number' might result in undef
            local $^W;
            if ($lh_results->to_number->value == $rh_results->to_number->value )
            {
                return( $TRUE );
            }
            return( $FALSE );
        }
        else
        {
            if( $lh_results->to_literal->value eq $rh_results->to_literal->value )
            {
                return( $TRUE );
            }
            return( $FALSE );
        }
    }
}

sub op_eval
{
    my $self = shift( @_ );
    my $node = shift( @_ );
    my $op = $self->{op};
    my $map =
    {
    'or'    => 'op_or',
    'and'   => 'op_and',
    '=~'    => 'op_match',
    '!~'    => 'op_not_match',
    '='     => 'op_equals',
    '!='    => 'op_nequals',
    '<='    => 'op_le',
    '>='    => 'op_ge',
    '>'     => 'op_gt',
    '<'     => 'op_lt',
    '+'     => 'op_plus',
    '-'     => 'op_minus',
    'div'   => 'op_div',
    'mod'   => 'op_mod',
    '*'     => 'op_mult',
    '|'     => 'op_union',
    };
    die( "No such operator, or operator unimplemented in ", $self->as_string, "\n" ) if( !CORE::exists( $map->{ $op } ) );
    my $mod = $map->{ $op };
    return( $self->$mod( $node, $self->{lhs}, $self->{rhs} ) );
}

sub op_ge
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;

    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    
    if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) &&
        $rh_results->isa( 'HTML::Object::XPath::NodeSet' ) )
    {
        foreach my $lhnode ( $lh_results->get_nodelist )
        {
            foreach my $rhnode ( $rh_results->get_nodelist )
            {
                my $lhNum = $self->new_number( $lhnode->string_value );
                my $rhNum = $self->new_number( $rhnode->string_value );
                if( $lhNum->value >= $rhNum->value )
                {
                    return( $TRUE );
                }
            }
        }
        return( $FALSE );
    }
    elsif( ( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ||
             $rh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) &&
           ( !$lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ||
             !$rh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) )
    {
        # (that says: one is a nodeset, and one is not a nodeset)
        if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) )
        {
            foreach my $node ( $lh_results->get_nodelist )
            {
                if( $node->to_number->value >= $rh_results->to_number->value )
                {
                    return( $TRUE );
                }
            }
        }
        else
        {
            foreach my $node ( $rh_results->get_nodelist )
            {
                if( $lh_results->to_number->value >= $node->to_number->value )
                {
                    return( $TRUE );
                }
            }
        }
        return( $FALSE );
    }
    # Neither is a nodeset
    else
    {
        if( $lh_results->isa( 'HTML::Object::XPath::Boolean' ) ||
            $rh_results->isa( 'HTML::Object::XPath::Boolean' ) )
        {
            # if either is a boolean
            if( $lh_results->to_boolean->to_number->value >= $rh_results->to_boolean->to_number->value )
            {
                return( $TRUE );
            }
        }
        else
        {
            if( $lh_results->to_number->value >= $rh_results->to_number->value )
            {
                return( $TRUE );
            }
        }
        return( $FALSE );
    }
}

sub op_gt
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;

    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    
    if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) &&
        $rh_results->isa( 'HTML::Object::XPath::NodeSet' ) )
    {
        foreach my $lhnode ( $lh_results->get_nodelist )
        {
            foreach my $rhnode ( $rh_results->get_nodelist )
            {
                my $lhNum = $self->new_number( $lhnode->string_value );
                my $rhNum = $self->new_number( $rhnode->string_value );
                if( $lhNum->value > $rhNum->value )
                {
                    return( $TRUE );
                }
            }
        }
        return( $FALSE );
    }
    elsif( ( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ||
             $rh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) &&
           ( !$lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ||
             !$rh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) )
    {
        # (that says: one is a nodeset, and one is not a nodeset)
        if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) )
        {
            foreach my $node ( $lh_results->get_nodelist )
            {
                if( $node->to_number->value > $rh_results->to_number->value )
                {
                    return( $TRUE );
                }
            }
        }
        else
        {
            foreach my $node ( $rh_results->get_nodelist )
            {
                if( $lh_results->to_number->value > $node->to_number->value )
                {
                    return( $TRUE );
                }
            }
        }
        return( $FALSE );
    }
    # Neither is a nodeset
    else
    {
        if( $lh_results->isa( 'HTML::Object::XPath::Boolean' ) ||
            $rh_results->isa( 'HTML::Object::XPath::Boolean' ) )
        {
            # if either is a boolean
            if( $lh_results->to_boolean->value > $rh_results->to_boolean->value )
            {
                return( $TRUE );
            }
        }
        else
        {
            if( $lh_results->to_number->value > $rh_results->to_number->value )
            {
                return( $TRUE );
            }
        }
        return( $FALSE );
    }
}

sub op_le
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    return( $self->op_ge( $node, $rhs, $lhs ) );
}

sub op_lt
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    return( $self->op_gt( $node, $rhs, $lhs ) );
}

sub op_match 
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;

    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    my $rh_value   = $rh_results->string_value;

    if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) 
    {
        foreach my $lhnode ( $lh_results->get_nodelist ) 
        {
            # / is important here, regexp is / delimited
            if( $lhnode->string_value =~ m/$rh_value/ )
            {
                return( $TRUE );
            }
        }
        return( $FALSE );
    }
    else
    {
        return(
            $lh_results->string_value =~ m/$rh_value/
                ? $TRUE
                : $FALSE
        );
    }
}
  
sub op_minus
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    
    my $result = $lh_results->to_number->value - $rh_results->to_number->value;
    return( $self->new_number( $result ) );
}

sub op_mod
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    
    my $result = $lh_results->to_number->value % $rh_results->to_number->value;
    return( $self->new_number( $result ) );
}

sub op_mult
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    
    my $result = $lh_results->to_number->value * $rh_results->to_number->value;
    return( $self->new_number( $result ) );
}

sub op_nequals
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    if( $self->op_equals( $node, $lhs, $rhs)->value )
    {
        return( $FALSE );
    }
    return( $TRUE );
}

sub op_not_match 
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;

    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    my $rh_value   = $rh_results->string_value;
    
    if( $lh_results->isa( 'HTML::Object::XPath::NodeSet' ) ) 
    {
        foreach my $lhnode ( $lh_results->get_nodelist ) 
        {
            if( $lhnode->string_value !~ m/$rh_value/ )
            {
                return( $TRUE );
            }
        }
        return( $FALSE );
    }
    else
    {
        return( $lh_results->string_value !~  m/$rh_value/ ? $TRUE : $FALSE );
    }
}

sub op_or
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    if( $lhs->evaluate( $node )->to_boolean->value )
    {
        return( $TRUE );
    }
    else
    {
        return $rhs->evaluate( $node )->to_boolean;
    }
}

sub op_plus
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    my $lh_results = $lhs->evaluate( $node );
    my $rh_results = $rhs->evaluate( $node );
    
    my $result = $lh_results->to_number->value + $rh_results->to_number->value;
    return( $self->new_number( $result ) );
}

sub op_union
{
    my $self = shift( @_ );
    my( $node, $lhs, $rhs ) = @_;
    my $lh_result = $lhs->evaluate( $node );
    my $rh_result = $rhs->evaluate( $node );
    
    if( $lh_result->isa( 'HTML::Object::XPath::NodeSet' ) &&
        $rh_result->isa( 'HTML::Object::XPath::NodeSet' ) )
    {
        my %found;
        my $results = $self->new_nodeset;
        foreach my $lhnode ( $lh_result->get_nodelist )
        {
            $found{ "$lhnode" }++;
            $results->push( $lhnode );
        }
        foreach my $rhnode ( $rh_result->get_nodelist )
        {
            $results->push( $rhnode ) unless( exists( $found{ "$rhnode" } ) );
        }
        return( $results->sort->remove_duplicates );
    }
    die( "Both sides of a union must be Node Sets\n" );
}

sub op_xml
{
    my $self = shift( @_ );
    my $op = $self->{op};

    my $map =
    {
    'and'   => 'And',
    'div'   => 'Div',
    'mod'   => 'Mod',
    'or'    => 'Or',
    '='     => 'Equals',
    '!='    => 'NotEquals',
    '<='    => 'LessThanOrEquals',
    '>='    => 'GreaterThanOrEquals',
    '>'     => 'GreaterThan',
    '<'     => 'LessThan',
    '+'     => 'Plus',
    '-'     => 'Minus',
    '*'     => 'Multiply',
    '|'     => 'Union',
    };
    die( "No tag equivalent for operator \"$op\".\n" ) if( !CORE::exists( $map->{ $op } ) );
    my $tag = $map->{ $op };
    return( "<$tag>\n" . $self->{lhs}->as_xml() . $self->{rhs}->as_xml() . "</$tag>\n" );
}

sub predicates { return( shift->_set_get_array_as_object( 'predicates', @_ ) ); }

sub push_predicate
{
    my $self = shift( @_ );
    
    die( "Only 1 predicate allowed on FilterExpr in W3C XPath 1.0" ) if( @{$self->{predicates}} );
    # push( @{$self->{predicates}}, $_[0] );
    $self->predicates->push( $_[0] );
    # Need to return $self
    # return( $self );
    return( $self->predicates->length );
}

sub set_lhs
{
    my $self = shift( @_ );
    $self->{lhs} = $_[0];
}

sub set_op
{
    my $self = shift( @_ );
    $self->{op} = $_[0];
}

sub set_rhs
{
    my $self = shift( @_ );
    $self->{rhs} = $_[0];
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

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath::Expr - HTML Object XPath Expression

=head1 SYNOPSIS

    use HTML::Object::XPath::Expr;
    my $this = HTML::Object::XPath::Expr->new || die( HTML::Object::XPath::Expr->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This modules represents an L<HTML::Object::XPath> expression.

=head1 METHODS

=head2 new

Provided with an L<HTML::Object::XPath> object and this returns a new L<HTML::Object::XPath::Expr> object.

=head2 as_string

Returns the expression as a string.

=head2 as_xml

Returns the expression as xml.

=head2 evaluate

Provided with a L<HTML::Object::XPath::NodeSet> object, and this will call L</op_eval> with an L<operator|/op> has been set, otherwise, it calls L<HTML::Object::XPath::LocationPath/evaluate> passing it the node set. It returns the result from either call.

=head2 filter_by_predicate

This takes a nodeset object and a predicate.

For each node in the node-set to be filtered, the predicate Expr is evaluated with that node as the context node, with the number of nodes in the node set as the context size, and with the proximity position of the node in the node set with respect to the axis as the context position.

It returns a new L<node set|HTML::Object::XPath::NodeSet> object.

=head2 get_lhs

Returns the L<HTML::Object::XPath::LocationPath> object for the left-hand side of the expression.

=head2 get_rhs

Returns the L<HTML::Object::XPath::LocationPath> object for the right-hand side of the expression.

=head2 get_op

Returns the current operator set for this expression.

=head2 new_literal

Returns a new L<literal object|HTML::Object::XPath::Literal>, passing it whatever argument was provided.

=head2 new_nodeset

Returns a new L<node set object|HTML::Object::XPath::NodeSet>, passing it whatever argument was provided.

=head2 new_number

Returns a new L<number object|HTML::Object::XPath::Number>, passing it whatever argument was provided.

=head2 op_and

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will evaluate the node using the left-hand side LocationPath object, and return L<false|HTML::Object::XPath::Boolean> if it failed, or otherwise it wil evaluate the node using the right-hand side LocationPath object and return its result.

=head2 op_div

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will attempt to divide the left-hand value by the right-hand value. If ther eis an error, it returns L<infinity|HTML::Object::XPath::Number>, otherwise it returns the value from the division as a L<number object|HTML::Object::XPath::Number>.

=head2 op_equals

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will check if the left-hand side LocationPath is equal tot he right-hand side LocationPath. Returns L<true|HTML::Object::XPath::Boolean> or L<false|HTML::Object::XPath::Boolean>

=head2 op_eval

This method will evaluate the L<node|HTML::Object::ELement> provided with the left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> object also specified by calling the appropriate method in this module based on the operator value set with L</op>

=head2 op_ge

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will check if the left-hand side is greater or equal to the right-hand side.

Returns L<true|HTML::Object::XPath::Boolean> or L<false|HTML::Object::XPath::Boolean>

=head2 op_gt

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will check if the left-hand side is greater than the right-hand side.

Returns L<true|HTML::Object::XPath::Boolean> or L<false|HTML::Object::XPath::Boolean>

=head2 op_le

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will check if the left-hand side is lower or equal than the right-hand side.

Returns L<true|HTML::Object::XPath::Boolean> or L<false|HTML::Object::XPath::Boolean>

=head2 op_lt

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will check if the left-hand side is lower than the right-hand side.

Returns L<true|HTML::Object::XPath::Boolean> or L<false|HTML::Object::XPath::Boolean>

=head2 op_match

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will check if the left-hand side match the right-hand side as a regular expression.

Returns L<true|HTML::Object::XPath::Boolean> or L<false|HTML::Object::XPath::Boolean>

=head2 op_minus

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will subtract the right-hand side from the left-hand side and return the result as a L<number object|HTML::Object::XPath::Number>.

=head2 op_mod

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will get the modulo between the left-hand side and the right-hand side and return the result as a L<number object|HTML::Object::XPath::Number>.

=head2 op_mult

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will multiply the right-hand side by the left-hand side and return the result as a L<number object|HTML::Object::XPath::Number>.

=head2 op_nequals

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will return L<true|HTML::Object::XPath::Boolean> if the left-hand side is not equal to the right-hand side, or L<false|HTML::Object::XPath::Boolean> otherwise.

=head2 op_not_match

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will check if the left-hand side does B<not> match the right-hand side as a regular expression.

Returns L<true|HTML::Object::XPath::Boolean> or L<false|HTML::Object::XPath::Boolean>

=head2 op_or

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will evaluate the node using the left-hand side LocationPath and return L<true|HTML::Object::XPath::Boolean> if it worked, or otherwise return the value from evaluating the node using the right-hand side LocationPath.

=head2 op_plus

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will add the right-hand side to the left-hand side and return the result as a L<number object|HTML::Object::XPath::Number>.

=head2 op_union

Provided a L<node object|HTML::Object:Element>, a left-hand side and right-hand side L<LocationPath objects|HTML::Object::XPath::LocationPath> and this will evaluate the node both by the left-hand side and right-hand side LocationPath and return a new L<node set array object|HTML::Object::XPath::NodeSet> containing all the unique nodes resulting from those both evaluation.

=head2 op_xml

Provided with an operator and this returns its xml equivalent.

Operators supported are: C<and>, C<div>, C<mod>, C<or>, C<=>, C<!=>, C<<=>, C<>=>, C<>>, C<<>, C<+>, C<->, C<*>, C<|>

They will be converted respectively to: C<And>, C<Div>, C<Mod>, C<Or>, C<Equals>, C<NotEquals>, C<LessThanOrEquals>, C<GreaterThanOrEquals>, C<GreaterThan>, C<LessThan>, C<Plus>, C<Minus>, C<Multiply>, C<Union>

=head2 predicates

Set or get the predicates as an L<array object|Module::Generic::Array>

=head2 push_predicate

Add the predicate to the list and will raise an exception if more than one predicate was provided.

=head2 set_lhs

Set the left-hand side L<LocationPath|HTML::Object::XPath::LocationPath>

=head2 set_op

Set the operator for this expression.

=head2 set_rhs

Set the right-hand side L<LocationPath|HTML::Object::XPath::LocationPath>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
