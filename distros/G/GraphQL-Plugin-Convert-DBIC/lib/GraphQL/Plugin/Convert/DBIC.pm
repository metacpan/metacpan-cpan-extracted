package GraphQL::Plugin::Convert::DBIC;
use strict;
use warnings;
use GraphQL::Schema;
use GraphQL::Debug qw(_debug);
use Lingua::EN::Inflect::Number qw(to_S to_PL);
use Carp qw(confess);

our $VERSION = "0.15";
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

my %GRAPHQL_TYPE2SQLS = (
  String => [
    'wlongvarchar',
    'guid',
    'uuid',
    'wvarchar',
    'wchar',
    'longvarbinary',
    'varbinary',
    'binary',
    'longvarchar',
    'unknown_type',
    'all_types',
    'char',
    'varchar',
    'udt',
    'udt_locator',
    'row',
    'ref',
    'blob',
    'blob_locator',
    'clob',
    'clob_locator',
    'array',
    'array_locator',
    'multiset',
    'multiset_locator',
    # mysql
    'text',
    'tinytext',
    'mediumtext',
    'longtext',
    # pgsql
    'cidr',
    'inet',
  ],
  Int => [
    'bigint',
    'bit',
    'tinyint',
    'integer',
    'smallint',
    'interval',
    'interval_year',
    'interval_month',
    'interval_day',
    'interval_hour',
    'interval_minute',
    'interval_second',
    'interval_year_to_month',
    'interval_day_to_hour',
    'interval_day_to_minute',
    'interval_day_to_second',
    'interval_hour_to_minute',
    'interval_hour_to_second',
    'interval_minute_to_second',
    # not DBI SQL_* types
    'int',
  ],
  Float => [
    'numeric',
    'decimal',
    'float',
    'real',
    'double',
  ],
  DateTime => [
    'datetime',
    'date',
    'time',
    'timestamp',
    'type_date',
    'type_time',
    'type_timestamp',
    'type_time_with_timezone',
    'type_timestamp_with_timezone',
    # pgsql
    'timestamp with time zone',
    'timestamp without time zone',
  ],
  Boolean => [
    'boolean',
  ],
  ID => [
    'wvarchar',
  ],
);
my %TYPEMAP = (
  (map {
    my $gql_type = $_;
    map {
      ($_ => $gql_type)
    } @{ $GRAPHQL_TYPE2SQLS{$gql_type} }
  } keys %GRAPHQL_TYPE2SQLS),
  enum => sub {
    my ($source, $column, $info) = @_;
    my $extra = $info->{extra};
    return {
      kind => 'enum',
      name => _dbicsource2pretty(
        $extra->{custom_type_name} || "${source}_$column"
      ),
      values => { map { _trim_name($_) => { value => $_ } } @{ $extra->{list} } },
    }
  },
);
my %TYPE2SCALAR = map { ($_ => 1) } qw(ID String Int Float Boolean);

sub _dbicsource2pretty {
  my ($source) = @_;
  confess "_dbicsource2pretty given undef" if !defined $source;
  $source = eval { $source->source_name } || $source;
  $source =~ s#.*::##;
  $source = to_S $source;
  join '', map ucfirst, split /_+/, $source;
}

sub _trim_name {
  my ($name) = @_;
  return if !defined $name;
  $name =~ s#[^a-zA-Z0-9_]+#_#g;
  $name;
}

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

sub _type2createinput {
  my ($name, $fields, $pk21, $fk21, $column21, $name2type) = @_;
  +{
    kind => 'input',
    name => "${name}CreateInput",
    fields => {
      (map { ($_ => $fields->{$_}) }
        grep !$pk21->{$_} && !$fk21->{$_}, keys %$column21),
      _make_fk_fields($name, $fk21, $name2type),
    },
  };
}

sub _type2idinput {
  my ($name, $fields, $pk21) = @_;
  +{
    kind => 'input',
    name => "${name}IDInput",
    fields => {
      (map { ($_ => $fields->{$_}) }
        keys %$pk21),
    },
  };
}

sub _type2searchinput {
  my ($name, $column2rawtype, $pk21, $column21) = @_;
  +{
    kind => 'input',
    name => "${name}SearchInput",
    fields => {
      (map { ($_ => { type => $column2rawtype->{$_} }) }
        grep !$pk21->{$_}, keys %$column21),
    },
  };
}

sub _type2updateinput {
  my ($name) = @_;
  +{
    kind => 'input',
    name => "${name}UpdateInput",
    fields => {
      id => { type => _apply_modifier('non_null', "${name}IDInput") },
      payload => { type => _apply_modifier('non_null', "${name}SearchInput") },
    },
  };
}

