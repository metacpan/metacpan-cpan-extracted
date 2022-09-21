##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/04
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XPath;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw(
        $CACHE $AXES $AXES_KEYS $NC_NAME_RE $QNAME_RE $NC_WILD_RE $QN_WILD_RE 
        $NODE_TYPE_RE $AXIS_NAME_RE $NUMBER_RE $LITERAL_RE $REGEXP_RE $REGEXP_MOD_RE
        $BASE_CLASS $VERSION
    );
    use HTML::Object::XPath::Step;
    use HTML::Object::XPath::Expr;
    use HTML::Object::XPath::Function;
    use HTML::Object::XPath::LocationPath;
    use HTML::Object::XPath::Variable;
    use HTML::Object::XPath::Literal;
    use HTML::Object::XPath::Number;
    use HTML::Object::XPath::NodeSet;
    use HTML::Object::XPath::Root;
    our $VERSION = 'v0.2.0';
    our $CACHE = {};
    # Axis name to principal node type mapping
    our $AXES =
    {
        'ancestor' => 'element',
        'ancestor-or-self' => 'element',
        'attribute' => 'attribute',
        'namespace' => 'namespace',
        'child' => 'element',
        'descendant' => 'element',
        'descendant-or-self' => 'element',
        'following' => 'element',
        'following-sibling' => 'element',
        'parent' => 'element',
        'preceding' => 'element',
        'preceding-sibling' => 'element',
        'self' => 'element',
    };
    my $AXES_KEYS   = join( '|', keys( %$AXES ) );
    our $NC_NAME_RE    = qr/([A-Za-z_][\w\.\-]*)/;
    our $QNAME_RE      = qr/(${NC_NAME_RE}:)?${NC_NAME_RE}/;
    our $NC_WILD_RE    = qr/${NC_NAME_RE}:\*/;
    our $QN_WILD_RE    = qr/\*/;
    our $NODE_TYPE_RE  = qr/((text|comment|processing-instruction|node)\(\))/;
    our $AXIS_NAME_RE  = qr/(${AXES_KEYS})::/;
    our $NUMBER_RE     = qr/\d+(\.\d*)?|\.\d+/;
    our $LITERAL_RE    = qr/\"[^\"]*\"|\'[^\']*\'/;
    our $REGEXP_RE     = qr{(?:m?/(?:\\.|[^/])*/)};
    our $REGEXP_MOD_RE = qr{(?:[imsx]+)};
    our $BASE_CLASS    = __PACKAGE__;
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{context_pos} = undef; # 1 based position in array context
    $self->{context_set} = $self->new_nodeset;
    $self->{context_size} = 0; # total size of context
    $self->clear_namespaces();
    $self->{cache} = {};
    $self->{direction} = 'forward';
    $self->{namespaces} = {};
    $self->{vars} = {};
    $self->{_tokpos} = 0;
    return( $self );
}

sub clear_namespaces
{
    my $self = shift( @_ );
    $self->{uses_namespaces} = 0;
    $self->{namespaces} = {};
    return( $self );
}

sub exists
{
    my $self = shift( @_ );
    my( $path, $context ) = @_;
    $self = '/' if( !defined( $self ) );
    my @nodeset = $self->findnodes( $path, $context );
    return( scalar( @nodeset ) ? 1 : 0 );
}

sub find
{
    my $self = shift( @_ );
    # xpath expression and $context is a HTML::Object::Element
    my( $path, $context ) = @_;
    # _parse returns an HTML::Object::XPath::Expr object
    my $parsed_path = $self->_parse( $path );
    # $parsed_path is an HTML:: Object::XPath::Expr object
    # $results could be a HTML::Object::XPath::NodeSet or something else like HTML::Object::XPath::Number
    my $results = $parsed_path->evaluate( $context );
    # if( $results->isa( 'HTML::Object::XPath::NodeSet') )
    # if( $self->isa_nodeset( $results ) ) 
    if( $self->_is_a( $results, 'HTML::Object::XPath::NodeSet' ) )
    {
        return( $results->sort->remove_duplicates );
    }
    else
    {
        return( $results );
    }
}

sub findnodes
{
    my $self = shift( @_ );
    my( $path, $context ) = @_;
    
    my $results = $self->find( $path, $context );
    
    if( $self->_is_a( $results => 'HTML::Object::XPath::NodeSet' ) )
    {
        return( wantarray() ? $results->get_nodelist : $results );
    }
    # result should be SCALAR
    else
    {
        return( wantarray() ? $self->new_nodeset( $results ) : $results );
    }
    #{ return wantarray ? ($results) : $results; } # result should be SCALAR
    #{ return wantarray ? () : HTML::Object::XPath::NodeSet->new();   }
}

sub findnodes_as_string
{
    my $self = shift( @_ );
    my( $path, $context ) = @_;
    
    my $results = $self->find( $path, $context );
    if( $self->_is_a( $results => 'HTML::Object::XPath::NodeSet' ) )
    {
        return( join( '', map{ $_->toString } $results->get_nodelist ) );
    }
    elsif( $self->_is_a( $results => 'HTML::Object::XPath::Boolean' ) )
    {
        # to behave like XML::LibXML
        return( '' );
    }
    elsif( $self->_is_a( $results => 'HTML::Object::XPath::Node' ) )
    {
        return( $results->toString );
    }
    else
    {
        return( $self->_xml_escape_text( $results->value ) );
    }
}

