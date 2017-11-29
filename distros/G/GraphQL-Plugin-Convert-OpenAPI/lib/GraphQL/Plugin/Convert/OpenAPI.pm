package GraphQL::Plugin::Convert::OpenAPI;
use 5.008001;
use strict;
use warnings;
use GraphQL::Schema;
use GraphQL::Debug qw(_debug);
use JSON::Validator::OpenAPI;
use OpenAPI::Client;

our $VERSION = "0.03";
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

my %TYPEMAP = (
  string => 'String',
  date => 'DateTime',
  integer => 'Int',
  number => 'Float',
  boolean => 'Boolean',
);
my %TYPE2SCALAR = map { ($_ => 1) } qw(ID String Int Float Boolean DateTime);
my %METHOD2MUTATION = map { ($_ => 1) } qw(post put patch delete);
my @METHODS = (keys %METHOD2MUTATION, qw(get options head));

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
  return $typespec->{type} if ref $typespec eq 'HASH';
  return $typespec if ref $typespec ne 'ARRAY';
  _remove_modifiers($typespec->[1]);
}

sub field_resolver {
  my ($root_value, $args, $context, $info) = @_;
  my $field_name = $info->{field_name};
  DEBUG and _debug('OpenAPI.resolver', $root_value, $field_name, $args);
  my $property = ref($root_value) eq 'HASH'
    ? $root_value->{$field_name}
    : $root_value;
  return $property->($args, $context, $info) if ref $property eq 'CODE';
  return $property // die "OpenAPI.resolver could not resolve '$field_name'\n"
    if ref $root_value eq 'HASH' or !$root_value->can($field_name);
  return $root_value->$field_name($args, $context, $info)
    if !UNIVERSAL::isa($root_value, 'OpenAPI::Client');
  # call OAC method
  my $got = $root_value->$field_name($args);
  DEBUG and _debug('OpenAPI.resolver(got)', $got->res->json);
  $got->res->json;
}

sub _trim_name {
  my ($name) = @_;
  $name =~ s#[^a-zA-Z0-9_]##g;
  $name;
}

