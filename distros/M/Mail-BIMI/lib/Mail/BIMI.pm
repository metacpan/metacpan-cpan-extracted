package Mail::BIMI;
# ABSTRACT: BIMI object
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Moose::Util::TypeConstraints;
use Mail::BIMI::Prelude;
use Mail::BIMI::Options;
use Mail::BIMI::Record;
use Mail::BIMI::Result;
use Mail::DMARC::PurePerl;
use Net::DNS::Resolver;

with 'Mail::BIMI::Role::HasError';

subtype 'MaybeDMARC'
  => as 'Any'
  => where {
    !defined $_
    || ref $_ eq 'Mail::DMARC::PurePerl'
    || ref $_ eq 'Mail::DMARC::Result'
  }
  => message {"dmarc_object Must be a Mail::DMARC::PurePerl, Mail::DMARC::Result, or Undefined"};

coerce 'Mail::BIMI::Options'
  => from 'HashRef'
  => via {
    my $args = $_;
    my $options = Mail::BIMI::Options->new;
    foreach my $option ( sort keys $args->%* ) {
      $options->$option($args->{$option});
    }
    return $options;
  };

has domain => ( is => 'rw', isa => 'Str', required => 0,
  documentation => 'inputs: Domain to lookup/domain record was retrieved from', );
has selector => ( is => 'rw', isa => 'Str', lazy => 1, default => sub{ return 'default' },
  documentation => 'inputs: Selector to lookup/selector record was retrieved from', );
has dmarc_object => ( is => 'rw', isa => 'MaybeDMARC',
  documentation => 'inputs: Validated Mail::DMARC::PurePerl object from parsed message', );
has spf_object => ( is => 'rw', isa => 'Mail::SPF::Result',
  documentation => 'inputs: Mail::SPF::Result object from parsed message', );
has dmarc_result_object => ( is => 'rw', isa => 'Maybe[Mail::DMARC::Result]', lazy => 1, builder => '_build_dmarc_result_object',
  documentation => 'Relevant Mail::DMARC::Result object' );
has dmarc_pp_object => ( is => 'rw', isa => 'Maybe[Mail::DMARC::PurePerl]', lazy => 1, builder => '_build_dmarc_pp_object',
  documentation => 'Relevant Mail::DMARC::PurePerl object' );
has record => ( is => 'rw', lazy => 1, builder => '_build_record',
  documentation => 'Mail::BIMI::Record object' );
has resolver => ( is => 'rw', lazy => 1, builder => '_build_resolver',
  documentation => 'inputs: Net::DNS::Resolver object to use for DNS lookups; default used if not set', );
has result => ( is => 'rw', lazy => 1, builder => '_build_result',
  documentation => 'Mail::BIMI::Result object' );
has time => ( is => 'ro', lazy => 1, default => sub{return time},
  documentation => 'time of retrieval - useful in testing' );
has options => ( is => 'rw', isa => 'Mail::BIMI::Options', default => sub{Mail::BIMI::Options->new}, coerce => 1,
  documentation => 'Options class' );


sub _build_resolver($self) {
  if (defined $Mail::BIMI::TestSuite::Resolver) {
    return $Mail::BIMI::TestSuite::Resolver;
  }
  my $resolver = Net::DNS::Resolver->new(dnsrch => 0);
  $resolver->tcp_timeout( $self->options->dns_client_timeout );
  $resolver->udp_timeout( $self->options->dns_client_timeout );
  return $resolver;
}

sub _build_dmarc_result_object($self) {
  return $self->dmarc_object->result if ref $self->dmarc_object eq 'Mail::DMARC::PurePerl';
  return $self->dmarc_object         if ref $self->dmarc_object eq 'Mail::DMARC::Result';
  return;
}

sub _build_dmarc_pp_object($self) {
  return $self->dmarc_object if ref $self->dmarc_object eq 'Mail::DMARC::PurePerl';
  $self->log_verbose('Building our own Mail::DMARC::PurePerl object');
  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->set_resolver($self->resolver);
  $dmarc->header_from($self->domain);
  $dmarc->validate;
  return $dmarc;
}

sub _build_record($self) {
  croak 'Domain required' if ! $self->domain;
  return Mail::BIMI::Record->new( domain => $self->domain, selector => $self->selector, bimi_object => $self );
}

