# $Id: Parser.pm 71 2008-08-31 05:58:17Z jabra $
package MetasploitExpress::Parser;
{
    use Object::InsideOut;
    use MetasploitExpress::Parser::Session;
    my @session : Field : Arg(session) : Get(session) :
        Type(MetasploitExpress::Parser::Session);

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
        return MetasploitExpress::Parser->new( session =>
                MetasploitExpress::Parser::Session->parse( $parser, $doc ) );
    }

    sub get_session {
        my ($self) = @_;
        return $self->session;
    }

    sub get_host {
        my ( $self, $ip ) = @_;
        return $self->session->scandetails->get_host_ip($ip);
    }

    sub get_all_hosts {
        my ($self) = @_;
        return $self->session->scandetails->all_hosts();
    }

    sub get_all_services {
        my ($self) = @_;
        return $self->session->scandetails->all_services();
    }

    sub get_all_events {
        my ($self) = @_;
        return $self->session->scandetails->all_events();
    }

    sub get_all_tasks {
        my ($self) = @_;
        return $self->session->scandetails->all_tasks();
    }

    sub get_all_reports {
        my ($self) = @_;
        return $self->session->scandetails->all_reports();
    }
}
1;

