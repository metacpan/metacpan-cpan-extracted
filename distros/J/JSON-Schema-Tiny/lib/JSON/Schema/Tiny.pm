use strict;
use warnings;
package JSON::Schema::Tiny; # git description: v0.013-5-gb4e2ba8
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Validate data against a schema, minimally
# KEYWORDS: JSON Schema data validation structure specification tiny

our $VERSION = '0.014';

use 5.020;  # for unicode_strings, signatures, postderef features
use experimental qw(signatures postderef);
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use B;
use Ref::Util 0.100 qw(is_plain_arrayref is_plain_hashref is_ref is_plain_arrayref);
use Mojo::URL;
use Mojo::JSON::Pointer;
use Carp qw(croak carp);
use Storable 'dclone';
use JSON::MaybeXS 1.004001 'is_bool';
use Feature::Compat::Try;
use JSON::PP ();
use List::Util 1.33 qw(any none);
use Scalar::Util 'blessed';
use if "$]" >= 5.022, POSIX => 'isinf';
use namespace::clean;
use Exporter 5.57 'import';

our @EXPORT_OK = qw(evaluate);

our $BOOLEAN_RESULT = 0;
our $SHORT_CIRCUIT = 0;
our $MAX_TRAVERSAL_DEPTH = 50;
our $MOJO_BOOLEANS; # deprecated; renamed to $SCALARREF_BOOLEANS
our $SCALARREF_BOOLEANS;
our $SPECIFICATION_VERSION;

my %version_uris = (
  'https://json-schema.org/draft/2020-12/schema' => 'draft2020-12',
  'https://json-schema.org/draft/2019-09/schema' => 'draft2019-09',
  'http://json-schema.org/draft-07/schema#'      => 'draft7',
);

sub new ($class, %args) {
  bless(\%args, $class);
}

sub evaluate {
  croak 'evaluate called in void context' if not defined wantarray;

  $SCALARREF_BOOLEANS = $SCALARREF_BOOLEANS // $MOJO_BOOLEANS;
  local $BOOLEAN_RESULT = $_[0]->{boolean_result} // $BOOLEAN_RESULT,
  local $SHORT_CIRCUIT = $_[0]->{short_circuit} // $SHORT_CIRCUIT,
  local $MAX_TRAVERSAL_DEPTH = $_[0]->{max_traversal_depth} // $MAX_TRAVERSAL_DEPTH,
  local $SCALARREF_BOOLEANS = $_[0]->{scalarref_booleans} // $SCALARREF_BOOLEANS // $_[0]->{mojo_booleans},
  local $SPECIFICATION_VERSION = $_[0]->{specification_version} // $SPECIFICATION_VERSION,
  shift
    if blessed($_[0]) and blessed($_[0])->isa(__PACKAGE__);

  croak '$SPECIFICATION_VERSION value is invalid'
    if defined $SPECIFICATION_VERSION and none { $SPECIFICATION_VERSION eq $_ } values %version_uris;

  croak 'insufficient arguments' if @_ < 2;
  my ($data, $schema) = @_;

  my $state = {
    depth => 0,
    data_path => '',
    traversed_schema_path => '',          # the accumulated traversal path up to the last $ref traversal
    initial_schema_uri => Mojo::URL->new, # the canonical URI as of the start or the last traversed $ref
    schema_path => '',                    # the rest of the path, since the start or the last traversed $ref
    errors => [],
    seen => {},
    short_circuit => $BOOLEAN_RESULT || $SHORT_CIRCUIT,
    root_schema => $schema,                 # so we can do $refs within the same document
    spec_version => $SPECIFICATION_VERSION,
  };

  my $valid;
  try {
    $valid = _eval_subschema($data, $schema, $state)
  }
  catch ($e) {
    if (is_plain_hashref($e)) {
      push $state->{errors}->@*, $e;
    }
    else {
      E($state, 'EXCEPTION: '.$e);
    }

    $valid = 0;
  }

  warn 'result is false but there are no errors' if not $valid and not $state->{errors}->@*;

  return $BOOLEAN_RESULT ? $valid : +{
    valid => $valid ? JSON::PP::true : JSON::PP::false,
    $valid ? () : (errors => $state->{errors}),
  };
}

######## NO PUBLIC INTERFACES FOLLOW THIS POINT ########

# current spec version => { keyword => undef, or arrayref of alternatives }
my %removed_keywords = (
  'draft7' => {
    id => [ '$id' ],
  },
  'draft2019-09' => {
    id => [ '$id' ],
    definitions => [ '$defs' ],
    dependencies => [ qw(dependentSchemas dependentRequired) ],
  },
  'draft2020-12' => {
    id => [ '$id' ],
    definitions => [ '$defs' ],
    dependencies => [ qw(dependentSchemas dependentRequired) ],
    '$recursiveAnchor' => [ '$dynamicAnchor' ],
    '$recursiveRef' => [ '$dynamicRef' ],
    additionalItems => [ 'items' ],
  },
);

