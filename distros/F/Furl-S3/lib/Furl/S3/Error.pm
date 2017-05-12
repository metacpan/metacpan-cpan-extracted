package Furl::S3::Error;
use strict;
use Class::Accessor::Lite;
use XML::LibXML;
use overload q{""} => \&stringify;

Class::Accessor::Lite->mk_accessors(qw(code http_code http_status message request_id host_id));

sub new {
    my( $class, $res ) = @_;
    my $self = bless {
        http_code => $res->{code},
        http_status => $res->{msg},
    }, $class;
    if ( my $xml = $res->{body} ) {
        $self->_parse_xml( $xml );
    }
    $self;
}

sub stringify {
    my $self = shift;
    if ( $self->message ) {
        return sprintf('%s: %s', $self->code, $self->message);
    }
    else {
        return sprintf('HTTP Error: %s %s', $self->http_code, $self->http_status);
    }
}

sub _parse_xml {
    my( $self, $xml ) = @_;
    my $doc = XML::LibXML->new->parse_string( $xml );
    my $code = $doc->findvalue('/Error/Code');
    my $message = $doc->findvalue('/Error/Message');
    my $request_id = $doc->findvalue('/Error/RequestId');
    my $host_id = $doc->findvalue('/Error/HostId');
    $self->code( $code );
    $self->message( $message );
    $self->request_id( $request_id );
    $self->host_id( $host_id );
}

1;

__END__
