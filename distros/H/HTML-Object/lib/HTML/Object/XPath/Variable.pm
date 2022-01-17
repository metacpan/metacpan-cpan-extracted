##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Variable.pm
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
package HTML::Object::XPath::Variable;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $DEBUG = 0;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{path_parser} = shift( @_ );
    $self->{name} = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    return( '\$' . $self->{name} );
}

sub as_xml
{
    my $self = shift( @_ );
    return( "<Variable>" . $self->{name} . "</Variable>\n" );
}

sub get_value
{
    my $self = shift( @_ );
    return( $self->{path_parser}->get_var( $self->{name} ) );
}

sub set_value
{
    my $self = shift( @_ );
    my $val  = shift( @_ );
    return( $self->{path_parser}->set_var( $self->{name} => $val ) );
}

sub evaluate
{
    my $self = shift( @_ );
    my $val = $self->get_value;
    return( $val );
}

1;

__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath::Variable - HTML Object XPath Variable

=head1 SYNOPSIS

    use HTML::Object::XPath::Variable;
    my $var = HTML::Object::XPath::Variable->new || 
        die( HTML::Object::XPath::Variable->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This represent a L<HTML::Object::XPath> variable

=head1 CONSTRUCTOR

=head2 new

Provided with a L<HTML::Object::XPath> object and a variable name and this return a new l<HTML::Object::XPath::Variable> object.

=head1 METHODS

=head2 as_string

Returns a string representation of the variable.

=head2 as_xml

Returns a xml representation of the variable.

=head2 get_value

Returns the value for the variable set upon object instantiation. This actually calls L<HTML::Object::XPath/get_var>

=head2 set_value

Set the value for the variable set upon object instantiation. This actually calls L<HTML::Object::XPath/set_var>

=head2 evaluate

Returns the variable value by returning L</get_value>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
