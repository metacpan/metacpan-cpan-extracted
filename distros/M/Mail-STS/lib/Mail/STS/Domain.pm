package Mail::STS::Domain;

use Moose;

our $VERSION = '0.01'; # VERSION
# ABSTRACT: class for MTA-STS domain lookups

use Mail::STS::STSRecord;
use Mail::STS::TLSRPTRecord;
use Mail::STS::Policy;


has 'domain' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'resolver' => (
  is => 'ro',
  isa => 'Net::DNS::Resolver',
  required => 1,
);

has 'agent' => (
  is => 'ro',
  isa => 'LWP::UserAgent',
  required => 1,
);

has 'max_policy_size' => (
  is => 'rw',
  isa => 'Maybe[Int]',
  default => 65536,
);

my $RECORDS = {
  'mx' => {
    type => 'MX',
  },
  'a' => {
    type => ['AAAA', 'A'],
  },
  'tlsa' => {
    type => 'TLSA',
    name => sub { '_25._tcp.'.shift },
    from => 'primary',
  },
  'sts' => {
    type => 'TXT',
    name => sub { '_mta-sts.'.shift },
  },
  'tlsrpt' => {
    type => 'TXT',
    name => sub { '_smtp._tcp.'.shift },
  },
};

foreach my $record (keys %$RECORDS) {
  my $is_secure = "is_${record}_secure";
  my $accessor = "_${record}";
  my $type = $RECORDS->{$record}->{'type'};
  my $name = $RECORDS->{$record}->{'name'} || sub { shift };
  my $from = $RECORDS->{$record}->{'from'} || 'domain';

  has $is_secure => (
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    default => sub {
      my $self = shift;
      return 0 unless defined $self->$accessor;
      return $self->$accessor->header->ad ? 1 : 0;
    },
  );

  has $accessor => (
    is => 'ro',
    isa => 'Maybe[Net::DNS::Packet]',
    lazy => 1,
    default => sub {
      my $self = shift;
      my $domainname = $name->($self->$from);
      return $self->resolver->query($domainname, $type);
    },
  );
}


has 'mx' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  lazy => 1,
  default => sub {
    my $self = shift;
    return [] unless defined $self->_mx;
    my @mx;
    if( $self->_mx->answer ) {
      my @rr = grep { $_->type eq 'MX' } $self->_mx->answer;
      @rr = sort { $a->preference <=> $b->preference } @rr;
      @mx = map { $_->exchange } @rr;
    }
    return \@mx;
  },
  traits => ['Array'],
  handles => {
    'mx_count' => 'count',
  },
);


has 'a' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy => 1,
  default => sub {
    my $self = shift;
    if( my @rr = $self->_a->answer ) {
      return $self->domain;
    }
    return;
  },
);


has 'record_type' => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  default => sub {
    my $self = shift;
    return 'mx' if $self->mx_count;
    return 'a' if defined $self->a;
    return 'non-existent';
  },
);


has 'primary' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy => 1,
  default => sub {
    my $self = shift;
    return $self->mx->[0] if $self->record_type eq 'mx';
    return $self->a if $self->record_type eq 'a';
    return;
  },
);


has 'is_primary_secure' => (
  is => 'ro',
  isa => 'Bool',
  lazy => 1,
  default => sub {
    my $self = shift;
    return $self->is_mx_secure if $self->record_type eq 'mx';
    return $self->is_a_secure if $self->record_type eq 'a';
    return 0;
  },
);



has 'tlsa' => (
  is => 'ro',
  isa => 'Maybe[Net::DNS::RR]',
  lazy => 1,
  default => sub {
    my $self = shift;
    return unless defined $self->_tlsa;
    if( my @rr = $self->_tlsa->answer ) {
      return $rr[0];
    }
    return;
  },
);


