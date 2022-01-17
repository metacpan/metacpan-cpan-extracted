##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Function.pm
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
package HTML::Object::XPath::Function;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use HTML::Object::XPath::Boolean;
    our $TRUE  = HTML::Object::XPath::Boolean->True;
    our $FALSE = HTML::Object::XPath::Boolean->False;
    our $BASE_CLASS = 'HTML::Object::XPath';
    our $DEBUG = 0;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    # XPath Parser -> HTML::Object::XPath
    $self->{pp} = shift( @_ );
    $self->{name} = shift( @_ );
    $self->{params} = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $string = $self->{name} . '(';
    my $second;
    foreach( @{$self->{params}} )
    {
        $string .= ',' if( $second++ );
        $string .= $_->as_string;
    }
    $string .= ')';
    return( $string );
}

sub as_xml
{
    my $self = shift( @_ );
    my $string = sprintf( '<Function name="%s"', $self->{name} );
    my $params = '';
    foreach( @{$self->{params}} )
    {
        $params .= '<Param>' . $_->as_xml . "</Param>\n";
    }
    if( $params )
    {
        $string .= ">\n$params</Function>\n";
    }
    else
    {
        $string .= " />\n";
    }
    return( $string );
}

sub boolean
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "boolean: Incorrect number of parameters\n" ) if( @params != 1 );
    return( $params[0]->to_boolean );
}

sub ceiling
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    require POSIX;
    my $num = $self->number( $node, @params );
    return( $self->new_number( POSIX::ceil( $num->value ) ) );
}

sub concat
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "concat: Too few parameters\n" ) if( @params < 2 );
    # XXX Check for improvement
    my $string = join( '', map{ $_->string_value } @params );
    return( $self->new_literal( $string ) );
}

sub contains
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "starts-with: incorrect number of params\n" ) unless( @params == 2 );
    my $value = $params[1]->string_value;
    if( $params[0]->string_value =~ /(.*?)\Q$value\E(.*)/ )
    {
        return( $TRUE );
    }
    return( $FALSE );
}

sub count
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "count: Parameter must be a NodeSet\n" ) unless( $params[0]->isa( 'HTML::Object::XPath::NodeSet' ) );
    return( $self->new_number( $params[0]->size ) );
}

sub evaluate
{
    my $self = shift( @_ );
    my $node = shift( @_ );
    while( $node->isa( 'HTML::Object::XPath::NodeSet' ) )
    {
        $node = $node->get_node(1);
    }
    my @params;
    foreach my $param ( @{$self->{params}} )
    {
        $self->message( 3, "Evaluating node '$node' (", $node->as_string, ") using '$param'" );
        my $results = $param->evaluate( $node );
        $self->message( 3, "Adding results '$results' from $param->evaluate( $node ) to \@params" );
        push( @params, $results );
    }
    $self->message( 3, "Calling $self->_execute with name '$self->{name}, node '$node' and params '", join( "', '", @params ), "'" );
    return( $self->_execute( $self->{name}, $node, @params ) );
}

sub false
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "true: function takes no parameters\n" ) if( @params > 0 );
    return( $FALSE );
}

sub floor
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    require POSIX;
    my $num = $self->number( $node, @params );
    return( $self->new_number( POSIX::floor( $num->value ) ) );
}

sub id
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "id: Function takes 1 parameter\n" ) unless( @params == 1 );
    my $results = $self->new_nodeset();
    if( $self->_is_a( $params[0] => 'HTML::Object::XPath::NodeSet' ) )
    {
        # result is the union of applying id() to the
        # string value of each node in the nodeset.
        foreach my $node ( $params[0]->get_nodelist )
        {
            my $string = $node->string_value;
            $results->append( $self->id( $node, $self->new_literal( $string ) ) );
        }
    }
    # The actual id() function...
    else
    {
        my $string = $self->string( $node, $params[0] );
        # get perl scalar
        # $_ = $string->value;
        # split $_
        # my @ids = split;
        # die( "Splitting '", $string->value, "' with result: '", join( "', '", @ids ), "'\n" );
        my @ids = split( /[[:blank:]]/, $string->value );
        if( $node->isAttributeNode )
        {
            warn( "calling \($node->getParentNode->getRootNode->getChildNodes)->[0] on attribute node\n" );
            $node = ( $node->getParentNode->getRootNode->getChildNodes )->[0];
        }
        foreach my $id ( @ids )
        {
            if( my $found = $node->getElementById( $id ) )
            {
                $results->push( $found );
            }
        }
    }
    return( $results );
}

