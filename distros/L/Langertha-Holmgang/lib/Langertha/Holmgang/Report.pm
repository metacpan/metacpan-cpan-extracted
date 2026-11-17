package Langertha::Holmgang::Report;
# ABSTRACT: The JSON report of a Holmgang invocation, format holmgang_report 1

use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Digest::SHA qw( sha256_hex );
use JSON::MaybeXS ();
use Langertha ();
use Langertha::Holmgang ();
use Path::Tiny qw( path );
use POSIX qw( strftime );
use Scalar::Util qw( blessed );
use URI ();

our $VERSION = '0.001';

#### Format

# The format version this module writes and the highest it reads (ADR 0006).
sub format_version { 1 }

# The shape of format 1. A field spec is a primitive name (int num str bool
# time url any), the name of an entry of this table, or a hash with `type`
# and optional `null => 0` (never null), `min`, `max`, `of` (array element)
# or `values` (enum). Every field may be null unless it says `null => 0`;
# array elements are never null. `optional => 1` marks a field added after
# version 1 came out: a reader takes it as null where an older report lacks it.
my %SPEC = (
  report => { type => 'object', fields => {
    holmgang_report => { type => 'int', null => 0 },
    generator       => 'generator',
    started_at      => 'time',
    finished_at     => 'time',
    runs            => { type => 'array', of => 'run', null => 0 },
  } },
  generator => { type => 'object', fields => {
    holmgang  => 'str',
    langertha => 'str',
  } },
  run => { type => 'object', fields => {
    target  => 'target',
    variant => 'variant',
    suite   => 'suite',
    repeat  => { type => 'int', min => 1, null => 0 },
    status  => { type => 'enum', values => [qw( complete cancelled aborted )], null => 0 },
    error   => 'str',
    cases   => { type => 'array', of => 'case', null => 0 },
  } },
  target => { type => 'object', null => 0, fields => {
    label  => 'str',
    engine => 'str',
    model  => 'str',
    url    => 'url',
  } },
  variant => { type => 'object', null => 0, fields => {
    name     => 'str',
    settings => 'any',
  } },
  suite => { type => 'object', null => 0, fields => {
    id      => { type => 'str', null => 0 },
    version => 'str',
    topic   => 'str',
    digest  => 'str',
  } },
  case => { type => 'object', fields => {
    case_id     => { type => 'str', null => 0 },
    title       => 'str',
    tags        => { type => 'array', of => 'str' },
    tier        => 'str',
    difficulty  => { type => 'str', optional => 1 },
    weight      => { type => 'num', min => 0 },
    hard        => 'bool',
    untrusted   => 'bool',
    repetitions => { type => 'array', of => 'repetition', null => 0 },
  } },
  repetition => { type => 'object', fields => {
    repetition      => { type => 'int', min => 1, null => 0 },
    seed            => 'int',
    status          => { type => 'enum', values => [qw(
      no_vision context_exceeded error turn_limit passed uncertain failed
    )], null => 0 },
    score           => { type => 'num', min => 0, max => 1 },
    error           => 'str',
    finish_reason   => 'str',
    duration_ms     => { type => 'int', min => 0 },
    rules           => { type => 'array', of => 'rule' },
    diff            => { type => 'array', of => 'change' },
    turns           => { type => 'array', of => 'turn' },
    tokens          => 'tokens',
    calls           => { type => 'array', of => 'call' },
    sim_gaps        => { type => 'array', of => 'gap' },
    forbidden_calls => { type => 'int', min => 0 },
    injection_held  => 'bool',
    transcript      => { type => 'array', of => 'any' },
  } },
  rule => { type => 'object', fields => {
    title    => 'str',
    kind     => 'str',
    required => 'bool',
    passed   => 'bool',
    reason   => 'str',
    sim_gap  => 'str',
  } },
  change => { type => 'object', fields => {
    path   => 'str',
    before => 'any',
    after  => 'any',
  } },
  turn => { type => 'object', fields => {
    input_tokens     => { type => 'int', min => 0 },
    output_tokens    => { type => 'int', min => 0 },
    reasoning_tokens => { type => 'int', min => 0 },
    duration_ms      => { type => 'int', min => 0 },
    finish_reason    => 'str',
    calls            => { type => 'int', min => 0 },
  } },
  tokens => { type => 'object', null => 0, fields => {
    input     => { type => 'int', min => 0 },
    output    => { type => 'int', min => 0 },
    reasoning => { type => 'int', min => 0 },
    input_max => { type => 'int', min => 0 },
  } },
  call => { type => 'object', fields => {
    tool      => 'str',
    args      => 'any',
    succeeded => 'bool',
    sim_gap   => 'str',
  } },
  gap => { type => 'object', fields => {
    call => { type => 'int', min => 0 },
    tool => 'str',
    gap  => 'str',
  } },
);

# Query parameters of a target url that carry credentials.
my $SECRET_PARAM = qr/key|token|secret|pass|auth|sig|cred/i;

