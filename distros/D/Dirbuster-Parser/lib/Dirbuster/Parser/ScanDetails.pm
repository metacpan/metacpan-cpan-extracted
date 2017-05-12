# $Id: ScanDetails.pm 18 2008-05-05 23:55:18Z jabra $
package Dirbuster::Parser::ScanDetails;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Dirbuster::Parser::Result;
    my @results : Field : Arg(results) : Get(results) : Type(List(Dirbuster::Parser::Result));

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        my $xpc = XML::LibXML::XPathContext->new($doc);
        my @results;

        foreach my $h ( $xpc->findnodes('//DirBusterResults/Result') ) {
            my $type            = $h->getAttribute('type');
            my $path            = $h->getAttribute('path');
            my $response_code   = $h->getAttribute('responseCode');
            
            my $result = Dirbuster::Parser::Result->new(
                type            => $type,
                path            => $path,
                response_code   => $response_code,
            );

            push( @results, $result );
        }

        return Dirbuster::Parser::ScanDetails->new( results => \@results );
    }

    sub all_results {
        my ($self) = @_;
        my @results = @{ $self->results };
        return @results;
    }

    sub print_hosts {
        my ($self) = @_;
        foreach my $r ( @{ $self->results } ) {
            print "Path: " . $r->path . "\n";
            print "Type: " . $r->type . "\n";
            print "Response Code: " . $r->response_code . "\n";
        }
    }
}
1;