sub _eval_subschema ($data, $schema, $state) {
  croak '_eval_subschema called in void context' if not defined wantarray;

  # do not propagate upwards changes to depth, traversed paths,
  # but additions to errors are by reference and will be retained
  $state = { %$state };
  delete $state->@{'keyword', grep /^_/, keys %$state};

  abort($state, 'EXCEPTION: maximum evaluation depth exceeded')
    if $state->{depth}++ > $MAX_TRAVERSAL_DEPTH;

  # find all schema locations in effect at this data path + canonical_uri combination
  # if any of them are absolute prefix of this schema location, we are in a loop.
  my $canonical_uri = canonical_uri($state);
  my $schema_location = $state->{traversed_schema_path}.$state->{schema_path};
  abort($state, 'EXCEPTION: infinite loop detected (same location evaluated twice)')
    if grep substr($schema_location, 0, length) eq $_,
      keys $state->{seen}{$state->{data_path}}{$canonical_uri}->%*;
  $state->{seen}{$state->{data_path}}{$canonical_uri}{$schema_location}++;

  my $schema_type = get_type($schema);
  return $schema || E($state, 'subschema is false') if $schema_type eq 'boolean';
  abort($state, 'invalid schema type: %s', $schema_type) if $schema_type ne 'object';

  return 1 if not keys %$schema;

  my $valid = 1;
  my $spec_version = $state->{spec_version}//'';

  foreach my $keyword (
    # CORE KEYWORDS
    qw($id $schema),
    !$spec_version || $spec_version ne 'draft7' ? '$anchor' : (),
    !$spec_version || $spec_version eq 'draft2019-09' ? '$recursiveAnchor' : (),
    !$spec_version || $spec_version eq 'draft2020-12' ? '$dynamicAnchor' : (),
    '$ref',
    !$spec_version || $spec_version eq 'draft2019-09' ? '$recursiveRef' : (),
    !$spec_version || $spec_version eq 'draft2020-12' ? '$dynamicRef' : (),
    !$spec_version || $spec_version ne 'draft7' ? qw($vocabulary $comment) : (),
    !$spec_version || $spec_version eq 'draft7' ? 'definitions' : (),
    !$spec_version || $spec_version ne 'draft7' ? '$defs' : (),
    # APPLICATOR KEYWORDS
    qw(allOf anyOf oneOf not if),
    !$spec_version || $spec_version ne 'draft7' ? 'dependentSchemas' : (),
    !$spec_version || $spec_version eq 'draft7' ? 'dependencies' : (),
    !$spec_version || $spec_version !~ qr/^draft(7|2019-09)$/ ? 'prefixItems' : (),
    'items',
    !$spec_version || $spec_version =~ qr/^draft(?:7|2019-09)$/ ? 'additionalItems' : (),
    qw(contains properties patternProperties additionalProperties propertyNames),
    # UNEVALUATED KEYWORDS
    !$spec_version || $spec_version ne 'draft7' ? qw(unevaluatedItems unevaluatedProperties) : (),
    # VALIDATOR KEYWORDS
    qw(type enum const
      multipleOf maximum exclusiveMaximum minimum exclusiveMinimum
      maxLength minLength pattern
      maxItems minItems uniqueItems),
    !$spec_version || $spec_version ne 'draft7' ? qw(maxContains minContains) : (),
    qw(maxProperties minProperties required),
    !$spec_version || $spec_version ne 'draft7' ? 'dependentRequired' : (),
  ) {
    next if not exists $schema->{$keyword};

    # keywords adjacent to $ref (except for definitions) are not evaluated before draft2019-09
    next if $keyword ne '$ref' and $keyword ne 'definitions'
      and exists $schema->{'$ref'} and $spec_version eq 'draft7';

    $state->{keyword} = $keyword;
    my $error_count = $state->{errors}->@*;

    my $sub = __PACKAGE__->can('_eval_keyword_'.($keyword =~ s/^\$//r));
    if (not $sub->($data, $schema, $state)) {
      warn 'result is false but there are no errors (keyword: '.$keyword.')'
        if $error_count == $state->{errors}->@*;
      $valid = 0;
    }

    last if not $valid and $state->{short_circuit};
  }

  # check for previously-supported but now removed keywords
  foreach my $keyword (sort keys $removed_keywords{$spec_version}->%*) {
    next if not exists $schema->{$keyword};
    my $message ='no-longer-supported "'.$keyword.'" keyword present (at location "'
      .canonical_uri($state).'")';
    if (my $alternates = $removed_keywords{$spec_version}->{$keyword}) {
      my @list = map '"'.$_.'"', @$alternates;
      @list = ((map $_.',', @list[0..$#list-1]), $list[-1]) if @list > 2;
      splice(@list, -1, 0, 'or') if @list > 1;
      $message .= ': this should be rewritten as '.join(' ', @list);
    }
    carp $message;
  }

  return $valid;
}

# KEYWORD IMPLEMENTATIONS

sub _eval_keyword_schema ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'string');
  assert_uri($state, $schema);

  return abort($state, '$schema can only appear at the schema resource root')
    if length($state->{schema_path});

  my $spec_version = $version_uris{$schema->{'$schema'}};
  abort($state, 'custom $schema URIs are not supported (must be one of: %s',
     join(', ', map '"'.$_.'"', keys %version_uris))
    if not $spec_version;

  abort($state, '"$schema" indicates a different version than that requested by $JSON::Schema::Tiny::SPECIFICATION_VERSION')
    if defined $SPECIFICATION_VERSION and $SPECIFICATION_VERSION ne $spec_version;

  # we special-case this because the check in _eval for older drafts + $ref has already happened
  abort($state, '$schema and $ref cannot be used together in older drafts')
    if exists $schema->{'$ref'} and $spec_version eq 'draft7';

  $state->{spec_version} = $spec_version;
}

sub _eval_keyword_ref ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'string');
  assert_uri_reference($state, $schema);

  my $uri = Mojo::URL->new($schema->{$state->{keyword}})->to_abs($state->{initial_schema_uri});
  abort($state, '%ss to anchors are not supported', $state->{keyword})
    if ($uri->fragment//'') !~ m{^(/(?:[^~]|~[01])*|)$};

  # the base of the $ref uri must be the same as the base of the root schema
  # unfortunately this means that many uses of $ref won't work, because we don't
  # track the locations of $ids in this or other documents.
  abort($state, 'only same-document, same-base JSON pointers are supported in %s', $state->{keyword})
    if $uri->clone->fragment(undef) ne Mojo::URL->new($state->{root_schema}{'$id'}//'');

  my $subschema = Mojo::JSON::Pointer->new($state->{root_schema})->get($uri->fragment);
  abort($state, 'EXCEPTION: unable to find resource %s', $uri) if not defined $subschema;

  return _eval_subschema($data, $subschema,
    +{ %$state,
      traversed_schema_path => $state->{traversed_schema_path}.$state->{schema_path}.'/'.$state->{keyword},
      initial_schema_uri => $uri,
      schema_path => '',
    });
}

sub _eval_keyword_recursiveRef ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'string');
  assert_uri_reference($state, $schema);

  my $uri = Mojo::URL->new($schema->{'$recursiveRef'})->to_abs($state->{initial_schema_uri});
  abort($state, '$recursiveRefs to anchors are not supported')
    if ($uri->fragment//'') !~ m{^(/(?:[^~]|~[01])*|)$};

  # the base of the $recursiveRef uri must be the same as the base of the root schema.
  # unfortunately this means that nearly all usecases of $recursiveRef won't work, because we don't
  # track the locations of $ids in this or other documents.
  abort($state, 'only same-document, same-base JSON pointers are supported in $recursiveRef')
    if $uri->clone->fragment(undef) ne Mojo::URL->new($state->{root_schema}{'$id'}//'');

  my $subschema = Mojo::JSON::Pointer->new($state->{root_schema})->get($uri->fragment);
  abort($state, 'EXCEPTION: unable to find resource %s', $uri) if not defined $subschema;

  if (is_type('boolean', $subschema->{'$recursiveAnchor'}) and $subschema->{'$recursiveAnchor'}) {
    $uri = Mojo::URL->new($schema->{'$recursiveRef'})
      ->to_abs($state->{recursive_anchor_uri} // $state->{initial_schema_uri});
    $subschema = Mojo::JSON::Pointer->new($state->{root_schema})->get($uri->fragment);
    abort($state, 'EXCEPTION: unable to find resource %s', $uri) if not defined $subschema;
  }

  return _eval_subschema($data, $subschema,
    +{ %$state,
      traversed_schema_path => $state->{traversed_schema_path}.$state->{schema_path}.'/$recursiveRef',
      initial_schema_uri => $uri,
      schema_path => '',
    });
}

sub _eval_keyword_dynamicRef { goto \&_eval_keyword_ref }

sub _eval_keyword_id ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'string');
  assert_uri_reference($state, $schema);

  my $uri = Mojo::URL->new($schema->{'$id'});

  if (($state->{spec_version}//'') eq 'draft7') {
    if (length($uri->fragment)) {
      abort($state, '$id cannot change the base uri at the same time as declaring an anchor')
        if length($uri->clone->fragment(undef));

      abort($state, '$id value does not match required syntax')
        if $uri->fragment !~ m/^[A-Za-z][A-Za-z0-9_:.-]*$/;

      return 1;
    }
  }
  else {
    abort($state, '$id value "%s" cannot have a non-empty fragment', $uri) if length $uri->fragment;
  }

  $uri->fragment(undef);
  return E($state, '$id cannot be empty') if not length $uri;

  $state->{initial_schema_uri} = $uri->is_abs ? $uri : $uri->to_abs($state->{initial_schema_uri});
  $state->{traversed_schema_path} = $state->{traversed_schema_path}.$state->{schema_path};
  $state->{schema_path} = '';

  return 1;
}

sub _eval_keyword_anchor ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'string');

  return 1 if
    (!$state->{spec_version} or $state->{spec_version} eq 'draft2019-09')
        and ($schema->{'$anchor'}//'') =~ /^[A-Za-z][A-Za-z0-9_:.-]*$/
      or
    (!$state->{spec_version} or $state->{spec_version} eq 'draft2020-12')
        and ($schema->{'$anchor'}//'') =~ /^[A-Za-z_][A-Za-z0-9._-]*$/;

  abort($state, '$anchor value does not match required syntax');
}

sub _eval_keyword_recursiveAnchor ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'boolean');
  return 1 if not $schema->{'$recursiveAnchor'} or exists $state->{recursive_anchor_uri};

  # this is required because the location is used as the base URI for future resolution
  # of $recursiveRef, and the fragment would be disregarded in the base
  abort($state, '"$recursiveAnchor" keyword used without "$id"')
    if not exists $schema->{'$id'};

  # record the canonical location of the current position, to be used against future resolution
  # of a $recursiveRef uri -- as if it was the current location when we encounter a $ref.
  $state->{recursive_anchor_uri} = canonical_uri($state);

  return 1;
}

sub _eval_keyword_dynamicAnchor ($data, $schema, $state) {
  return if not assert_keyword_type($state, $schema, 'string');

  abort($state, '$dynamicAnchor value does not match required syntax')
    if $schema->{'$dynamicAnchor'} !~ /^[A-Za-z_][A-Za-z0-9._-]*$/;
  return 1;
}

sub _eval_keyword_vocabulary ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'object');

  foreach my $property (sort keys $schema->{'$vocabulary'}->%*) {
    assert_keyword_type({ %$state, _schema_path_suffix => $property }, $schema, 'boolean');
    assert_uri($state, undef, $property);
  }

  abort($state, '$vocabulary can only appear at the schema resource root')
    if length($state->{schema_path});

  abort($state, '$vocabulary can only appear at the document root')
    if length($state->{traversed_schema_path}.$state->{schema_path});

  return 1;
}

