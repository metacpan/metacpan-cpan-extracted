package Mail::TLSRPT::Policy;
# ABSTRACT: TLSRPT policy object
our $VERSION = '2.20261112'; # VERSION
use 5.20.0;
use Moo;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::Failure;
    has policy_type => (is => 'rw', isa => Str, required => 1);
    has policy_string => (is => 'rw', isa => ArrayRef, required => 1);
    has policy_domain => (is => 'rw', isa => Str, required => 1);
    has policy_mx_host => (is => 'rw', isa => Str, required => 1);
    has _policy_mx_hosts => (is => 'ro', isa => ArrayRef[Str], predicate => '_has_policy_mx_hosts');
    has total_successful_session_count => (is => 'rw', isa => Int, required => 1);
    has total_failure_session_count => (is => 'rw', isa => Int, required => 1);
    has failures => (is => 'rw', isa => ArrayRef, required => 0, lazy => 1, builder => sub{return []} );

around BUILDARGS => sub($orig,$class,@args) {
    my $args = $class->$orig(@args);
    if ( exists $args->{policy_mx_hosts} ) {
        my $hosts = delete $args->{policy_mx_hosts};
        croak 'Give policy_mx_host or policy_mx_hosts, not both' if exists $args->{policy_mx_host};
        croak 'policy_mx_hosts is not a list of strings' if ref $hosts ne 'ARRAY' || grep { ! defined $_ || ref $_ } $hosts->@*;
        $args->{policy_mx_host} = join( ' ', $hosts->@* );
        $args->{_policy_mx_hosts} = [ $hosts->@* ];
    }
    return $args;
};


sub new_from_data($class,$data) {
    croak 'Policy is not an object' unless ref $data eq 'HASH';
    foreach my $key ( qw{ policy summary } ) {
        croak "$key: not an object" if defined $data->{$key} && ref $data->{$key} ne 'HASH';
    }
    my $mx_host = $data->{policy}->{'mx-host'} // '';
    if ( ref $mx_host eq 'ARRAY' ) {
        croak 'policy.mx-host: not a list of strings' if grep { ! defined $_ || ref $_ } $mx_host->@*;
    }
    my $failure_details = $data->{'failure-details'} // [];
    croak 'failure-details: not a list' unless ref $failure_details eq 'ARRAY';
    my @failures;
    foreach my $i ( keys $failure_details->@* ) {
        my $failure = eval { Mail::TLSRPT::Failure->new_from_data($failure_details->[$i]) };
        die "failure-details[$i]: $@" unless $failure;
        push @failures, $failure;
    }
    my $self = $class->new(
        policy_type => $data->{policy}->{'policy-type'},
        policy_string => $data->{policy}->{'policy-string'} // [],
        policy_domain => $data->{policy}->{'policy-domain'},
        ref $mx_host eq 'ARRAY'
          ? ( policy_mx_hosts => $mx_host )
          : ( policy_mx_host => $mx_host ),
        total_successful_session_count => $data->{summary}->{'total-successful-session-count'} // 0,
        total_failure_session_count => $data->{summary}->{'total-failure-session-count'} // 0,
        failures => \@failures,
    );
    return $self;
}


sub policy_mx_hosts($self) {
    return [ $self->_policy_mx_hosts->@* ]
      if $self->_has_policy_mx_hosts && $self->policy_mx_host eq join( ' ', $self->_policy_mx_hosts->@* );
    return [ split( ' ', $self->policy_mx_host ) ];
}


sub policy_mode($self) {
    return undef unless $self->policy_type eq 'sts';
    foreach my $line ( $self->policy_string->@* ) {
        next if ! defined $line || ref $line;
        return $1 if $line =~ /^mode:[ \t]*(\S+)/m;
    }
    return undef;
}


sub known_policy_types($class) {
    return qw( tlsa sts no-policy-found );
}


sub is_known_policy_type($self) {
    return scalar grep { $_ eq $self->policy_type } $self->known_policy_types;
}


