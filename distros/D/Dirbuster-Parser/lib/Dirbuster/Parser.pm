# $Id: Parser.pm 71 2008-08-31 05:58:17Z jabra $
package Dirbuster::Parser;
{
    our $VERSION = '0.02';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use Dirbuster::Parser::Session;
    my @session : Field : Arg(session) : Get(session) : Type(Dirbuster::Parser::Session);

    # parse_file
    #
    # Input:
    # argument  -   self obj    -
    # argument  -   xml         scalar
    #
    # Ouptut:
    #
    sub parse_file {
        my ( $self, $file ) = @_;
        my $parser = XML::LibXML->new();

        my $doc = $parser->parse_file($file);
        return Dirbuster::Parser->new(
            session => Dirbuster::Parser::Session->parse( $parser, $doc ) );
    }

    sub get_session {
        my ($self) = @_;
        return $self->session;
    }   

    sub get_all_results {
        my ($self) = @_;
        my @all_results = $self->session->scandetails->all_results();
        return @all_results;
    }
}
1;