sub _eval_keyword_comment ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'string');
  return 1;
}

sub _eval_keyword_definitions { goto \&_eval_keyword_defs }

sub _eval_keyword_defs ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'object');
  return 1;
}

sub _eval_keyword_type ($data, $schema, $state) {
  if (is_plain_arrayref($schema->{type})) {
    abort($state, 'type array is empty') if not $schema->{type}->@*;
    foreach my $type ($schema->{type}->@*) {
      abort($state, 'unrecognized type "%s"', $type//'<null>')
        if not any { ($type//'') eq $_ } qw(null boolean object array string number integer);
    }
    abort($state, '"type" values are not unique') if not is_elements_unique($schema->{type});

    my $type = get_type($data);
    return 1 if any {
      $type eq $_ or ($_ eq 'number' and $type eq 'integer')
        or ($_ eq 'boolean' and $SCALARREF_BOOLEANS and $type eq 'reference to SCALAR')
    } $schema->{type}->@*;
    return E($state, 'got %s, not one of %s', $type, join(', ', $schema->{type}->@*));
  }
  else {
    assert_keyword_type($state, $schema, 'string');
    abort($state, 'unrecognized type "%s"', $schema->{type}//'<null>')
      if not any { ($schema->{type}//'') eq $_ } qw(null boolean object array string number integer);

    my $type = get_type($data);
    return 1 if $type eq $schema->{type} or ($schema->{type} eq 'number' and $type eq 'integer')
      or ($schema->{type} eq 'boolean' and $SCALARREF_BOOLEANS and $type eq 'reference to SCALAR');
    return E($state, 'got %s, not %s', $type, $schema->{type});
  }
}

sub _eval_keyword_enum ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'array');
  abort($state, '"enum" values are not unique') if not is_elements_unique($schema->{enum});

  my @s; my $idx = 0;
  return 1 if any { is_equal($data, $_, $s[$idx++] = {}) } $schema->{enum}->@*;

  return E($state, 'value does not match'
    .(!(grep $_->{path}, @s) ? ''
      : ' (differences start '.join(', ', map 'from item #'.$_.' at "'.$s[$_]->{path}.'"', 0..$#s).')'));
}

sub _eval_keyword_const ($data, $schema, $state) {
  return 1 if is_equal($data, $schema->{const}, my $s = {});
  return E($state, 'value does not match'
    .($s->{path} ? ' (differences start at "'.$s->{path}.'")' : ''));
}

sub _eval_keyword_multipleOf ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'number');
  abort($state, 'multipleOf value is not a positive number') if $schema->{multipleOf} <= 0;

  return 1 if not is_type('number', $data);

  # if either value is a float, use the bignum library for the calculation
  if (ref($data) =~ /^Math::Big(?:Int|Float)$/ or ref($schema->{multipleOf}) =~ /^Math::Big(?:Int|Float)$/) {
    $data = ref($data) =~ /^Math::Big(?:Int|Float)$/ ? $data->copy : Math::BigFloat->new($data);
    my $divisor = ref($schema->{multipleOf}) =~ /^Math::Big(?:Int|Float)$/ ? $schema->{multipleOf} : Math::BigFloat->new($schema->{multipleOf});
    my ($quotient, $remainder) = $data->bdiv($divisor);
    return E($state, 'overflow while calculating quotient') if $quotient->is_inf;
    return 1 if $remainder == 0;
  }
  else {
    my $quotient = $data / $schema->{multipleOf};
    return E($state, 'overflow while calculating quotient')
      if "$]" >= 5.022 ? isinf($quotient) : $quotient =~ /^-?Inf$/i;
    return 1 if int($quotient) == $quotient;
  }

  return E($state, 'value is not a multiple of %s', sprintf_num($schema->{multipleOf}));
}

sub _eval_keyword_maximum ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data <= $schema->{maximum};
  return E($state, 'value is larger than %s', sprintf_num($schema->{maximum}));
}

sub _eval_keyword_exclusiveMaximum ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data < $schema->{exclusiveMaximum};
  return E($state, 'value is equal to or larger than %s', sprintf_num($schema->{exclusiveMaximum}));
}

sub _eval_keyword_minimum ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data >= $schema->{minimum};
  return E($state, 'value is smaller than %s', sprintf_num($schema->{minimum}));
}

sub _eval_keyword_exclusiveMinimum ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data > $schema->{exclusiveMinimum};
  return E($state, 'value is equal to or smaller than %s', sprintf_num($schema->{exclusiveMinimum}));
}

sub _eval_keyword_maxLength ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);

  return 1 if not is_type('string', $data);
  return 1 if length($data) <= $schema->{maxLength};
  return E($state, 'length is greater than %d', $schema->{maxLength});
}

