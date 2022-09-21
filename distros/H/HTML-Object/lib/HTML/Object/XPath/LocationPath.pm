##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/LocationPath.pm
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
package HTML::Object::XPath::LocationPath;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $BASE_CLASS $DEBUG $VERSION );
    our $BASE_CLASS = 'HTML::Object::XPath';
    our $DEBUG = 0;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    return( bless( [] => ( ref( $this ) || $this ) ) );
}

sub as_string
{
    my $self = shift( @_ );
    my $string;
    for( my $i = 0; $i < @$self; $i++ )
    {
        $string .= $self->[ $i ]->as_string;
        $string .= '/' if( $self->[ $i + 1 ] );
    }
    return( $string );
}

sub as_xml
{
    my $self = shift( @_ );
    my $string = "<LocationPath>\n";
    
    for (my $i = 0; $i < @$self; $i++ )
    {
        $string .= $self->[ $i ]->as_xml;
    }
    $string .= "</LocationPath>\n";
    return( $string );
}

sub evaluate
{
    my $self = shift( @_ );
    # context _MUST_ be a single node
    my $context = shift( @_ );
    die( "No context" ) unless( $context );
    if( $self->debug )
    {
        my( $p, $f, $l ) = caller;
    }
    
    # I _think_ this is how it should work :)
    my $nodeset = $self->new_nodeset();
    $nodeset->push( $context );
    
    foreach my $step ( @$self )
    {
        # For each step
        # evaluate the step with the nodeset
        my $pos = 1;
        # die( "Looping !\n" ) if( ref( $step ) eq ref( $self ) );
        die( "Looping !\n" ) if( $step eq $self );
        $nodeset = $step->evaluate( $nodeset );
    }
    return( $nodeset );
}

sub new_nodeset { return( shift->_class_for( 'NodeSet' )->new( @_ ) ); }

sub new_root { return( shift->_class_for( 'Root' )->new( @_ ) ); }

# sub push { return( CORE::push( @{$_[0]}, @_ ) ); }
sub push
{
    my $self = shift( @_ );
    if( $self->debug )
    {
        my( $p, $f, $l ) = caller;
        for( @_ )
        {
            if( ref( $_ ) eq ref( $self ) )
            {
                die( "A LocationPath object was added to its own stack!\n" );
            }
        }
    }
    return( CORE::push( @$self, @_ ) );
}

sub set_root
{
    my $self = shift( @_ );
    return( unshift( @$self, $self->new_root ) );
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

HTML::Object::XPath::LocationPath - HTML Object XPath Location Path

=head1 SYNOPSIS

    use HTML::Object::XPath::LocationPath;
    my $this = HTML::Object::XPath::LocationPath->new || 
        die( HTML::Object::XPath::LocationPath->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module represents a XML LocationPath.

=head1 CONSTRUCTOR

Takes no argument and returns a new array-based object.

=head1 METHODS

=head2 as_string

For each element in it the current object array, this will call C<as_string> and concatenate those strings separated by C</>. It returns the result as a regular perl string.

=head2 as_xml

Calls C<as_xml> on each elements in the current object array and returns the concatenated string enclosed in <LocationPath> and </LocationPath>

=head2 evaluate

Provided with a L<context|HTML::Object::Element>, and this will call C<evaluate> for each object in the stack. It returns a new L<HTML::Object::XPath::NodeSet> object containing the result with the C<context> initially provided as the first in the node set.

=head2 new_nodeset

Returns a new L<HTML::Object::XPath::NodeSet> passing it whatever argument was provided.

=head2 new_root

Returns a new L<HTML::Object::XPath::Root> passing it whatever argument was provided.

=head2 push

Add the elements provided to the object array.

=head2 set_root

Add a new L<root object|HTML::Object::XPath::Root> as the first element of our internal array.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
