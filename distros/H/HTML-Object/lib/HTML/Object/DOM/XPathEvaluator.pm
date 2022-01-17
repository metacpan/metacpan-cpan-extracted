##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/XPathEvaluator.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/01
## Modified 2022/01/01
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::XPathEvaluator;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use HTML::Object::XPath;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_xp} = HTML::Object::XPath->new;
    return( $self );
}

sub createExpression { return( shift->{_xp}->parse( @_ ) ); }

sub createNSResolver { return; }

sub evaluate
{
    my $self = shift( @_ );
    my $expr = shift( @_ );
    if( $self->_is_a( $expr => 'HTML::Object::XPath::Expr' ) )
    {
        return( $expr->evaluate( @_ ) );
    }
    elsif( !ref( $expr ) || overload::Method( $expr, '""' ) )
    {
        my $xpath = $self->{_xp}->parse( $expr ) || return( $self->pass_error( $self->{_xp}->error ) );
        return( $xpath->evaluate( @_ ) );
    }
    else
    {
        return( $self->error({
            message => 'Value provided (' . overload::StrVal( $expr ) . ' is not a HTML::Object::XPath::Expr object. You can create one using createExpression()',
            class => 'HTML::Object::TypeError',
        }) );
    }
    return( $self );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::XPathEvaluator - HTML Object DOM XPathEvaluator Class

=head1 SYNOPSIS

    use HTML::Object::DOM::XPathEvaluator;
    my $this = HTML::Object::DOM::XPathEvaluator->new || 
        die( HTML::Object::DOM::XPathEvaluator->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<XPathEvaluator> interface allows to compile and evaluate XPath expressions.

=head1 PROPERTIES

There are no properties.

=head1 METHODS

=head2 createExpression

Creates a parsed XPath expression with resolved namespaces.

Example:

    <div>XPath example</div>
    <div>Number of &lt;div&gt;s: <output></output></div>

    use HTML::Object::DOM;
    my $parser = HTML::Object::DOM->new;
    my $doc = $parser->parse_data( $html ) || die( $parser->error );
    my $evaluator = HTML::Object::DOM::XPathEvaluator->new;
    my $expression = $evaluator->createExpression( '//div' );
    my $result = $expression->evaluate( $document );
    $doc->querySelector( 'output' )->textContent = $result->snapshotLength;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathEvaluator/createExpression>

=head2 createNSResolver

This always returns C<undef>, since this L<HTML::Object> does not work on XML documents.

Normally, this would adapt any L<DOM node|HTML::Object::DOM::Node> to resolve namespaces allowing the XPath expression to be evaluated relative to the context of the node where it appeared within the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathEvaluator/createNSResolver>

=head2 evaluate

Evaluates an XPath expression string and returns a result of the specified type if possible.

Parameters:

=over 4

=item expression

A string representing the XPath expression to be parsed and evaluated, or an L<XPath expression object|HTML::Object::XPath::Expr> to be evaluated. The latter would be equivalent to:

    $xpath_expression->evaluate( $context );

With C<$context> being a L<node object|HTML::Object::DOM::Node> provided, such as L<HTML::Object::DOM::Document>.

=item contextNode

A L<Node|HTML::Object::DOM::Node> representing the context to use for evaluating the expression.

=back

Example:

    <div>XPath example</div>
    <div>Number of &lt;div&gt;s: <output></output></div>

    use HTML::Object::DOM;
    my $parser = HTML::Object::DOM->new;
    my $doc = $parser->parse_data( $html ) || die( $parser->error );
    my $evaluator = HTML::Object::DOM::XPathEvaluator->new;
    my $result = $evaluator->evaluate( '//div', $doc );
    $doc->querySelector( 'output' )->textContent = $result->snapshotLength;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathEvaluator/evaluate>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Selector::XPath>, L<HTML::Object::XPath>, L<HTML::Object::XPath::Expr>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