sub _eval_keyword_minLength ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);

  return 1 if not is_type('string', $data);
  return 1 if length($data) >= $schema->{minLength};
  return E($state, 'length is less than %d', $schema->{minLength});
}

sub _eval_keyword_pattern ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'string');
  assert_pattern($state, $schema->{pattern});

  return 1 if not is_type('string', $data);
  return 1 if $data =~ m/$schema->{pattern}/;
  return E($state, 'pattern does not match');
}

sub _eval_keyword_maxItems ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);

  return 1 if not is_type('array', $data);
  return 1 if @$data <= $schema->{maxItems};
  return E($state, 'more than %d item%s', $schema->{maxItems}, $schema->{maxItems} > 1 ? 's' : '');
}

sub _eval_keyword_minItems ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);

  return 1 if not is_type('array', $data);
  return 1 if @$data >= $schema->{minItems};
  return E($state, 'fewer than %d item%s', $schema->{minItems}, $schema->{minItems} > 1 ? 's' : '');
}

sub _eval_keyword_uniqueItems ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'boolean');
  return 1 if not is_type('array', $data);
  return 1 if not $schema->{uniqueItems};
  return 1 if is_elements_unique($data, my $equal_indices = []);
  return E($state, 'items at indices %d and %d are not unique', @$equal_indices);
}

sub _eval_keyword_maxContains ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);
  return 1 if not exists $state->{_num_contains};
  return 1 if not is_type('array', $data);

  return E($state, 'contains too many matching items')
    if $state->{_num_contains} > $schema->{maxContains};

  return 1;
}

sub _eval_keyword_minContains ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);
  return 1 if not exists $state->{_num_contains};
  return 1 if not is_type('array', $data);

  return E($state, 'contains too few matching items')
    if $state->{_num_contains} < $schema->{minContains};

  return 1;
}

sub _eval_keyword_maxProperties ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);

  return 1 if not is_type('object', $data);
  return 1 if keys %$data <= $schema->{maxProperties};
  return E($state, 'more than %d propert%s', $schema->{maxProperties},
    $schema->{maxProperties} > 1 ? 'ies' : 'y');
}

sub _eval_keyword_minProperties ($data, $schema, $state) {
  assert_non_negative_integer($schema, $state);

  return 1 if not is_type('object', $data);
  return 1 if keys %$data >= $schema->{minProperties};
  return E($state, 'fewer than %d propert%s', $schema->{minProperties},
    $schema->{minProperties} > 1 ? 'ies' : 'y');
}

sub _eval_keyword_required ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'array');
  abort($state, '"required" element is not a string')
    if any { !is_type('string', $_) } $schema->{required}->@*;
  abort($state, '"required" values are not unique') if not is_elements_unique($schema->{required});

  return 1 if not is_type('object', $data);

  my @missing = grep !exists $data->{$_}, $schema->{required}->@*;
  return 1 if not @missing;
  return E($state, 'missing propert%s: %s', @missing > 1 ? 'ies' : 'y', join(', ', @missing));
}

sub _eval_keyword_dependentRequired ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'object');

  foreach my $property (sort keys $schema->{dependentRequired}->%*) {
    E({ %$state, _schema_path_suffix => $property }, 'value is not an array'), next
      if not is_type('array', $schema->{dependentRequired}{$property});

    foreach my $index (0..$schema->{dependentRequired}{$property}->$#*) {
      abort({ %$state, _schema_path_suffix => [ $property, $index ] }, 'element #%d is not a string', $index)
        if not is_type('string', $schema->{dependentRequired}{$property}[$index]);
    }

    abort({ %$state, _schema_path_suffix => $property }, 'elements are not unique')
      if not is_elements_unique($schema->{dependentRequired}{$property});
  }

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys $schema->{dependentRequired}->%*) {
    next if not exists $data->{$property};

    if (my @missing = grep !exists($data->{$_}), $schema->{dependentRequired}{$property}->@*) {
      $valid = E({ %$state, _schema_path_suffix => $property },
        'missing propert%s: %s', @missing > 1 ? 'ies' : 'y', join(', ', @missing));
    }
  }

  return 1 if $valid;
  return E($state, 'not all dependencies are satisfied');
}

sub _eval_keyword_allOf ($data, $schema, $state) {
  assert_array_schemas($schema, $state);

  my @invalid;
  foreach my $idx (0..$schema->{allOf}->$#*) {
    next if _eval_subschema($data, $schema->{allOf}[$idx],
      +{ %$state, schema_path => $state->{schema_path}.'/allOf/'.$idx });

    push @invalid, $idx;
    last if $state->{short_circuit};
  }

  return 1 if @invalid == 0;

  my $pl = @invalid > 1;
  return E($state, 'subschema%s %s %s not valid', $pl?'s':'', join(', ', @invalid), $pl?'are':'is');
}

sub _eval_keyword_anyOf ($data, $schema, $state) {
  assert_array_schemas($schema, $state);

  my $valid = 0;
  my @errors;
  foreach my $idx (0..$schema->{anyOf}->$#*) {
    next if not _eval_subschema($data, $schema->{anyOf}[$idx],
      +{ %$state, errors => \@errors, schema_path => $state->{schema_path}.'/anyOf/'.$idx });
    ++$valid;
    last if $state->{short_circuit};
  }

  return 1 if $valid;
  push $state->{errors}->@*, @errors;
  return E($state, 'no subschemas are valid');
}

sub _eval_keyword_oneOf ($data, $schema, $state) {
  assert_array_schemas($schema, $state);

  my (@valid, @errors);
  foreach my $idx (0..$schema->{oneOf}->$#*) {
    next if not _eval_subschema($data, $schema->{oneOf}[$idx],
      +{ %$state, errors => \@errors, schema_path => $state->{schema_path}.'/oneOf/'.$idx });
    push @valid, $idx;
    last if @valid > 1 and $state->{short_circuit};
  }

  return 1 if @valid == 1;

  if (not @valid) {
    push $state->{errors}->@*, @errors;
    return E($state, 'no subschemas are valid');
  }
  else {
    return E($state, 'multiple subschemas are valid: '.join(', ', @valid));
  }
}

sub _eval_keyword_not ($data, $schema, $state) {
  return 1 if not _eval_subschema($data, $schema->{not},
    +{ %$state, schema_path => $state->{schema_path}.'/not', short_circuit => 1, errors => [] });

  return E($state, 'subschema is valid');
}

