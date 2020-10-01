package Mail::BIMI::VMC;
# ABSTRACT: Class to model a VMC
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use File::Slurp qw{ read_file write_file };
use MIME::Base64;
use Term::ANSIColor qw{ :constants };
use Mail::BIMI::Indicator;
use Mail::BIMI::VMC::Chain;

extends 'Mail::BIMI::Base';
with(
  'Mail::BIMI::Role::HasError',
  'Mail::BIMI::Role::HasHTTPClient',
  'Mail::BIMI::Role::Cacheable',
);
has uri => ( is => 'rw', isa => 'Str', traits => ['CacheKey'],
  documentation => 'inputs: URI of this VMC', );
has data => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_build_data', traits => ['Cacheable'],
  documentation => 'inputs: Raw data of the VMC contents; Fetched from authority URI if not given', );
has cert_list => ( is => 'rw', isa => 'ArrayRef', lazy => 1, builder => '_build_cert_list', traits => ['Cacheable'],
  documentation => 'ArrayRef of individual Certificates in the chain' );
has chain_object => ( is => 'rw', lazy => 1, builder => '_build_chain_object', traits => ['Cacheable'],
  documentation => 'Mail::BIMI::VMC::Chain object for this Chain' );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', traits => ['Cacheable'],
  documentation => 'Is this VMC valid' );
has vmc_object => ( is => 'rw', lazy => 1, builder => '_build_vmc_object', traits => ['Cacheable'],
  documentation => 'Mail::BIMI::VMC::Cert object for this VMC Set' );
has is_cert_valid => ( is => 'rw', lazy => 1, builder => '_build_is_cert_valid', traits => ['Cacheable'],
  documentation => 'Is this Certificate Set valid' );
has indicator_uri => ( is => 'rw', lazy => 1, builder => '_build_indicator_uri', traits => ['Cacheable'],
  documentation => 'The URI of the embedded Indicator' );
has indicator => ( is => 'rw', lazy => 1, builder => '_build_indicator',
  documentation => 'Mail::BIMI::Indicator object for the Indicator embedded in this VMC Set' );



sub cache_valid_for($self) { return 3600 }


sub http_client_max_fetch_size($self) { return $self->bimi_object->options->vmc_max_fetch_size };

sub _build_data($self) {
  if ( ! $self->uri ) {
    $self->add_error('CODE_MISSING_AUTHORITY');
    return '';
  }
  if ($self->bimi_object->options->vmc_from_file) {
    return scalar read_file $self->bimi_object->options->vmc_from_file;
  }
  $self->log_verbose('HTTP Fetch: '.$self->uri);
  my $response = $self->http_client->get( $self->uri );
  if ( !$response->{success} ) {
    if ( $response->{status} == 599 ) {
      $self->add_error('VMC_FETCH_ERROR',$response->{content});
    }
      else {
      $self->add_error('VMC_FETCH_ERROR',$response->{status});
    }
    return '';
  }
  return $response->{content};
}

sub _build_cert_list($self) {
  my @certs;
  my $this_cert = [];
  my $data = $self->data;
  foreach my $cert_line ( split(/\n/,$data) ) {
    $cert_line =~ s/\r//;
    next if ! $cert_line;
    push $this_cert->@*, $cert_line;
    if ( $cert_line =~ /^\-+END CERTIFICATE\-+$/ ) {
        push @certs, $this_cert if $this_cert->@*;
        $this_cert = [];
    }
  }
  push @certs, $this_cert if $this_cert->@*;
  return \@certs;
}


sub _build_chain_object($self) {
  return Mail::BIMI::VMC::Chain->new( bimi_object => $self->bimi_object, cert_list => $self->cert_list );
}


sub _build_vmc_object($self) {
  return if !$self->chain_object;
  return if !$self->chain_object->vmc;
  return $self->chain_object->vmc;
}

sub _build_is_cert_valid($self) {
  return 1 if $self->bimi_object->options->no_validate_cert;
  return $self->chain_object->is_valid;
}


sub subject($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->subject;
}


sub not_before($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->notBefore;
}


sub not_after($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->notAfter;
}


sub issuer($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->issuer;
}


