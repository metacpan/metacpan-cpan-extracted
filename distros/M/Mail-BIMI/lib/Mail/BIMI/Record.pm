package Mail::BIMI::Record;
# ABSTRACT: Class to model a BIMI record
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Term::ANSIColor qw{ :constants };
use Mail::BIMI::Record::Authority;
use Mail::BIMI::Record::Location;
use Mail::DMARC::PurePerl;

extends 'Mail::BIMI::Base';
with(
  'Mail::BIMI::Role::HasError',
  'Mail::BIMI::Role::Cacheable',
);
has domain => ( is => 'rw', isa => 'Str', required => 1, traits => ['CacheKey'],
  documentation => 'inputs: Domain the for the record; will become fallback domain if used', );
has retrieved_record => ( is => 'rw', traits => ['Cacheable'],
  documentation => 'Record as retrieved' );
has selector => ( is => 'rw', isa => 'Str', traits => ['CacheKey'],
  documentation => 'inputs: Selector used to retrieve the record; will become default if fallback was used', );
has version => ( is => 'rw', isa => 'Maybe[Str]', lazy => 1, builder => '_build_version', traits => ['Cacheable'],
  documentation => 'BIMI Version tag' );
has authority => ( is => 'rw', isa => 'Mail::BIMI::Record::Authority', lazy => 1, builder => '_build_authority',
  documentation => 'Mail::BIMI::Record::Authority object for this record' );
has location => ( is => 'rw', isa => 'Mail::BIMI::Record::Location', lazy => 1, builder => '_build_location',
  documentation => 'Mail::BIMI::Record::Location object for this record' );
has record_hashref => ( is => 'rw', isa => 'HashRef', lazy => 1, builder => '_build_record_hashref', traits => ['Cacheable'],
  documentation => 'Hashref of record values' );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid', traits => ['Cacheable'],
  documentation => 'Is this record valid' );



sub cache_valid_for($self) { return 3600 }

sub _build_version($self) {
  if ( !exists  $self->record_hashref->{v} ) {
    return undef;
  }
  return $self->record_hashref->{v};
}

sub _build_authority($self) {
  my $uri;
  if ( exists $self->record_hashref->{a} ) {
    $uri = $self->record_hashref->{a} // '';
  }
  # TODO better parser here
  return Mail::BIMI::Record::Authority->new( uri => $uri, bimi_object => $self->bimi_object );
}

sub _build_location($self) {
  my $uri;
  if ( exists $self->record_hashref->{l} ) {
    $uri = $self->record_hashref->{l} // '';
  }
  # TODO better parser here
  # Need to decode , and ; as per spec>
  my $location = Mail::BIMI::Record::Location->new( uri => $uri, is_relevant => $self->location_is_relevant, bimi_object => $self->bimi_object );
  return $location;
}


sub location_is_relevant($self) {
  # True if we don't have a relevant authority OR if we are checking VMC AND Location
  return 1 unless $self->bimi_object->options->no_location_with_vmc;
  if ( $self->authority && $self->authority->is_relevant ) {
    $self->log_verbose('Location is not relevant');
    return 0;
  }
  return 1;
}

sub _build_is_valid($self) {
  return 0 if ! keys $self->record_hashref->%*;

  if ( !defined $self->version ) {
    $self->add_error('MISSING_V_TAG');
    return 0;
  }
  else {
    $self->add_error('EMPTY_V_TAG')   if lc $self->version eq '';
    $self->add_error('INVALID_V_TAG') if lc $self->version ne 'bimi1';
    return 0 if $self->errors->@*;
  }
  if ($self->authority->is_relevant && !$self->authority->is_valid) {
    $self->add_error_object( $self->authority->errors );
  }
  if ($self->location_is_relevant && !$self->location->is_valid) {
    $self->add_error_object( $self->location->errors );
  }

  return 0 if $self->errors->@*;

  if ( $self->bimi_object->options->require_vmc ) {
      unless ( $self->authority && $self->authority->vmc && $self->authority->vmc->is_valid ) {
          $self->add_error('VMC_REQUIRED');
      }
  }

  if ( $self->authority && $self->authority->is_relevant ) {
    # Check the SVG payloads are identical
    ## Compare raw? or Uncompressed?
    if ( $self->location_is_relevant && $self->authority->vmc->indicator->data_uncompressed ne $self->location->indicator->data_uncompressed ) {
    #if ( $self->authority->vmc->indicator->data_maybe_compressed ne $self->location->indicator->data_maybe_compressed ) {
      $self->add_error('SVG_MISMATCH');
    }
  }

  return 0 if $self->errors->@*;
  $self->log_verbose('Record is valid');
  return 1;
}