sub as_struct($self) {
    my @failures = map {$_->as_struct} $self->failures->@*;
    return {
        policy => {
            'policy-type' => $self->policy_type,
            'policy-string' => $self->policy_string,
            'policy-domain' => $self->policy_domain,
            'mx-host' => $self->_has_policy_mx_hosts ? $self->policy_mx_hosts : $self->policy_mx_host,
        },
        summary => {
            'total-successful-session-count' => $self->total_successful_session_count,
            'total-failure-session-count' => $self->total_failure_session_count,
        },
        scalar $self->failures->@* ? ( 'failure-details' => \@failures ) : (),
    };
}


sub as_string($self) {
    return join( "\n",
        'Policy:',
        ' Type: '.$self->policy_type,
        ' String: '. join('; ', map { $_ // '' } $self->policy_string->@*),
        ' Domain: '.$self->policy_domain,
        ' MX-Host: '.$self->policy_mx_host,
        ' Successful-Session-Count: '.$self->total_successful_session_count,
        ' Failure-Session-Count: '.$self->total_failure_session_count,
        map { $_->as_string } $self->failures->@*,
    );
}

sub _register_prometheus($self,$prometheus) {
    $prometheus->declare('tlsrpt_sessions_total', help=>'TLSRPT tls sessions', type=>'counter' );
}


sub process_prometheus($self,$report,$prometheus) {
    $self->_register_prometheus($prometheus);
    $prometheus->add('tlsrpt_sessions_total',$self->total_successful_session_count,{
        result=>'successful',
        organization_name=>$report->organization_name,
        policy_type=>$self->policy_type,
        policy_domain=>$self->policy_domain,
        policy_mx_host=>$self->policy_mx_host,
    });
    $prometheus->add('tlsrpt_sessions_total',$self->total_failure_session_count,{
        result=>'failure',
        organization_name=>$report->organization_name,
        policy_type=>$self->policy_type,
        policy_domain=>$self->policy_domain,
        policy_mx_host=>$self->policy_mx_host,
    });
    Mail::TLSRPT::Failure->_register_prometheus($prometheus) if ! scalar $self->failures->@*;
    foreach my $failure ( $self->failures->@* ) {
        $failure->process_prometheus($self,$report,$prometheus);
    }
}

sub _csv_headers($self) {
    return (
        'policy type',
        'policy string',
        'policy domain',
        'policy mx host',
        'total successful session count',
        'total failure session count',
    );
}

sub _csv_fragment($self) {
    return (
        $self->policy_type,
        join('; ', map { $_ // '' } $self->policy_string->@*),
        $self->policy_domain,
        $self->policy_mx_host,
        $self->total_successful_session_count,
        $self->total_failure_session_count,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::TLSRPT::Policy - TLSRPT policy object

=head1 VERSION

version 2.20261112

=head1 SYNOPSIS

my $policy = Mail::TLSRPT::Policy->new(
    policy_type => 'no-policy-found',
    policy_string => [],
    policy_domain => 'example.com',
    polixy_mx_host => 'mx.example.com',
    total_succerssful_session_count => 10,
    total_failure_session_count => 2,
    failures => $failures,
);

=head1 DESCRIPTION

Classes to process tlsrpt policy in a report

=head1 CONSTRUCTOR

=head2 I<new($class)>

Create a new object

=head2 I<new_from_data($data)>

Create a new object using a data structure, this will create sub-objects as required.

=head1 METHODS

=head2 I<policy_mx_hosts>

Return the mx-host patterns as an arrayref. RFC 8460 gives mx-host as a list,
though its own example gives a string. A list can be given to new as
policy_mx_hosts, in place of policy_mx_host: it's joined with spaces into
policy_mx_host, and as_struct gives mx-host back as that list, or if
policy_mx_host has been set since, as policy_mx_host split on whitespace.

=head2 I<policy_mode>

Return the mode from the mode field of an sts policy_string, as written, or
undef if there isn't one. Returns undef for other policy types.

=head2 I<known_policy_types>

Return the list of policy types RFC 8460 section 4.4 defines

=head2 I<is_known_policy_type>

Return true if the policy type is one of known_policy_types

=head2 I<as_struct>

Return the current object and sub-objects as a data structure

=head2 I<as_string>

Return a textual human readable representation of the current object and its sub-objects

=head2 I<process_prometheus($prometheus,$report)>

Generate metrics using the given Prometheus::Tiny object

=head1 AUTHOR

Jemma Bradshaw <jemma@nothingbutstatic.dev>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Jemma Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