sub _check_dmarc_enforcement_status($self,$dmarc,$result) {
  # Set result and return true if there are any DMARC enforcement issues, Return false if there are none
  if (exists $dmarc->result->{published}){
    my $published_policy = $dmarc->result->published->p // '';
    my $published_subdomain_policy = $dmarc->result->published->sp // '';
    my $published_policy_pct = $dmarc->result->published->pct // 100;
    my $effective_published_policy = ( $dmarc->is_subdomain && $published_subdomain_policy ) ? lc $published_subdomain_policy : lc $published_policy;
    if ( $effective_published_policy eq 'quarantine' && $published_policy_pct ne '100' ) {
      $result->set_result( Mail::BIMI::Error->new(code=>'DMARC_NOT_ENFORCING'));
      return 1;
    }
    if ( $effective_published_policy ne 'quarantine' && $effective_published_policy ne 'reject' ) {
      $result->set_result( Mail::BIMI::Error->new(code=>'DMARC_NOT_ENFORCING'));
      return 1;
    }
    if ( $published_subdomain_policy && $published_subdomain_policy eq 'none' ) {
      $result->set_result( Mail::BIMI::Error->new(code=>'DMARC_NOT_ENFORCING'));
      return 1;
    }
  }
  else {
    $result->set_result( Mail::BIMI::Error->new(code=>'NO_DMARC'));
    return 1;
  }
  return 0;
}

sub _build_result($self) {
  croak 'Domain required' if ! $self->domain;

  my $result = Mail::BIMI::Result->new(
    bimi_object => $self,
    headers => {},
  );

  # does DMARC pass
  if ( ! $self->dmarc_result_object ) {
    $result->set_result( Mail::BIMI::Error->new(code=>'NO_DMARC'));
    return $result;
  }
  if ( $self->dmarc_result_object->result ne 'pass' ) {
      $result->set_result( Mail::BIMI::Error->new(code=>'DMARC_NOT_PASS',detail=>$self->dmarc_result_object->result));
      return $result;
  }

  # Is DMARC enforcing?
  my $dmarc = $self->dmarc_pp_object;
  return $result if $self->_check_dmarc_enforcement_status($dmarc,$result);

  # Is Org DMARC Enforcing?
  my $org_domain   = Mail::DMARC::PurePerl->new->get_organizational_domain($self->domain);
  if ( lc $org_domain ne lc $self->domain ) {
    my $org_dmarc = Mail::DMARC::PurePerl->new;
    $org_dmarc->set_resolver($self->resolver);
    $org_dmarc->header_from($org_domain);
    $org_dmarc->validate;
    return $result if $self->_check_dmarc_enforcement_status($org_dmarc,$result);
  }

  # Optionally check Author Domain SPF
  if ( $self->options->strict_spf ) {
    if ( $self->spf_object ) {
      my $spf_request = $self->spf_object->request;
      if ( $spf_request ) {
        my $spf_record = $spf_request->record;
        if ( $spf_record ) {
          my @spf_terms = $spf_record->terms;
          if ( @spf_terms ) {
            my $last_term = pop @spf_terms;
            if ( $last_term->name eq 'all' && $last_term->qualifier eq '+') {
              $result->set_result( Mail::BIMI::Error->new(code=>'SPF_PLUS_ALL'));
              return $result;
            }
          }
        }
      }
    }
  }

  if ( ! $self->record->is_valid ) {
    my $has_error;
    # Known errors, in order of importance
    my @known_errors = qw{
      NO_BIMI_RECORD
      DNS_ERROR
      NO_DMARC
      MULTI_BIMI_RECORD
      DUPLICATE_KEY
      EMPTY_L_TAG
      EMPTY_V_TAG
      INVALID_V_TAG
      MISSING_L_TAG
      MISSING_V_TAG
      MULTIPLE_AUTHORITIES
      MULTIPLE_LOCATIONS
      INVALID_TRANSPORT_A
      INVALID_TRANSPORT_L
      SPF_PLUS_ALL
      SVG_FETCH_ERROR
      VMC_FETCH_ERROR
      VMC_PARSE_ERROR
      VMC_VALIDATION_ERROR
      SVG_GET_ERROR
      SVG_SIZE
      SVG_UNZIP_ERROR
      SVG_INVALID_XML
      SVG_VALIDATION_ERROR
      SVG_MISMATCH
      VMC_REQUIRED
    };
    my $found_error = 0;

    foreach my $known_error (@known_errors) {
      if ( my ($error) = $self->record->filter_errors( $known_error ) ) {
        $found_error = 1;
        $result->set_result( $error );
        last;
      }
    }
    if ( !$found_error ) {
      $result->set_result( Mail::BIMI::Error->new(code=>'BIMI_INVALID'));
    }
    return $result;
  }

  $result->set_result( 'pass' );

  my @bimi_location;
  if ( $self->record->authority && $self->record->authority->is_relevant ) {
    push @bimi_location, '    l='.$self->record->location->uri if $self->record->location_is_relevant;
    push @bimi_location, '    a='.$self->record->authority->uri;
    $result->headers->{'BIMI-Indicator'} = $self->record->authority->vmc->indicator->header;
  }
  else {
    push @bimi_location, '    l='.$self->record->location->uri;
    $result->headers->{'BIMI-Indicator'} = $self->record->location->indicator->header;
  }

  $result->headers->{'BIMI-Location'} = join( "\n",
    'v=BIMI1;',
    @bimi_location,
  );

  return $result;
}