has 'tlsrpt' => (
  is => 'ro',
  isa => 'Maybe[Mail::STS::TLSRPTRecord]',
  lazy => 1,
  default => sub {
    my $self = shift;
    return unless defined $self->_tlsrpt;
    if( my @rr = $self->_tlsrpt->answer ) {
      return Mail::STS::TLSRPTRecord->new_from_string($rr[0]->txtdata);
    }
    return;
  },
);


has 'sts' => (
  is => 'ro',
  isa => 'Maybe[Mail::STS::STSRecord]',
  lazy => 1,
  default => sub {
    my $self = shift;
    return unless defined $self->_sts;
    if( my @rr = $self->_sts->answer ) {
      return Mail::STS::STSRecord->new_from_string($rr[0]->txtdata);
    }
    return;
  },
);


has 'policy' => (
  is => 'ro',
  isa => 'Mail::STS::Policy',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $url = 'https://mta-sts.'.$self->domain.'/.well-known/mta-sts.txt';
    my $response = $self->agent->get($url);
    my $content = $response->decoded_content;
    if(defined $self->max_policy_size && length($content) > $self->max_policy_size) {
      die('policy exceeding maximum policy size limit');
    }
    die('could not retrieve policy: '.$response->status_line) unless $response->is_success;
    return Mail::STS::Policy->new_from_string($content);
  },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::STS::Domain - class for MTA-STS domain lookups

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $domain = $sts->domain('example.com');
  # or construct it yourself
  my $domain = Mail::STS::Domain(
    resolver => $resolver, # Net::DNS::Resolver
    agent => $agent, # LWP::UserAgent
    domain => 'example.com',
  );

  $domain->mx;
  # [ 'mta1.example.com', ... ]
  $domain->tlsa;
  # undef or Net::DNS::RR:TLSA
  $domain->primary
  # mta1.example.com
  $domain->tlsrpt;
  # undef or Mail::STS::TLSRPTRecord
  $domain->sts;
  # undef or Mail::STS::STSRecord
  $domain->policy;
  # Mail::STS::Policy or will die()

=head1 ATTRIBUTES

=head2 domain (required)

The domain to lookup.

=head2 resolver (required)

A Net::DNS::Resolver object to use for DNS lookups.

=head2 agent (required)

A LWP::UserAgent object to use for retrieving policy
documents by https.

=head2 max_policy_size(default: 65536)

Maximum size allowed for STS policy document.

=head1 METHODS

=head2 mx()

Retrieves MX hostnames from DNS and returns a array reference.

List is sorted by priority.

  $domain->mx;
  # [ 'mta1.example.com', 'backup-mta1.example.com' ]

=head2 a()

Returns the domainname if a AAAA or A record exists for the domain.

  $domain->a;
  # "example.com"

=head2 record_type()

Returns the type of record the domain resolves to:

=over

=item "mx"

If domain has MX records.

=item "a"

If domain has an AAAA or A record.

=item "non-existent"

If the domain does not exist.

=back

=head2 primary()

Returns the hostname of the primary MTA for this domain.

In case of MX records the first element of mx().

In case of an AAAA or A record the domainname.

Or undef if the domain does not resolve at all.

=head2 is_primary_secure()

Returns 1 if resolver signaled successfull DNSSEC validation
for the hostname returned by primary().

Otherwise returns 0.

=head2 tlsa()

Returns a Net::DNS::RR in case an TLSA record exists
for the hostname returned by primary() otherwise undef.

=head2 tlsrpt()

Returns an Mail::STS::TLSRPTRecord if a TLSRPT TXT
record for the domain could be lookup.

=head2 sts()

Returns an Mail::STS::STSRecord if a STS TXT
record for the domain could be lookup.

=head2 policy()

Returns a Mail::STS::Policy object if a policy for the domain
could be retrieved by the well known URL.

Otherwise will die with an error.

=head2 is_mx_secure()
=head2 is_a_secure()
=head2 is_tlsa_secure()
=head2 is_sts_secure()
=head2 is_tlsrpt_secure()

Returns 1 if resolver signaled successfull DNSSEC validation
(ad flag) for returned record otherwise returns 0.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
