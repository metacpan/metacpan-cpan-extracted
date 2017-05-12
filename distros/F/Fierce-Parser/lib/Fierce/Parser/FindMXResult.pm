# $Id: FindMXResult.pm 207 2009-10-24 20:33:30Z jabra $
package Fierce::Parser::FindMXResult;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    my @preference : Field : Arg(preference) : Get(preference);
    my @exchange : Field : Arg(exchange) : Get(exchange);
}
1;