sub _make_fk_fields {
  my ($name, $fk21, $name2type) = @_;
  my $type = $name2type->{$name};
  (map {
    my $field_type = $type->{fields}{$_}{type};
    if (!$TYPE2SCALAR{_remove_modifiers($field_type)}) {
      my $non_null =
        ref($field_type) eq 'ARRAY' && $field_type->[0] eq 'non_null';
      $field_type = _apply_modifier(
        $non_null && 'non_null', _remove_modifiers($field_type)."IDInput"
      );
    }
    ($_ => { type => $field_type })
  } keys %$fk21);
}

sub field_resolver {
  my ($root_value, $args, $context, $info) = @_;
  my $field_name = $info->{field_name};
  DEBUG and _debug('DBIC.resolver', $field_name, $args, $info);
  my $parent_name = $info->{parent_type}->name;
  if ($parent_name eq 'Mutation') {
    goto &_mutation_resolver;
  } elsif ($parent_name eq 'Query') {
    goto &_query_resolver;
  }
  my $property = ref($root_value) eq 'HASH'
    ? $root_value->{$field_name}
    : $root_value;
  return $property->($args, $context, $info) if ref $property eq 'CODE';
  return $property // die "DBIC.resolver could not resolve '$field_name'\n"
    if ref $root_value eq 'HASH' or !$root_value->can($field_name);
  return $root_value->$field_name($args, $context, $info)
    if !UNIVERSAL::isa($root_value, 'DBIx::Class::Core');
  # dbic search
  my $rs = $root_value->$field_name;
  $rs = [ $rs->all ] if $info->{return_type}->isa('GraphQL::Type::List');
  return $rs;
}

sub _subfieldrels {
  my ($field_node) = @_;
  die "_subfieldrels called on non-field" if $field_node->{kind} ne 'field';
  return {} unless my @sels = @{ $field_node->{selections} || [] };
  return {} unless my @withsels = grep @{ $_->{selections} || [] }, @sels;
  +{ map { $_->{name} => _subfieldrels($_) } @withsels };
}

sub _query_resolver {
  my ($dbic_schema, $args, $context, $info) = @_;
  my $name = $info->{return_type}->name;
  my $method = $info->{return_type}->isa('GraphQL::Type::List')
    ? 'search' : 'find';
  my @subfieldrels = map _subfieldrels($_), @{$info->{field_nodes}};
  $args = $args->{input} if ref $args->{input} eq 'HASH';
  $args = +{ map { ("me.$_" => $args->{$_}) } keys %$args };
  DEBUG and _debug('DBIC.root_value', $name, $method, $args, \@subfieldrels, $info);
  my $rs = $dbic_schema->resultset($name);
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my $result = $rs->$method(
    $args,
    { prefetch => { map %$, @subfieldrels } },
  );
  $result = [ $result->all ] if $method eq 'search';
  $result;
}

sub _make_query_pk_field {
  my ($typename, $type, $name2pk21, $is_list) = @_;
  my $return_type = $typename;
  $return_type = _apply_modifier('list', $return_type) if $is_list;
  +{
    type => $return_type,
    args => {
      map {
        my $field_type = _apply_modifier('non_null', $type->{fields}{$_}{type});
        $field_type = _apply_modifier('non_null', _apply_modifier('list',
          $field_type
        )) if $is_list;
        $_ => { type => $field_type }
      } keys %{ $name2pk21->{$typename} }
    },
  };
}

sub _make_input_field {
  my ($typename, $return_type, $mutation_kind, $list_in, $list_out) = @_;
  $return_type = _apply_modifier('list', $return_type) if $list_out;
  my $input_type = $typename . ucfirst($mutation_kind) . 'Input';
  $input_type = _apply_modifier('non_null', $input_type);
  $input_type = _apply_modifier('non_null', _apply_modifier('list',
    $input_type
  )) if $list_in;
  +{
    type => $return_type,
    args => { input => { type => $input_type } },
  };
}

use constant MUTATE_ARGSPROCESS => {
  update => sub { $_[0]->{payload} },
  delete => sub { },
};
use constant MUTATE_POSTPROCESS => {
  update => sub { ref($_[0]) eq 'GraphQL::Error' ? $_[0] : $_[0]->discard_changes },
  delete => sub { ref($_[0]) eq 'GraphQL::Error' ? $_[0] : $_[0] && 1 },
};
sub _mutation_resolver {
  my ($dbic_schema, $args, $context, $info) = @_;
  my $name = $info->{field_name};
  die "Couldn't understand field '$name'"
    unless $name =~ s/^(create|update|delete)//;
  my $method = $1;
  my $find_first = $method ne 'create';
  my ($args_process, $result_process) = map $_->{$method},
    MUTATE_ARGSPROCESS, MUTATE_POSTPROCESS;
  $args = $args->{input} if $args->{input};
  my $is_list = ref $args eq 'ARRAY';
  $args = [ $args ] if !$is_list; # so can just deal as list below
  DEBUG and _debug("DBIC.root_value", $args);
  my $rs = $dbic_schema->resultset($name);
  my $all_result = [
    map {
      my $operand = $rs;
      $operand = $operand->find($_->{id}) if $find_first;
      my $result = $operand
        ? $operand->$method($args_process ? $args_process->($_) : $_)
        : GraphQL::Error->coerce("$name not found");
      $result = $result_process->($result)
        if $result_process and ref($result) ne 'GraphQL::Error';
      $result;
    } @$args
  ];
  $all_result = $all_result->[0] if !$is_list;
  $all_result
}

