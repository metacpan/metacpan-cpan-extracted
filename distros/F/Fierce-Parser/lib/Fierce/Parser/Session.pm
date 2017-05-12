# $Id: Session.pm 297 2009-11-16 04:37:07Z jabra $
package Fierce::Parser::Session;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Fierce::Parser::DomainScanDetails;

    my @options : Field : Arg(options) : All(options);
    my @startscan : Field : Arg(startscan) : All(startscan);
    my @startscanstr : Field : Arg(startscanstr) : All(startscanstr);
    my @endscan : Field : Arg(endscan) : All(endscan);
    my @endscanstr : Field : Arg(endscanstr) : All(endscanstr);
    my @elapsedtime : Field : Arg(elapsedtime) : All(elapsedtime);
    my @fversion : Field : Arg(fversion) : All(fversion);
    my @xmlversion : Field : Arg(xmlversion) : All(xmlversion);
    my @domainscandetails : Field : Arg(domainscandetails) :
        Get(domainscandetails) : Type(Fierce::Parser::DomainScanDetails);

    sub parse {
        my ( $self, $parser, $doc ) = @_;
        my ( $endscan, $endscanstr, $elapsedtime );

        foreach my $fiercescan ( $doc->getElementsByTagName('fiercescan') ) {

            foreach my $end ( $fiercescan->getElementsByTagName('endscan') ) {
                $endscan    = $end->getAttribute('endtime');
                $endscanstr = $end->getAttribute('endtimestr');
                $elapsedtime  = $end->getAttribute('elapsedtime');
            }

            return Fierce::Parser::Session->new(
                options      => $fiercescan->getAttribute('args'),
                startscan    => $fiercescan->getAttribute('startscan'),
                startscanstr => $fiercescan->getAttribute('startscanstr'),
                fversion     => $fiercescan->getAttribute('fversion'),
                xmlversion   => $fiercescan->getAttribute('xmlversion'),
                endscan      => $endscan,
                endscanstr   => $endscanstr,
                elapsedtime    => $elapsedtime,
                domainscandetails =>
                    Fierce::Parser::DomainScanDetails->parse( $parser, $doc ),
            );
        }
    }

}
1;
