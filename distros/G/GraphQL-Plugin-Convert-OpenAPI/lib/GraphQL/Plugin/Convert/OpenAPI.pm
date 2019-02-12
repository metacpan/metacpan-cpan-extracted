package GraphQL::Plugin::Convert::OpenAPI;
use 5.008001;
use strict;
use warnings;
use GraphQL::Schema;
use GraphQL::Debug qw(_debug);
use JSON::Validator::OpenAPI::Mojolicious;
use OpenAPI::Client;

our $VERSION = "0.19";
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

my %TYPEMAP = (
  string => 'String',
  date => 'DateTime',
  integer => 'Int',
  number => 'Float',
  boolean => 'Boolean',
  file => 'String',
);
my %TYPE2SCALAR = map { ($_ => 1) } qw(ID String Int Float Boolean DateTime);
my %METHOD2MUTATION = map { ($_ => 1) } qw(post put patch delete);
my @METHODS = (keys %METHOD2MUTATION, qw(get options head));
my %KIND2SIMPLE = (scalar => 1, enum => 1);

sub _apply_modifier {
  my ($modifier, $typespec) = @_;
  return $typespec if !$modifier;
  return $typespec if $modifier eq 'non_null'
    and ref $typespec eq 'ARRAY'
    and $typespec->[0] eq 'non_null'; # no double-non_null
  [ $modifier, { type => $typespec } ];
}

sub _remove_modifiers {
  my ($typespec) = @_;
  return _remove_modifiers($typespec->{type}) if ref $typespec eq 'HASH';
  return $typespec if ref $typespec ne 'ARRAY';
  _remove_modifiers($typespec->[1]);
}

sub _map_args {
  my ($type, $args, $type2info) = @_;
  DEBUG and _debug('OpenAPI._map_args', $type, $args, $type2info);
  die "Undefined type" if !defined $type;
  return $args if $TYPE2SCALAR{$type} or ($type2info->{$type}||{})->{is_enum};
  if (ref $type eq 'ARRAY') {
    # type modifiers
    my ($mod, $typespec) = @$type;
    return _map_args($typespec->{type}, @_[1..3]) if $mod eq 'non_null';
    die "Invalid typespec @$type" if $mod ne 'list';
    return [ map _map_args($typespec->{type}, $_, @_[2..3]), @$args ];
  }
  my $field2prop = $type2info->{$type}{field2prop};
  my $field2type = $type2info->{$type}{field2type};
  my $field2is_hashpair = $type2info->{$type}{field2is_hashpair};
  +{ map {
    my $value;
    if ($field2is_hashpair->{$_}) {
      my $pairtype = _remove_modifiers($field2type->{$_});
      my $value_type = $type2info->{$pairtype}{field2type}{value};
      my $pairs = $args->{$_};
      my %hashval;
      for my $pair (@$pairs) {
        $hashval{$pair->{key}} = _map_args(
          $value_type, $pair->{value}, $type2info,
        );
      }
      DEBUG and _debug('OpenAPI._map_args(hashpair)', $type, $pairtype, $pairs, $value_type, \%hashval);
      $value = \%hashval;
    } else {
      $value = _map_args(
        $field2type->{$_}, $args->{$_}, $type2info,
      );
    }
    ($field2prop->{$_} => $value)
  } keys %$args };
}

