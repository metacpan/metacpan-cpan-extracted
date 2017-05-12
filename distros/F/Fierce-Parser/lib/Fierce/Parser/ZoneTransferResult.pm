# $Id: ZoneTransferResult.pm 291 2009-11-15 22:05:38Z jabra $
package Fierce::Parser::ZoneTransferResult;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    my @name_server : Field : Arg(name_server) : Get(name_server);
    my @domain : Field : Arg(domain) : Get(domain);
    my @bool : Field : Arg(bool) : Get(bool);
    my @raw_output : Field : Arg(raw_output) : Get(raw_output);
    my @nodes : Field : Arg(nodes) : Get(nodes) :
        Type(List(Fierce::Parser::Node));
}
1;