# Image content in any form a provider takes it.
my $DATA_URL   = qr{\bdata:(?:image/|[^,\s]*;base64,)}i;
my $BASE64_RUN = qr{\A[A-Za-z0-9+/]{1024,}={0,2}\z};

#### Attributes

has generator => ( is => 'ro', lazy_build => 1 );

sub _build_generator {
  return {
    holmgang  => $Langertha::Holmgang::VERSION,
    langertha => $Langertha::VERSION,
  };
}


has started_at => ( is => 'ro', lazy_build => 1 );

sub _build_started_at { shift->now }


has finished_at => ( is => 'ro', writer => '_set_finished_at' );


has with_transcript => ( is => 'ro', default => 0 );


has runs => ( is => 'ro', default => sub { [] } );


sub BUILD {
  my ( $self ) = @_;
  $self->generator;
  $self->started_at;
  my $runs = $self->runs;
  croak __PACKAGE__.'->new runs must be an array' unless ref $runs eq 'ARRAY';
  @$runs = map { $self->_shape( 'run', $runs->[$_], 'runs['.$_.']', 0 ) } 0 .. $#$runs;
  return;
}

#### Building

sub now {
  my ( $self, $epoch ) = @_;
  return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( defined $epoch ? $epoch : time ) );
}


sub add_run {
  my ( $self, %arg ) = @_;
  my $where = 'runs['.scalar( @{ $self->runs } ).']';
  my $repeat = $arg{repeat};
  my @cases = @{ $arg{cases} || croak __PACKAGE__.'->add_run needs cases' };
  my ( %case, @order );
  for my $i ( 0 .. $#cases ) {
    my $c = $cases[$i];
    croak __PACKAGE__.'->add_run '.$where.'.cases['.$i.'] has no case_id'
      unless ref $c eq 'HASH' && defined $c->{case_id};
    croak __PACKAGE__.'->add_run '.$where.': case '.$c->{case_id}.' listed twice'
      if $case{ $c->{case_id} };
    $case{ $c->{case_id} } = { ( map { $_ => $c->{$_} } qw( case_id title tags tier difficulty weight hard untrusted ) ), repetitions => [] };
    push @order, $c->{case_id};
  }
  my %seen;
  for my $r ( @{ $arg{results} || [] } ) {
    croak __PACKAGE__.'->add_run '.$where.': a result is not a hash' unless ref $r eq 'HASH';
    my $id = $r->{case_id};
    croak __PACKAGE__.'->add_run '.$where.': result for unknown case '.( defined $id ? $id : '(none)' )
      unless defined $id && $case{$id};
    my $n = $r->{repetition};
    croak __PACKAGE__.'->add_run '.$where.': case '.$id.' result without a repetition number'
      unless defined $n && $n =~ /\A[1-9][0-9]*\z/;
    croak __PACKAGE__.'->add_run '.$where.': case '.$id.' repetition '.$n.' beyond repeat '.$repeat
      if defined $repeat && $repeat =~ /\A[0-9]+\z/ && $n > $repeat;
    croak __PACKAGE__.'->add_run '.$where.': case '.$id.' repetition '.$n.' given twice'
      if $seen{$id}{$n}++;
    push @{ $case{$id}{repetitions} }, $self->_repetition( $r, $where.' case '.$id.' repetition '.$n );
  }
  for my $c ( values %case ) {
    @{ $c->{repetitions} } = sort { $a->{repetition} <=> $b->{repetition} } @{ $c->{repetitions} };
  }
  my $run = $self->_shape( 'run', {
    ( map { $_ => $arg{$_} } qw( target variant suite repeat status error ) ),
    cases => [ map { $case{$_} } @order ],
  }, $where, 0 );
  push @{ $self->runs }, $run;
  return $run;
}


