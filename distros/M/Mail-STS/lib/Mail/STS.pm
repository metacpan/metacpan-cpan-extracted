package Mail::STS;

use Moose;

our $VERSION = '0.05'; # VERSION
# ABSTRACT: library for looking up MTA-STS policies

use LWP::UserAgent;
use Net::DNS::Resolver;

use Mail::STS::Domain;


has 'agent_timeout' => (
  is => 'ro',
  isa => 'Int',
  default => 60,
);


has 'max_policy_size' => (
  is => 'rw',
  isa => 'Maybe[Int]',
  default => 65536,
);


has 'resolver' => (
  is => 'ro',
  isa => 'Net::DNS::Resolver',
  lazy => 1,
  default => sub {
    return Net::DNS::Resolver->new(
      dnssec => 1,
      adflag => 1,
    );
  },
);


has 'agent' => (
  is => 'ro',
  isa => 'LWP::UserAgent',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $agent = LWP::UserAgent->new(
      agent => 'Mail::STS',
      max_redirect => 0,
      requests_redirectable => [],
      protocols_allowed => ['https'],
      timeout => $self->agent_timeout,
    );
    $agent->ssl_opts(verify_hostname => 1);
    $agent->ssl_opts(ssl_ca_file => $self->ssl_ca_file) if defined $self->ssl_ca_file;
    $agent->ssl_opts(ssl_ca_path => $self->ssl_ca_path) if defined $self->ssl_ca_path;
    return $agent;
  },
  handles => [ 'ssl_opts', 'proxy', 'no_proxy', 'env_proxy' ],
);


has 'ssl_ca_file' => (
  is => 'ro',
  isa => 'Maybe[Str]',
);


has 'ssl_ca_path' => (
  is => 'ro',
  isa => 'Maybe[Str]',
);


sub domain {
  my ($self, $domain) = @_;
  return Mail::STS::Domain->new(
    resolver => $self->resolver,
    agent => $self->agent,
    max_policy_size => $self->max_policy_size,
    domain => $domain,
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::STS - library for looking up MTA-STS policies

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  my $sts = Mail::STS->new;
  $domain = $sts->domain('domain.de');

  # may try dane first?
  return 'dane' if $domain->tlsa;
  
  # has a TLSRPT record?
  $domain->tlsrpt
  # undef or Mail::STS::TLSRPTRecord

  $domain->sts;
  # undef or Mail::STS::STSRecord
  $domain->sts->id;
  # 12345...

  $policy = $domain->policy;
  # Mail::STS::Policy or will die on error
  $policy->mode;
  # 'enforce', 'testing' or 'none'
  $policy->mx;
  # ['mta1.example.net', '*.example.de', ...]
  $policy->match_mx('whatever.example.de');
  # 1

=head1 DESCRIPTION

This class provides an interface for looking up RFC8461
MTA-STS policies.

=head1 ATTRIBUTES

=head2 agent_timeout(default: 60)

Set default for http agent for policy retrieval.

A timeout of one minute is suggested.

=head2 max_policy_size(default: 65536)

Maximum size for STS policy documents in bytes.

=head2 resolver

By default will use a Net::DNS::Resolver with dnssec/adflag enabled.

Could be used to provide a custom Net::DNS::Resolver object.

=head2 agent

By default will initialize a new LWP::UserAgent with
parameters take from this object.

=head2 ssl_opts, proxy, no_proxy, env_proxy

These methods are delegated to the LWP::UserAgent object.

See L<LWP::UserAgent> for details.

=head2 ssl_ca_file (default: undef)

Set a ssl_ca_file for the default LWP::UserAgent.

=head2 ssl_ca_path (default: undef)

Set a ssl_ca_path for the default LWP::UserAgent.

=head1 METHODS

=head2 domain($domain)

Returns a Mail::STS::Domain object for $domain
for lookup of domain details.

=head1 SEE ALSO

L<Mail::STS::Domain>, L<Mail::STS::Policy>, L<Mail::STS::TLSRPTRecord>, L<Mail::STS::STSRecord>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