sub _eval_keyword_if ($data, $schema, $state) {
  return 1 if not exists $schema->{then} and not exists $schema->{else};
  my $keyword = _eval_subschema($data, $schema->{if},
      +{ %$state, schema_path => $state->{schema_path}.'/if', short_circuit => 1, errors => [] })
    ? 'then' : 'else';

  return 1 if not exists $schema->{$keyword};
  return 1 if _eval_subschema($data, $schema->{$keyword},
    +{ %$state, schema_path => $state->{schema_path}.'/'.$keyword });
  return E({ %$state, keyword => $keyword }, 'subschema is not valid');
}

sub _eval_keyword_dependentSchemas ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'object');

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys $schema->{dependentSchemas}->%*) {
    next if not exists $data->{$property}
      or _eval_subschema($data, $schema->{dependentSchemas}{$property},
        +{ %$state, schema_path => jsonp($state->{schema_path}, 'dependentSchemas', $property) });

    $valid = 0;
    last if $state->{short_circuit};
  }

  return E($state, 'not all dependencies are satisfied') if not $valid;
  return 1;
}

sub _eval_keyword_dependencies ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'object');

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys $schema->{dependencies}->%*) {
    if (is_type('array', $schema->{dependencies}{$property})) {
      # as in dependentRequired

      foreach my $index (0..$schema->{dependencies}{$property}->$#*) {
        $valid = E({ %$state, _schema_path_suffix => [ $property, $index ] }, 'element #%d is not a string', $index)
          if not is_type('string', $schema->{dependencies}{$property}[$index]);
      }

      abort({ %$state, _schema_path_suffix => $property }, 'elements are not unique')
        if not is_elements_unique($schema->{dependencies}{$property});

      next if not exists $data->{$property};

      if (my @missing = grep !exists($data->{$_}), $schema->{dependencies}{$property}->@*) {
        $valid = E({ %$state, _schema_path_suffix => $property },
          'missing propert%s: %s', @missing > 1 ? 'ies' : 'y', join(', ', @missing));
      }
    }
    else {
      # as in dependentSchemas
      next if not exists $data->{$property}
        or _eval_subschema($data, $schema->{dependencies}{$property},
          +{ %$state, schema_path => jsonp($state->{schema_path}, 'dependencies', $property) });

      $valid = 0;
      last if $state->{short_circuit};
    }
  }

  return 1 if $valid;
  return E($state, 'not all dependencies are satisfied');
}

# drafts 4, 6, 7, 2019-09:
# prefixItems: ignored
# items - array-based  - start at 0; set $state->{_last_items_index} to last evaluated (not successfully).
# items - schema-based - start at 0; set $state->{_last_items_index} to last data item.
#                        booleans NOT accepted in draft4.
# additionalItems - schema-based. consume $state->{_last_items_index} as starting point.
#                                 booleans accepted in all versions.

# draft2020-12:
# prefixItems - array-based - start at 0; set $state->{_last_items_index} to last evaluated (not successfully).
# items - array-based: error
# items - schema-based - consume $state->{_last_items_index} as starting point.
# additionalItems - ignored

# no $SPECIFICATION_VERSION specified:
# prefixItems - array-based - set $state->{_last_items_index} to last evaluated (not successfully).
# items - array-based  -  starting index is always 0
#                             set $state->{_last_items_index} to last evaluated (not successfully).
# items - schema-based -  consume $state->{_last_items_index} as starting point
#                             set $state->{_last_items_index} to last data item.
#                                  booleans accepted.
# additionalItems - schema-based. consume $state->{_last_items_index} as starting point.
#                                 booleans accepted.

# prefixItems + items(array-based): items will generate an error
# prefixItems + additionalItems: additionalItems will be ignored
# items(schema-based) + additionalItems: additionalItems does nothing.

sub _eval_keyword_prefixItems ($data, $schema, $state) {
  return if not assert_array_schemas($schema, $state);
  goto \&_eval_keyword__items_array_schemas;
}