sub make_field_resolver {
  my ($type2info) = @_;
  DEBUG and _debug('OpenAPI.make_field_resolver', $type2info);
  sub {
    my ($root_value, $args, $context, $info) = @_;
    my $field_name = $info->{field_name};
    my $parent_type = $info->{parent_type}->to_string;
    my $pseudo_type = join '.', $parent_type, $field_name;
    DEBUG and _debug('OpenAPI.resolver', $root_value, $field_name, $pseudo_type, $args);
    if (
      ref($root_value) eq 'HASH' and
      $type2info->{$parent_type} and
      my $prop = $type2info->{$parent_type}{field2prop}{$field_name}
    ) {
      return $root_value->{$prop};
    }
    my $property = ref($root_value) eq 'HASH'
      ? $root_value->{$field_name}
      : $root_value;
    my $result = eval {
      return $property->($args, $context, $info) if ref $property eq 'CODE';
      return $property if ref $root_value eq 'HASH';
      if (!UNIVERSAL::isa($root_value, 'OpenAPI::Client')) {
        return $property // die "OpenAPI.resolver could not resolve '$field_name'\n"
          if !$root_value->can($field_name);
        return $root_value->$field_name($args, $context, $info);
      }
      # call OAC method
      my $operationId = $type2info->{$parent_type}{field2operationId}{$field_name};
      my $mapped_args = _map_args(
        $pseudo_type,
        $args,
        $type2info,
      );
      DEBUG and _debug('OpenAPI.resolver(c)', $operationId, $args, $mapped_args);
      my $got = $root_value->call_p($operationId => $mapped_args)->then(
        sub {
          my $res = shift->res;
          DEBUG and _debug('OpenAPI.resolver(res)', $res);
          die $res->body."\n" if $res->is_error;
          my $json = $res->json;
          DEBUG and _debug('OpenAPI.resolver(got)', $json);
          my $return_type = $info->{return_type};
          $return_type = $return_type->of while $return_type->can('of');
          if ($type2info->{$return_type->to_string}{is_hashpair}) {
            $json = [ map {
              +{ key => $_, value => $json->{$_} }
            } sort keys %{$json || {}} ];
          }
          DEBUG and _debug('OpenAPI.resolver(rettype)', $return_type->to_string, $json);
          $json;
        }, sub {
          DEBUG and _debug('OpenAPI.resolver(error)', shift->res->body);
          die shift->res->body . "\n";
        }
      );
    };
    die $@ if $@;
    $result;
  };
}

sub _trim_name {
  my ($name) = @_;
  return if !defined $name;
  $name =~ s#[^a-zA-Z0-9_]+#_#g;
  $name;
}

