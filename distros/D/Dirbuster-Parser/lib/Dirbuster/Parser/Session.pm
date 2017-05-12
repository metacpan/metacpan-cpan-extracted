# $Id: Session.pm 18 2008-05-05 23:55:18Z jabra $
package Dirbuster::Parser::Session;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Dirbuster::Parser::ScanDetails;

#    my @title : Field : Arg(title) : All(title);
#    my @web : Field : Arg(web) : All(web);
#    my @version : Field : Arg(version) : All(version);
    my @scandetails : Field : Arg(scandetails) : Get(scandetails) :
        Type(Dirbuster::Parser::ScanDetails);

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        foreach my $Dirbusterscan ( $doc->getElementsByTagName('DirBusterResults') ) {
            return Dirbuster::Parser::Session->new(
                scandetails => Dirbuster::Parser::ScanDetails->parse( $parser, $doc ),
            );
        }
    }
}
1;
