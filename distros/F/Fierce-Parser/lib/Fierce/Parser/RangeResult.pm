# $Id: RangeResult.pm 207 2009-10-24 20:33:30Z jabra $
package Fierce::Parser::RangeResult;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    my @net_range : Field : Arg(net_range) : Get(net_range);
    my @net_handle : Field : Arg(net_handle) : Get(net_handle);
}
1;