sub findnodes_as_strings
{
    my $self = shift( @_ );
    my( $path, $context ) = @_;
    my $results = $self->find( $path, $context );
    
    if( $self->_is_a( $results => 'HTML::Object::XPath::NodeSet' ) )
    {
        return( map{ $_->getValue } $results->get_nodelist );
    }
    elsif( $self->_is_a( $results => 'HTML::Object::XPath::Boolean' ) )
    {
        # to behave like XML::LibXML
        return( () );
    }
    elsif( $self->_is_a( $results => 'HTML::Object::XPath::Node' ) )
    {
        return( $results->getValue );
    }
    else
    {
        return( $self->_xml_escape_text( $results->value ) );
    }
}

sub findvalue
{
    my $self = shift( @_ );
    my( $path, $context ) = @_;
    my $results = $self->find( $path, $context );
    if( $self->_is_a( $results => 'HTML::Object::XPath::NodeSet' ) ) 
    {
        return( $results->to_final_value );
    }
    #{ return $results->to_literal; }
    return( $results->value );
}

sub findvalues
{
    my $self = shift( @_ );
    my( $path, $context ) = @_;
    my $results = $self->find( $path, $context );
    if( $self->_is_a( $results => 'HTML::Object::XPath::NodeSet' ) ) 
    {
        return( $results->string_values );
    }
    return( $results->string_value );
}

sub get_namespace
{
    my $self = shift( @_ );
    my( $prefix, $node ) = @_;
   
    my $ns = $node
        ? $node->getNamespace( $prefix )
        : $self->{uses_namespaces}
            ? $self->{namespaces}->{ $prefix }
            : $prefix;
    return( $ns );
}

sub get_var
{
    my $self = shift( @_ );
    my $var = shift( @_ );
    $self->{vars}->{ $var };
}

sub matches
{
    my $self = shift( @_ );
    my( $node, $path, $context ) = @_;
    my @nodes = $self->findnodes( $path, $context );
    return(1) if( grep{ "$node" eq "$_" } @nodes );
    return;
}

sub namespaces { return( shift->_set_get_hash_as_mix_object( 'namespaces', @_ ) ); }

sub new_expr { return( shift->_class_for( 'Expr' )->new( @_ ) ); }

sub new_function { return( shift->_class_for( 'Function' )->new( @_ ) ); }

sub new_literal { return( shift->_class_for( 'Literal' )->new( @_ ) ); }

sub new_location_path { return( shift->_class_for( 'LocationPath' )->new( @_ ) ); }

sub new_nodeset { return( shift->_class_for( 'NodeSet' )->new( @_ ) ); }

sub new_number { return( shift->_class_for( 'Number' )->new( @_ ) ); }

sub new_root { return( shift->_class_for( 'Root' )->new( @_ ) ); }

sub new_step { return( shift->_class_for( 'Step' )->new( @_ ) ); }

sub new_variable { return( shift->_class_for( 'Variable' )->new( @_ ) ); }

sub parse { return( shift->_parse( @_ ) ); }

sub set_namespace
{
    my $self = shift( @_ );
    my( $prefix, $expanded ) = @_;
    $self->{uses_namespaces} = 1;
    $self->{namespaces}{ $prefix } = $expanded;
}

sub set_strict_namespaces
{
    my( $self, $strict ) = @_;
    $self->{strict_namespaces} = $strict;
}

sub set_var
{
    my $self = shift( @_ );
    my $var = shift( @_ );
    my $val = shift( @_ );
    $self->{vars}->{ $var } = $val;
}

sub _analyze
{
    my $self = shift( @_ );
    # Array object
    my $tokens = shift( @_ );
    # lexical analysis
    if( $self->debug )
    {
        my( $p, $f, $l ) = caller;
    }
    return( $self->_expr( $tokens ) );
}

sub _arguments
{
    my( $self, $tokens ) = @_;
    my $args = $self->new_array;
    if( $tokens->[ $self->{_tokpos} ] eq ')' )
    {
        return( $args );
    }
    
    $args->push( $self->_expr( $tokens ) );
    while( $self->_match( $tokens, qr/\,/ ) )
    {
        $args->push( $self->_expr( $tokens ) );
    }
    return( $args );
}

