# $Id: Host.pm 18 2008-05-05 23:55:18Z jabra $
package Dirbuster::Parser::Result;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @path : Field : Arg(path) : Get(path);
    my @response_code : Field : Arg(response_code) : Get(response_code);
    my @type : Field : Arg(type) : Get(type);
}
1;