sub is_expired($self) {
  return if !$self->vmc_object;
  my $seconds = 0;
  if ($self->vmc_object->x509_object->checkend($seconds)) {
    $self->log_verbose('Cert is expired');
    return 1;
  }
  else {
    return 0;
  }
}


sub alt_name($self) {
  return if !$self->vmc_object;
  my $exts = eval{ $self->vmc_object->x509_object->extensions_by_oid() };
  return if !$exts;
  return if !exists $exts->{'2.5.29.17'};
  my $alt_name = $exts->{'2.5.29.17'}->to_string;
  $self->log_verbose('Cert alt name '.$alt_name);
  return $alt_name;
}


sub is_valid_alt_name($self) {
  return 1 if ! $self->authority_object; # Cannot check without context
  return 1 if $self->bimi_object->options->vmc_no_check_alt;
  my $domain = lc $self->authority_object->record_object->domain;
  return 0 if !$self->alt_name;
  my @alt_names = split( ',', lc $self->alt_name );
  foreach my $alt_name ( @alt_names ) {
    $alt_name =~ s/^\s+//;
    $alt_name =~ s/\s+$//;
    next if ! $alt_name =~ /^dns:/;
    $alt_name =~ s/^dns://;
    return 1 if $alt_name eq $domain;
  }
  return 0;
}


sub is_self_signed($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->x509_object->is_selfsigned ? 1 : 0;
}


sub has_valid_usage($self) {
  return if !$self->vmc_object;
  return $self->vmc_object->has_valid_usage;
}

sub _build_indicator_uri($self) {
  return if !$self->vmc_object;
  return if !$self->vmc_object->indicator_asn;
  my $uri;
  eval{
    $uri = $self->vmc_object->indicator_asn->{subjectLogo}->{direct}->{image}->[0]->{imageDetails}->{logotypeURI}->[0];
    1;
  } || do {
    my $error = $@;
    $self->add_error('VMC_PARSE_ERROR','Could not extract SVG from VMC');
  };
  return $uri;
}

sub _build_indicator($self) {
#  return if ! $self->_is_valid;
  return if !$self->is_cert_valid;
  my $uri = $self->indicator_uri;
  return if !$uri;
  ## TODO MAKE THIS BETTER
  if ( $uri =~ /^data:image\/svg\+xml;base64,/ ) {
    my ( $null, $base64 ) = split( ',', $uri );
    my $data = MIME::Base64::decode($base64);
    return Mail::BIMI::Indicator->new( location => $self->indicator_uri, data => $data, bimi_object => $self->bimi_object, source => 'VMC' );
  }
  else {
    $self->add_error('VMC_PARSE_ERROR','Could not extract SVG from VMC');
    return;
  }
}


sub _build_is_valid($self) {

  $self->add_error('VMC_VALIDATION_ERROR','Expired') if $self->is_expired;
  $self->add_error('VMC_VALIDATION_ERROR','Missing usage flag') if !$self->has_valid_usage;
  $self->add_error('VMC_VALIDATION_ERROR','Invalid alt name') if !$self->is_valid_alt_name;
  $self->is_cert_valid;

  if ( $self->chain_object && !$self->chain_object->is_valid ) {
    $self->add_error_object( $self->chain_object->errors );
  }

  if ( $self->indicator && !$self->indicator->is_valid ) {
    $self->add_error_object( $self->indicator->errors );
  }

  return 0 if $self->errors->@*;
  $self->log_verbose('VMC is valid');
  return 1;
}


sub finish($self) {
  $self->indicator->finish if $self->indicator;
  $self->_write_cache;
}


