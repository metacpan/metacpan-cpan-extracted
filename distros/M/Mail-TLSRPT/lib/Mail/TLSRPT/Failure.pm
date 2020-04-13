package Mail::TLSRPT::Failure;
# ABSTRACT: TLSRPT failure object
our $VERSION = '1.20200413.1'; # VERSION
use 5.20.0;
use Moo;
use Mail::TLSRPT::Pragmas;
use Net::IP;
    has result_type => (is => 'rw', isa => Enum[ qw( starttls-not-supported certificate-host-mismatch certificate-expired certificate-not-trusted validation-failure tlsa-invalid dnssec-invalid dane-required sts-policy-fetch-error sts-policy-invalid sts-webpki-invalid ) ], required => 1);
    has sending_mta_ip => (is => 'rw', isa => class_type('Net::IP'), required => 1,coerce => sub{&_coerce_ip});
    has receiving_mx_hostname => (is => 'rw', isa => Str, required => 1);
    has receiving_mx_helo => (is => 'rw', isa => Str, required => 0);
    has receiving_ip => (is => 'rw', isa => class_type('Net::IP'), required => 0, coerce => sub{&_coerce_ip});
    has failed_session_count => (is => 'rw', isa => Int, required => 1);
    has additional_information => (is => 'rw', isa => Str, required => 0);
    has failure_reason_code => (is => 'rw', isa => Str, required => 0);

sub _coerce_ip {
    my $ip = shift;
    $ip = Net::IP->new($ip) unless ref $ip eq 'Net::IP';
    return $ip;
}


sub new_from_data($class,$data) {
    my $self = $class->new(
        result_type => $data->{'result-type'},
        sending_mta_ip => $data->{'sending-mta-ip'},
        receiving_mx_hostname => $data->{'receiving-mx-hostname'},
        $data->{'receiving-mx-helo'} ? ( receiving_mx_helo => $data->{'receiving-mx-helo'} ) : (),
        $data->{'receiving-ip'} ? ( receiving_ip => $data->{'receiving-ip'} ) : (),
        failed_session_count => $data->{'failed-session-count'} // 0,
        $data->{'additional-information'} ? ( additional_information => $data->{'additional-information'} ) : (),
        $data->{'failure-reason-code'} ? ( failure_reason_code => $data->{'failure-reason-code'} ) : (),
    );
    return $self;
}


sub as_struct($self) {
    return {
        'result-type' => $self->result_type,
        $self->sending_mta_ip ? ( 'sending-mta-ip' => $self->sending_mta_ip->ip ) : (),
        'receiving-mx-hostname' => $self->receiving_mx_hostname,
        $self->receiving_mx_helo ? ( 'receiving-mx-helo' => $self->receiving_mx_helo ) : (),
        $self->receiving_ip ? ( 'receiving-ip' => $self->receiving_ip->ip ) : (),
        'failed-session-count' => $self->failed_session_count,
        $self->additional_information ? ( 'additional-information' => $self->additional_information ) : (),
        $self->failure_reason_code ? ( 'failure-reason-code' => $self->failure_reason_code ) : (),
    };
}


sub as_string($self) {
    my $receiving_ip = $self->receiving_ip ? ' ('.$self->receiving_ip->ip.')' : '';
    return join( "\n",
        ' Failure:',
        '  Result-Type: '.$self->result_type,
        $self->sending_mta_ip ? ('  Sending-MTA-IP: '.$self->sending_mta_ip->ip) : (),
        '  Receiving-MX-Hostname: '.$self->receiving_mx_hostname . $receiving_ip,
        $self->receiving_mx_helo ? ('  Receiving-MX-HELO: '.$self->receiving_mx_helo) : (),
        '  Failed-Session-Count: '.$self->failed_session_count,
        $self->additional_information ? ('  Additional-Information: '.$self->additional_information ) : (),
        $self->failure_reason_code ? ('  Failure-Reason-Code: '.$self->failure_reason_code ) : (),
    );
}

sub _register_prometheus($self,$prometheus) {
    $prometheus->declare('tlsrpt_failures_total', help=>'TLSRPT failures', type=>'counter' );
}


sub process_prometheus($self,$policy,$report,$prometheus) {
    $self->_register_prometheus($prometheus);
    $prometheus->add('tlsrpt_failures_total',$self->failed_session_count,{
        organization_name=>$report->organization_name,
        policy_type=>$policy->policy_type,
        policy_domain=>$policy->policy_domain,
        policy_mx_host=>$policy->policy_mx_host,
        result_type=>$self->result_type,
        sending_mta_ip=>$self->sending_mta_ip,
        receiving_mx_hostname=>$self->receiving_mx_hostname,
        receiving_mx_helo=>$self->receiving_mx_helo // '',
        receiving_ip=>($self->receiving_ip?$self->receiving_ip->ip:''),
    });
}

sub _csv_headers($self) {
    return (
        'result type',
        'sending mta ip',
        'receiving mx hostname',
        'receiving mx helo',
        'receiving ip',
        'failed session count',
        'additional information',
        'failure reason code',
    );
}

sub _csv_fragment($self) {
    return (
        $self->result_type,
        $self->sending_mta_ip->ip,
        $self->receiving_mx_hostname,
        $self->receiving_mx_helo // '',
        $self->receiving_ip ? $self->receiving_ip->ip : '',
        $self->failed_session_count,
        $self->additional_information // '',
        $self->failure_reason_code // '',
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::TLSRPT::Failure - TLSRPT failure object

=head1 VERSION

version 1.20200413.1

=head1 SYNOPSIS

my $failure = Mail::TLSRPT::Failure->new(
    result_type => 'certificate-expired',
    sending_mta_ip => Net::IP->new($ip),
    receiving_mx_hostname => 'mx.example.com',
    receiving_mx_helo => 'mx1.example.com',
    receiving_ip => Net::IP->new($ip),
    failed_session_count => 10,
    additional_information => 'Foo',
    failure_reason_code => 'Bar',
);

=head1 DESCRIPTION

Classes to process tlsrpt failure in a report

=head1 CONSTRUCTOR

=head2 I<new($class)>

Create a new object

=head2 I<new_from_data($data)>

Create a new object using a data structure, this will create sub-objects as required.

=head1 METHODS

=head2 I<as_struct>

Return the current object as a data structure

=head2 I<as_string>

Return a textual human readable representation of the current object and its sub-objects

=head2 I<process_prometheus($prometheus,$report)>

Generate metrics using the given Prometheus::Tiny object

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