sub _get_type {
  my ($info, $maybe_name, $name2type, $type2info) = @_;
  DEBUG and _debug("_get_type($maybe_name)", $info);
  return 'String' if !$info or !%$info; # bodge but unavoidable
  # ignore definitions that are an array as not GQL-idiomatic, deal as array
  if ($info->{'$ref'} and ($info->{type}//'') ne 'array') {
    DEBUG and _debug("_get_type($maybe_name) ref");
    my $rawtype = $info->{'$ref'};
    $rawtype =~ s:^#/definitions/::;
    return $rawtype;
  }
  if (
    $info->{additionalProperties}
      or (($info->{type}//'') eq 'object' and !$info->{properties})
  ) {
    my $type = _get_type(
      {
        type => 'array',
        items => {
          type => 'object',
          properties => {
            key => { type => 'string' },
            value => $info->{additionalProperties} // { type => 'string' },
          },
        },
      },
      $maybe_name,
      $name2type,
      $type2info,
    );
    DEBUG and _debug("_get_type($maybe_name) aP", $type);
    $type2info->{$maybe_name}{is_hashpair} = 1;
    return $type;
  }
  if ($info->{properties} or $info->{allOf} or $info->{enum}) {
    DEBUG and _debug("_get_type($maybe_name) p");
    return _get_spec_from_info(
      $maybe_name, $info,
      $name2type,
      $type2info,
    );
  }
  if ($info->{type} eq 'array') {
    DEBUG and _debug("_get_type($maybe_name) a");
    return _apply_modifier(
      'list',
      _get_type(
        $info->{items}, $maybe_name,
        $name2type,
        $type2info,
      )
    );
  }
  return 'DateTime'
    if ($info->{type}//'') eq 'string'
    and ($info->{format}//'') eq 'date-time';
  DEBUG and _debug("_get_type($maybe_name) simple");
  $TYPEMAP{$info->{type}}
    // die "'$maybe_name' unknown data type: @{[$info->{type}]}\n";
}

sub _refinfo2fields {
  my ($name, $refinfo, $name2type, $type2info) = @_;
  my %fields;
  my $properties = $refinfo->{properties};
  my %required = map { ($_ => 1) } @{$refinfo->{required} || []};
  for my $prop (keys %$properties) {
    my $info = $properties->{$prop};
    my $field = _trim_name($prop);
    $type2info->{$name}{field2prop}{$field} = $prop;
    DEBUG and _debug("_refinfo2fields($name) $prop/$field", $info, $type2info->{$name});
    my $rawtype = _get_type(
      $info, $name.ucfirst($field),
      $name2type,
      $type2info,
    );
    my $fulltype = _apply_modifier(
      $required{$prop} && 'non_null',
      $rawtype,
    );
    $type2info->{$name}{field2type}{$field} = $fulltype;
    $fields{$field} = +{ type => $fulltype };
    $fields{$field}->{description} = $info->{description}
      if $info->{description};
  }
  \%fields;
}

sub _merge_fields {
  my ($f1, $f2) = @_;
  my %merged = %$f1;
  for my $k (keys %$f2) {
    if (exists $merged{$k}) {
      $merged{$k} = $f2->{$k} if ref $f2->{$k}{type}; # ie modified ie non-null
    } else {
      $merged{$k} = $f2->{$k};
    }
  }
  \%merged;
}

sub _get_spec_from_info {
  my (
    $name, $refinfo,
    $name2type,
    $type2info,
  ) = @_;
  DEBUG and _debug("_get_spec_from_info($name)", $refinfo);
  my %implements;
  my $fields = {};
  if ($refinfo->{allOf}) {
    for my $schema (@{$refinfo->{allOf}}) {
      DEBUG and _debug("_get_spec_from_info($name)(allOf)", $schema);
      if ($schema->{'$ref'}) {
        my $othertype = _get_type($schema, '$ref', $name2type, $type2info);
        my $othertypedef = $name2type->{$othertype};
        push @{$implements{interfaces}}, $othertype
          if $othertypedef->{kind} eq 'interface';
        $fields = _merge_fields($fields, $othertypedef->{fields});
      } else {
        $fields = _merge_fields($fields, _refinfo2fields(
          $name, $schema,
          $name2type,
          $type2info,
        ));
      }
    }
  } elsif (my $values = $refinfo->{enum}) {
    my (%enum2value, %trimmed2suffix);
    for my $uniqvalue (sort keys %{{ @$values, reverse @$values }}) {
      my $trimmed = _trim_name($uniqvalue);
      $trimmed = 'EMPTY' if !length $trimmed;
      $trimmed .= $trimmed2suffix{$trimmed}++ || '';
      $enum2value{$trimmed} = { value => $uniqvalue };
    }
    DEBUG and _debug("_get_spec_from_info($name)(enum)", $values, \%enum2value);
    my $spec = +{
      kind => 'enum',
      name => $name,
      values => \%enum2value,
    };
    $spec->{description} = $refinfo->{title} if $refinfo->{title};
    $spec->{description} = $refinfo->{description}
      if $refinfo->{description};
    $name2type->{$name} = $spec;
    $type2info->{$name}{is_enum} = 1;
    return $name;
  } else {
    %$fields = (%$fields, %{_refinfo2fields(
      $name, $refinfo,
      $name2type,
      $type2info,
    )});
  }
  my $spec = +{
    kind => $refinfo->{discriminator} ? 'interface' : 'type',
    name => $name,
    fields => $fields,
    %implements,
  };
  $spec->{description} = $refinfo->{title} if $refinfo->{title};
  $spec->{description} = $refinfo->{description}
    if $refinfo->{description};
  $name2type->{$name} = $spec;
  $name;
}

sub _make_union {
  my ($types, $name2type) = @_;
  my %seen;
  my $types2 = [ sort grep !$seen{$_}++, map _remove_modifiers($_), @$types ];
  return $types->[0] if @$types2 == 1; # no need for a union
  my $typename = join '', @$types2, 'Union';
  DEBUG and _debug("_make_union", $types, $types2, $typename);
  $name2type->{$typename} ||= {
    name => $typename,
    kind => 'union',
    types => $types2,
  };
  $typename;
}

sub _make_input {
  my ($type, $name2type, $type2info) = @_;
  DEBUG and _debug("_make_input", $type);
  $type = $type->{type} if ref $type eq 'HASH';
  if (ref $type eq 'ARRAY') {
    # modifiers, recurse
    return _apply_modifier(
      $type->[0],
      _make_input(
        $type->[1],
        $name2type,
        $type2info,
      ),
    )
  }
  return $type
    if $TYPE2SCALAR{$type}
    or $name2type->{$type}{kind} eq 'enum'
    or $name2type->{$type}{kind} eq 'input';
  # not deal with unions for now
  # is an output "type"
  my $input_name = $type.'Input';
  my $typedef = $name2type->{$type};
  my $inputdef = $name2type->{$input_name} ||= {
    name => $input_name,
    kind => 'input',
    $typedef->{description} ? (description => $typedef->{description}) : (),
    fields => +{
      map {
        my $fielddef = $typedef->{fields}{$_};
        ($_ => +{
          %$fielddef, type => _make_input(
            $fielddef->{type},
            $name2type,
            $type2info,
          ),
        })
      } keys %{$typedef->{fields}}
    },
  };
  my $inputdef_fields = $inputdef->{fields};
  $type2info->{$input_name}{field2prop} = $type2info->{$type}{field2prop};
  $type2info->{$input_name}{field2type} = +{
    map {
      ($_ => $inputdef_fields->{$_}{type})
    } keys %$inputdef_fields
  };
  DEBUG and _debug("_make_input(object)($input_name)", $typedef, $type2info->{$input_name}, $type2info->{$type}, $name2type, $type2info);
  $input_name;
}

sub _resolve_schema_ref {
  my ($obj, $schema) = @_;
  my $ref = $obj->{'$ref'};
  return $obj if !$ref;
  $ref =~ s{^#}{};
  $schema->get($ref);
}

sub _kind2name2endpoint {
  my ($paths, $schema, $name2type, $type2info) = @_;
  my %kind2name2endpoint;
  for my $path (keys %$paths) {
    for my $method (grep $paths->{$path}{$_}, @METHODS) {
      my $info = $paths->{$path}{$method};
      my $op_id = $info->{operationId} || $method.'_'._trim_name($path);
      my $fieldname = _trim_name($op_id);
      my $kind = $METHOD2MUTATION{$method} ? 'mutation' : 'query';
      $type2info->{ucfirst $kind}{field2operationId}{$fieldname} = $op_id;
      my @successresponses = map _resolve_schema_ref($_, $schema),
        map $info->{responses}{$_},
        grep /^2/, keys %{$info->{responses}};
      DEBUG and _debug("_kind2name2endpoint($path)($method)($fieldname)($op_id)", $info->{responses}, \@successresponses);
      my @responsetypes = map _get_type(
        $_->{schema}, $fieldname.'Return',
        $name2type,
        $type2info,
      ), @successresponses;
      @responsetypes = ('String') if !@responsetypes; # void return
      my $union = _make_union(
        \@responsetypes,
        $name2type,
      );
      my @parameters = map _resolve_schema_ref($_, $schema),
        @{ $info->{parameters} };
      my $pseudo_type = join '.', ucfirst($kind), $fieldname;
      my %args = map {
        my $argprop = $_->{name};
        my $argfield = _trim_name($argprop);
        $type2info->{$pseudo_type}{field2prop}{$argfield} = $argprop;
        my $type = _get_type(
          $_->{schema} ? $_->{schema} : $_, "${fieldname}_$argfield",
          $name2type,
          $type2info,
        );
        my $typename = _remove_modifiers($type);
        my $is_hashpair = ($type2info->{$typename}||{})->{is_hashpair};
        $type = _make_input(
          $type,
          $name2type,
          $type2info,
        );
        $type2info->{$pseudo_type}{field2is_hashpair}{$argfield} = $is_hashpair
          if $is_hashpair;
        $type2info->{$pseudo_type}{field2type}{$argfield} = $type;
        ($argfield => {
          type => _apply_modifier($_->{required} && 'non_null', $type),
          $_->{description} ? (description => $_->{description}) : (),
        })
      } @parameters;
      DEBUG and _debug("_kind2name2endpoint($fieldname) params", \%args);
      my $description = $info->{summary} || $info->{description};
      $kind2name2endpoint{$kind}->{$fieldname} = +{
        type => $union,
        $description ? (description => $description) : (),
        %args ? (args => \%args) : (),
      };
    }
  }
  (\%kind2name2endpoint);
}

# possible "kind"s: scalar enum type input union interface
# mutates %$name2typeused - is boolean
sub _walk_type {
  my ($name, $name2typeused, $name2type) = @_;
  DEBUG and _debug("OpenAPI._walk_type", $name, $name2typeused);#, $name2type
  return if $name2typeused->{$name}; # seen - stop
  return if $TYPE2SCALAR{$name}; # builtin scalar - stop
  $name2typeused->{$name} = 1;
  my $type = $name2type->{$name};
  return if $KIND2SIMPLE{ $type->{kind} }; # no sub-fields, types, etc - stop
  if ($type->{kind} eq 'union') {
    DEBUG and _debug("OpenAPI._walk_type(union)");
    _walk_type($_, $name2typeused, $name2type) for @{$type->{types}};
    return;
  }
  if ($type->{kind} eq 'interface') {
    DEBUG and _debug("OpenAPI._walk_type(interface)");
    for my $maybe_type (values %$name2type) {
      next if $maybe_type->{kind} ne 'type' or !$maybe_type->{interfaces};
      next if !grep $_ eq $name, @{$maybe_type->{interfaces}};
      _walk_type($maybe_type->{name}, $name2typeused, $name2type);
    }
    # continue to pick up the fields' types too
  }
  # now only input and output object remain (but still interfaces too)
  for my $fieldname (keys %{ $type->{fields} }) {
    my $field_def = $type->{fields}{$fieldname};
    DEBUG and _debug("OpenAPI._walk_type($name)(*object)", $field_def);
    _walk_type(_remove_modifiers($field_def->{type}), $name2typeused, $name2type);
    next if !%{ $field_def->{args} || {} };
    for my $argname (keys %{ $field_def->{args} }) {
      DEBUG and _debug("OpenAPI._walk_type(arg)($argname)");
      my $arg_def = $field_def->{args}{$argname};
      _walk_type(_remove_modifiers($arg_def->{type}), $name2typeused, $name2type);
    }
  }
}

sub to_graphql {
  my ($class, $spec, $app) = @_;
  my %appargs = (app => $app) if $app;
  my $openapi_schema = JSON::Validator::OpenAPI::Mojolicious->new(
    %appargs
  )->schema($spec)->schema;
  DEBUG and _debug('OpenAPI.schema', $openapi_schema);
  my $defs = $openapi_schema->get("/definitions");
  my @ast;
  my (
    %name2type,
    %type2info,
  );
  # all non-interface-consumers first
  # also drop defs that are an array as not GQL-idiomatic - treat as that array
  for my $name (
    grep !$defs->{$_}{allOf} && ($defs->{$_}{type}//'') ne 'array', keys %$defs
  ) {
    _get_spec_from_info(
      _trim_name($name), $defs->{$name},
      \%name2type,
      \%type2info,
    );
  }
  # now interface-consumers and can now put in interface fields too
  for my $name (grep $defs->{$_}{allOf}, keys %$defs) {
    _get_spec_from_info(
      _trim_name($name), $defs->{$name},
      \%name2type,
      \%type2info,
    );
  }
  my ($kind2name2endpoint) = _kind2name2endpoint(
    $openapi_schema->get("/paths"), $openapi_schema,
    \%name2type,
    \%type2info,
  );
  for my $kind (keys %$kind2name2endpoint) {
    $name2type{ucfirst $kind} = +{
      kind => 'type',
      name => ucfirst $kind,
      fields => { %{ $kind2name2endpoint->{$kind} } },
    };
  }
  my %name2typeused;
  _walk_type(ucfirst $_, \%name2typeused, \%name2type)
    for keys %$kind2name2endpoint;
  push @ast, map $name2type{$_}, keys %name2typeused;
  +{
    schema => GraphQL::Schema->from_ast(\@ast),
    root_value => OpenAPI::Client->new($openapi_schema->data, %appargs),
    resolver => make_field_resolver(\%type2info),
  };
}

=encoding utf-8

=head1 NAME

GraphQL::Plugin::Convert::OpenAPI - convert OpenAPI schema to GraphQL schema

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-OpenAPI.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-OpenAPI) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-OpenAPI.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::OpenAPI) [![Coverage Status](https://coveralls.io/repos/github/graphql-perl/GraphQL-Plugin-Convert-OpenAPI/badge.svg?branch=master)](https://coveralls.io/github/graphql-perl/GraphQL-Plugin-Convert-OpenAPI?branch=master)

=end markdown

=head1 SYNOPSIS

  use GraphQL::Plugin::Convert::OpenAPI;
  my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
    'file-containing-spec.json',
  );
  print $converted->{schema}->to_doc;

=head1 DESCRIPTION

This module implements the L<GraphQL::Plugin::Convert> API to convert
a L<JSON::Validator::OpenAPI::Mojolicious> specification to L<GraphQL::Schema> etc.

It uses, from the given API spec:

=over

=item * the given "definitions" as output types

=item * the given "definitions" as input types when required for an
input parameter

=item * the given operations as fields of either C<Query> if a C<GET>,
or C<Mutation> otherwise

=back

If an output type has C<additionalProperties> (effectively a hash whose
values are of a specified type), this poses a problem for GraphQL which
does not have such a concept. It will be treated as being made up of a
list of pairs of objects (i.e. hashes) with two keys: C<key> and C<value>.

The queries will be run against the spec's server.  If the spec starts
with a C</>, and a L<Mojolicious> app is supplied (see below), that
server will instead be the given app.

=head1 ARGUMENTS

To the C<to_graphql> method: a URL to a specification, or a filename
containing a JSON specification, or a data structure, of an OpenAPI v2.

Optionally, a L<Mojolicious> app can be given as the second argument. In
this case, with a L<Mojolicious::Lite> app, do:

  my $api = plugin OpenAPI => {spec => 'data://main/api.yaml'};
  plugin(GraphQL => {convert => [ 'OpenAPI', $api->validator->bundle, app ]});

with the usual mapping in the case of a full app. For this to work you
need L<Mojolicious::Plugin::OpenAPI> version 1.25+, which returns itself
on C<register>.

=head1 PACKAGE FUNCTIONS

=head2 make_field_resolver

This is available as C<\&GraphQL::Plugin::Convert::OpenAPI::make_field_resolver>
in case it is wanted for use outside of the "bundle" of the C<to_graphql>
method. It takes arguments:

=over

=item

a hash-ref mapping from a GraphQL type-name to another hash-ref with
information about that type. There are addition pseudo-types with stored
information, named eg C<TypeName.fieldName>, for the obvious
purpose. The use of C<.> avoids clashing with real types. This will only
have information about input types.

Valid keys:

=over

=item is_hashpair

True value if that type needs transforming from a hash into pairs.

=item field2operationId

Hash-ref mapping from a GraphQL operation field-name (which will
only be done on the C<Query> or C<Mutation> types, for obvious reasons)
to an C<operationId>.

=item field2type

Hash-ref mapping from a GraphQL type's field-name to hash-ref mapping
its arguments, if any, to the corresponding GraphQL type-name.

=item field2prop

Hash-ref mapping from a GraphQL type's field-name to the corresponding
OpenAPI property-name.

=item is_enum

Boolean value indicating whether the type is a L<GraphQL::Type::Enum>.

=back

=back

and returns a closure that can be used as a field resolver.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

Parts based on L<https://github.com/yarax/swagger-to-graphql>

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