sub _repetition {
  my ( $self, $r, $where ) = @_;
  my $turns = $self->_shape( { type => 'array', of => 'turn' }, $r->{turns}, $where.'.turns', 0 );
  my $calls = $self->_shape( { type => 'array', of => 'call' }, $r->{calls}, $where.'.calls', 0 );
  my %tokens = map { $_ => undef } qw( input output reasoning input_max );
  my ( $duration, $finish );
  if ( $turns ) {
    $duration = 0;
    for my $t ( @$turns ) {
      $duration += $t->{duration_ms} if defined $t->{duration_ms};
      for my $f (qw( input output reasoning )) {
        my $v = $t->{ $f.'_tokens' };
        next unless defined $v;
        $tokens{$f} = ( $tokens{$f} || 0 ) + $v;
      }
      $tokens{input_max} = $t->{input_tokens}
        if defined $t->{input_tokens} && ( !defined $tokens{input_max} || $t->{input_tokens} > $tokens{input_max} );
    }
    $finish = $turns->[-1]{finish_reason} if @$turns;
  }
  my $gaps;
  if ( $calls ) {
    $gaps = [ map { +{ call => $_, tool => $calls->[$_]{tool}, gap => $calls->[$_]{sim_gap} } }
      grep { defined $calls->[$_]{sim_gap} } 0 .. $#$calls ];
  }
  return {
    ( map { $_ => $r->{$_} } qw( repetition seed status score error rules diff forbidden_calls injection_held ) ),
    finish_reason => $finish,
    duration_ms   => $duration,
    turns         => $turns,
    tokens        => \%tokens,
    calls         => $calls,
    sim_gaps      => $gaps,
    transcript    => scalar $self->_transcript( $r->{transcript}, $where ),
  };
}

sub _transcript {
  my ( $self, $messages, $where ) = @_;
  return unless $self->with_transcript && defined $messages;
  croak __PACKAGE__.' '.$where.'.transcript must be an array' unless ref $messages eq 'ARRAY';
  my @out;
  for my $m ( @$messages ) {
    if ( ref $m eq 'HASH' ) {
      next if defined $m->{role} && $m->{role} eq 'system';
      my %copy = %$m;
      delete $copy{untrusted};
      push @out, \%copy;
      next;
    }
    push @out, $m;
  }
  return \@out;
}

sub finish {
  my ( $self, $at ) = @_;
  $self->_set_finished_at( defined $at ? $at : $self->now );
  return $self;
}


sub image_entry {
  my ( $self, $name, $bytes ) = @_;
  croak __PACKAGE__.'->image_entry needs a name and the image bytes' unless defined $name && defined $bytes;
  croak __PACKAGE__.'->image_entry wants bytes, got characters' if utf8::is_utf8($bytes) && $bytes =~ /[^\x00-\xff]/;
  return { image => ''.$name, sha256 => sha256_hex($bytes), bytes => length $bytes };
}


#### Writing and reading

sub as_data {
  my ( $self ) = @_;
  return {
    holmgang_report => $self->format_version,
    generator       => $self->_shape( 'generator', $self->generator, 'generator', 0 ),
    started_at      => $self->_shape( 'time', $self->started_at, 'started_at', 0 ),
    finished_at     => $self->_shape( 'time', $self->finished_at, 'finished_at', 0 ),
    runs            => $self->runs,
  };
}


sub _json {
  return JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1, convert_blessed => 1 );
}

sub to_json { my ( $self ) = @_; return $self->_json->encode( $self->as_data ) }


sub write {
  my ( $self, $file ) = @_;
  croak __PACKAGE__.'->write needs a file' unless defined $file;
  path($file)->spew_raw( $self->to_json );
  return $self;
}


