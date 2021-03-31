use strict;
use warnings;
package JSON::Schema::Tiny; # git description: a043fb2
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Validate data against a schema, minimally
# KEYWORDS: JSON Schema data validation structure specification tiny

our $VERSION = '0.001';

use 5.016;  # for the unicode_strings feature
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use B;
use Ref::Util 0.100 qw(is_plain_arrayref is_plain_hashref is_ref);
use Mojo::URL;
use Mojo::JSON::Pointer;
use Carp 'croak';
use Storable 'dclone';
use JSON::MaybeXS 1.004001 'is_bool';
use Feature::Compat::Try;
use JSON::PP ();
use List::Util 'any';
use namespace::clean;
use Exporter 5.57 'import';

our @EXPORT_OK = qw(evaluate);

our $BOOLEAN_RESULT = 0;
our $SHORT_CIRCUIT = 0;
our $MAX_TRAVERSAL_DEPTH = 50;

sub evaluate {
  my ($data, $schema) = @_;

  croak 'evaluate called in void context' if not defined wantarray;

  my $state = {
    depth => 0,
    data_path => '',
    traversed_schema_path => '',            # the accumulated path up to the last $ref traversal
    canonical_schema_uri => Mojo::URL->new, # the canonical path of the last traversed $ref
    schema_path => '',                      # the rest of the path, since the last traversed $ref
    errors => [],
    seen => {},
    short_circuit => $BOOLEAN_RESULT || $SHORT_CIRCUIT,
    root_schema => $schema,
  };

  my $result;
  try {
    $result = _eval($data, $schema, $state)
  }
  catch ($e) {
    if (is_plain_hashref($e)) {
      push @{$state->{errors}}, $e;
    }
    else {
      E($state, 'EXCEPTION: '.$e);
    }

    $result = 0;
  }

  return $BOOLEAN_RESULT ? $result : +{
    valid => $result ? JSON::PP::true : JSON::PP::false,
    $result ? () : (errors => $state->{errors}),
  };
}

######## NO PUBLIC INTERFACES FOLLOW THIS POINT ########