sub lang
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "lang: function takes 1 parameter\n" ) if( @params != 1 );
    my $lang = $node->findvalue( '(ancestor-or-self::*[@xml:lang]/@xml:lang)[1]' );
    my $lclang = lc( $params[0]->string_value );
    # warn("Looking for lang($lclang) in $lang\n");
    if( substr( lc( $lang ), 0, length( $lclang ) ) eq $lclang )
    {
        return( $TRUE );
    }
    else
    {
        return( $FALSE );
    }
}

sub last
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "last: function doesn't take parameters\n" ) if( scalar( @params ) );
    return( $self->new_number( $self->{pp}->_get_context_size ) );
}

sub local_name
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    if( @params > 1 )
    {
        die( "name() function takes one or no parameters\n" );
    }
    elsif( @params )
    {
        my $nodeset = shift( @params );
        $node = $nodeset->get_node(1);
    }
    return( $self->new_literal( $node->getLocalName ) );
}

sub name
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    if( @params > 1 )
    {
        die( "name() function takes one or no parameters\n" );
    }
    elsif( @params )
    {
        my $nodeset = shift( @params );
        $node = $nodeset->get_node(1);
    }
    return( $self->new_literal( $node->getName ) );
}

sub namespace_uri
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "namespace-uri: Function not supported\n" );
}

sub new_literal { return( shift->_class_for( 'Literal' )->new( @_ ) ); }

sub new_nodeset { return( shift->_class_for( 'NodeSet' )->new( @_ ) ); }

sub new_number { return( shift->_class_for( 'Number' )->new( @_ ) ); }

sub normalize_space
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "normalize-space: Wrong number of params\n" ) if( @params > 1 );
    my $str;
    if( @params )
    {
        $str = $params[0]->string_value;
    }
    else
    {
        $str = $node->string_value;
    }
    # $str =~ s/^\s*//;
    # $str =~ s/\s*$//;
    $str =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
    # $str =~ s/\s+/ /g;
    $str =~ s/[[:blank:]\h]+/ /g;
    return( $self->new_literal( $str ) );
}

sub not
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    $params[0] = $params[0]->to_boolean unless( $params[0]->isa( 'HTML::Object::XPath::Boolean' ) );
    return( $params[0]->value ? $FALSE : $TRUE );
}

sub number
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "number: Too many parameters\n" ) if( @params > 1 );
    if( @params )
    {
        if( $params[0]->isa( 'HTML::Object::XPath::Node' ) )
        {
            return( $self->new_number( $params[0]->string_value ) );
        }
        return( $params[0]->to_number );
    }
    return( $self->new_number( $node->string_value ) );
}

sub position
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    if( scalar( @params ) )
    {
        die( "position: function doesn't take parameters [ ", @params, " ]\n" );
    }
    # return pos relative to axis direction
    return( $self->new_number( $self->{pp}->_get_context_pos ) );
}

sub round
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    my $num = $self->number( $node, @params );
    require POSIX;
    # Yes, I know the spec says do not do this...
    # return( $self->new_number( POSIX::floor( $num->value + 0.5 ) ) );
    return( $self->new_number( CORE::sprintf( '%.*f', $num->value ) ) );
}

sub starts_with
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "starts-with: incorrect number of params\n" ) unless( @params == 2 );
    my( $string1, $string2 ) = ( $params[0]->string_value, $params[1]->string_value );
    if( substr( $string1, 0, length( $string2 ) ) eq $string2 )
    {
        return( $TRUE );
    }
    return( $FALSE );
}

sub string
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "string: Too many parameters\n" ) if( @params > 1 );
    if( @params )
    {
        return( $self->new_literal( $params[0]->string_value ) );
    }
    
    # TODO - this MUST be wrong! - not sure now. -matt
    return( $self->new_literal( $node->string_value ) );
    # default to nodeset with just $node in.
}

sub string_length
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "string-length: Wrong number of params\n" ) if( @params > 1 );
    if( @params )
    {
        return( $self->new_number( length( $params[0]->string_value ) ) );
    }
    else
    {
        return( $self->new_number( length( $node->string_value ) ) );
    }
}

sub substring
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "substring: Wrong number of parameters\n" ) if( @params < 2 || @params > 3 );
    my( $str, $offset, $len );
    $str = $params[0]->string_value;
    $offset = $params[1]->value;
    # uses 1 based offsets
    $offset--;
    if( @params == 3 )
    {
        $len = $params[2]->value;
        return( $self->new_literal( substr( $str, $offset, $len ) ) );
    }
    else
    {
        return( $self->new_literal( substr( $str, $offset ) ) );
    }
}

sub substring_after
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "starts-with: incorrect number of params\n" ) unless( @params == 2 );
    my $long  = $params[0]->string_value;
    my $short = $params[1]->string_value;
    if( $long =~ m{\Q$short\E(.*)$} )
    {
        return( $self->new_literal( $1 ) );
    }
    else
    {
        return( $self->new_literal( '' ) );
    }
}