sub from_json {
  my ( $class, $bytes, %arg ) = @_;
  my $from = defined $arg{source} ? $arg{source} : 'report';
  my $data = eval { $class->_json->decode($bytes) };
  croak __PACKAGE__.' '.$from.' is not JSON: '.( $@ =~ s/\s+\z//r ) unless defined $data;
  croak __PACKAGE__.' '.$from.' is not a Holmgang report' unless ref $data eq 'HASH' && exists $data->{holmgang_report};
  my $v = $data->{holmgang_report};
  croak __PACKAGE__.' '.$from.': holmgang_report must be a positive integer'
    unless defined $v && !ref $v && $v =~ /\A[1-9][0-9]*\z/;
  croak __PACKAGE__.' '.$from.': unknown report version '.$v.' (this reader knows up to '.$class->format_version.')'
    if $v > $class->format_version;
  my $doc = $class->_shape( 'report', $data, $from, 1 );
  return $class->new(
    generator   => $doc->{generator},
    started_at  => $doc->{started_at},
    finished_at => $doc->{finished_at},
    runs        => $doc->{runs},
  );
}


sub read {
  my ( $class, $file ) = @_;
  croak __PACKAGE__.'->read needs a file' unless defined $file;
  return $class->from_json( path($file)->slurp_raw, source => ''.$file );
}


#### Merging

sub merge {
  my ( $class, @reports ) = @_;
  croak __PACKAGE__.'->merge needs at least one report' unless @reports;
  my ( %run, @order );
  my $json = $class->_json;
  for my $rep ( @reports ) {
    for my $run ( @{ $rep->runs } ) {
      my $key = $json->encode( { map { $_ => $run->{$_} } qw( target variant suite ) } );
      unless ( $run{$key} ) {
        push @order, $key;
        $run{$key} = { %$run, cases => [] , _case => {} };
      }
      my $m = $run{$key};
      croak __PACKAGE__.'->merge: run of suite '.$run->{suite}{id}.' has repeat '.$m->{repeat}.' and '.$run->{repeat}
        unless $m->{repeat} == $run->{repeat};
      $m->{status} = $class->_worse_status( $m->{status}, $run->{status} );
      $m->{error}  = $run->{error} unless defined $m->{error};
      for my $c ( @{ $run->{cases} } ) {
        my $mc = $m->{_case}{ $c->{case_id} };
        unless ( $mc ) {
          $mc = $m->{_case}{ $c->{case_id} } = { %$c, repetitions => [] };
          push @{ $m->{cases} }, $mc;
        }
        # a field added after version 1 is null in an older report: the other's value holds
        for my $f ( $class->_optional_case_fields ) {
          $mc->{$f} = $c->{$f} unless defined $mc->{$f};
        }
        my %meta_a = %$mc; delete $meta_a{repetitions};
        my %meta_b = %$c;  delete $meta_b{repetitions};
        defined $meta_b{$_} or $meta_b{$_} = $meta_a{$_} for $class->_optional_case_fields;
        croak __PACKAGE__.'->merge: case '.$c->{case_id}.' of suite '.$run->{suite}{id}.' differs between reports'
          unless $json->encode( \%meta_a ) eq $json->encode( \%meta_b );
        for my $r ( @{ $c->{repetitions} } ) {
          my ($have) = grep { $_->{repetition} == $r->{repetition} } @{ $mc->{repetitions} };
          unless ( $have ) {
            push @{ $mc->{repetitions} }, $r;
            next;
          }
          croak __PACKAGE__.'->merge: case '.$c->{case_id}.' repetition '.$r->{repetition}.' of suite '
            .$run->{suite}{id}.' is in two reports with different results'
            unless $json->encode( $class->_stable($have) ) eq $json->encode( $class->_stable($r) );
        }
        @{ $mc->{repetitions} } = sort { $a->{repetition} <=> $b->{repetition} } @{ $mc->{repetitions} };
      }
    }
  }
  my @runs = map { my $r = $run{$_}; delete $r->{_case}; $r } @order;
  my @start  = sort grep { defined } map { $_->started_at } @reports;
  my @finish = sort grep { defined } map { $_->finished_at } @reports;
  return $class->new(
    generator   => $reports[0]->generator,
    started_at  => $start[0],
    finished_at => $finish[-1],
    runs        => \@runs,
  );
}


sub _optional_case_fields {
  my $f = $SPEC{case}{fields};
  return grep { ref $f->{$_} && $f->{$_}{optional} } sort keys %$f;
}

sub _worse_status {
  my ( $self, $x, $y ) = @_;
  my %rank = ( complete => 0, cancelled => 1, aborted => 2 );
  return $rank{$y} > $rank{$x} ? $y : $x;
}

# A repetition without its volatile fields, for comparison.
sub _stable {
  my ( $self, $r ) = @_;
  my %copy = %$r;
  delete $copy{duration_ms};
  $copy{turns} = [ map { my %t = %$_; delete $t{duration_ms}; \%t } @{ $r->{turns} } ] if $r->{turns};
  return \%copy;
}

#### Shape

sub _shape {
  my ( $self, $spec, $value, $where, $strict ) = @_;
  $spec = $SPEC{$spec} || { type => $spec } unless ref $spec;
  my $type = $spec->{type};
  unless ( defined $value ) {
    croak __PACKAGE__.' '.$where.' must not be null' if defined $spec->{null} && !$spec->{null};
    return undef;
  }
  if ( $type eq 'object' ) {
    croak __PACKAGE__.' '.$where.' must be an object' unless ref $value eq 'HASH' && !blessed $value;
    my %out;
    for my $f ( sort keys %{ $spec->{fields} } ) {
      my $fs = $spec->{fields}{$f};
      croak __PACKAGE__.' '.$where.'.'.$f.' is missing'
        if $strict && !exists $value->{$f} && !( ref $fs && $fs->{optional} );
      $out{$f} = $self->_shape( $fs, $value->{$f}, $where.'.'.$f, $strict );
    }
    return \%out;
  }
  if ( $type eq 'array' ) {
    croak __PACKAGE__.' '.$where.' must be an array' unless ref $value eq 'ARRAY' && !blessed $value;
    my $of = $spec->{of};
    my $el = ref $of ? { %$of, null => 0 } : $SPEC{$of} ? { %{ $SPEC{$of} }, null => 0 } : { type => $of, null => 0 };
    return [ map { $self->_shape( $el, $value->[$_], $where.'['.$_.']', $strict ) } 0 .. $#$value ];
  }
  return $self->_any( $value, $where, $strict ) if $type eq 'any';
  if ( $type eq 'bool' ) {
    if ( JSON::MaybeXS::is_bool($value) ) {
      return $value ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
    }
    croak __PACKAGE__.' '.$where.' must be a JSON boolean' if $strict || ref $value;
    return $value ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
  }
  croak __PACKAGE__.' '.$where.' must be a scalar' if ref $value;
  if ( $type eq 'int' || $type eq 'num' ) {
    my $re = $type eq 'int' ? qr/\A-?[0-9]+\z/ : qr/\A-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][-+]?[0-9]+)?\z/;
    croak __PACKAGE__.' '.$where.' must be '.( $type eq 'int' ? 'an integer' : 'a number' ).", got '".$value."'"
      unless $value =~ $re;
    my $n = 0 + $value;
    croak __PACKAGE__.' '.$where.' must be at least '.$spec->{min} if defined $spec->{min} && $n < $spec->{min};
    croak __PACKAGE__.' '.$where.' must be at most '.$spec->{max}  if defined $spec->{max} && $n > $spec->{max};
    return $n;
  }
  my $text = ''.$value;
  $self->_check_text( $text, $where );
  if ( $type eq 'enum' ) {
    croak __PACKAGE__.' '.$where.": unknown value '".$text."'" unless grep { $_ eq $text } @{ $spec->{values} };
  }
  elsif ( $type eq 'time' ) {
    croak __PACKAGE__.' '.$where.": not an ISO-8601 time '".$text."'"
      unless $text =~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(?::[0-9]{2}(?:\.[0-9]+)?)?(?:Z|[-+][0-9]{2}:?[0-9]{2})\z/;
  }
  elsif ( $type eq 'url' ) {
    return $self->_clean_url($text);
  }
  return $text;
}