sub _class_for
{
    my( $self, $mod ) = @_;
    eval( "require ${BASE_CLASS}\::${mod};" );
    die( $@ ) if( $@ );
    # ${"${BASE_CLASS}\::${mod}\::DEBUG"} = $self->debug;
    eval( "\$${BASE_CLASS}\::${mod}\::DEBUG = " . ( $self->debug // 0 ) );
    return( "${BASE_CLASS}::${mod}" );
}

sub _expr
{
    my( $self, $tokens ) = @_;
    # $tokens are an array object of xpath expression token
#     if( $self->debug )
#     {
#         my( $p, $f, $l ) = caller;
#     }
    # Returning an HTML::Object::XPath::Expr object
    return( $self->_expr_or( $tokens ) );
}

sub _expr_additive
{
    my( $self, $tokens ) = @_;
    
    my $expr = $self->_expr_multiplicative( $tokens );
    while( $self->_match( $tokens, qr/[\+\-]/ ) )
    {
        my $add_expr = $self->new_expr( $self );
        $add_expr->set_lhs( $expr );
        $add_expr->set_op( $self->{_curr_match} );
        
        my $rhs = $self->_expr_multiplicative( $tokens );
        
        $add_expr->set_rhs( $rhs );
        $expr = $add_expr;
    }
    return( $expr );
}

sub _expr_and
{
    my( $self, $tokens ) = @_;
    my $expr = $self->_expr_match( $tokens );
    while( $self->_match( $tokens, 'and' ) )
    {
        my $and_expr = $self->new_expr( $self );
        $and_expr->set_lhs( $expr );
        $and_expr->set_op( 'and' );
        my $rhs = $self->_expr_match( $tokens );
        $and_expr->set_rhs( $rhs );
        $expr = $and_expr;
    }
    return( $expr );
}

sub _expr_equality
{
    my( $self, $tokens ) = @_;
    
    my $expr = $self->_expr_relational( $tokens );
    while( $self->_match( $tokens, qr/!?=/ ) )
    {
        my $eq_expr = $self->new_expr( $self );
        $eq_expr->set_lhs( $expr );
        $eq_expr->set_op( $self->{_curr_match} );
        
        my $rhs = $self->_expr_relational( $tokens );
        
        $eq_expr->set_rhs( $rhs );
        $expr = $eq_expr;
    }
    return( $expr );
}

sub _expr_filter
{
    my( $self, $tokens ) = @_;
    
    
    my $expr = $self->_expr_primary( $tokens );
    while( $self->_match( $tokens, qr/\[/ ) )
    {
        # really PredicateExpr...
        $expr->push_predicate( $self->_expr( $tokens ) );
        $self->_match( $tokens, qr/\]/, 1 );
    }
    return( $expr );
}

sub _expr_match
{
    my( $self, $tokens ) = @_;
    
    my $expr = $self->_expr_equality( $tokens );

    while( $self->_match( $tokens, qr/[=!]~/ ) )
    {
        my $match_expr = $self->new_expr( $self );
        $match_expr->set_lhs( $expr );
        $match_expr->set_op( $self->{_curr_match} );
        
        my $rhs = $self->_expr_equality( $tokens );
        
        $match_expr->set_rhs( $rhs );
        $expr = $match_expr;
    }
    return( $expr );
}

sub _expr_multiplicative
{
    my( $self, $tokens ) = @_;
    
    my $expr = $self->_expr_unary( $tokens );
    while( $self->_match( $tokens, qr/(\*|div|mod)/ ) )
    {
        my $mult_expr = $self->new_expr( $self );
        $mult_expr->set_lhs( $expr );
        $mult_expr->set_op( $self->{_curr_match} );
        
        my $rhs = $self->_expr_unary( $tokens );
        
        $mult_expr->set_rhs( $rhs );
        $expr = $mult_expr;
    }
    return( $expr );
}

sub _expr_or
{
    my( $self, $tokens ) = @_;
    
    my $expr = $self->_expr_and( $tokens );
    while( $self->_match( $tokens, 'or' ) )
    {
        my $or_expr = $self->new_expr( $self );
        $or_expr->set_lhs( $expr );
        $or_expr->set_op( 'or' );

        my $rhs = $self->_expr_and( $tokens );

        $or_expr->set_rhs( $rhs );
        $expr = $or_expr;
    }
    if( $self->debug )
    {
        my( $p, $f, $l ) = caller;
    }
    return( $expr );
}

sub _expr_path
{
    my( $self, $tokens ) = @_;
    # _expr_path is _location_path | _expr_filter | _expr_filter '//?' _relative_location_path
    # Since we are being predictive we need to find out which function to call next, then.
    # LocationPath either starts with "/", "//", ".", ".." or a proper Step.
    my $expr = $self->new_expr( $self );
    
    # $test is a fragment of the xpath initially provided and broken down into bits by
    # HTML::Object::XPath::_tokenize
    my $test = $tokens->[ $self->{_tokpos} ];
    
    # Test for AbsoluteLocationPath and AbbreviatedRelativeLocationPath
    if( $test =~ /^(\/\/?|\.\.?)$/ )
    {
        # LocationPath
        $expr->set_lhs( $self->_location_path( $tokens ) );
    }
    # Test for AxisName::...
    elsif( $self->_is_step( $tokens ) )
    {
        $expr->set_lhs( $self->_location_path( $tokens ) );
    }
    else
    {
        # Not a LocationPath
        # Use _expr_filter instead:
        $expr = $self->_expr_filter( $tokens );
        if( $self->_match( $tokens, qr/\/\/?/ ) )
        {
            my $loc_path = $self->new_location_path();
            $loc_path->push( $expr );
            if( $self->{_curr_match} eq '//' )
            {
                $loc_path->push( $self->new_step( $self, 'descendant-or-self', $self->_class_for( 'Step' )->TEST_NT_NODE ) );
            }
            $loc_path->push( $self->_relative_location_path( $tokens ) );
            my $new_expr = $self->new_expr( $self );
            $new_expr->set_lhs( $loc_path );
            return( $new_expr );
        }
    }
    return( $expr );
}

sub _expr_primary
{
    my( $self, $tokens ) = @_;
    
    my $expr = $self->new_expr( $self );
    
    if( $self->_match( $tokens, $LITERAL_RE ) )
    {
        # new Literal with $self->{_curr_match}...
        $self->{_curr_match} =~ m/^(["'])(.*)\1$/;
        $expr->set_lhs( $self->new_literal( $2 ) );
    }
    elsif( $self->_match( $tokens, qr/${REGEXP_RE}${REGEXP_MOD_RE}?/ ) )
    {
        # new Literal with $self->{_curr_match} turned into a regexp... 
        my( $regexp, $mod)= $self->{_curr_match} =~  m{($REGEXP_RE)($REGEXP_MOD_RE?)};
        $regexp =~ s{^m?s*/}{};
        $regexp =~ s{/$}{};                        
        # move the mods inside the regexp
        if( $mod )
        {
            $regexp =~ qr/(?$mod:$regexp)/;
        }
        $expr->set_lhs( $self->new_literal( $regexp ) );
    }
    elsif( $self->_match( $tokens, $NUMBER_RE ) )
    {
        # new Number with $self->{_curr_match}...
        $expr->set_lhs( $self->new_number( $self->{_curr_match} ) );
    }
    elsif( $self->_match( $tokens, qr/\(/ ) )
    {
        $expr->set_lhs( $self->_expr( $tokens ) );
        $self->_match( $tokens, qr/\)/, 1 );
    }
    elsif( $self->_match( $tokens, qr/\$$QNAME_RE/ ) )
    {
        # new Variable with $self->{_curr_match}...
        $self->{_curr_match} =~ /^\$(.*)$/;
        $expr->set_lhs( $self->new_variable( $self, $1 ) );
    }
    elsif( $self->_match( $tokens, $QNAME_RE ) )
    {
        # check match not Node_Type - done in lexer...
        # new Function
        my $func_name = $self->{_curr_match};
        $self->_match( $tokens, qr/\(/, 1 );
        $expr->set_lhs(
            $self->new_function(
                $self,
                $func_name,
                $self->_arguments( $tokens )
            )
        );
        $self->_match( $tokens, qr/\)/, 1 );
    }
    else
    {
        # die "Not a _expr_primary at ", $tokens->[$self->{_tokpos}], "\n";
        return( $self->error( "Not a _expr_primary at ", $tokens->[ $self->{_tokpos} ] ) );
    }
    return( $expr );
}

sub _expr_relational
{
    my( $self, $tokens ) = @_;
    
    my $expr = $self->_expr_additive( $tokens );
    while( $self->_match( $tokens, qr/(<|>|<=|>=)/ ) )
    {
        my $rel_expr = $self->new_expr( $self );
        $rel_expr->set_lhs( $expr );
        $rel_expr->set_op( $self->{_curr_match} );
        
        my $rhs = $self->_expr_additive( $tokens );
        
        $rel_expr->set_rhs( $rhs );
        $expr = $rel_expr;
    }
    return $expr;
}

sub _expr_unary
{
    my( $self, $tokens ) = @_;
    # $tokens are an array object of expression tokens
    
    if( $self->_match( $tokens, qr/-/ ) )
    {
        my $expr = $self->new_expr( $self );
        $expr->set_lhs( $self->new_number(0) );
        $expr->set_op( '-' );
        $expr->set_rhs( $self->_expr_unary( $tokens ) );
        return( $expr );
    }
    else
    {
        return( $self->_expr_union( $tokens ) );
    }
}

sub _expr_union
{
    my( $self, $tokens ) = @_;
    # $tokens are an array object of expression tokens
    
    my $expr = $self->_expr_path( $tokens );
    while( $self->_match( $tokens, qr/\|/ ) )
    {
        my $un_expr = $self->new_expr( $self );
        $un_expr->set_lhs( $expr );
        $un_expr->set_op( '|' );
        
        my $rhs = $self->_expr_path( $tokens );
        $un_expr->set_rhs( $rhs );
        $expr = $un_expr;
    }
    return( $expr );
}

sub _get_context_node { return( $_[0]->{context_set}->get_node( $_[0]->{context_pos} ) ); }

sub _get_context_pos { return( shift->{context_pos} ); }

sub _get_context_set { return( shift->{context_set} ); }

sub _get_context_size { return( shift->{context_set}->size ); }

sub _is_step
{
    my( $self, $tokens ) = @_;
    my $token = $tokens->[ $self->{_tokpos} ];
    return unless( defined( $token ) );

    # local $^W = 0;
    if( ( $token eq 'processing-instruction' ) || 
        ( $token =~ /^\@($NC_WILD_RE|$QNAME_RE|$QN_WILD_RE)$/o ) || 
        ( ( $token =~ /^($NC_WILD_RE|$QNAME_RE|$QN_WILD_RE)$/o ) && 
          ( ( $tokens->[ $self->{_tokpos} + 1 ] || '' ) ne '(' ) ) || 
        ( $token =~ /^$NODE_TYPE_RE$/o ) || 
        ( $token =~ /^$AXIS_NAME_RE($NC_WILD_RE|$QNAME_RE|$QN_WILD_RE|$NODE_TYPE_RE)$/o )
      )
    {
        return(1);
    }
    else
    {
        return;
    }
}

sub _location_path
{
    my( $self, $tokens ) = @_;
    my $loc_path = $self->new_location_path;
    
    if( $self->_match( $tokens, qr/\// ) )
    {
        # root
        # push @$loc_path, HTML::Object::XPath::Root->new();
        $loc_path->push( $self->new_root );
        # Is it a valid token step?
        if( $self->_is_step( $tokens ) )
        {
            # push @$loc_path, $self->_relative_location_path( $tokens);
            $loc_path->push( $self->_relative_location_path( $tokens ) );
        }
    }
    elsif( $self->_match( $tokens, qr/\/\// ) )
    {
        # root
        $loc_path->push( $self->new_root );
        my $optimised = $self->_optimise_descendant_or_self( $tokens );
        if( !$optimised )
        {
            $loc_path->push(
                $self->new_step( $self, 'descendant-or-self', $self->_class_for( 'Step' )->TEST_NT_NODE )
            );
            $loc_path->push( $self->_relative_location_path( $tokens ) );
        }
        else
        {
            $loc_path->push( $optimised, $self->_relative_location_path( $tokens ) );
        }
    }
    else
    {
        $loc_path->push( $self->_relative_location_path( $tokens ) );
    }
    return( $loc_path );
}

sub _match
{
    my( $self, $tokens, $match, $fatal ) = @_;
    # Enabling this debugging section will take a lot more time, because of the 
    # $tokens->length that creates a new Module::Generic::Number every time
    # and _match gets called a lot
#     if( $self->debug )
#     {
#         my( $p, $f, $l ) = caller;
#     }
    $self->{_curr_match} = '';
    return(0) unless( $self->{_tokpos} < scalar( @$tokens ) );
    # return(0) unless( $self->{_tokpos} < $tokens->length );

    # local $^W;
    if( $tokens->[ $self->{_tokpos} ] =~ /^$match$/ )
    {
        $self->{_curr_match} = $tokens->[ $self->{_tokpos} ];
        $self->{_tokpos}++;
        return(1);
    }
    else
    {
        if( $fatal )
        {
            die( "Invalid token: ", $tokens->[$self->{_tokpos}], "\n" );
            # return( $self->error( "Invalid token: ", $tokens->[ $self->{_tokpos} ] ) );
        }
        else
        {
            return(0);
        }
    }
}

sub _optimise_descendant_or_self
{
    my( $self, $tokens ) = @_;
    
    my $tokpos = $self->{_tokpos};
    
    # // must be followed by a Step.
    if( $tokens->[ $tokpos + 1 ] && $tokens->[ $tokpos + 1 ] eq '[' )
    {
        # next token is a predicate
        return;
    }
    elsif( $tokens->[ $tokpos ] =~ /^\.\.?$/ )
    {
        # abbreviatedStep - can't optimise.
        return;
    }                                                                                              
    else
    {
        my $step = $self->_step( $tokens );
        if( $step->axis ne 'child' )
        {
            # can't optimise axes other than child for now...
            $self->{_tokpos} = $tokpos;
            return;
        }
        $step->axis( 'descendant' );
        $step->axis_method( 'axis_descendant' );
        $self->{_tokpos}--;
        $tokens->[ $self->{_tokpos} ] = '.';
        return( $step );
    }
}

sub _parse
{
    my $self = shift( @_ );
    my $path = shift( @_ );

    # $context is something like: //*[@att2="vv"]
    # my $context = join( '&&', $path, map { "$_=>$self->{namespaces}->{$_}" } sort keys %{$self->{namespaces}});
    my $context = $self->namespaces->keys->sort->map(sub{ sprintf( '%s=>%s', $_, $self->namespaces->get( $_ ) ); })->prepend( $path )->join( '&&' );
    
    return( $CACHE->{ $context } ) if( $CACHE->{ $context } );

    # my $tokens = $self->_tokenize( $path ) || return( $self->pass_error );
    my $tokens = $self->_tokenize( $path );

    $self->{_tokpos} = 0;
    my $tree = $self->_analyze( $tokens );
    
    if( $self->{_tokpos} < $tokens->length )
    {
        # didn't manage to parse entire expression - throw an exception
        die "Parse of expression $path failed - junk after end of expression: $tokens->[$self->{_tokpos}]";
        # return( $self->error( "Parse of expression $path failed - junk after end of expression: $tokens->[$self->{_tokpos}]" ) );
    }

    $tree->{uses_namespaces}   = $self->{uses_namespaces};   
    $tree->{strict_namespaces} = $self->{strict_namespaces};   
 
    $CACHE->{ $context } = $tree;
    
    if( $self->debug )
    {
        my( $p, $f, $l ) = caller;
    }
    return( $tree );
}

sub _relative_location_path
{
    my( $self, $tokens ) = @_;
    my @steps;
    
    push( @steps, $self->_step( $tokens ) );
    while( $self->_match( $tokens, qr/\/\/?/ ) )
    {
        if( $self->{_curr_match} eq '//' )
        {
            my $optimised = $self->_optimise_descendant_or_self( $tokens);
            if( !$optimised )
            {
                push( @steps, $self->new_step( $self, 'descendant-or-self', $self->_class_for( 'Step' )->TEST_NT_NODE ) );
            }
            else
            {
                push( @steps, $optimised );
            }
        }
        push( @steps, $self->_step( $tokens ) );
        if( @steps > 1 && 
            $steps[-1]->axis eq 'self' && 
            $steps[-1]->test == $self->_class_for( 'Step' )->TEST_NT_NODE )
        {
            pop( @steps );
        }
    }
    return( @steps );
}

sub _set_context_pos { return( shift->_set_get_scalar( 'context_pos', @_ ) ); }

sub _set_context_set { return( shift->_set_get_scalar( 'context_set', @_ ) ); }

sub _step
{
    my( $self, $tokens ) = @_;
    if( $self->_match( $tokens, qr/\./ ) )
    {
        # self::node()
        return( $self->new_step( $self, 'self', $self->_class_for( 'Step' )->TEST_NT_NODE ) );
    }
    elsif( $self->_match( $tokens, qr/\.\./ ) )
    {
        # parent::node()
        return( $self->new_step( $self, 'parent', $self->_class_for( 'Step' )->TEST_NT_NODE ) );
    }
    else
    {
        # AxisSpecifier NodeTest Predicate(s?)
        my $token = $tokens->[ $self->{_tokpos} ];
        
        my $step;
        if( $token eq 'processing-instruction' )
        {
            $self->{_tokpos}++;
            $self->_match( $tokens, qr/\(/, 1 );
            $self->_match( $tokens, $LITERAL_RE );
            $self->{_curr_match} =~ /^["'](.*)["']$/;
            $step = $self->new_step(
                $self, 'child',
                $self->_class_for( 'Step' )->TEST_NT_PI,
                $self->new_literal( $1 )
            );
            $self->_match( $tokens, qr/\)/, 1 );
        }
        elsif( $token =~ /^\@($NC_WILD_RE|$QNAME_RE|$QN_WILD_RE)$/o )
        {
            $self->{_tokpos}++;
            if( $token eq '@*' )
            {
                $step = $self->new_step(
                    $self, 'attribute',
                    $self->_class_for( 'Step' )->TEST_ATTR_ANY,
                    '*'
                );
            }
            elsif( $token =~ /^\@($NC_NAME_RE):\*$/o )
            {
                $step = $self->new_step(
                    $self, 'attribute',
                    $self->_class_for( 'Step' )->TEST_ATTR_NCWILD,
                    $1
                );
            }
            elsif( $token =~ /^\@($QNAME_RE)$/o )
            {
                $step = $self->new_step(
                    $self, 'attribute',
                    $self->_class_for( 'Step' )->TEST_ATTR_QNAME,
                    $1
                );
            }
        }
        # ns:*
        elsif( $token =~ /^($NC_NAME_RE):\*$/o )
        {
            $self->{_tokpos}++;
            $step = $self->new_step(
                $self, 'child', 
                $self->_class_for( 'Step' )->TEST_NCWILD,
                $1
            );
        }
        # *
        elsif( $token =~ /^$QN_WILD_RE$/o )
        {
            $self->{_tokpos}++;
            $step = $self->new_step(
                $self, 'child', 
                $self->_class_for( 'Step' )->TEST_ANY,
                $token
            );
        }
        # name:name
        elsif( $token =~ /^$QNAME_RE$/o )
        {
            $self->{_tokpos}++;
            $step = $self->new_step(
                $self, 'child', 
                $self->_class_for( 'Step' )->TEST_QNAME,
                $token
            );
        }
        elsif( $token eq 'comment()' )
        {
            $self->{_tokpos}++;
            $step = $self->new_step(
                $self, 'child',
                $self->_class_for( 'Step' )->TEST_NT_COMMENT
            );
        }
        elsif( $token eq 'text()' )
        {
            $self->{_tokpos}++;
            $step = $self->new_step(
                $self, 'child',
                $self->_class_for( 'Step' )->TEST_NT_TEXT
            );
        }
        elsif( $token eq 'node()' )
        {
            $self->{_tokpos}++;
            $step = $self->new_step(
                $self, 'child',
                $self->_class_for( 'Step' )->TEST_NT_NODE
            );
        }
        elsif( $token eq 'processing-instruction()' )
        {
            $self->{_tokpos}++;
            $step = $self->new_step(
                $self, 'child',
                $self->_class_for( 'Step' )->TEST_NT_PI
            );
        }
        elsif( $token =~ /^$AXIS_NAME_RE($NC_WILD_RE|$QNAME_RE|$QN_WILD_RE|$NODE_TYPE_RE)$/o )
        {
            my $axis = $1;
            $self->{_tokpos}++;
            $token = $2;
            if( $token eq 'processing-instruction' )
            {
                $self->_match( $tokens, qr/\(/, 1 );
                $self->_match( $tokens, $LITERAL_RE );
                $self->{_curr_match} =~ /^["'](.*)["']$/;
                $step = $self->new_step(
                    $self, $axis,
                    $self->_class_for( 'Step' )->TEST_NT_PI,
                    HTML::Object::XPath::Literal->new( $1 )
                );
                $self->_match( $tokens, qr/\)/, 1 );
            }
            # ns:*
            elsif( $token =~ /^($NC_NAME_RE):\*$/o )
            {
                $step = $self->new_step(
                    $self, $axis, 
                    ( ( $axis eq 'attribute' )
                        ? $self->_class_for( 'Step' )->TEST_ATTR_NCWILD
                        : $self->_class_for( 'Step' )->TEST_NCWILD
                    ),
                    $1
                );
            }
            # *
            elsif( $token =~ /^$QN_WILD_RE$/o )
            {
                $step = $self->new_step(
                    $self, $axis, 
                    ( ( $axis eq 'attribute' )
                        ? $self->_class_for( 'Step' )->TEST_ATTR_ANY
                        : $self->_class_for( 'Step' )->TEST_ANY
                    ),
                    $token
                );
            }
            # name:name
            elsif( $token =~ /^$QNAME_RE$/o )
            {
                $step = $self->new_step(
                    $self, $axis, 
                    ( ( $axis eq 'attribute' )
                        ? $self->_class_for( 'Step' )->TEST_ATTR_QNAME
                        : $self->_class_for( 'Step' )->TEST_QNAME
                    ),
                    $token
                );
            }
            elsif( $token eq 'comment()' )
            {
                $step = $self->new_step(
                    $self, $axis,
                    $self->_class_for( 'Step' )->TEST_NT_COMMENT
                );
            }
            elsif( $token eq 'text()' )
            {
                $step = $self->new_step(
                    $self, $axis,
                    $self->_class_for( 'Step' )->TEST_NT_TEXT
                );
            }
            elsif( $token eq 'node()' )
            {
                $step = $self->new_step(
                    $self, $axis,
                    $self->_class_for( 'Step' )->TEST_NT_NODE
                );
            }
            elsif( $token eq 'processing-instruction()' )
            {
                $step = $self->new_step(
                    $self, $axis,
                    $self->_class_for( 'Step' )->TEST_NT_PI
                );
            }
            else
            {
                die( "Shouldn't get here" );
            }
        }
        else
        {
            die( "token $token does not match format of a 'Step'\n" );
        }
        
        while( $self->_match( $tokens, qr/\[/ ) )
        {
            push( @{$step->{predicates}}, $self->_expr( $tokens ) );
            $self->_match( $tokens, qr/\]/, 1 );
        }
        return( $step );
    }
}

sub _tokenize
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    my $tokens = $self->new_array;
    
    
    # Bug: We do not allow "'@' NodeType" which is in the grammar, but I think is just plain stupid.
    
    # used to desambiguate conflicts (for REs)
    my $expected = '';

    while( length( $path ) )
    {
        my $token = '';
        if( $expected eq 'RE' && ( $path =~ m{\G\s*($REGEXP_RE $REGEXP_MOD_RE?)\s*}gcxso ) )
        {
            # special case: regexp expected after =~ or !~, regular parsing rules do not apply
            # ( the / is now the regexp delimiter) 
            $token    = $1;
            $expected = ''; 
        }
        elsif( $path =~ m/\G
            \s* # ignore all whitespace
            ( # tokens
                $LITERAL_RE|
                $NUMBER_RE|                            # digits
                \.\.|                                  # parent
                \.|                                    # current
                ($AXIS_NAME_RE)?$NODE_TYPE_RE|         # tests
                processing-instruction|
                \@($NC_WILD_RE|$QNAME_RE|$QN_WILD_RE)| # attrib
                \$$QNAME_RE|                           # variable reference
                ($AXIS_NAME_RE)?($NC_WILD_RE|$QNAME_RE|$QN_WILD_RE)| # NCName,NodeType,Axis::Test
                \!=|<=|\-|>=|\/\/|and|or|mod|div|      # multi-char seps
                =~|\!~|                                # regexp (not in the XPath spec)
                [,\+=\|<>\/\(\[\]\)]|                  # single char seps
                (?<!(\@|\(|\[))\*|                     # multiply operator rules (see xpath spec)
                (?<!::)\*|
                $                                      # end of query
            )
            \s*                                        # ignore all whitespace
            /gcxso ) 
        { 
            $token = $1;
            $expected = ( $token =~ m{^[=!]~$} ) ? 'RE' : '';
        }
        else
        {
            $token = '';
            last;
        }

        if( length( $token ) )
        {
            # push( @tokens, $token );
            $tokens->push( $token );
        }
    }
    
    if( pos( $path ) < length( $path ) )
    {
        my $marker = ( '.' x ( pos( $path ) -1 ) );
        $path = substr( $path, 0, pos( $path ) + 8 ) . '...';
        $path =~ s/\n/ /g;
        $path =~ s/\t/ /g;
        die "Query:\n", "$path\n", $marker, "^^^\n", "Invalid query somewhere around here (I think)\n";
        # return( $self->error( "Query:\n", "$path\n", $marker, "^^^\n", "Invalid query somewhere around here (I think)" ) );
    }
    # return( \@tokens );
    return( $tokens );
}

sub _xml_escape_text
{
    my( $self, $text ) = @_;
    my $entities = { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quote;' };
    $text =~ s{([&<>])}{$entities->{$1}}g;
    return( $text );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath - HTML Object XPath Class

=head1 SYNOPSIS

    use HTML::Object;
    use HTML::Object::XQuery;
    use HTML::Object::XPath;
    my $this = HTML::Object::XPath->new || die( HTML::Object::XPath->error, "\n" );

    my $p = HTML::Object->new;
    my $doc = $p->parse_file( $path_to_html_file ) || die( $p->error );
    # Returns a list of HTML::Object::Element objects matching the select, which is
    # converted into a xpath
    my @nodes = $doc->find( 'p' );

    # or directly:
    use HTML::Object::XPath;
    my $xp = use HTML::Object::XPath->new;
    my @nodes = $xp->findnodes( $xpath, $element_object );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module implements the XPath engine used by L<HTML::Object::XQuery> to provide a jQuery-like interface to query the parsed DOM object.

=head1 METHODS

=head2 clear_namespaces

Clears all previously set namespace mappings.

=head2 exists

Provided with a C<path> and a C<context> and this returns true if the given path exists.

=head2 findnodes

Provided with a C<path> and a C<context> this returns a list of nodes found by C<path>, optionally in context C<context>.

In scalar context it returns an HTML::Object::XPath::NodeSet object.

=head2 findnodes_as_string

Provided with a C<path> and a C<context> and this returns the nodes found as a single string. The result is not guaranteed to be valid HTML though (it could for example be just text if the query returns attribute values).

=head2 findnodes_as_strings

Provided with a C<path> and a C<context> and this returns the nodes found as a list of strings, one per node found.

=head2 findvalue

Provided with a C<path> and a C<context> and this returns the result as a string (the concatenation of the values of the result nodes).

=head2 findvalues

Provided with a C<path> and a C<context> and this returns the values of the result nodes as a list of strings.

=head2 matches($node, $path, $context)

Provided with a C<node> L<object|HTML::Object::Element>, C<path> and a C<context> and this returns true if the node matches the path.

=head2 find

Provided with a C<path> and a C<context> and this returns either a L<HTML::Object::XPath::NodeSet> object containing the nodes it found (or empty if no nodes matched the path), or one of L<HTML::Object::XPath::Literal> (a string), L<HTML::Object::XPath::Number>, or L<HTML::Object::XPath::Boolean>. It should always return something - and you can use ->isa() to find out what it returned. If you need to check how many nodes it found you should check $nodeset->size.

See L<HTML::Object::XPath::NodeSet>. 

=head2 get_namespace ($prefix, $node)

Provided with a C<prefix> and a C<node> L<object|HTML::Object::Element> and this returns the uri associated to the prefix for the node (mostly for internal usage)

=head2 get_var

Provided with a variable name, and this returns the value of the XPath variable (mostly for internal usage)

=head2 getNodeText

Provided with a C<path> and this returns the text string for a particular node. It returns a string, or C<undef> if the node does not exist.

=head2 namespaces

Sets or gets an hash reference of namespace attributes.

=head2 new_expr

Create a new L<HTML::Object::XPath::Expr>, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_function

Create a new L<HTML::Object::XPath::Function> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_literal

Create a new L<HTML::Object::XPath::Literal> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_location_path

Create a new L<HTML::Object::XPath::LocationPath> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_nodeset

Create a new L<HTML::Object::XPath::NodeSet> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_number

Create a new L<HTML::Object::XPath::Number> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_root

Create a new L<HTML::Object::XPath::Root> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_step

Create a new L<HTML::Object::XPath::Step> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 new_variable

Create a new L<HTML::Object::XPath::Variable> object, passing it whatever argument was provided, and returns the newly instantiated object, or C<undef> upon L<error|Module::Generic/error>

=head2 set_namespace

Provided with a C<prefix> and an C<uri> and this sets the namespace prefix mapping to the uri.

Normally in L<HTML::Object::XPath> the prefixes in XPath node tests take their context from the current node. This means that foo:bar will always match an element <foo:bar> regardless of the namespace that the prefix foo is mapped to (which might even change within the document, resulting in unexpected results). In order to make prefixes in XPath node tests actually map to a real URI, you need to enable that via a call to the set_namespace method of your HTML::Object::XPath object.

=head2 parse

Provided with an XPath expression and this returns a new L<HTML::Object::XPath::Expr> object that can then be used repeatedly.

You can create an XPath expression from a CSS selector expression using L<HTML::selector::XPath>

=head2 set_strict_namespaces

Takes a boolean value.

By default, for historical as well as convenience reasons, L<HTML::Object::XPath> has a slightly non-standard way of dealing with the default namespace. 

If you search for C<//tag> it will return elements C<tag>. As far as I understand it, if the document has a default namespace, this should not return anything. You would have to first do a C<set_namespace>, and then search using the namespace.

Passing a true value to C<set_strict_namespaces> will activate this behaviour, passing a false value will return it to its default behaviour.

=head2 set_var

Provided with a variable name and its value and this sets an XPath variable (that can be used in queries as C<$var>)

=head1 NODE STRUCTURE

All nodes have the same first 2 entries in the array: node_parent and node_pos. The type of the node is determined using the ref() function.

The node_parent always contains an entry for the parent of the current node - except for the root node which has undef in there. And node_pos is the position of this node in the array that it is in (think: $node == $node->[node_parent]->[node_children]->[$node->[node_pos]] )

Nodes are structured as follows:

=head2 Root Node

The L<root node|HTML::Object::Root> is just an element node with no parent.

    [
      undef, # node_parent - check for undef to identify root node
      undef, # node_pos
      undef, # node_prefix
      [ ... ], # node_children (see below)
    ]

=head2 L<Element|HTML::Object::Element> Node

    [
      $parent, # node_parent
      <position in current array>, # node_pos
      'xxx', # node_prefix - namespace prefix on this element
      [ ... ], # node_children
      'yyy', # node_name - element tag name
      [ ... ], # node_attribs - attributes on this element
      [ ... ], # node_namespaces - namespaces currently in scope
    ]

=head2 L<Attribute|HTML::Object::Attribute> Node

    [
      $parent, # node_parent - the element node
      <position in current array>, # node_pos
      'xxx', # node_prefix - namespace prefix on this element
      'href', # node_key - attribute name
      'ftp://ftp.com/', # node_value - value in the node
    ]

=head2 L<Text|HTML::Object::Text> Nodes

    [
      $parent,
      <pos>,
      'This is some text' # node_text - the text in the node
    ]

=head2 L<Comment|HTML::Object::Comment> Nodes

    [
      $parent,
      <pos>,
      'This is a comment' # node_comment
    ]

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/XPath/Introduction_to_using_XPath_in_JavaScript>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
