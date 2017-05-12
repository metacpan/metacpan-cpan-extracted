# $Id: Parser.pm 302 2009-11-21 02:31:24Z jabra $
package Fierce::Parser;
{
    our $VERSION = '0.08';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use Fierce::Parser::Session;
    my @session : Field : Arg(session) : Get(session) :
        Type(Fierce::Parser::Session);

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
        return Fierce::Parser->new(
            session => Fierce::Parser::Session->parse( $parser, $doc ) );
    }

    sub parse_scan {
        my ( $self, $args, @domains ) = @_;
        my $FH;

        if ( $args =~ /-format/i ) {
            die
                "[Fierce::Parser] Cannot pass option '-format ' to parse_scan()";
        }

        if ( $args =~ /-output/i ) {
            die
                "[Fierce::Parser] Cannot pass option '-output ' to parse_scan()";
        }

        my $cmd = "fierce -format xml $args -dns " . ( join ',', @domains );

        #print "$cmd\n";
        open $FH, "$cmd |"
            || die "[Fierce::Parser] Could not perform nikto scan - $!";
        my $p      = XML::LibXML->new();
        my $doc    = $p->parse_fh($FH);
        my $parser = Fierce::Parser->new(
            session => Fierce::Parser::Session->parse( $p, $doc ) );
        close $FH;
        return $parser;
    }

    sub get_session {
        my ($self) = @_;
        return $self->session;
    }

    sub get_node {
        my ( $self, $domain ) = @_;
        return $self->session->domainscandetails->get_host_hostname($domain);
    }

    sub get_all_nodes {
        my ($self) = @_;
        my @all_hosts = $self->session->domainscandetails->all_hosts();
        return @all_hosts;
    }
}
1;

