# $Id: WhoisLookup.pm 84 2009-05-19 16:42:43Z jabra $
package Fierce::Parser::Domain::ARIN;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @result : Field : Arg(result) : Get(result) :
        Type(List(Fierce::Parser::RangeResult));

    my @query : Field : Arg(query) : Get(query);

    my @starttime : Field : Arg(starttime) : Get(starttime);
    my @endtime : Field : Arg(endtime) : Get(endtime);
    my @starttimestr : Field : Arg(starttimestr) : Get(starttimestr);
    my @endtimestr : Field : Arg(endtimestr) : Get(endtimestr);
    my @elapsedtime : Field : Arg(elapsedtime) : Get(elapsedtime);
}
1;