sub to_graphql {
  my ($class, $dbic_schema) = @_;
  $dbic_schema = $dbic_schema->() if ((ref($dbic_schema)||'') eq 'CODE');
  my @ast;
  my (
    %name2type, %name2column21, %name2pk21, %name2fk21,
    %name2column2rawtype, %seentype, %name2isview,
  );
  for my $source (map $dbic_schema->source($_), $dbic_schema->sources) {
    my $name = _dbicsource2pretty($source);
    DEBUG and _debug("schema_dbic2graphql($name)", $source);
    $name2isview{$name} = 1 if $source->can('view_definition');
    my %fields;
    my $columns_info = $source->columns_info;
    $name2pk21{$name} = +{ map { ($_ => 1) } $source->primary_columns };
    my %rel2info = map {
      ($_ => $source->relationship_info($_))
    } $source->relationships;
    for my $column (keys %$columns_info) {
      my $info = $columns_info->{$column};
      DEBUG and _debug("schema_dbic2graphql($name.col)", $column, $info);
      my $rawtype = $TYPEMAP{ lc $info->{data_type} };
      if ( 'CODE' eq ref $rawtype ) {
        my $col_spec = $rawtype->($name, $column, $info);
        push @ast, $col_spec unless $seentype{$col_spec->{name}};
        $rawtype = $col_spec->{name};
        $seentype{$col_spec->{name}} = 1;
      }
      $name2column2rawtype{$name}->{$column} = $rawtype;
      my $fulltype = _apply_modifier(
        !$info->{is_nullable} && 'non_null',
        $rawtype
          // die "'$column' unknown data type: @{[lc $info->{data_type}]}\n",
      );
      $fields{$column} = +{ type => $fulltype };
      $name2fk21{$name}->{$column} = 1 if $info->{is_foreign_key};
      $name2column21{$name}->{$column} = 1;
    }
    for my $rel (keys %rel2info) {
      my $info = $rel2info{$rel};
      DEBUG and _debug("schema_dbic2graphql($name.rel)", $rel, $info);
      my $type = _dbicsource2pretty($info->{source});
      $rel =~ s/_id$//; # dumb heuristic
      delete $name2column21{$name}->{$rel}; # so it's not a "column" now
      delete $name2pk21{$name}{$rel}; # it's not a PK either
      # if it WAS a column, capture its non-null-ness
      my $non_null = ref(($fields{$rel} || {})->{type}) eq 'ARRAY';
      $type = _apply_modifier('non_null', $type) if $non_null;
      $type = _apply_modifier('list', $type) if $info->{attrs}{accessor} eq 'multi';
      $type = _apply_modifier('non_null', $type) if $non_null; # in case list
      $fields{$rel} = +{ type => $type };
    }
    my $spec = +{
      kind => 'type',
      name => $name,
      fields => \%fields,
    };
    $name2type{$name} = $spec;
    push @ast, $spec;
  }
  push @ast, map _type2idinput(
    $_, $name2type{$_}->{fields}, $name2pk21{$_},
    $name2column21{$_},
  ), grep !$name2isview{$_} || keys %{ $name2pk21{$_} }, keys %name2type;
  push @ast, map _type2createinput(
    $_, $name2type{$_}->{fields}, $name2pk21{$_}, $name2fk21{$_},
    $name2column21{$_}, \%name2type,
  ), grep !$name2isview{$_}, keys %name2type;
  push @ast, map _type2searchinput(
    $_, $name2column2rawtype{$_}, $name2pk21{$_},
    $name2column21{$_},
  ), keys %name2type;
  push @ast, map _type2updateinput($_), grep !$name2isview{$_}, keys %name2type;
  push @ast, {
    kind => 'type',
    name => 'Query',
    fields => {
      map {
        my $name = $_;
        my $type = $name2type{$name};
        my $pksearch_name = lcfirst $name;
        my $pksearch_name_plural = to_PL($pksearch_name);
        my $input_search_name = "search$name";
        my @fields = (
          $input_search_name => _make_input_field($name, $name, 'search', 0, 1),
        );
        push @fields, map((
          ($_ ? $pksearch_name_plural : $pksearch_name),
          _make_query_pk_field($name, $type, \%name2pk21, $_),
        ), (0, 1)) if keys %{ $name2pk21{$name} };
        @fields;
      } keys %name2type
    },
  };
  push @ast, {
    kind => 'type',
    name => 'Mutation',
    fields => {
      map {
        my $name = $_;
        my $create_name = "create$name";
        my $update_name = "update$name";
        my $delete_name = "delete$name";
        (
          $create_name => _make_input_field($name, $name, 'create', 1, 1),
          $update_name => _make_input_field($name, $name, 'update', 1, 1),
          $delete_name => _make_input_field($name, 'Boolean', 'ID', 1, 1),
        )
      } grep !$name2isview{$_}, keys %name2type
    },
  };
  +{
    schema => GraphQL::Schema->from_ast(\@ast),
    root_value => $dbic_schema,
    resolver => \&field_resolver,
  };
}