sub _eval_keyword_items ($data, $schema, $state) {
  if (is_plain_arrayref($schema->{items})) {
    abort($state, 'array form of "items" not supported in %s', $state->{spec_version})
      if ($state->{spec_version}//'') eq 'draft2020-12';

    goto \&_eval_keyword__items_array_schemas;
  }

  $state->{_last_items_index} //= -1;
  goto \&_eval_keyword__items_schema;
}

sub _eval_keyword_additionalItems ($data, $schema, $state) {
  return 1 if not exists $state->{_last_items_index};
  goto \&_eval_keyword__items_schema;
}

# prefixItems (draft 2020-12), array-based items (all drafts)
sub _eval_keyword__items_array_schemas ($data, $schema, $state) {
  abort($state, '%s array is empty', $state->{keyword}) if not $schema->{$state->{keyword}}->@*;
  return 1 if not is_type('array', $data);

  my $valid = 1;

  foreach my $idx (0..$data->$#*) {
    last if $idx > $schema->{$state->{keyword}}->$#*;
    $state->{_last_items_index} = $idx;

    if (is_type('boolean', $schema->{$state->{keyword}}[$idx])) {
      next if $schema->{$state->{keyword}}[$idx];
      $valid = E({ %$state, data_path => $state->{data_path}.'/'.$idx,
        _schema_path_suffix => $idx }, 'item not permitted');
    }
    else {
      next if _eval_subschema($data->[$idx], $schema->{$state->{keyword}}[$idx],
        +{ %$state, data_path => $state->{data_path}.'/'.$idx,
          schema_path => $state->{schema_path}.'/'.$state->{keyword}.'/'.$idx });
    }

    $valid = 0;
    last if $state->{short_circuit} and not exists $schema->{
        $state->{keyword} eq 'prefixItems' ? 'items'
      : $state->{keyword} eq 'items' ? 'additionalItems' : die
    };
  }

  return E($state, 'not all items are valid') if not $valid;
  return 1;
}

# schema-based items (all drafts), and additionalItems (drafts 4,6,7,2019-09)
sub _eval_keyword__items_schema ($data, $schema, $state) {
  return 1 if not is_type('array', $data);
  return 1 if $state->{_last_items_index} == $data->$#*;

  my $valid = 1;
  foreach my $idx ($state->{_last_items_index}+1 .. $data->$#*) {
    if (is_type('boolean', $schema->{$state->{keyword}})
        and ($state->{keyword} eq 'additionalItems')) {
      next if $schema->{$state->{keyword}};
      $valid = E({ %$state, data_path => $state->{data_path}.'/'.$idx },
        '%sitem not permitted',
        exists $schema->{prefixItems} || $state->{keyword} eq 'additionalItems' ? 'additional ' : '');
    }
    else {
      next if _eval_subschema($data->[$idx], $schema->{$state->{keyword}},
        +{ %$state, data_path => $state->{data_path}.'/'.$idx,
          schema_path => $state->{schema_path}.'/'.$state->{keyword} });
      $valid = 0;
    }

    last if $state->{short_circuit};
  }

  $state->{_last_items_index} = $data->$#*;

  return E($state, 'subschema is not valid against all %sitems',
      exists $schema->{prefixItems} || $state->{keyword} eq 'additionalItems' ? 'additional ' : '')
    if not $valid;
  return 1;
}

sub _eval_keyword_contains ($data, $schema, $state) {
  return 1 if not is_type('array', $data);

  $state->{_num_contains} = 0;
  my @errors;
  foreach my $idx (0..$data->$#*) {
    if (_eval_subschema($data->[$idx], $schema->{contains},
        +{ %$state, errors => \@errors,
          data_path => $state->{data_path}.'/'.$idx,
          schema_path => $state->{schema_path}.'/contains' })) {
      ++$state->{_num_contains};

      last if $state->{short_circuit}
        and (not exists $schema->{maxContains} or $state->{_num_contains} > $schema->{maxContains})
        and ($state->{_num_contains} >= ($schema->{minContains}//1));
    }
  }

  # note: no items contained is only valid when minContains is explicitly 0
  if (not $state->{_num_contains} and (($schema->{minContains}//1) > 0
      or $state->{spec_version} and $state->{spec_version} eq 'draft7')) {
    push $state->{errors}->@*, @errors;
    return E($state, 'subschema is not valid against any item');
  }

  return 1;
}

sub _eval_keyword_properties ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'object');
  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys $schema->{properties}->%*) {
    next if not exists $data->{$property};

    if (is_type('boolean', $schema->{properties}{$property})) {
      next if $schema->{properties}{$property};
      $valid = E({ %$state, data_path => jsonp($state->{data_path}, $property),
        _schema_path_suffix => $property }, 'property not permitted');
    }
    else {
      next if _eval_subschema($data->{$property}, $schema->{properties}{$property},
        +{ %$state,
          data_path => jsonp($state->{data_path}, $property),
          schema_path => jsonp($state->{schema_path}, 'properties', $property) });

      $valid = 0;
    }
    last if $state->{short_circuit};
  }

  return E($state, 'not all properties are valid') if not $valid;
  return 1;
}

sub _eval_keyword_patternProperties ($data, $schema, $state) {
  assert_keyword_type($state, $schema, 'object');

  foreach my $property (sort keys $schema->{patternProperties}->%*) {
    assert_pattern({ %$state, _schema_path_suffix => $property }, $property);
  }

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property_pattern (sort keys $schema->{patternProperties}->%*) {
    foreach my $property (sort grep m/$property_pattern/, keys %$data) {
      if (is_type('boolean', $schema->{patternProperties}{$property_pattern})) {
        next if $schema->{patternProperties}{$property_pattern};
        $valid = E({ %$state, data_path => jsonp($state->{data_path}, $property),
          _schema_path_suffix => $property_pattern }, 'property not permitted');
      }
      else {
        next if _eval_subschema($data->{$property}, $schema->{patternProperties}{$property_pattern},
          +{ %$state,
            data_path => jsonp($state->{data_path}, $property),
            schema_path => jsonp($state->{schema_path}, 'patternProperties', $property_pattern) });

        $valid = 0;
      }
      last if $state->{short_circuit};
    }
  }

  return E($state, 'not all properties are valid') if not $valid;
  return 1;
}

sub _eval_keyword_additionalProperties ($data, $schema, $state) {
  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys %$data) {
    next if exists $schema->{properties} and exists $schema->{properties}{$property};
    next if exists $schema->{patternProperties}
      and any { $property =~ /$_/ } keys $schema->{patternProperties}->%*;

    if (is_type('boolean', $schema->{additionalProperties})) {
      next if $schema->{additionalProperties};

      $valid = E({ %$state, data_path => jsonp($state->{data_path}, $property) },
        'additional property not permitted');
    }
    else {
      next if _eval_subschema($data->{$property}, $schema->{additionalProperties},
        +{ %$state,
          data_path => jsonp($state->{data_path}, $property),
          schema_path => $state->{schema_path}.'/additionalProperties' });

      $valid = 0;
    }
    last if $state->{short_circuit};
  }

  return E($state, 'not all additional properties are valid') if not $valid;
  return 1;
}

sub _eval_keyword_propertyNames ($data, $schema, $state) {
  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys %$data) {
    next if _eval_subschema($property, $schema->{propertyNames},
      +{ %$state,
        data_path => jsonp($state->{data_path}, $property),
        schema_path => $state->{schema_path}.'/propertyNames' });

    $valid = 0;
    last if $state->{short_circuit};
  }

  return E($state, 'not all property names are valid') if not $valid;
  return 1;
}

sub _eval_keyword_unevaluatedItems ($data, $schema, $state) {
  abort($state, 'keyword not yet supported');
}

sub _eval_keyword_unevaluatedProperties ($data, $schema, $state) {
  abort($state, 'keyword not yet supported');
}

# UTILITIES

sub is_type ($type, $value) {
  if ($type eq 'null') {
    return !(defined $value);
  }
  if ($type eq 'boolean') {
    return is_bool($value);
  }
  if ($type eq 'object') {
    return is_plain_hashref($value);
  }
  if ($type eq 'array') {
    return is_plain_arrayref($value);
  }

  if ($type eq 'string' or $type eq 'number' or $type eq 'integer') {
    return 0 if not defined $value;
    my $flags = B::svref_2object(\$value)->FLAGS;

    if ($type eq 'string') {
      return !is_ref($value) && $flags & B::SVf_POK && !($flags & (B::SVf_IOK | B::SVf_NOK));
    }

    if ($type eq 'number') {
      return ref($value) =~ /^Math::Big(?:Int|Float)$/
        || !($flags & B::SVf_POK) && ($flags & (B::SVf_IOK | B::SVf_NOK));
    }

    if ($type eq 'integer') {
      return ref($value) =~ /^Math::Big(?:Int|Float)$/ && $value->is_int
        || !($flags & B::SVf_POK) && ($flags & (B::SVf_IOK | B::SVf_NOK)) && int($value) == $value;
    }
  }

  if ($type =~ /^reference to (.+)$/) {
    return !blessed($value) && ref($value) eq $1;
  }

  return ref($value) eq $type;
}

sub get_type ($value) {
  return 'null' if not defined $value;
  return 'object' if is_plain_hashref($value);
  return 'array' if is_plain_arrayref($value);
  return 'boolean' if is_bool($value);

  return ref($value) =~ /^Math::Big(?:Int|Float)$/ ? ($value->is_int ? 'integer' : 'number')
      : (blessed($value) ? '' : 'reference to ').ref($value)
    if is_ref($value);

  my $flags = B::svref_2object(\$value)->FLAGS;
  return 'string' if $flags & B::SVf_POK && !($flags & (B::SVf_IOK | B::SVf_NOK));
  return int($value) == $value ? 'integer' : 'number'
    if !($flags & B::SVf_POK) && ($flags & (B::SVf_IOK | B::SVf_NOK));

  croak sprintf('ambiguous type for %s',
    JSON::MaybeXS->new(allow_nonref => 1, canonical => 1, utf8 => 0, allow_bignum => 1, allow_blessed => 1)->encode($value));
}