sub substring_before
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "starts-with: incorrect number of params\n" ) unless( @params == 2 );
    my $long  = $params[0]->string_value;
    my $short = $params[1]->string_value;
    if( $long =~ m{^(.*?)\Q$short} )
    {
        return( $self->new_literal( $1 ) );
    }
    else
    {
        return( $self->new_literal( '' ) );
    }
}

sub sum
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "sum: Parameter must be a NodeSet\n" ) unless( $params[0]->isa( 'HTML::Object::XPath::NodeSet' ) );
    my $sum = 0;
    foreach my $node ( $params[0]->get_nodelist )
    {
        $sum += $self->number( $node )->value;
    }
    return( $self->new_number( $sum ) );
}

sub translate
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "translate: Wrong number of params\n" ) if( @params != 3 );
    local $_ = $params[0]->string_value;
    my $find = $params[1]->string_value;
    my $repl = $params[2]->string_value;
    $repl= substr( $repl, 0, length( $find ) );
    my %repl;
    @repl{split( //, $find )} = split( //, $repl );
    s{(.)}
    {
        CORE::exists( $repl{$1} ) ? defined( $repl{$1} ) ? $repl{$1} : '' : $1
    }ges;
    return( $self->new_literal( $_ ) );
}

sub true
{
    my $self = shift( @_ );
    my( $node, @params ) = @_;
    die( "true: function takes no parameters\n" ) if( @params > 0 );
    return( $TRUE );
}

sub _class_for
{
    my( $self, $mod ) = @_;
    eval( "require ${BASE_CLASS}\::${mod};" );
    die( $@ ) if( $@ );
    ${"${BASE_CLASS}\::${mod}\::DEBUG"} = $DEBUG;
    return( "${BASE_CLASS}::${mod}" );
}

sub _execute
{
    my $self = shift( @_ );
    my( $name, $node, @params ) = @_;
    $name =~ s/-/_/g;
    no strict 'refs';
    $self->message( 3, "Calling method '$self-\>$name' with node '$node' and params '", join( "', '", @params ), "'" );
    return( $self->$name( $node, @params ) );
}

1;

__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath::Function - HTML Object XPath Functions

=head1 SYNOPSIS

    use HTML::Object::XPath::Function;
    my $func = HTML::Object::XPath::Function->new || 
        die( HTML::Object::XPath::Function->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module implements various XPath functions described below.

=head1 CONSTRUCTOR

Provided with a L<XPath object|HTML::Object::XPath>, a function C<name> and function C<parameters> and this will instantiate a new L<HTML::Object::Function> object and return it.

=head1 METHODS

=head2 as_string

Returns a string representation of this function object.

=head2 as_xml

Returns a xml representation of this function object.

=head2 boolean

Provided with a L<node object|HTML::Object::Element> and a list of parameters and this will return the first parameter as a L<boolean object|HTML::Object::XPath::Booleab>. It will raise an exception if there are more than one arguments provided.

=head2 ceiling

Provided with a L<node object|HTML::Object::Element> and an optional parameter, and this will return the L<ceiling|POSIX/ceil> of the string value of the node or that of the parameter provided, if any.

It returns its value as a new L<number object|HTML::Object::XPath::Number>. It will raise an exception if more than one parameter was provided.

=head2 concat

Provided with a L<node object|HTML::Object::Element> and a list of 2 parameters or more and this will return a new L<literal object|HTML::Object::XPath::Literal> from the concatenation of each parameter string value.

=head2 contains

Provided with a L<node object|HTML::Object::Element> and a list of exactly 2 parameters and this will return L<true|HTML::Object::XPath::Boolean> if the first parameter match the second one as a regular expression, or returns L<false|HTML::Object::XPath::Boolean> otherwise.

=head2 count

Provided with a L<node object|HTML::Object::Element> and a L<node set|HTML::Object::XPath::NodeSet> and this will return the size of the node set as a L<number|HTML::Object::XPath::Number>

=head2 evaluate

Provided with a L<node object|HTML::Object::Element> and this will evaluate the node using each parameter set during object instantiation and add the result for each in a new array.

It will then return the execution of the function name on the node passing it the list of previously collected results.

=head2 false

Returns L<false|HTML::Object::XPath::Boolean> and it will raise an exception if any arguments was provided.

=head2 floor

Provided with a L<node object|HTML::Object::Element> and an optional parameter, and this will return the L<floor|
POSIX/floor> of the string value of the node or that of the parameter provided, if any.

It returns its value as a new L<number object|HTML::Object::XPath::Number>. It will raise an exception if more than one parameter was provided.

=head2 id

Provided with a L<node object|HTML::Object::Element> and 1 parameter, and this will return a new L<node set|HTML::Object::XPath::NodeSet> of L<element object|HTML::Object::Element> who match the id found in the node provided.

=head2 lang

Provided with a L<node object|HTML::Object::Element> and 1 parameter, and this will return L<true|HTML::Object::XPath::Boolean> if the node lang, if any at all, match the one provide as a parameter, otherwise it returns L<false|HTML::Object::XPath::Boolean>.

=head2 last

This takes no argument and returns the size, as a L<number|HTML::Object::XPath::Number> of the nodes in the context set in XPath.

=head2 local_name

Provided with a L<node object|HTML::Object::Element> and optionally some parameter and this will return the local name of the node, or that of the first parameter provided, if any, as a L<literal object|HTML::Object::XPath::Literal>

=head2 name

Provided with a L<node object|HTML::Object::Element> and optionally some parameter and this will return the name of the node, or that of the first parameter provided, if any, as a L<literal object|HTML::Object::XPath::Literal>

=head2 namespace_uri

This is an unsupported function and it will raise an exception when called.

=head2 new_literal

Returns a new L<literal object|HTML::Object::XPath::Literal> passing it whatever arguments was provided.

=head2 new_nodeset

Returns a new L<node set object|HTML::Object::XPath::NodeSet> passing it whatever arguments was provided.

=head2 new_number

Returns a new L<number object|HTML::Object::XPath::Number> passing it whatever arguments was provided.

=head2 normalize_space

Provided with a L<node object|HTML::Object::Element> and optionally some parameter and this will take the string value of the node, or that of the first parameter, if any at al, and remove any leading or trailing spaces as well as replacing multiple spaces by just one space, and return the new string as a L<literal object|HTML::Object::XPath::Literal>

=head2 not

Provided with a L<node object|HTML::Object::Element> and one parameter and this will return L<true|HTML::Object::XPath::Boolean> if the value of the first parameter is B<not> true, or L<false|HTML::Object::XPath::Boolean> otherwise.

=head2 number

Provided with a L<node object|HTML::Object::Element> and optionally one parameter and this will return the node string value, or that of the parameter provided, if any, as a new L<number object|HTML::Object::XPath::Number>

=head2 position

Returns th context position as a L<number|HTML::Object::XPath::Number>. It will raise an exception if any parameter was provided.

=head2 round

=head2 starts_with

Provided with a L<node object|HTML::Object::Element> and two parameters and this will return L<true|HTML::Object::XPath::Boolean> if the string value of the second parameter is at the beginning of the first parameter, or L<false|HTML::Object::XPath::Boolean> otherwise.

=head2 string

Provided with a L<node object|HTML::Object::Element> and one parameter and this returns the parameter string value as a new L<literal object|HTML::Object::XPath::Literal>

It will raise an exception if more than one parameter was provided.

=head2 string_length

Provided with a L<node object|HTML::Object::Element> and optionally one parameter and this will return the size, as a L<number|HTML::Object::XPath::Number>, of the string value of the node or that of the parameter if any was provided.

=head2 substring

Provided with a L<node object|HTML::Object::Element> and two or three parameters and this returns the substring of of the first parameter as a value, at offset specified by the second parameter, and optionally for a length defined by a third parameter, if any. If no third parameter is provided, then it will be until the end of the string.

It returns the substring as a new L<literal object|HTML::Object::XPath::Literal>. It will raise an exception if less than 2 or more than 3 parameters were provided.

=head2 substring_after

Provided with a L<node object|HTML::Object::Element> and two parameters and this will return the string that follows the string value of the second parameter in the first one up to its end.

It returns the substring as a new L<literal object|HTML::Object::XPath::Literal>. It will raise an exception if less or more than 2 parameters were provided.

=head2 substring_before

Provided with a L<node object|HTML::Object::Element> and two parameters and this will return the string that precede the string value of the second parameter in the first one up to its start.

It returns the substring as a new L<literal object|HTML::Object::XPath::Literal>. It will raise an exception if less or more than 2 parameters were provided.

=head2 sum

Provided with a L<node object|HTML::Object::Element> and a parameters that must be a L<node set|HTML::Object::XPath::NodeSet> and this will return the cumulative string value of each node as a number.

It returns the resulting total as a new L<number> object|HTML::Object::XPath::Number>. It will raise an exception if the parameter provided is not a L<HTML::Object::XPath::NodeSet> object.

=head2 translate

Provided with a L<node object|HTML::Object::Element> and three parameters, and this will search in the first parameter for any occurrence of characters found in the second parameter and replace them with their alternative at the exact same position in string in the third parameter.

It returns the substring as a new L<literal object|HTML::Object::XPath::Literal>. It will raise an exception if less or more than 3 parameters were provided.

=head2 true

Returns L<true|HTML::Object::XPath::Boolean> and it will raise an exception if any arguments was provided.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