=encoding utf-8

=head1 NAME

GraphQL::Plugin::Convert::DBIC - convert DBIx::Class schema to GraphQL schema

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-DBIC.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-DBIC) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-DBIC.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::DBIC)

=end markdown

=head1 SYNOPSIS

  use GraphQL::Plugin::Convert::DBIC;
  use Schema;
  my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(Schema->connect);
  print $converted->{schema}->to_doc;

=head1 DESCRIPTION

This module implements the L<GraphQL::Plugin::Convert> API to convert
a L<DBIx::Class::Schema> to L<GraphQL::Schema> etc.

Its C<Query> type represents a guess at what fields are suitable, based
on providing a lookup for each type (a L<DBIx::Class::ResultSource>).

=head2 Example

Consider this minimal data model:

  blog:
    id # primary key
    articles # has_many
    title # non null
    language # nullable
  article:
    id # primary key
    blog # foreign key to Blog
    title # non null
    content # nullable

=head2 Generated Output Types

These L<GraphQL::Type::Object> types will be generated:

  type Blog {
    id: Int!
    articles: [Article]
    title: String!
    language: String
  }

  type Article {
    id: Int!
    blog: Blog
    title: String!
    content: String
  }

  type Query {
    blog(id: [Int!]!): [Blog]
    article(id: [Int!]!): [Blog]
  }

Note that while the queries take a list, the return order is
undefined. This also applies to the mutations. If this matters, request
the primary key fields and use those to sort.

=head2 Generated Input Types

Different input types are needed for each of CRUD (Create, Read, Update,
Delete).

The create one needs to have non-null fields be non-null, for idiomatic
GraphQL-level error-catching. The read one needs all fields nullable,
since this will be how searches are implemented, allowing fields to be
left un-searched-for. Both need to omit primary key fields. The read
one also needs to omit foreign key fields, since the idiomatic GraphQL
way for this is to request the other object, with this as a field on it,
then request any required fields of this.

Meanwhile, the update and delete ones need to include the primary key
fields, to indicate what to mutate, and also all non-primary key fields
as nullable, which for update will mean leaving them unchanged, and for
delete is to be ignored. These input types are split into one input
for the primary keys, which is a full input type to allow for multiple
primary keys, then a wrapper input for updates, that takes one ID input,
and a payload that due to the same requirements, is just the search input.

Therefore, for the above, these input types (and an updated Query,
and Mutation) are created:

  input BlogCreateInput {
    title: String!
    language: String
  }

  input BlogSearchInput {
    title: String
    language: String
  }

  input BlogIDInput {
    id: Int!
  }

  input BlogUpdateInput {
    id: BlogIDInput!
    payload: BlogSearchInput!
  }

  input ArticleCreateInput {
    blog_id: Int!
    title: String!
    content: String
  }

  input ArticleSearchInput {
    title: String
    content: String
  }

  input ArticleIDInput {
    id: Int!
  }

  input ArticleUpdateInput {
    id: ArticleIDInput!
    payload: ArticleSearchInput!
  }

  type Mutation {
    createBlog(input: [BlogCreateInput!]!): [Blog]
    createArticle(input: [ArticleCreateInput!]!): [Article]
    deleteBlog(input: [BlogIDInput!]!): [Boolean]
    deleteArticle(input: [ArticleIDInput!]!): [Boolean]
    updateBlog(input: [BlogUpdateInput!]!): [Blog]
    updateArticle(input: [ArticleUpdateInput!]!): [Article]
  }

  extends type Query {
    searchBlog(input: BlogSearchInput!): [Blog]
    searchArticle(input: ArticleSearchInput!): [Article]
  }

=head1 ARGUMENTS

To the C<to_graphql> method: a  L<DBIx::Class::Schema> object.

=head1 PACKAGE FUNCTIONS

=head2 field_resolver

This is available as C<\&GraphQL::Plugin::Convert::DBIC::field_resolver>
in case it is wanted for use outside of the "bundle" of the C<to_graphql>
method.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