# compares two arbitrary data payloads for equality, as per
# https://json-schema.org/draft/2020-12/json-schema-core.html#rfc.section.4.2.2
# if provided with a state hashref, any differences are recorded within
sub is_equal ($x, $y, $state = {}) {
  $state->{path} //= '';

  my @types = map get_type($_), $x, $y;

  if ($SCALARREF_BOOLEANS) {
    ($x, $types[0]) = (0+!!$$x, 'boolean') if $types[0] eq 'reference to SCALAR';
    ($y, $types[1]) = (0+!!$$y, 'boolean') if $types[1] eq 'reference to SCALAR';
  }

  return 0 if $types[0] ne $types[1];
  return 1 if $types[0] eq 'null';
  return $x eq $y if $types[0] eq 'string';
  return $x == $y if grep $types[0] eq $_, qw(boolean number integer);

  my $path = $state->{path};
  if ($types[0] eq 'object') {
    return 0 if keys %$x != keys %$y;
    return 0 if not is_equal([ sort keys %$x ], [ sort keys %$y ]);
    foreach my $property (sort keys %$x) {
      $state->{path} = jsonp($path, $property);
      return 0 if not is_equal($x->{$property}, $y->{$property}, $state);
    }
    return 1;
  }

  if ($types[0] eq 'array') {
    return 0 if @$x != @$y;
    foreach my $idx (0..$x->$#*) {
      $state->{path} = $path.'/'.$idx;
      return 0 if not is_equal($x->[$idx], $y->[$idx], $state);
    }
    return 1;
  }

  return 0; # should never get here
}

# checks array elements for uniqueness. short-circuits on first pair of matching elements
# if second arrayref is provided, it is populated with the indices of identical items
sub is_elements_unique ($array, $equal_indices = undef) {
  foreach my $idx0 (0..$array->$#*-1) {
    foreach my $idx1 ($idx0+1..$array->$#*) {
      if (is_equal($array->[$idx0], $array->[$idx1])) {
        push @$equal_indices, $idx0, $idx1 if defined $equal_indices;
        return 0;
      }
    }
  }
  return 1;
}

# shorthand for creating and appending json pointers
sub jsonp {
  return join('/', shift, map s/~/~0/gr =~ s!/!~1!gr, map +(is_plain_arrayref($_) ? @$_ : $_), grep defined, @_);
}

