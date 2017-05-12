# $Id: Node.pm 291 2009-11-15 22:05:38Z jabra $
package Fierce::Parser::Node;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    my @ip : Field : Arg(ip) : Get(ip);
    my @hostname : Field : Arg(hostname) : Get(hostname);
    my @type : Field : Arg(type) : Get(type);
    my @ttl : Field : Arg(ttl) : Get(ttl);
    my @from : Field : Arg(from) : Get(from);
}
1;