sub _eval {
  my ($data, $schema, $state) = @_;

  $state = { %$state };     # changes to $state should only affect subschemas, not parents
  delete $state->{keyword};

  abort($state, 'EXCEPTION: maximum evaluation depth exceeded')
    if $state->{depth}++ > $MAX_TRAVERSAL_DEPTH;

  # find all schema locations in effect at this data path + canonical_uri combination
  # if any of them are absolute prefix of this schema location, we are in a loop.
  my $canonical_uri = canonical_schema_uri($state);
  my $schema_location = $state->{traversed_schema_path}.$state->{schema_path};
  abort($state, 'EXCEPTION: infinite loop detected (same location evaluated twice)')
    if grep substr($schema_location, 0, length) eq $_,
      keys %{$state->{seen}{$state->{data_path}}{$canonical_uri}};
  $state->{seen}{$state->{data_path}}{$canonical_uri}{$schema_location}++;

  my $schema_type = get_type($schema);
  return $schema || E($state, 'subschema is false') if $schema_type eq 'boolean';
  abort($state, 'invalid schema type: %s', $schema_type) if $schema_type ne 'object';

  my $result = 1;

  foreach my $keyword (
    # CORE KEYWORDS
    qw($schema $ref $defs),
    # VALIDATOR KEYWORDS
    qw(type enum const
      multipleOf maximum exclusiveMaximum minimum exclusiveMinimum
      maxLength minLength pattern
      maxItems minItems uniqueItems
      maxProperties minProperties required dependentRequired),
    # APPLICATOR KEYWORDS
    qw(allOf anyOf oneOf not if dependentSchemas
      items contains
      properties patternProperties additionalProperties propertyNames),
  ) {
    next if not exists $schema->{$keyword};

    my $sub = __PACKAGE__->can('_eval_keyword_'.($keyword =~ s/^\$//r));
    $result = 0 if not $sub->($data, $schema, +{ %$state, keyword => $keyword });

    last if not $result and $state->{short_circuit};
  }

  # UNSUPPORTED KEYWORDS
  foreach my $keyword (
    # CORE KEYWORDS
    qw($id $anchor $recursiveAnchor $recursiveRef $vocabulary $dynamicAnchor $dynamicRef definitions),
    # APPLICATOR KEYWORDS
    qw(dependencies unevaluatedItems unevaluatedProperties),
  ) {
    next if not exists $schema->{$keyword};
    abort({ %$state, keyword => $keyword }, 'keyword not supported');
  }

  return $result;
}

# KEYWORD IMPLEMENTATIONS

sub _eval_keyword_schema {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'string');

  return abort($state, '$schema can only appear at the schema resource root')
    if length($state->{schema_path});

  abort($state, 'custom $schema references are not supported')
    if $schema->{'$schema'} ne 'https://json-schema.org/draft/2019-09/schema';
}

sub _eval_keyword_ref {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'string');

  abort($state, 'only same-document JSON pointers are supported in $ref')
    if $schema->{'$ref'} !~ m{^#(/(?:[^~]|~[01])*|)$};

  my $uri = Mojo::URL->new($schema->{'$ref'});
  my $fragment = $uri->fragment;

  my $subschema = Mojo::JSON::Pointer->new($state->{root_schema})->get($fragment);
  # thsi is not a runtime exception because all $refs must be local
  abort($state, 'EXCEPTION: unable to find resource %s', $uri) if not defined $subschema;

  return _eval($data, $subschema,
    +{ %$state,
      traversed_schema_path => $state->{traversed_schema_path}.$state->{schema_path}.'/$ref',
      canonical_schema_uri => $uri,
      schema_path => '',
    });
}

sub _eval_keyword_defs {
  my ($data, $schema, $state) = @_;
  return if not assert_keyword_type($state, $schema, 'object');
  return 1;
}

sub _eval_keyword_type {
  my ($data, $schema, $state) = @_;

  if (is_plain_arrayref($schema->{type})) {
    foreach my $type (@{$schema->{type}}) {
      abort($state, 'unrecognized type "%s"', $type//'<null>')
        if not any { ($type//'') eq $_ } qw(null boolean object array string number integer);
    }
    abort($state, '"type" values are not unique') if not is_elements_unique($schema->{type});

    foreach my $type (@{$schema->{type}}) {
      return 1 if is_type($type, $data);
    }
    return E($state, 'wrong type (expected one of %s)', join(', ', @{$schema->{type}}));
  }
  else {
    abort($state, 'unrecognized type "%s"', $schema->{type}//'<null>')
      if not any { ($schema->{type}//'') eq $_ } qw(null boolean object array string number integer);
    return 1 if is_type($schema->{type}, $data);
    return E($state, 'wrong type (expected %s)', $schema->{type});
  }
}

sub _eval_keyword_enum {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'array');
  abort($state, '"enum" values are not unique') if not is_elements_unique($schema->{enum});

  my @s; my $idx = 0;
  return 1 if any { is_equal($data, $_, $s[$idx++] = {}) } @{$schema->{enum}};

  return E($state, 'value does not match'
    .(!(grep $_->{path}, @s) ? ''
      : ' (differences start '.join(', ', map 'from #'.$_.' at "'.$s[$_]->{path}.'"', 0..$#s).')'));
}

sub _eval_keyword_const {
  my ($data, $schema, $state) = @_;

  return 1 if is_equal($data, $schema->{const}, my $s = {});
  return E($state, 'value does not match'
    .($s->{path} ? ' (differences start at "'.$s->{path}.'")' : ''));
}

sub _eval_keyword_multipleOf {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'number');
  abort($state, 'multipleOf value is not a positive number') if $schema->{multipleOf} <= 0;

  return 1 if not is_type('number', $data);

  my $quotient = $data / $schema->{multipleOf};
  return 1 if int($quotient) == $quotient and $quotient !~ /^-?Inf$/i;
  return E($state, 'value is not a multiple of %g', $schema->{multipleOf});
}

sub _eval_keyword_maximum {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data <= $schema->{maximum};
  return E($state, 'value is larger than %g', $schema->{maximum});
}

sub _eval_keyword_exclusiveMaximum {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data < $schema->{exclusiveMaximum};
  return E($state, 'value is equal to or larger than %g', $schema->{exclusiveMaximum});
}

sub _eval_keyword_minimum {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data >= $schema->{minimum};
  return E($state, 'value is smaller than %g', $schema->{minimum});
}

sub _eval_keyword_exclusiveMinimum {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'number');
  return 1 if not is_type('number', $data);
  return 1 if $data > $schema->{exclusiveMinimum};
  return E($state, 'value is equal to or smaller than %g', $schema->{exclusiveMinimum});
}

sub _eval_keyword_maxLength {
  my ($data, $schema, $state) = @_;

  return if not assert_non_negative_integer($schema, $state);

  return 1 if not is_type('string', $data);
  return 1 if length($data) <= $schema->{maxLength};
  return E($state, 'length is greater than %d', $schema->{maxLength});
}

sub _eval_keyword_minLength {
  my ($data, $schema, $state) = @_;

  return if not assert_non_negative_integer($schema, $state);

  return 1 if not is_type('string', $data);
  return 1 if length($data) >= $schema->{minLength};
  return E($state, 'length is less than %d', $schema->{minLength});
}

sub _eval_keyword_pattern {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'string');
  return if not assert_pattern($state, $schema->{pattern});

  return 1 if not is_type('string', $data);
  return 1 if $data =~ m/$schema->{pattern}/;
  return E($state, 'pattern does not match');
}

sub _eval_keyword_maxItems {
  my ($data, $schema, $state) = @_;

  return if not assert_non_negative_integer($schema, $state);

  return 1 if not is_type('array', $data);
  return 1 if @$data <= $schema->{maxItems};
  return E($state, 'more than %d item%s', $schema->{maxItems}, $schema->{maxItems} > 1 ? 's' : '');
}

sub _eval_keyword_minItems {
  my ($data, $schema, $state) = @_;

  return if not assert_non_negative_integer($schema, $state);

  return 1 if not is_type('array', $data);
  return 1 if @$data >= $schema->{minItems};
  return E($state, 'fewer than %d item%s', $schema->{minItems}, $schema->{minItems} > 1 ? 's' : '');
}

sub _eval_keyword_uniqueItems {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'boolean');
  return 1 if not is_type('array', $data);
  return 1 if not $schema->{uniqueItems};
  return 1 if is_elements_unique($data, my $equal_indices = []);
  return E($state, 'items at indices %d and %d are not unique', @$equal_indices);
}

sub _eval_keyword_maxProperties {
  my ($data, $schema, $state) = @_;

  return if not assert_non_negative_integer($schema, $state);

  return 1 if not is_type('object', $data);
  return 1 if keys %$data <= $schema->{maxProperties};
  return E($state, 'more than %d propert%s', $schema->{maxProperties},
    $schema->{maxProperties} > 1 ? 'ies' : 'y');
}

sub _eval_keyword_minProperties {
  my ($data, $schema, $state) = @_;

  return if not assert_non_negative_integer($schema, $state);

  return 1 if not is_type('object', $data);
  return 1 if keys %$data >= $schema->{minProperties};
  return E($state, 'fewer than %d propert%s', $schema->{minProperties},
    $schema->{minProperties} > 1 ? 'ies' : 'y');
}

sub _eval_keyword_required {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'array');
  abort($state, '"required" element is not a string')
    if any { !is_type('string', $_) } @{$schema->{required}};
  abort($state, '"required" values are not unique') if not is_elements_unique($schema->{required});

  return 1 if not is_type('object', $data);

  my @missing = grep !exists $data->{$_}, @{$schema->{required}};
  return 1 if not @missing;
  return E($state, 'missing propert%s: %s', @missing > 1 ? 'ies' : 'y', join(', ', @missing));
}

sub _eval_keyword_dependentRequired {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'object');
  abort($state, '"%s" property is not an array', $state->{keyword})
    if any { !is_type('array', $schema->{$state->{keyword}}{$_}) }
      keys %{$schema->{$state->{keyword}}};
  abort($state, '"%s" property element is not a string', $state->{keyword})
    if any { !is_type('string', $_) } map @$_, values %{$schema->{$state->{keyword}}};
  abort($state, '"%s" property elements are not unique', $state->{keyword})
    if any { !is_elements_unique($schema->{$state->{keyword}}{$_}) }
      keys %{$schema->{$state->{keyword}}};

  return 1 if not is_type('object', $data);

  my @missing = grep
    +(exists $data->{$_} && any { !exists $data->{$_} } @{ $schema->{$state->{keyword}}{$_} }),
    keys %{$schema->{$state->{keyword}}};

  return 1 if not @missing;
  return E($state, 'missing propert%s: %s', @missing > 1 ? 'ies' : 'y', join(', ', sort @missing));
}

sub _eval_keyword_allOf {
  my ($data, $schema, $state) = @_;

  return if not assert_array_schemas($schema, $state);

  my @invalid;
  foreach my $idx (0 .. $#{$schema->{allOf}}) {
    next if _eval($data, $schema->{allOf}[$idx],
      +{ %$state, schema_path => $state->{schema_path}.'/allOf/'.$idx });

    push @invalid, $idx;
    last if $state->{short_circuit};
  }

  return 1 if @invalid == 0;

  my $pl = @invalid > 1;
  return E($state, 'subschema%s %s %s not valid', $pl?'s':'', join(', ', @invalid), $pl?'are':'is');
}

sub _eval_keyword_anyOf {
  my ($data, $schema, $state) = @_;

  return if not assert_array_schemas($schema, $state);

  my $valid = 0;
  my @errors;
  foreach my $idx (0 .. $#{$schema->{anyOf}}) {
    next if not _eval($data, $schema->{anyOf}[$idx],
      +{ %$state, errors => \@errors, schema_path => $state->{schema_path}.'/anyOf/'.$idx });
    ++$valid;
    last if $state->{short_circuit};
  }

  return 1 if $valid;
  push @{$state->{errors}}, @errors;
  return E($state, 'no subschemas are valid');
}

sub _eval_keyword_oneOf {
  my ($data, $schema, $state) = @_;

  return if not assert_array_schemas($schema, $state);

  my (@valid, @errors);
  foreach my $idx (0 .. $#{$schema->{oneOf}}) {
    next if not _eval($data, $schema->{oneOf}[$idx],
      +{ %$state, errors => \@errors, schema_path => $state->{schema_path}.'/oneOf/'.$idx });
    push @valid, $idx;
    last if @valid > 1 and $state->{short_circuit};
  }

  return 1 if @valid == 1;

  if (not @valid) {
    push @{$state->{errors}}, @errors;
    return E($state, 'no subschemas are valid');
  }
  else {
    return E($state, 'multiple subschemas are valid: '.join(', ', @valid));
  }
}

sub _eval_keyword_not {
  my ($data, $schema, $state) = @_;

  return 1 if not _eval($data, $schema->{not},
    +{ %$state, schema_path => $state->{schema_path}.'/not', short_circuit => 1, errors => [] });

  return E($state, 'subschema is valid');
}

sub _eval_keyword_if {
  my ($data, $schema, $state) = @_;

  return 1 if not exists $schema->{then} and not exists $schema->{else};
  my $keyword = _eval($data, $schema->{if},
      +{ %$state, schema_path => $state->{schema_path}.'/if', short_circuit => 1, errors => [] })
    ? 'then' : 'else';

  return 1 if not exists $schema->{$keyword};
  return 1 if _eval($data, $schema->{$keyword},
    +{ %$state, schema_path => $state->{schema_path}.'/'.$keyword });
  return E({ %$state, keyword => $keyword }, 'subschema is not valid');
}

sub _eval_keyword_dependentSchemas {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'object');

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys %{$schema->{$state->{keyword}}}) {
    next if not exists $data->{$property}
      or _eval($data, $schema->{$state->{keyword}}{$property},
        +{ %$state, schema_path => jsonp($state->{schema_path}, $state->{keyword}, $property) });

    $valid = 0;
    last if $state->{short_circuit};
  }

  return E($state, 'not all subschemas are valid') if not $valid;
  return 1;
}

sub _eval_keyword_items {
  my ($data, $schema, $state) = @_;

  # TODO: for draft2020-12, reject the array form of items
  goto \&_eval_keyword_prefixItems if is_plain_arrayref($schema->{items});

  return 1 if not is_type('array', $data);

  my $valid = 1;
  foreach my $idx (0 .. $#{$data}) {
    if (is_type('boolean', $schema->{items})) {
      next if $schema->{items};
      $valid = E({ %$state, data_path => $state->{data_path}.'/'.$idx }, 'item not permitted');
    }
    else {
      next if _eval($data->[$idx], $schema->{items}, +{ %$state,
          data_path => $state->{data_path}.'/'.$idx,
          schema_path => $state->{schema_path}.'/items' });
      $valid = 0;
    }

    last if $state->{short_circuit};
  }

  return E($state, 'subschema is not valid against all items') if not $valid;
  return 1;
}

sub _eval_keyword_prefixItems {
  my ($data, $schema, $state) = @_;

  return if not assert_array_schemas($schema, $state);

  return 1 if not is_type('array', $data);

  my $last_index = -1;
  my $valid = 1;
  foreach my $idx (0 .. $#{$data}) {
    last if $idx > $#{$schema->{$state->{keyword}}};
    $last_index = $idx;

    if (is_type('boolean', $schema->{$state->{keyword}}[$idx])) {
      next if $schema->{$state->{keyword}}[$idx];
      $valid = E({ %$state, data_path => $state->{data_path}.'/'.$idx,
        _schema_path_suffix => $idx }, 'item not permitted');
    }
    else {
      next if _eval($data->[$idx], $schema->{$state->{keyword}}[$idx],
        +{ %$state,
          data_path => $state->{data_path}.'/'.$idx,
          schema_path => $state->{schema_path}.'/'.$state->{keyword}.'/'.$idx });
    }

    $valid = 0;
    last if $state->{short_circuit} and not exists $schema->{additionalItems};
  }

  E($state, 'subschema is not valid against all items') if not $valid;

  return $valid if not exists $schema->{additionalItems} or $last_index == $#{$data};
  $state->{keyword} = 'additionalItems';

  foreach my $idx ($last_index+1 .. $#{$data}) {
    if (is_type('boolean', $schema->{additionalItems})) {
      next if $schema->{additionalItems};
      $valid = E({ %$state, data_path => $state->{data_path}.'/'.$idx },
        'additional item not permitted');
    }
    else {
      next if _eval($data->[$idx], $schema->{additionalItems},
        +{ %$state, data_path => $state->{data_path}.'/'.$idx,
        schema_path => $state->{schema_path}.'/additionalItems' });
      $valid = 0;
    }
    last if $state->{short_circuit};
  }

  return E($state, 'subschema is not valid against all additional items') if not $valid;
  return 1;
}

sub _eval_keyword_contains {
  my ($data, $schema, $state) = @_;

  return if exists $schema->{minContains}
    and not assert_non_negative_integer($schema, { %$state, keyword => 'minContains' });
  return if exists $schema->{maxContains}
    and not assert_non_negative_integer($schema, { %$state, keyword => 'maxContains' });

  return 1 if not is_type('array', $data);

  my $num_valid = 0;
  my @errors;
  foreach my $idx (0 .. $#{$data}) {
    if (_eval($data->[$idx], $schema->{contains},
        +{ %$state, errors => \@errors,
          data_path => $state->{data_path}.'/'.$idx,
          schema_path => $state->{schema_path}.'/contains' })) {
      ++$num_valid;
      last if $state->{short_circuit}
        and (not exists $schema->{maxContains} or $num_valid > $schema->{maxContains})
        and ($num_valid >= ($schema->{minContains} // 1));
    }
  }

  my $valid = 1;
  # note: no items contained is only valid when minContains=0
  if (not $num_valid and ($schema->{minContains} // 1) > 0) {
    $valid = 0;
    push @{$state->{errors}}, @errors;
    E($state, 'subschema is not valid against any item');
    return 0 if $state->{short_circuit};
  }

  if (exists $schema->{maxContains} and $num_valid > $schema->{maxContains}) {
    $valid = E({ %$state, keyword => 'maxContains' }, 'contains too many matching items');
    return 0 if $state->{short_circuit};
  }

  if ($num_valid < ($schema->{minContains} // 1)) {
    $valid = E({ %$state, keyword => 'minContains' }, 'contains too few matching items');
    return 0 if $state->{short_circuit};
  }

  return $valid;
}

sub _eval_keyword_properties {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'object');
  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys %{$schema->{properties}}) {
    next if not exists $data->{$property};

    if (is_type('boolean', $schema->{properties}{$property})) {
      next if $schema->{properties}{$property};
      $valid = E({ %$state, data_path => jsonp($state->{data_path}, $property),
        _schema_path_suffix => $property }, 'property not permitted');
    }
    else {
      next if _eval($data->{$property}, $schema->{properties}{$property},
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

sub _eval_keyword_patternProperties {
  my ($data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'object');

  foreach my $property (sort keys %{$schema->{patternProperties}}) {
    return if not assert_pattern({ %$state, _schema_path_suffix => $property }, $property);
  }

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property_pattern (sort keys %{$schema->{patternProperties}}) {
    foreach my $property (sort grep m/$property_pattern/, keys %$data) {
      if (is_type('boolean', $schema->{patternProperties}{$property_pattern})) {
        next if $schema->{patternProperties}{$property_pattern};
        $valid = E({ %$state, data_path => jsonp($state->{data_path}, $property),
          _schema_path_suffix => $property_pattern }, 'property not permitted');
      }
      else {
        next if _eval($data->{$property}, $schema->{patternProperties}{$property_pattern},
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

sub _eval_keyword_additionalProperties {
  my ($data, $schema, $state) = @_;

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys %$data) {
    next if exists $schema->{properties} and exists $schema->{properties}{$property};
    next if exists $schema->{patternProperties}
      and any { $property =~ /$_/ } keys %{$schema->{patternProperties}};

    if (is_type('boolean', $schema->{additionalProperties})) {
      next if $schema->{additionalProperties};

      $valid = E({ %$state, data_path => jsonp($state->{data_path}, $property) },
        'additional property not permitted');
    }
    else {
      next if _eval($data->{$property}, $schema->{additionalProperties},
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

sub _eval_keyword_propertyNames {
  my ($data, $schema, $state) = @_;

  return 1 if not is_type('object', $data);

  my $valid = 1;
  foreach my $property (sort keys %$data) {
    next if _eval($property, $schema->{propertyNames},
      +{ %$state,
        data_path => jsonp($state->{data_path}, $property),
        schema_path => $state->{schema_path}.'/propertyNames' });

    $valid = 0;
    last if $state->{short_circuit};
  }

  return E($state, 'not all property names are valid') if not $valid;
  return 1;
}


# UTILITIES

sub is_type {
  my ($type, $value) = @_;

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
    return 0 if not defined $value or is_ref($value);
    my $flags = B::svref_2object(\$value)->FLAGS;

    if ($type eq 'string') {
      return $flags & B::SVf_POK && !($flags & (B::SVf_IOK | B::SVf_NOK));
    }

    if ($type eq 'number') {
      return !($flags & B::SVf_POK) && ($flags & (B::SVf_IOK | B::SVf_NOK));
    }

    if ($type eq 'integer') {
      return !($flags & B::SVf_POK) && ($flags & (B::SVf_IOK | B::SVf_NOK))
        && int($value) == $value;
    }
  }

  croak sprintf('unknown type "%s"', $type);
}

# only the core six types are reported (integers are numbers)
# use is_type('integer') to differentiate numbers from integers.
sub get_type {
  my ($value) = @_;

  return 'null' if not defined $value;
  return 'object' if is_plain_hashref($value);
  return 'array' if is_plain_arrayref($value);
  return 'boolean' if is_bool($value);

  croak sprintf('unsupported reference type %s', ref $value) if is_ref($value);

  my $flags = B::svref_2object(\$value)->FLAGS;
  return 'string' if $flags & B::SVf_POK && !($flags & (B::SVf_IOK | B::SVf_NOK));
  return 'number' if !($flags & B::SVf_POK) && ($flags & (B::SVf_IOK | B::SVf_NOK));

  croak sprintf('ambiguous type for %s',
    JSON::MaybeXS->new(allow_nonref => 1, canonical => 1, utf8 => 0)->encode($value));
}

# compares two arbitrary data payloads for equality, as per
# https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.4.2.3
sub is_equal {
  my ($x, $y, $state) = @_;
  $state->{path} //= '';

  my @types = map get_type($_), $x, $y;
  return 0 if $types[0] ne $types[1];
  return 1 if $types[0] eq 'null';
  return $x eq $y if $types[0] eq 'string';
  return $x == $y if $types[0] eq 'boolean' or $types[0] eq 'number';

  my $path = $state->{path};
  if ($types[0] eq 'object') {
    return 0 if keys %$x != keys %$y;
    return 0 if not is_equal([ sort keys %$x ], [ sort keys %$y ]);
    foreach my $property (keys %$x) {
      $state->{path} = jsonp($path, $property);
      return 0 if not is_equal($x->{$property}, $y->{$property}, $state);
    }
    return 1;
  }

  if ($types[0] eq 'array') {
    return 0 if @$x != @$y;
    foreach my $idx (0 .. $#{$x}) {
      $state->{path} = $path.'/'.$idx;
      return 0 if not is_equal($x->[$idx], $y->[$idx], $state);
    }
    return 1;
  }

  return 0; # should never get here
}

# checks array elements for uniqueness. short-circuits on first pair of matching elements
# if second arrayref is provided, it is populated with the indices of identical items
sub is_elements_unique {
  my ($array, $equal_indices) = @_;
  foreach my $idx0 (0 .. $#{$array}-1) {
    foreach my $idx1 ($idx0+1 .. $#{$array}) {
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
  return join('/', shift, map s/~/~0/gr =~ s!/!~1!gr, grep defined, @_);
}

# shorthand for finding the canonical uri of the present schema location
sub canonical_schema_uri {
  my ($state, @extra_path) = @_;

  my $uri = $state->{canonical_schema_uri}->clone;
  $uri->fragment(($uri->fragment//'').jsonp($state->{schema_path}, @extra_path));
  $uri->fragment(undef) if not length($uri->fragment);
  $uri;
}

# shorthand for creating error objects
sub E {
  my ($state, $error_string, @args) = @_;

  # sometimes the keyword shouldn't be at the very end of the schema path
  my $uri = canonical_schema_uri($state, $state->{keyword}, $state->{_schema_path_suffix});

  my $keyword_location = $state->{traversed_schema_path}
    .jsonp($state->{schema_path}, $state->{keyword}, delete $state->{_schema_path_suffix});

  undef $uri if $uri eq '' and $keyword_location eq ''
    or ($uri->fragment // '') eq $keyword_location;

  push @{$state->{errors}}, {
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
sub abort {
  my ($state, $error_string, @args) = @_;
  E($state, $error_string, @args);
  die pop @{$state->{errors}};
}

# one common usecase of abort()
sub assert_keyword_type {
  my ($state, $schema, $type) = @_;
  return 1 if is_type($type, $schema->{$state->{keyword}});
  abort($state, '%s value is not a%s %s', $state->{keyword}, ($type =~ /^[aeiou]/ ? 'n' : ''), $type);
}

sub assert_pattern {
  my ($state, $pattern) = @_;
  try {
    local $SIG{__WARN__} = sub { die @_ };
    qr/$pattern/;
  }
  catch ($e) { abort($state, $e); };
  return 1;
}

sub assert_non_negative_integer {
  my ($schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'integer');
  return E($state, '%s value is not a non-negative integer', $state->{keyword})
    if $schema->{$state->{keyword}} < 0;
  return 1;
}

sub assert_array_schemas {
  my ($schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'array');
  abort($state, '"%s" array is empty') if not @{$schema->{$state->{keyword}}};
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords schema subschema metaschema validator evaluator

=head1 NAME

JSON::Schema::Tiny - Validate data against a schema, minimally

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use JSON::Schema::Tiny qw(evaluate);

  my $data = { hello => 1 };
  my $schema = {
    type => "object",
    properties => { hello => { type => "integer" } },
  };
  my $success = evaluate($data, $schema); # true

=head1 DESCRIPTION

This module aims to be a slimmed-down L<JSON Schema|https://json-schema.org/> evaluator and
validator, supporting the most popular keywords used in the draft 2019-09 version of the
specification. (See L</UNSUPPORTED JSON-SCHEMA FEATURES> below for exclusions.)

=head1 FUNCTIONS

=for Pod::Coverage is_type get_type is_equal is_elements_unique jsonp canonical_schema_uri E abort
assert_keyword_type assert_pattern assert_non_negative_integer assert_array_schemas

=head2 evaluate

  my $result = evaluate($data, $schema);

Evaluates the provided instance data against the known schema document.

The data is in the form of an unblessed nested Perl data structure representing any type that JSON
allows: null, boolean, string, number, object, array. (See L</TYPES> below.)

The schema must represent a JSON Schema that respects the Draft 2019-09 meta-schema at
L<https://json-schema.org/draft/2019-09/schema>, in the form of a Perl data structure, such as what is returned from a JSON decode operation.

With default configuration values, the return value is a hashref indicating the validation success
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
configure them for a local scope.

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

=head1 UNSUPPORTED JSON-SCHEMA FEATURES

Unlike L<JSON::Schema::Draft201909>, this is not a complete implementation of the JSON Schema
specification. Some features and keywords are left unsupported in order to keep the code small and
the execution fast. These features are not available:

=over 4

=item *

any output format other than C<flag> (when C<$BOOLEAN_RESULT> is true) or C<basic> (when it is false)

=item *

annotations in successful evaluation results (see L<Annotations|https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.7.7>).

=item *

use of C<$ref> other than to locations in the local schema in json-pointer format (e.g. C<#/path/to/property>). This means that references to external documents, either those available locally or on the network, are not permitted.

=back

In addition, these keywords are implemented only partially or not at all (their presence in a schema
will result in an error):

=over 4

=item *

C<$schema> - only accepted if set to the draft201909 metaschema URI ("C<https://json-schema.org/draft/2019-09/schema>")

=item *

C<$id>

=item *

C<$anchor>

=item *

C<$recursiveAnchor> and C<$recursiveRef>

=item *

C<$vocabulary>

=item *

C<unevaluatedItems> and C<unevaluatedProperties> (which require annotation support)

=item *

C<format>

=back

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

The C<pattern> and C<patternProperties> keywords, and the C<regex> format validator,
evaluate regular expressions from the schema.
No effort is taken (at this time) to sanitize the regular expressions for embedded code or
potentially pathological constructs that may pose a security risk, either via denial of service
or by allowing exposure to the internals of your application. B<DO NOT USE SCHEMAS FROM UNTRUSTED
SOURCES.>

=head1 SEE ALSO

=over 4

=item *

L<JSON::Schema::Draft201909>: a more spec-compliant JSON Schema evaluator

=item *

L<Test::JSON::Schema::Acceptance>

=item *

L<https://json-schema.org>

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Tiny/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.freenode.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