sub finish($self) {
  $self->record->finish if $self->record;
}


sub log_verbose($self,$text) {
  return unless $self->options->verbose;
  warn "$text\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI - BIMI object

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Brand Indicators for Message Identification (BIMI) retrieval, validation, and processing

=head1 SYNOPSIS

  # Assuming we have a message, and have verified it has exactly one From Header domain, and passes
  # any other BIMI and local site requirements not related to BIMI record validation...
  # For example, relevant DKIM coverage of any BIMI-Selector header
  my $message = ...Specifics of adding headers and Authentication-Results is left to the reader...

  my $domain = "example.com"; # domain from From header
  my $selector = "default";   # selector from From header
  my $spf = Mail::SPF->new( ...See Mail::SPF POD for options... );
  my $dmarc = Mail::DMARC::PurePerl->new( ...See Mail::DMARC POD for options... );
  $dmarc->validate;

  my $bimi = Mail::BIMI->new(
    dmarc_object => $dmarc,
    spf_object => $spf,
    domain => $domain,
    selector => $selector,
  );

  my $auth_results = $bimi->get_authentication_results_object;
  my $bimi_result = $bimi->result;

  $message->add_auth_results($auth_results); # See Mail::AuthenticationResults POD for usage

  if ( $bimi_result->result eq 'pass' ) {
    my $headers = $result->headers;
    if ($headers) {
      $message->add_header( 'BIMI-Location', $headers->{'BIMI-Location'} if exists $headers->{'BIMI-Location'};
      $message->add_header( 'BIMI-Indicator', $headers->{'BIMI-Indicator'} if exists $headers->{'BIMI-Indicator'};
    }
  }

=head1 INPUTS

These values are used as inputs for lookups and verifications, they are typically set by the caller based on values found in the message being processed

=head2 dmarc_object

is=rw

Validated Mail::DMARC::PurePerl object from parsed message

=head2 domain

is=rw

Domain to lookup/domain record was retrieved from

=head2 resolver

is=rw

Net::DNS::Resolver object to use for DNS lookups; default used if not set

=head2 selector

is=rw

Selector to lookup/selector record was retrieved from

=head2 spf_object

is=rw

Mail::SPF::Result object from parsed message

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 dmarc_pp_object

is=rw

Relevant Mail::DMARC::PurePerl object

=head2 dmarc_result_object

is=rw

Relevant Mail::DMARC::Result object

=head2 errors

is=rw

=head2 options

is=rw

Options class

=head2 record

is=rw

Mail::BIMI::Record object

=head2 result

is=rw

Mail::BIMI::Result object

=head2 time

is=ro

time of retrieval - useful in testing

=head1 CONSUMES

=over 4

=item * L<Mail::BIMI::Role::HasError>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 METHODS

=head2 I<finish()>

Finish and clean up, write cache if enabled.

=head2 I<log_verbose()>

Output given text if in verbose mode.

=head1 REQUIRES

=over 4

=item * L<Mail::BIMI::Options|Mail::BIMI::Options>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::Record|Mail::BIMI::Record>

=item * L<Mail::BIMI::Result|Mail::BIMI::Result>

=item * L<Mail::DMARC::PurePerl|Mail::DMARC::PurePerl>

=item * L<Moose|Moose>

=item * L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

=item * L<Net::DNS::Resolver|Net::DNS::Resolver>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
