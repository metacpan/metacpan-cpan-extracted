package Mail::TLSRPT::Policy;
# ABSTRACT: TLSRPT policy object
our $VERSION = '1.20200303.1'; # VERSION
use 5.20.0;
use Moo;
use Carp;
use Types::Standard qw{Str Int HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::Failure;
    has policy_type => (is => 'rw', isa => Str);
    has policy_string => (is => 'rw', isa => ArrayRef);
    has policy_domain => (is => 'rw', isa => Str);
    has policy_mx_host => (is => 'rw', isa => Str);
    has total_successful_session_count => (is => 'rw', isa => Int);
    has total_failure_session_count => (is => 'rw', isa => Int);
    has failures => (is => 'rw', isa => ArrayRef);

sub new_from_data($class,$data) {
    my @failures;
    foreach my $failure ( $data->{'failure-details'}->@* ) {
        push @failures, Mail::TLSRPT::Failure->new_from_data($failure);
    }
    my $self = $class->new(
        policy_type => $data->{policy}->{'policy-type'} // '',
        policy_string => $data->{policy}->{'policy-string'} // '',
        policy_domain => $data->{policy}->{'policy-domain'} // '',
        policy_mx_host => $data->{policy}->{'mx-host'} // '',
        total_successful_session_count => $data->{summary}->{'total-successful-session-count'} // 0,
        total_failure_session_count => $data->{summary}->{'total-failure-session-count'} // 0,
        failures => \@failures,
    );
    return $self;
}

sub as_string($self) {
    return join( "\n",
        'Policy:',
        ' Type: '.$self->policy_type,
        ' String: '. join('; ',$self->policy_string->@*),
        ' Domain: '.$self->policy_domain,
        ' MX-Host: '.$self->policy_mx_host,
        ' Successful-Session-Count: '.$self->total_successful_session_count,
        ' Failure-Session-Count: '.$self->total_failure_session_count,
        map { $_->as_string } $self->failures->@*,
    );
}

1;