sub _build_record_hashref($self) {
  my $domain            = $self->domain;
  my $selector          = $self->selector;
  my $fallback_selector = 'default';
  my $fallback_domain   = Mail::DMARC::PurePerl->new->get_organizational_domain($domain);

  my @records;
  eval {
    @records = $self->_get_from_dns($selector,$domain);
    1;
  } || do {
    my $error = $@;
    $error =~ s/ at \/.*$//s;
    $self->add_error('DNS_ERROR',$error);
    return {};
  };

  @records = grep { $_ =~ /^v=bimi1;/i } @records;

  if ( !@records ) {
    if ( $domain eq $fallback_domain && $selector eq $fallback_selector ) {
      # nothing to fall back to
      $self->add_error('NO_BIMI_RECORD');
      return {};
    }

    $self->log_verbose('Trying fallback domain');
    my @records;
    eval {
      @records = $self->_get_from_dns($fallback_selector,$fallback_domain);
      1;
    } || do {
      my $error = $@;
      $error =~ s/ at \/.*$//;
      $self->add_error('DNS_ERROR',$error);
      return {};
    };

    @records = grep { $_ =~ /^v=bimi1;/i } @records;

    if ( !@records ) {
      $self->add_error('NO_BIMI_RECORD');
      return {};
    }
    elsif ( scalar @records > 1 ) {
      $self->add_error('MULTI_BIMI_RECORD');
      return {};
    }
    else {
      # We have one record, let's use that.
      $self->domain($fallback_domain);
      $self->selector($fallback_selector);
      $self->retrieved_record($records[0]);
      return $self->_parse_record($records[0]);
    }
  }
  elsif ( scalar @records > 1 ) {
    $self->add_error('MULTI_BIMI_RECORD');
    return {};
  }
  else {
    # We have one record, let's use that.
    $self->retrieved_record($records[0]);
    return $self->_parse_record($records[0]);
  }
}

sub _get_from_dns($self,$selector,$domain) {
  my @matches;
  if ($self->bimi_object->options->force_record) {
    $self->log_verbose('Using fake record');
    push @matches, $self->bimi_object->options->force_record;
    return @matches;
  }
  my $res     = $self->bimi_object->resolver;
  my $query   = $res->query( "$selector._bimi.$domain", 'TXT' ) or do {
    return @matches;
  };
  for my $rr ( $query->answer ) {
    next if $rr->type ne 'TXT';
    push @matches, scalar $rr->txtdata;
  }
  return @matches;
}

sub _parse_record($self,$record) {
  my $data = {};
  my @parts = split ';', $record;
  foreach my $part ( @parts ) {
    $part =~ s/^ +//;
    $part =~ s/ +$//;
    my ( $key, $value ) = split '=', $part, 2;
    $key = lc $key;
    if ( exists $data->{ $key } ) {
      $self->add_error('DUPLICATE_KEY');
    }
    if ( grep { $key eq $_ } ( qw{ v l a } ) ) {
      $data->{$key} = $value;
    }
  }
  return $data;
}


sub finish($self) {
  $self->authority->finish if $self->authority;
  $self->location->finish if $self->location;
  $self->_write_cache;
}


sub app_validate($self) {
  say 'Record Returned: '.($self->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
  $self->is_valid; # To set retrieved record and actual domain/selector
  say YELLOW.'  Record    : '.($self->retrieved_record//'-none-').RESET;
  if ($self->retrieved_record){
    say YELLOW.'  Version   '.WHITE.': '.CYAN.($self->version//'-none-').RESET;
    say YELLOW.'  Domain    '.WHITE.': '.CYAN.($self->domain//'-none-').RESET;
    say YELLOW.'  Selector  '.WHITE.': '.CYAN.($self->selector//'-none-').RESET;
    say YELLOW.'  Authority '.WHITE.': '.CYAN.($self->authority->uri//'-none-').RESET if $self->authority;
    say YELLOW.'  Location  '.WHITE.': '.CYAN.($self->location->uri//'-none-').RESET if $self->location_is_relevant && $self->location;
    say YELLOW.'  Is Valid  '.WHITE.': '.($self->is_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  }

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
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Record - Class to model a BIMI record

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a BIMI Record

=head1 INPUTS

These values are used as inputs for lookups and verifications, they are typically set by the caller based on values found in the message being processed

=head2 domain

is=rw required

Domain the for the record; will become fallback domain if used

=head2 selector

is=rw

Selector used to retrieve the record; will become default if fallback was used

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 authority

is=rw

Mail::BIMI::Record::Authority object for this record

=head2 cache_backend

is=ro

=head2 errors

is=rw

=head2 is_valid

is=rw

Is this record valid

=head2 location

is=rw

Mail::BIMI::Record::Location object for this record

=head2 record_hashref

is=rw

Hashref of record values

=head2 retrieved_record

is=rw

Record as retrieved

=head2 version

is=rw

BIMI Version tag

=head1 CONSUMES

=over 4

=item * L<Mail::BIMI::Role::Cacheable>

=item * L<Mail::BIMI::Role::HasError>

=item * L<Mail::BIMI::Role::HasError|Mail::BIMI::Role::Cacheable>

=back

=head1 EXTENDS

=over 4

=item * L<Mail::BIMI::Base>

=back

=head1 METHODS

=head2 I<cache_valid_for()>

How long should the cache for this class be valid

=head2 I<location_is_relevant()>

Return true is the location is relevant to the validation of the record.

If we don't have a relevant authority, or we are checking BOTH authority and location.

=head2 I<finish()>

Finish and clean up, write cache if enabled.

=head2 I<app_validate()>

Output human readable validation status of this object

=head1 REQUIRES

=over 4

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::Record::Authority|Mail::BIMI::Record::Authority>

=item * L<Mail::BIMI::Record::Location|Mail::BIMI::Record::Location>

=item * L<Mail::DMARC::PurePerl|Mail::DMARC::PurePerl>

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