# shorthand for finding the canonical uri of the present schema location
sub canonical_uri ($state, @extra_path) {
  splice(@extra_path, -1, 1, $extra_path[-1]->@*) if @extra_path and is_plain_arrayref($extra_path[-1]);
  my $uri = $state->{initial_schema_uri}->clone;
  $uri->fragment(($uri->fragment//'').jsonp($state->{schema_path}, @extra_path));
  $uri->fragment(undef) if not length($uri->fragment);
  $uri;
}

# shorthand for creating error objects
sub E ($state, $error_string, @args) {
  # sometimes the keyword shouldn't be at the very end of the schema path
  my $uri = canonical_uri($state, $state->{keyword}, $state->{_schema_path_suffix});

  my $keyword_location = $state->{traversed_schema_path}
    .jsonp($state->{schema_path}, $state->{keyword}, delete $state->{_schema_path_suffix});

  undef $uri if $uri eq '' and $keyword_location eq ''
    or ($uri->fragment//'') eq $keyword_location and $uri->clone->fragment(undef) eq '';

  push $state->{errors}->@*, {
    instanceLocation => $state->{data_path},
    keywordLocation => $keyword_location,
    defined $uri ? ( absoluteKeywordLocation => $uri->to_string) : (),
    error => @args ? sprintf($error_string, @args) : $error_string,
  };

  return 0;
}

# creates an error object, but also aborts evaluation immediately
# only this error is returned, because other errors on the stack might not actually be "real"
# errors (consider if we were in the middle of evaluating a "not" or "if")
sub abort ($state, $error_string, @args) {
  E($state, $error_string, @args);
  die pop $state->{errors}->@*;
}

# one common usecase of abort()
sub assert_keyword_type ($state, $schema, $type) {
  my $value = $schema->{$state->{keyword}};
  $value = is_plain_hashref($value) ? $value->{$state->{_schema_path_suffix}}
      : is_plain_arrayref($value) ? $value->[$state->{_schema_path_suffix}]
      : die 'unknown type'
    if exists $state->{_schema_path_suffix};
  return 1 if is_type($type, $value);
  abort($state, '%s value is not a%s %s', $state->{keyword}, ($type =~ /^[aeiou]/ ? 'n' : ''), $type);
}

sub assert_pattern ($state, $pattern) {
  try {
    local $SIG{__WARN__} = sub { die @_ };
    qr/$pattern/;
  }
  catch ($e) { abort($state, $e); };
  return 1;
}

sub assert_uri_reference ($state, $schema) {
  my $ref = $schema->{$state->{keyword}};

  abort($state, '%s value is not a valid URI reference', $state->{keyword})
    # see also uri-reference format sub
    if fc(Mojo::URL->new($ref)->to_unsafe_string) ne fc($ref)
      or $ref =~ /[^[:ascii:]]/
      or $ref =~ /#/
        and $ref !~ m{#$}                          # empty fragment
        and $ref !~ m{#[A-Za-z][A-Za-z0-9_:.-]*$}  # plain-name fragment
        and $ref !~ m{#/(?:[^~]|~[01])*$};         # json pointer fragment

  return 1;
}

sub assert_uri ($state, $schema, $override = undef) {
  my $string = $override // $schema->{$state->{keyword}};
  my $uri = Mojo::URL->new($string);

  abort($state, '"%s" is not a valid URI', $string)
    # see also uri format sub
    if fc($uri->to_unsafe_string) ne fc($string)
      or $string =~ /[^[:ascii:]]/
      or not $uri->is_abs
      or $string =~ /#/
        and $string !~ m{#$}                          # empty fragment
        and $string !~ m{#[A-Za-z][A-Za-z0-9_:.-]*$}  # plain-name fragment
        and $string !~ m{#/(?:[^~]|~[01])*$};         # json pointer fragment

  return 1;
}

sub assert_non_negative_integer ($schema, $state) {
  assert_keyword_type($state, $schema, 'integer');
  abort($state, '%s value is not a non-negative integer', $state->{keyword})
    if $schema->{$state->{keyword}} < 0;
  return 1;
}

sub assert_array_schemas ($schema, $state) {
  assert_keyword_type($state, $schema, 'array');
  abort($state, '%s array is empty', $state->{keyword}) if not $schema->{$state->{keyword}}->@*;
  return 1;
}

sub sprintf_num ($value) {
  # use original value as stored in the NV, without losing precision
  ref($value) =~ /^Math::Big(?:Int|Float)$/ ? $value->bstr : sprintf('%s', $value);
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords schema subschema metaschema validator evaluator

=head1 NAME

JSON::Schema::Tiny - Validate data against a schema, minimally

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  my $data = { hello => 1 };
  my $schema = {
    type => "object",
    properties => { hello => { type => "integer" } },
  };

  # functional interface:
  use JSON::Schema::Tiny qw(evaluate);
  my $result = evaluate($data, $schema); # { valid => true }

  # object-oriented interface:
  use JSON::Schema::Tiny;
  my $js = JSON::Schema::Tiny->new;
  my $result = $js->evaluate($data, $schema); # { valid => true }

=head1 DESCRIPTION

This module aims to be a slimmed-down L<JSON Schema|https://json-schema.org/> evaluator and
validator, supporting the most popular keywords.
(See L</UNSUPPORTED JSON-SCHEMA FEATURES> below for exclusions.)

=head1 FUNCTIONS

=for Pod::Coverage is_type get_type is_equal is_elements_unique jsonp canonical_uri E abort
assert_keyword_type assert_pattern assert_uri assert_non_negative_integer assert_array_schemas
new assert_uri_reference sprintf_num

=head2 evaluate

  my $result = evaluate($data, $schema);

Evaluates the provided instance data against the known schema document.

The data is in the form of an unblessed nested Perl data structure representing any type that JSON
allows: null, boolean, string, number, object, array. (See L</TYPES> below.)

The schema must represent a valid JSON Schema in the form of a Perl data structure, such as what is
returned from a JSON decode operation.

With default configuration settings, the return value is a hashref indicating the validation success
or failure, plus (when validation failed), an arrayref of error strings in standard JSON Schema
format. For example:

running:

  $result = evaluate(1, { type => 'number' });

C<$result> is:

  { valid => true }

running:

  $result = evaluate(1, { type => 'number', multipleOf => 2 });

C<$result> is:

  {
    valid => false,
    errors => [
      {
        instanceLocation => '',
        keywordLocation => '/multipleOf',
        error => 'value is not a multiple of 2',
      },
    ],
  }

When L</C<$BOOLEAN_RESULT>> is true, the return value is a boolean (indicating evaluation success or
failure).

=head1 OPTIONS

All options are available as package-scoped global variables. Use L<local|perlfunc/local> to
configure them for a local scope. They may also be set via the constructor, as lower-cased values in
a hash, e.g.: C<< JSON::Schema::Tiny->new(boolean_result => 1, max_traversal_depth => 10); >>

=head2 C<$BOOLEAN_RESULT>

When true, L</evaluate> will return a true or false result only, with no error strings. This enables
short-circuit mode internally as this cannot effect results except get there faster. Defaults to false.

=head2 C<$SHORT_CIRCUIT>

When true, L</evaluate> will return from evaluating each subschema as soon as a true or false result
can be determined. When C<$BOOLEAN_RESULT> is false, an incomplete list of errors will be returned.
Defaults to false.

=head2 C<$MAX_TRAVERSAL_DEPTH>

The maximum number of levels deep a schema traversal may go, before evaluation is halted. This is to
protect against accidental infinite recursion, such as from two subschemas that each reference each
other, or badly-written schemas that could be optimized. Defaults to 50.

=head2 C<$SCALARREF_BOOLEANS>

When true, any type that is expected to be a boolean B<in the instance data> may also be expressed as
the scalar references C<\0> or C<\1> (which are serialized as booleans by JSON backends).
Defaults to false.

=head2 C<$SPECIFICATION_VERSION>

When set, the version of the draft specification is locked to one particular value, and use of
keywords inconsistent with that specification version will result in an error. Will be set
internally automatically with the use of the C<$schema> keyword. When not set, all keywords will be
honoured (when otherwise supported).

Supported values for this option, and the corresponding values for the C<$schema> keyword, are:

=over 4

=item *

L<C<draft2020-12>|https://json-schema.org/specification-links.html#2020-12>, corresponding to metaschema C<https://json-schema.org/draft/2020-12/schema>

=item *

L<C<draft2019-09>|https://json-schema.org/specification-links.html#2019-09-formerly-known-as-draft-8>, corresponding to metaschema C<https://json-schema.org/draft/2019-09/schema>.

=item *

L<C<draft7>|https://json-schema.org/specification-links.html#draft-7>, corresponding to metaschema C<http://json-schema.org/draft-07/schema#>

=back

Defaults to undef.

=head1 UNSUPPORTED JSON-SCHEMA FEATURES

Unlike L<JSON::Schema::Modern>, this is not a complete implementation of the JSON Schema
specification. Some features and keywords are left unsupported in order to keep the code small and
the execution fast. These features are not available:

=over 4

=item *

any output format other than C<flag> (when C<$BOOLEAN_RESULT> is true) or C<basic> (when it is false)

=item *

L<annotations|https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.7.7> in successful evaluation results

=item *

use of C<$ref> other than to locations in the local schema in json-pointer format (e.g. C<#/path/to/property>). This means that references to external documents, either those available locally or on the network, are not permitted.

=back

In addition, these keywords are implemented only partially or not at all (their presence in a schema
will be ignored or possibly result in an error):

=over 4

=item *

C<$schema> - only accepted if set to one of the specification metaschema URIs (see L<$SPECIFICATION_VERSION> for supported values)

=item *

C<$id>

=item *

C<$anchor>

=item *

C<$recursiveAnchor> and C<$recursiveRef> (draft2019-09), and C<$dynamicAnchor> and C<$dynamicRef> (draft2020-12 and thereafter)

=item *

C<$vocabulary>

=item *

C<unevaluatedItems> and C<unevaluatedProperties> (which require annotation support)

=item *

C<format> (does not cause an error when used)

=back

For a more full-featured implementation of the JSON Schema specification, see
L<JSON::Schema::Modern>.

=head1 LIMITATIONS

=head2 Types

Perl is a more loosely-typed language than JSON. This module delves into a value's internal
representation in an attempt to derive the true "intended" type of the value. However, if a value is
used in another context (for example, a numeric value is concatenated into a string, or a numeric
string is used in an arithmetic operation), additional flags can be added onto the variable causing
it to resemble the other type. This should not be an issue if data validation is occurring
immediately after decoding a JSON payload.

For more information, see L<Cpanel::JSON::XS/MAPPING>.

=head1 SECURITY CONSIDERATIONS

The C<pattern> and C<patternProperties> keywords evaluate regular expressions from the schema.
No effort is taken (at this time) to sanitize the regular expressions for embedded code or
potentially pathological constructs that may pose a security risk, either via denial of service
or by allowing exposure to the internals of your application. B<DO NOT USE SCHEMAS FROM UNTRUSTED
SOURCES.>

=head1 SEE ALSO

=over 4

=item *

L<JSON::Schema::Modern>: a more specification-compliant JSON Schema evaluator

=item *

L<Test::JSON::Schema::Acceptance>: contains the official JSON Schema test suite

=item *

L<https://json-schema.org>

=item *

L<Understanding JSON Schema|https://json-schema.org/understanding-json-schema>: tutorial-focused documentation

=back

=for stopwords OpenAPI

You can also find me on the L<JSON Schema Slack server|https://json-schema.slack.com> and L<OpenAPI Slack
server|https://open-api.slack.com>, which are also great resources for finding help.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Tiny/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Matt S Trout

Matt S Trout <mst@shadowcat.co.uk>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