sub app_validate($self) {
  say 'VMC Returned: '.($self->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
  say YELLOW.'  Subject         '.WHITE.': '.CYAN.($self->subject//'-none-').RESET;
  say YELLOW.'  Not Before      '.WHITE.': '.CYAN.($self->not_before//'-none-').RESET;
  say YELLOW.'  Not After       '.WHITE.': '.CYAN.($self->not_after//'-none-').RESET;
  say YELLOW.'  Issuer          '.WHITE.': '.CYAN.($self->issuer//'-none-').RESET;
  say YELLOW.'  Expired         '.WHITE.': '.($self->is_expired?BRIGHT_RED.'Yes':GREEN.'No').RESET;
  say YELLOW.'  Alt Name        '.WHITE.': '.CYAN.($self->alt_name//'-none-').RESET;
  say YELLOW.'  Alt Name Valid  '.WHITE.': '.CYAN.($self->is_valid_alt_name?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  say YELLOW.'  Has Valid Usage '.WHITE.': '.CYAN.($self->has_valid_usage?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  say YELLOW.'  Cert Valid      '.WHITE.': '.CYAN.($self->is_cert_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  say YELLOW.'  Is Valid        '.WHITE.': '.CYAN.($self->is_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  if ( ! $self->is_valid ) {
    say "Errors:";
    foreach my $error ( $self->errors->@* ) {
      my $error_code = $error->code;
      my $error_text = $error->description;
      my $error_detail = $error->detail // '';
      $error_detail =~ s/\n/\n    /g;
      say BRIGHT_RED."  $error_code ".WHITE.': '.CYAN.$error_text.($error_detail?"\n    ".$error_detail:'').RESET;
    }
  }
  if ($self->chain_object){
    say '';
    $self->chain_object->app_validate;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::VMC - Class to model a VMC

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a VMC Set

=head1 INPUTS

These values are used as inputs for lookups and verifications, they are typically set by the caller based on values found in the message being processed

=head2 data

is=rw

Raw data of the VMC contents; Fetched from authority URI if not given

=head2 uri

is=rw

URI of this VMC

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 cache_backend

is=ro

=head2 cert_list

is=rw

ArrayRef of individual Certificates in the chain

=head2 chain_object

is=rw

Mail::BIMI::VMC::Chain object for this Chain

=head2 errors

is=rw

=head2 http_client

is=rw

HTTP::Tiny::Paranoid (or similar) object used for HTTP operations

=head2 indicator

is=rw

Mail::BIMI::Indicator object for the Indicator embedded in this VMC Set

=head2 indicator_uri

is=rw

The URI of the embedded Indicator

=head2 is_cert_valid

is=rw

Is this Certificate Set valid

=head2 is_valid

is=rw

Is this VMC valid

=head2 vmc_object

is=rw

Mail::BIMI::VMC::Cert object for this VMC Set

=head1 CONSUMES

=over 4

=item * L<Mail::BIMI::Role::Cacheable>

=item * L<Mail::BIMI::Role::HasError>

=item * L<Mail::BIMI::Role::HasError|Mail::BIMI::Role::HasHTTPClient|Mail::BIMI::Role::Cacheable>

=item * L<Mail::BIMI::Role::HasHTTPClient>

=back

=head1 EXTENDS

=over 4

=item * L<Mail::BIMI::Base>

=back

=head1 METHODS

=head2 I<cache_valid_for()>

How long should the cache for this class be valid

=head2 I<http_client_max_fetch_size()>

Maximum permitted HTTP fetch

=head2 I<subject()>

Return the subject of the VMC

=head2 I<not_before()>

Return not before of the vmc

=head2 I<not_after()>

Return not after of the vmc

=head2 I<issuer()>

Return the issuer string of the VMC

=head2 I<is_expired()>

Return true if this VMC has expired

=head2 I<alt_name()>

Return the alt name string for the VMC

=head2 I<is_valid_alt_name()>

Return true if the VMC has a valid alt name for the domain of the current operation

=head2 I<is_self_signed()>

Return true if this VMC is self signed

=head2 I<has_valid_usage()>

Return true if this VMC has a valid usage extension for BIMI

=head2 I<finish()>

Finish and clean up, write cache if enabled.

=head2 I<app_validate()>

Output human readable validation status of this object

=head1 REQUIRES

=over 4

=item * L<File::Slurp|File::Slurp>

=item * L<MIME::Base64|MIME::Base64>

=item * L<Mail::BIMI::Indicator|Mail::BIMI::Indicator>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::VMC::Chain|Mail::BIMI::VMC::Chain>

=item * L<Moose|Moose>

=item * L<Term::ANSIColor|Term::ANSIColor>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
