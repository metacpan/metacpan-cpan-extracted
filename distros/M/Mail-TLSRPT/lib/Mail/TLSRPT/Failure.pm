package Mail::TLSRPT::Failure;
# ABSTRACT: TLSRPT failure object
our $VERSION = '1.20200303.1'; # VERSION
use 5.20.0;
use Moo;
use Carp;
use Types::Standard qw{Str Int HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::TLSRPT::Pragmas;
    has result_type => (is => 'rw', isa => Str);
    has sending_mta_ip => (is => 'rw', isa => Str);
    has receiving_mx_hostname => (is => 'rw', isa => Str);
    has receiving_mx_helo => (is => 'rw', isa => Str);
    has failed_session_count => (is => 'rw', isa => Int);
    has additional_information => (is => 'rw', isa => Str);
    has failure_reason_code => (is => 'rw', isa => Str);

sub new_from_data($class,$data) {
    my $self = $class->new(
        result_type => $data->{'result-type'} // '',
        sending_mta_ip => $data->{'sending-mta-ip'} // '',
        receiving_mx_hostname => $data->{'receiving-mx-hostname'} // '',
        receiving_mx_helo => $data->{'receiving-mx-helo'} // '',
        failed_session_count => $data->{'failed-session-count'} // 0,
        additional_information => $data->{'additional-information'} // '',
        failure_reason_code => $data->{'failure-reason-code'} // '',
    );
    return $self;
}

sub as_string($self) {
    return join( "\n",
        '  Failure:',
        '   Result-Type: '.$self->result_type,
        '   Sending-MTA-IP: '.$self->sending_mta_ip,
        '   Receiving-MX-Hostname: '.$self->receiving_mx_hostname,
        '   Receiving-MX-HELO: '.$self->receiving_mx_helo,
        '   Failed-Session-Count: '.$self->failed_session_count,
        '   Additional-Information: '.$self->additional_information,
        '   Failure-Reason-Code: '.$self->failure_reason_code,
    );
}

1;

