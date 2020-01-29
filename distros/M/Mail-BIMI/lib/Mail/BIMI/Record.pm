package Mail::BIMI::Record;
# ABSTRACT: Class to model a collection of egress pools
our $VERSION = '1.20200129'; # VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
use Mail::BIMI::Record::Authority;
use Mail::BIMI::Record::Location;
use Mail::DMARC::PurePerl;
  with 'Mail::BIMI::Role::Constants';
  with 'Mail::BIMI::Role::Error';
  with 'Mail::BIMI::Role::Resolver';
  has domain => ( is => 'rw', isa => Str, required => 1 );
  has selector => ( is => 'rw', isa => Str );
  has version => ( is => 'rw', isa => Str );
  has authorities => ( is => 'rw', isa => class_type('Mail::BIMI::Record::Authority'), lazy => 1, builder => '_build_authorities' );
  has locations => ( is => 'rw', isa => class_type('Mail::BIMI::Record::Location'), lazy => 1, builder => '_build_locations' );
  has record => ( is => 'rw', isa => HashRef, lazy => 1, builder => '_build_record' );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid' );

sub _build_authorities($self) {
  my $record = $self->record->{a} // '';
  # TODO better parser here
  my @authority = split( ',', $record );
  return Mail::BIMI::Record::Authority->new( authority => \@authority );
}

sub _build_locations($self) {
  my $record = '';
  if ( ! exists $self->record->{l} ) {
    $self->add_error( 'Missing l tag' );
  }
  else {
    $record = $self->record->{l} // '';
    if ( $record eq '' ) {
      $self->add_error( 'Empty l tag' );
    }
  }

  # TODO better parser here
    # Need to decode , and ; as per spec
    # TODO, should this have '.svg' appended?
  my @location = split( ',', $record );
  return Mail::BIMI::Record::Location->new( location => \@location );
}

sub _build_is_valid($self) {
  return 0 if ! keys $self->record->%*;

  if ( ! exists ( $self->record->{v} ) ) {
    $self->add_error( 'Missing v tag' );
  }
  else {
    $self->add_error( 'Empty v tag' )   if lc $self->record->{v} eq '';
    $self->add_error( 'Invalid v tag' ) if lc $self->record->{v} ne 'bimi1';
  }

  return 0 if !$self->locations->is_valid;
  return 0 if $self->error->@*;
  return 1;
}

sub _build_record($self) {
  my $domain            = $self->domain;
  my $selector          = $self->selector;
  my $fallback_selector = 'default';
  my $fallback_domain   = Mail::DMARC::PurePerl->new->get_organizational_domain($domain);

  my @records = grep { $_ =~ /^v=bimi1;/i } eval { $self->_get_dns_rr( 'TXT', $selector. '._bimi.' . $domain); };
  if ( my $error = $@ ) {
    $self->add_error( 'error querying DNS' );
    return {};
  }

  if ( !@records ) {
    if ( $domain eq $fallback_domain && $selector eq $fallback_selector ) {
      # nothing to fall back to
      $self->add_error( $self->NO_BIMI_RECORD );
      return {};
    }

    @records = grep { $_ =~ /^v=bimi1;/i } eval { $self->_get_dns_rr( 'TXT', $fallback_selector. '._bimi.' . $fallback_domain); };
    if ( my $error = $@ ) {
      $self->add_error( 'error querying DNS' );
      return {};
    }
    if ( !@records ) {
      $self->add_error( $self->NO_BIMI_RECORD );
      return {};
    }
    elsif ( scalar @records > 1 ) {
      $self->add_error( $self->MULTI_BIMI_RECORD );
      return {};
    }
    else {
      # We have one record, let's use that.
      $self->domain($fallback_domain);
      $self->selector($fallback_selector);
      return $self->_parse_record($records[0]);
    }
  }
  elsif ( scalar @records > 1 ) {
    push $self->error->@*, $self->MULTI_BIMI_RECORD;
    return {};
  }
  else {
    # We have one record, let's use that.
    return $self->_parse_record($records[0]);
  }
  return {};
}

sub _get_dns_rr($self,$type,$domain) {
  my @matches;
  my $res     = $self->resolver;
  my $query   = $res->query( $domain, $type ) or do {
    return @matches;
  };
  for my $rr ( $query->answer ) {
    next if $rr->type ne $type;
    push @matches, $rr->type eq  'A'   ?        $rr->address
                 : $rr->type eq 'PTR'  ?        $rr->ptrdname
                 : $rr->type eq  'NS'  ?        $rr->nsdname
                 : $rr->type eq  'TXT' ? scalar $rr->txtdata
                 : $rr->type eq  'SPF' ? scalar $rr->txtdata
                 : $rr->type eq 'AAAA' ?        $rr->address
                 : $rr->type eq  'MX'  ?        $rr->exchange
                 : $rr->answer;
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
      push $self->error->@*, 'Duplicate key in record';
    }
    if ( grep { $key eq $_ } ( qw{ v l a } ) ) {
      $data->{$key} = $value;
    }
  }
  return $data;
}

1;