sub _get_type {
  my ($info, $maybe_name, $name2type) = @_;
  DEBUG and _debug("_get_type($maybe_name)", $info);
  return 'String' if !%$info; # bodge but unavoidable
  if ($info->{'$ref'}) {
    DEBUG and _debug("_get_type($maybe_name) ref");
    my $rawtype = $info->{'$ref'};
    $rawtype =~ s:^#/definitions/::;
    return $rawtype;
  }
  if ($info->{additionalProperties}) {
    DEBUG and _debug("_get_type($maybe_name) aP");
    return _get_type(
      {
        type => 'array',
        items => {
          type => 'object',
          properties => {
            key => { type => 'string' },
            value => $info->{additionalProperties},
          },
        },
      },
      $maybe_name,
      $name2type,
    );
  }
  if ($info->{properties} or $info->{allOf} or $info->{enum}) {
    DEBUG and _debug("_get_type($maybe_name) p");
    return _get_spec_from_info(
      $maybe_name, $info,
      $name2type,
    );
  }
  if ($info->{type} eq 'array') {
    DEBUG and _debug("_get_type($maybe_name) a");
    return _apply_modifier(
      'list',
      _get_type(
        $info->{items}, $maybe_name,
        $name2type,
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
  my ($name, $refinfo, $name2type) = @_;
  my %fields;
  my $properties = $refinfo->{properties};
  my %required = map { ($_ => 1) } @{$refinfo->{required}};
  for my $prop (keys %$properties) {
    my $info = $properties->{$prop};
    DEBUG and _debug("_refinfo2fields($name) $prop", $info);
    my $rawtype = _get_type(
      $info, $name.ucfirst($prop),
      $name2type,
    );
    my $fulltype = _apply_modifier(
      $required{$prop} && 'non_null',
      $rawtype,
    );
    $fields{$prop} = +{ type => $fulltype };
    $fields{$prop}->{description} = $info->{description}
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
  ) = @_;
  DEBUG and _debug("_get_spec_from_info($name)", $refinfo);
  my %implements;
  my $fields = {};
  if ($refinfo->{allOf}) {
    for my $schema (@{$refinfo->{allOf}}) {
      DEBUG and _debug("_get_spec_from_info($name)(allOf)", $schema);
      if ($schema->{'$ref'}) {
        my $othertype = _get_type($schema, '$ref');
        my $othertypedef = $name2type->{$othertype};
        push @{$implements{interfaces}}, $othertype
          if $othertypedef->{kind} eq 'interface';
        $fields = _merge_fields($fields, $othertypedef->{fields});
      } else {
        $fields = _merge_fields($fields, _refinfo2fields(
          $name, $schema,
          $name2type,
        ));
      }
    }
  } elsif (my $values = $refinfo->{enum}) {
    DEBUG and _debug("_get_spec_from_info($name)(enum)", $values);
    my $spec = +{
      kind => 'enum',
      name => $name,
      values => +{ map { (_trim_name($_) => {}) } @$values },
    };
    $spec->{description} = $refinfo->{title} if $refinfo->{title};
    $spec->{description} = $refinfo->{description}
      if $refinfo->{description};
    $name2type->{$name} = $spec;
    return $name;
  } else {
    %$fields = (%$fields, %{_refinfo2fields(
      $name, $refinfo,
      $name2type,
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
  return $types->[0] if @$types == 1; # no need for a union
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
  my ($type, $name2type) = @_;
  DEBUG and _debug("_make_input", $type);
  if (ref $type eq 'ARRAY') {
    # modifiers, recurse
    return _apply_modifier(
      $type->[0],
      _make_input(
        $type->[1],
        $name2type,
      ),
    )
  }
  $type = $type->{type} if ref $type eq 'HASH';
  return $type
    if $TYPE2SCALAR{$type}
    or $name2type->{$type}{kind} eq 'enum'
    or $name2type->{$type}{kind} eq 'input';
  # not deal with unions for now
  # is an output "type"
  my $input_name = $type.'Input';
  my $typedef = $name2type->{$type};
  DEBUG and _debug("_make_input(object)", $name2type, $typedef);
  $name2type->{$input_name} ||= {
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
          ),
        })
      } keys %{$typedef->{fields}}
    },
  };
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
  my ($paths, $schema, $name2type) = @_;
  my %kind2name2endpoint;
  for my $path (keys %$paths) {
    for my $method (grep $paths->{$path}{$_}, @METHODS) {
      my $info = $paths->{$path}{$method};
      my $op_id = $info->{operationId} || $method.'_'._trim_name($path);
      my $kind = $METHOD2MUTATION{$method} ? 'mutation' : 'query';
      my @successresponses = map _resolve_schema_ref($_, $schema),
        map $info->{responses}{$_},
        grep /^2/, keys %{$info->{responses}};
      DEBUG and _debug("_kind2name2endpoint($path)($method)($op_id)", $info->{responses}, \@successresponses);
      my @responsetypes = map _get_type(
        $_->{schema}, 'param',
        $name2type,
      ), @successresponses;
      my $union = _make_union(
        \@responsetypes,
        $name2type,
      );
      my @parameters = map _resolve_schema_ref($_, $schema),
        @{ $info->{parameters} };
      my %args = map {
        my $type = _get_type(
          $_->{schema} ? $_->{schema} : $_, "${op_id}_$_->{name}",
          $name2type,
        );
        $type = _make_input(
          $type,
          $name2type,
        ) if $kind eq 'mutation';
        ($_->{name} => {
          type => _apply_modifier($_->{required} && 'non_null', $type),
          $_->{description} ? (description => $_->{description}) : (),
        })
      } @parameters;
      DEBUG and _debug("_kind2name2endpoint($op_id) params", \%args);
      my $description = $info->{summary} || $info->{description};
      $kind2name2endpoint{$kind}->{$op_id} = +{
        type => $union,
        $description ? (description => $description) : (),
        %args ? (args => \%args) : (),
      };
    }
  }
  \%kind2name2endpoint;
}

sub to_graphql {
  my ($class, $spec, $app) = @_;
  my %appargs = (app => $app) if $app;
  my $openapi_schema = JSON::Validator::OpenAPI->new(
    %appargs
  )->schema($spec)->schema;
  my $defs = $openapi_schema->get("/definitions");
  my @ast;
  my (
    %name2type,
  );
  # all non-interface-consumers first
  for my $name (grep !$defs->{$_}{allOf}, keys %$defs) {
    _get_spec_from_info(
      _trim_name($name), $defs->{$name},
      \%name2type,
    );
  }
  # now interface-consumers and can now put in interface fields too
  for my $name (grep $defs->{$_}{allOf}, keys %$defs) {
    _get_spec_from_info(
      _trim_name($name), $defs->{$name},
      \%name2type,
    );
  }
  my $kind2name2endpoint = _kind2name2endpoint(
    $openapi_schema->get("/paths"), $openapi_schema,
    \%name2type,
  );
  push @ast, values %name2type;
  push @ast, {
    kind => 'type',
    name => 'Query',
    fields => {
      map {
        my $name = $_;
        (
          $name => $kind2name2endpoint->{query}{$name},
        )
      } keys %{ $kind2name2endpoint->{query} }
    },
  };
  push @ast, {
    kind => 'type',
    name => 'Mutation',
    fields => {
      map {
        my $name = $_;
        (
          $name => $kind2name2endpoint->{mutation}{$name},
        )
      } keys %{ $kind2name2endpoint->{mutation} }
    },
  };
  +{
    schema => GraphQL::Schema->from_ast(\@ast),
    root_value => OpenAPI::Client->new($spec, %appargs),
    resolver => \&field_resolver,
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

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-OpenAPI.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::OpenAPI)

=end markdown

=head1 SYNOPSIS

  use GraphQL::Plugin::Convert::OpenAPI;
  use Schema;
  my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
    sub { Schema->connect }
  );
  print $converted->{schema}->to_doc;

=head1 DESCRIPTION

This module implements the L<GraphQL::Plugin::Convert> API to convert
a L<JSON::Validator::OpenAPI> specification to L<GraphQL::Schema> etc.

It uses, from the given API spec:

=over

=item * the given "definitions" as output types

=item * the given "definitions" as input types when required for an
input parameter

=item * the given operations as fields of either C<Query> if a C<GET>,
or C<Mutation> otherwise

=back

The queries will be run against the spec's server.  If the spec starts
with a C</>, and a L<Mojolicious> app is supplied (see below), that
server will instead be the given app.

=head1 ARGUMENTS

To the C<to_graphql> method: a URL to a specification, or a filename
containing a JSON specification, of an OpenAPI v2. Optionally, a
L<Mojolicious> app can be given as the second argument.

=head1 PACKAGE FUNCTIONS

=head2 field_resolver

This is available as C<\&GraphQL::Plugin::Convert::OpenAPI::field_resolver>
in case it is wanted for use outside of the "bundle" of the C<to_graphql>
method.

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