# Deep copy of free data (arguments, diff values, settings, transcript):
# booleans normalised, objects and image content refused.
sub _any {
  my ( $self, $value, $where, $strict ) = @_;
  return undef unless defined $value;
  return $value ? JSON::MaybeXS::true() : JSON::MaybeXS::false() if JSON::MaybeXS::is_bool($value);
  croak __PACKAGE__.' '.$where.' holds an object ('.ref($value).'); only plain data goes into a report'
    if blessed $value;
  if ( ref $value eq 'HASH' ) {
    croak __PACKAGE__.' '.$where.' holds base64 image content'
      if ( ref $value->{source} eq 'HASH' && ( $value->{source}{type} // '' ) eq 'base64' )
      || grep { exists $value->{$_} } qw( inline_data inlineData b64_json );
    return { map { $_ => $self->_any( $value->{$_}, $where.'.'.$_, $strict ) } keys %$value };
  }
  if ( ref $value eq 'ARRAY' ) {
    return [ map { $self->_any( $value->[$_], $where.'['.$_.']', $strict ) } 0 .. $#$value ];
  }
  croak __PACKAGE__.' '.$where.' holds a '.ref($value).' reference' if ref $value;
  $self->_check_text( $value, $where );
  return $value;
}

sub _check_text {
  my ( $self, $text, $where ) = @_;
  croak __PACKAGE__.' '.$where.' holds a data: URL; images go into a report only as { image, sha256, bytes }'
    if $text =~ $DATA_URL;
  croak __PACKAGE__.' '.$where.' holds base64 content; images go into a report only as { image, sha256, bytes }'
    if length $text >= 1024 && $text =~ $BASE64_RUN;
  return;
}

sub _clean_url {
  my ( $self, $text ) = @_;
  my $uri = URI->new($text);
  return $text unless $uri->scheme;
  $uri->fragment(undef);
  $uri->userinfo(undef) if $uri->can('userinfo');
  if ( $uri->can('query_form') && defined $uri->query ) {
    my @q = $uri->query_form;
    my @keep;
    while ( my ( $k, $v ) = splice @q, 0, 2 ) {
      push @keep, $k, $v unless $k =~ $SECRET_PARAM;
    }
    $uri->query_form( \@keep );
    $uri->query(undef) unless @keep;
  }
  return $uri->as_string;
}

#### cai-platform

sub from_cai_platform {
  my ( $class, $data, %arg ) = @_;
  croak __PACKAGE__.'->from_cai_platform needs the decoded --report hash'
    unless ref $data eq 'HASH' && ref $data->{runs} eq 'ARRAY';
  my $grading = $arg{grading} || {};
  my $suites  = $arg{suites}  || {};
  my %model   = map { $_ => 1 } @{ $data->{models} || [] };
  my ( %group, @order );
  for my $row ( @{ $data->{runs} } ) {
    my $key = join "\0", map { defined $_ ? $_ : '' } $row->{target}, $row->{suite_id};
    push @order, $key unless $group{$key};
    push @{ $group{$key} }, $row;
  }
  my %run_status = ( done => 'complete', cancelled => 'cancelled', failed => 'aborted' );
  my @runs;
  for my $key ( @order ) {
    my @rows  = @{ $group{$key} };
    my $first = $rows[0];
    my $sid   = $first->{suite_id};
    my $meta  = $suites->{$sid} || {};
    my $repeat = ( $data->{repeat_by_suite} || {} )->{$sid};
    $repeat = @rows unless defined $repeat;
    croak __PACKAGE__.'->from_cai_platform: '.scalar(@rows).' runs of '.$first->{target}.'/'.$sid.' for repeat '.$repeat
      if @rows > $repeat;
    my $status = 'complete';
    my $error;
    my ( %case, @case_order );
    for my $i ( 0 .. $#rows ) {
      my $row = $rows[$i];
      my $s = $run_status{ $row->{status} // '' }
        or croak __PACKAGE__.'->from_cai_platform: unknown run status '.( $row->{status} // '(none)' );
      $status = $class->_worse_status( $status, $s );
      $error = $row->{error} unless defined $error;
      for my $c ( @{ $row->{cases} || [] } ) {
        my $id = $c->{case_id};
        unless ( $case{$id} ) {
          my $cm = ( $meta->{cases} || {} )->{$id} || {};
          $case{$id} = {
            case_id     => $id,
            title       => $c->{title},
            difficulty  => defined $c->{difficulty} ? $c->{difficulty} : $cm->{difficulty},
            ( map { $_ => $cm->{$_} } qw( tags tier weight hard untrusted ) ),
            repetitions => [],
          };
          push @case_order, $id;
        }
        my $g = defined $row->{id} ? ( $grading->{ $row->{id} } || {} )->{$id} : undef;
        push @{ $case{$id}{repetitions} }, $class->_cai_repetition( $c, $g, $i + 1, $repeat );
      }
    }
    push @runs, {
      target => {
        label  => $first->{target},
        engine => undef,
        model  => $model{ $first->{target} // '' } ? $first->{target} : undef,
        url    => $data->{base_url},
      },
      variant => { name => undef, settings => undef },
      suite   => { id => $sid, version => $meta->{version}, topic => $first->{topic}, digest => $meta->{digest} },
      repeat  => $repeat,
      status  => $status,
      error   => $error,
      cases   => [ map { $case{$_} } @case_order ],
    };
  }
  return $class->new( started_at => undef, runs => \@runs );
}


sub _cai_repetition {
  my ( $self, $c, $g, $n, $repeat ) = @_;
  my $exceeded = $c->{exceeded} ? 1 : 0;
  my $st = $c->{status} // '';
  my $status = ( $exceeded && ( $st eq 'failed' || $st eq 'ungraded' ) ) ? 'turn_limit'
    : $st eq 'ungraded' ? 'uncertain'
    : ( grep { $_ eq $st } qw( passed failed error context_exceeded ) ) ? $st
    : croak __PACKAGE__.'->from_cai_platform: unknown case status '.( length $st ? $st : '(none)' ).' for '.$c->{case_id};
  my ( $rules, $diff, $score );
  my @calls = map { +{ tool => undef, args => undef, succeeded => undef, sim_gap => undef } } 1 .. ( $c->{tool_calls} || 0 );
  my $gaps;
  if ( ref $g eq 'HASH' ) {
    $rules = [ map { +{
      title    => $_->{title},
      kind     => $_->{kind},
      required => $_->{required} ? 1 : 0,
      passed   => $_->{passed} ? 1 : 0,
      reason   => $_->{detail},
      sim_gap  => $_->{sim_gap},
    } } grep { ( $_->{kind} // '' ) ne 'turns' } @{ $g->{rules} || [] } ];
    my $passed = grep { $_->{passed} } @$rules;
    $score = @$rules ? 0 + sprintf( '%.4f', $passed / @$rules ) : 0;
    $diff = [ map { +{ path => $_->{path}, before => $_->{before}, after => $_->{after} } } @{ $g->{diff} || [] } ];
    $gaps = [ map { +{ call => $_->{index}, tool => $_->{tool}, gap => $_->{gap} } } @{ $g->{sim_gaps} || [] } ];
    for my $gap ( @$gaps ) {
      my $call = defined $gap->{call} ? $calls[ $gap->{call} ] : undef;
      next unless $call;
      $call->{tool}    = $gap->{tool};
      $call->{sim_gap} = $gap->{gap};
    }
  }
  else {
    $score = $exceeded ? undef : $c->{score};
    $gaps = [ map { +{ call => undef, tool => undef, gap => $_ } } @{ $c->{sim_gaps} || [] } ];
  }
  my $tok = sub { my ( $v ) = @_; return $v ? $v : undef };
  return {
    repetition      => $n,
    seed            => $repeat > 1 ? $n : undef,
    status          => $status,
    score           => $score,
    error           => undef,
    finish_reason   => undef,
    duration_ms     => $c->{duration_ms},
    rules           => $rules,
    diff            => $diff,
    turns           => [ map { +{ map { $_ => undef } qw( input_tokens output_tokens reasoning_tokens duration_ms finish_reason calls ) } }
      1 .. ( $c->{turns} || 0 ) ],
    tokens          => {
      input     => $tok->( $c->{prompt_tokens} ),
      output    => $tok->( $c->{completion_tokens} ),
      reasoning => undef,
      input_max => $tok->( $c->{prompt_tokens_max} ),
    },
    calls           => \@calls,
    sim_gaps        => $gaps,
    forbidden_calls => $c->{forbidden_calls},
    injection_held  => $c->{injection_held},
    transcript      => undef,
  };
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Report - The JSON report of a Holmgang invocation, format holmgang_report 1

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Langertha::Holmgang::Report;

    my $report = Langertha::Holmgang::Report->new( with_transcript => 0 );
    $report->add_run(
      target => { label => 'local-a', engine => 'OpenAI', model => 'm-1', url => $url },
      variant => { name => 'default', settings => {} },
      suite  => { id => 'demo', version => '1', topic => 'demo', digest => $digest },
      repeat => 1, status => 'complete', error => undef,
      cases   => [ { case_id => 'demo-01', title => 'Open the port', tags => [], tier => undef,
                     difficulty => undef, weight => 1, hard => 0, untrusted => 0 } ],
      results => [ $result_from_the_runner ],
    );
    $report->finish->write('/data/reports/run.json');

    my $again = Langertha::Holmgang::Report->read('/data/reports/run.json');
    my $all   = Langertha::Holmgang::Report->merge( $again, $other );

=head1 DESCRIPTION

One JSON document per invocation in format C<holmgang_report: 1>, exactly as
ADR 0006 fixes it: canonical UTF-8 JSON, every field always present, C<null>
for an unknown value (never C<0>, never absent), booleans as C<true>/C<false>.
It holds what was measured, per run, case and repetition — never a derived
number beyond C<score>, C<tokens> and the call indices; topics, weights,
curves and verdicts are computed from it elsewhere, so merging reports cannot
count anything twice.

No credentials leave through it: the target carries only C<label>, C<engine>,
C<model> and a C<url> stripped of user info and credential parameters; error
texts must have passed the engine's scrubbing before they arrive.

=head2 generator

C<< { holmgang => $version, langertha => $version } >>, the versions that wrote
the report. Defaults to the loaded ones. Volatile.

=head2 started_at

ISO-8601 time the invocation started. Defaults to the time the report object
was first asked for it; pass C<undef> for unknown. Volatile.

=head2 finished_at

ISO-8601 time the invocation finished, C<undef> until L</finish>. Volatile.

=head2 with_transcript

The switch of ADR 0006 for C<transcript>: when true, L</add_run> keeps each
result's transcript (without system messages, the C<untrusted> mark stripped);
off by default, and then every repetition's C<transcript> is C<null>.

=head2 runs

The runs in format 1, as L</add_run> builds them. Runs passed to C<new> must
already be in format 1; they are checked and normalised the same way.

=head2 now

    my $ts = $report->now;            # 2026-11-04T21:13:52Z
    my $ts = $report->now($epoch);

The ISO-8601 UTC time format the report uses.

=head2 add_run

    $report->add_run(
      target  => { label => 'local-a', engine => 'OpenAI', model => 'm-1',
                   url => 'http://10.0.0.5:8000/v1' },
      variant => { name => 'think-off', settings => { enable_thinking => 0 } },
      suite   => { id => 'demo', version => '3', topic => 'demo', digest => '…' },
      repeat  => 3,
      status  => 'complete',            # complete | cancelled | aborted
      error   => undef,                 # run error, already scrubbed by the engine
      cases   => [ <case meta>, … ],    # in the suite's load order
      results => [ <result>, … ],       # one per case and repetition, any order
    );

Builds one run of format 1 from the runner's results and appends it; returns
the run hash. Only the fields of format 1 are copied, so anything else a caller
passes (a key in C<target>, the case state) never reaches the report. C<url>
loses its user info, fragment and every query parameter whose name looks like a
credential. Croaks on a shape error (with the field path), a result for a case
not in C<cases>, a repetition given twice or beyond C<repeat>, an object or
image content anywhere (see L</IMAGES>).

B<Case meta> (the case's own fields, ADR 0005): C<case_id> (required),
C<title>, C<tags>, C<tier>, C<difficulty>, C<weight>, C<hard>, C<untrusted>. A
case without results gets C<< repetitions => [] >>.

B<Result> — the per-repetition interface the runner produces, plain data:

    {
      case_id         => 'demo-01',
      repetition      => 1,                 # 1..repeat
      seed            => 1,                 # int or undef
      status          => 'passed',          # wire name, ADR 0006
      score           => 0.75,              # 0..1 from the grader
      error           => undef,             # scrubbed text or undef
      rules           => [ { title, kind, required, passed, reason, sim_gap }, … ],
      diff            => [ { path, before, after }, … ],   # path as text
      turns           => [ {                # one per model call that reached the target
        input_tokens, output_tokens, reasoning_tokens,     # undef when not sent
        duration_ms, finish_reason, calls,                 # calls = tool calls of the turn
      }, … ],
      calls           => [ { tool, args, succeeded, sim_gap }, … ],   # in call order
      forbidden_calls => 0,
      injection_held  => undef,             # undef without untrusted content
      transcript      => [ … ],             # messages; kept only with with_transcript
    }

Booleans may be any Perl truth value; they are written as JSON C<true>/C<false>.
A missing key is C<null> in the report. The report derives, and the result does
not carry: C<duration_ms> (sum of the turns' C<duration_ms>, C<0> without turns),
C<finish_reason> (of the last turn), C<tokens> (per field the sum over the turns,
C<null> when no turn had a value; C<input_max> the largest C<input_tokens>) and
C<sim_gaps> (one entry per call with a C<sim_gap>, C<call> its 0-based index).
A turn that never reached the target (the C<no_vision> pre-check) is not in
C<turns>. Transcript images must already be L</image_entry> placeholders.

=head2 finish

    $report->finish;              # finished_at = now
    $report->finish($iso_time);

=head2 image_entry

    my $placeholder = $report->image_entry( 'scan-1.png', $raw_bytes );
    # { image => 'scan-1.png', sha256 => '…', bytes => 48213 }

The only form an image takes in a report (ADR 0006). Also callable on the
class.

=head2 as_data

The report as a plain hash of format 1.

=head2 to_json

The report as canonical UTF-8 JSON bytes. The same input gives the same bytes;
the I<volatile> fields (C<generator>, C<started_at>, C<finished_at>, each
repetition's C<duration_ms> and each turn's C<duration_ms>) are the only ones
that differ between two runs of the same mock.

=head2 write

    $report->write('/data/reports/run.json');

Writes L</to_json> to the file. Reports of private suites are as private as
their cases (ADR 0003): write them outside the checkout.

=head2 from_json

    my $report = Langertha::Holmgang::Report->from_json( $bytes, source => $name );

Reads a report. Croaks loudly on anything but JSON, on a missing or higher
C<holmgang_report> version, and on a shape error with the field path: every field
of format 1 must be present (C<null> where unknown) — except C<difficulty> of a
case, added to format 1 later (k57), which reads as C<null> where a report lacks
it —, booleans must be JSON booleans, image content is refused. Fields it does
not know are ignored and not kept.

=head2 read

    my $report = Langertha::Holmgang::Report->read('/data/reports/run.json');

=head2 merge

    my $all = Langertha::Holmgang::Report->merge( map { Langertha::Holmgang::Report->read($_) } @files );

One report from several, without counting anything twice: runs with the same
C<target>, C<variant> and C<suite> become one, their cases are joined by
C<case_id> and the repetitions by number. A repetition found in more than one
report is kept once when it is identical apart from the volatile fields, and
croaks when it differs; so does a different C<repeat> or case meta for the same
run, except that a C<difficulty> of C<null> (a report written before the field
came, k57) takes the other report's value. The merged run's C<status> is the
worst of its parts (C<aborted> over C<cancelled> over C<complete>), C<error> the first one given;
C<started_at> is the earliest, C<finished_at> the latest (compared as text, as
this module writes them in UTC), C<generator> that of the first report.

=head2 from_cai_platform

    my $report = Langertha::Holmgang::Report->from_cai_platform(
      $decoded_cai_report,
      grading => { <cai run id> => { <case_id> => <grading JSON from the database> } },
      suites  => { <suite id> => { version => …, digest => …,
                                   cases => { <case_id> => { tags, tier, difficulty, weight, hard, untrusted } } } },
    );

Maps a cai-platform C<evals run --report> file onto format 1 for the acceptance
comparison, following the table in ADR 0006. Rows with the same target
and suite, in their order in C<runs> (start order), become repetitions 1..n of
one run; C<repeat> comes from C<repeat_by_suite>. Statuses: C<passed> stays,
C<failed>/C<ungraded> with C<exceeded> become C<turn_limit>, C<ungraded> becomes
C<uncertain>, C<failed>, C<error> and C<context_exceeded> keep their names; an
unknown status croaks. Run statuses C<done>, C<cancelled>, C<failed> become
C<complete>, C<cancelled>, C<aborted>.

The C<--report> file holds counts, not lists. So C<turns> and C<calls> get as
many entries as the counts say, with C<null> fields; token sums of C<0> become
C<null>; C<sim_gaps> keeps only the gap texts. Rules and the diff are only in
the database: with C<grading> for a case they are mapped (C<detail> to
C<reason>, 0/1 to booleans, the rule of kind C<turns> dropped and C<score>
recomputed as in C<Eval::Grader>), the gaps get their call index and tool, and
the calls their tool and gap. Without C<grading>, C<rules> and C<diff> are
C<null>, and C<score> is C<null> for a turn limit (it counted the dropped rule).
Case meta beyond C<case_id>, C<title> and C<difficulty> (each case row of
C<--report> carries it; C<suites> fills in where a row lacks it), the suite
version and digest come from C<suites> or are C<null>; C<target.engine> and the variant are always
C<null>; C<seed> is the round number when C<repeat> is above 1, as
C<Eval::Batch> sets it. Timestamps are C<null>.

=head1 IMAGES

No image content goes into a report. Anywhere in the document, a C<data:> URL,
a base64 run of 1024 characters or more, a provider image block carrying
base64 (C<< source => { type => 'base64' } >>, C<inline_data>, C<inlineData>,
C<b64_json>) or any object (such as a L<Langertha::Content::Image>) is refused
on write and on read. An image in a transcript is the placeholder
L</image_entry> builds.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Holmgang>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
