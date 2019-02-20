package GraphQL::Plugin::Convert::DBIC;
use 5.008001;
use strict;
use warnings;
use GraphQL::Schema;
use GraphQL::Debug qw(_debug);
use Lingua::EN::Inflect::Number qw(to_S);
use Carp qw(confess);

our $VERSION = "0.10";
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
  my ($name, $fields, $name2pk21, $fk21, $column21, $name2type) = @_;
  +{
    kind => 'input',
    name => "${name}CreateInput",
    fields => {
      (map { ($_ => $fields->{$_}) }
        grep !$name2pk21->{$name}{$_} && !$fk21->{$_}, keys %$column21),
      _make_fk_fields($name, $fk21, $name2type, $name2pk21),
    },
  };
}

sub _type2searchinput {
  my ($name, $column2rawtype, $name2pk21, $column21, $name2type) = @_;
  +{
    kind => 'input',
    name => "${name}SearchInput",
    fields => {
      (map { ($_ => { type => $column2rawtype->{$_} }) }
        grep !$name2pk21->{$name}{$_}, keys %$column21),
    },
  };
}

sub _type2mutateinput {
  my ($name, $column2rawtype, $fields, $name2pk21, $column21) = @_;
  +{
    kind => 'input',
    name => "${name}MutateInput",
    fields => {
      (map { ($_ => { type => $column2rawtype->{$_} }) }
        grep !$name2pk21->{$name}{$_}, keys %$column21),
      (map { ($_ => $fields->{$_}) }
        grep $name2pk21->{$name}{$_}, keys %$column21),
    },
  };
}

sub _make_fk_fields {
  my ($name, $fk21, $name2type, $name2pk21) = @_;
  my $type = $name2type->{$name};
  (map {
    my $field_type = $type->{fields}{$_}{type};
    if (!$TYPE2SCALAR{_remove_modifiers($field_type)}) {
      my $non_null =
        ref($field_type) eq 'ARRAY' && $field_type->[0] eq 'non_null';
      $field_type = _apply_modifier(
        $non_null && 'non_null', _remove_modifiers($field_type)."MutateInput"
      );
    }
    ($_ => { type => $field_type })
  } keys %$fk21);
}

sub field_resolver {
  my ($root_value, $args, $context, $info) = @_;
  my $field_name = $info->{field_name};
  DEBUG and _debug('DBIC.resolver', $root_value, $field_name, $args);
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
  my ($name, $name2rel21, $field_nodes) = @_;
  grep $name2rel21->{$name}->{$_},
    map $_->{name}, grep $_->{kind} eq 'field', map @{$_->{selections}},
    grep $_->{kind} eq 'field', @$field_nodes;
}

sub _make_update_arg {
  my ($name, $pk21, $input) = @_;
  +{ map { $_ => $input->{$_} } grep !$pk21->{$_}, keys %$input };
}

sub to_graphql {
  my ($class, $dbic_schema_cb) = @_;
  my $dbic_schema = $dbic_schema_cb->();
  my %root_value;
  my @ast;
  my (
    %name2type, %name2column21, %name2pk21, %name2fk21, %name2rel21,
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
      $name2rel21{$name}->{$rel} = 1;
    }
    my $spec = +{
      kind => 'type',
      name => $name,
      fields => \%fields,
    };
    $name2type{$name} = $spec;
    push @ast, $spec;
  }
  push @ast, map _type2createinput(
    $_, $name2type{$_}->{fields}, \%name2pk21, $name2fk21{$_},
    $name2column21{$_}, \%name2type,
  ), grep !$name2isview{$_}, keys %name2type;
  push @ast, map _type2searchinput(
    $_, $name2column2rawtype{$_}, \%name2pk21,
    $name2column21{$_}, \%name2type,
  ), keys %name2type;
  push @ast, map _type2mutateinput(
    $_, $name2column2rawtype{$_}, $name2type{$_}->{fields}, \%name2pk21,
    $name2column21{$_},
  ), grep !$name2isview{$_}, keys %name2type;
  push @ast, {
    kind => 'type',
    name => 'Query',
    fields => {
      map {
        my $name = $_;
        my $type = $name2type{$name};
        my $pksearch_name = lcfirst $name;
        my $input_search_name = "search$name";
        # TODO now only one deep, no handle fragments or abstract types
        $root_value{$pksearch_name} = sub {
          my ($args, $context, $info) = @_;
          my @subfieldrels = _subfieldrels($name, \%name2rel21, $info->{field_nodes});
          DEBUG and _debug('DBIC.root_value', @subfieldrels);
          [
            $dbic_schema_cb->()->resultset($name)->search(
              +{ map { ("me.$_" => $args->{$_}) } keys %$args },
              {
                prefetch => \@subfieldrels,
              },
            )
          ];
        };
        $root_value{$input_search_name} = sub {
          my ($args, $context, $info) = @_;
          my @subfieldrels = _subfieldrels($name, \%name2rel21, $info->{field_nodes});
          DEBUG and _debug('DBIC.root_value', @subfieldrels);
          [
            $dbic_schema_cb->()->resultset($name)->search(
              +{
                map { ("me.$_" => $args->{input}{$_}) } keys %{$args->{input}}
              },
              {
                prefetch => \@subfieldrels,
              },
            )
          ];
        };
        (
          # the PKs query
          keys %{ $name2pk21{$name} } ? ($pksearch_name => {
            type => _apply_modifier('list', $name),
            args => {
              map {
                $_ => {
                  type => _apply_modifier('non_null', _apply_modifier('list',
                    _apply_modifier('non_null', $type->{fields}{$_}{type})
                  ))
                }
              } keys %{ $name2pk21{$name} }
            },
          }) : (),
          $input_search_name => {
            description => 'input to search',
            type => _apply_modifier('list', $name),
            args => {
              input => {
                type => _apply_modifier('non_null', "${name}SearchInput")
              },
            },
          },
        )
      } keys %name2type
    },
  };
  push @ast, {
    kind => 'type',
    name => 'Mutation',
    fields => {
      map {
        my $name = $_;
        my $type = $name2type{$name};
        my $create_name = "create$name";
        $root_value{$create_name} = sub {
          my ($args, $context, $info) = @_;
          my @subfieldrels = _subfieldrels($name, \%name2rel21, $info->{field_nodes});
          DEBUG and _debug("DBIC.root_value($create_name)", $args, \@subfieldrels);
          [
            map $dbic_schema_cb->()->resultset($name)->create(
              $_,
              {
                prefetch => \@subfieldrels,
              },
            ), @{ $args->{input} }
          ];
        };
        my $update_name = "update$name";
        $root_value{$update_name} = sub {
          my ($args, $context, $info) = @_;
          my @subfieldrels = _subfieldrels($name, \%name2rel21, $info->{field_nodes});
          DEBUG and _debug("DBIC.root_value($update_name)", $args, \@subfieldrels);
          [
            map {
              my $input = $_;
              my $row = $dbic_schema_cb->()->resultset($name)->find(
                +{
                  map {
                    my $key = $_;
                    ("me.$key" => $input->{$key})
                  } keys %{$name2pk21{$name}}
                },
                {
                  prefetch => \@subfieldrels,
                },
              );
              $row
                ? $row->update(
                  _make_update_arg($name, $name2pk21{$name}, $input)
                )->discard_changes
                : GraphQL::Error->coerce("$name not found");
            } @{ $args->{input} }
          ];
        };
        my $delete_name = "delete$name";
        $root_value{$delete_name} = sub {
          my ($args, $context, $info) = @_;
          DEBUG and _debug("DBIC.root_value($delete_name)", $args);
          [
            map {
              my $input = $_;
              my $row = $dbic_schema_cb->()->resultset($name)->find(
                +{
                  map {
                    my $key = $_;
                    ("me.$key" => $input->{$key})
                  } keys %{$name2pk21{$name}}
                },
              );
              $row
                ? $row->delete && 1
                : GraphQL::Error->coerce("$name not found");
            } @{ $args->{input} }
          ];
        };
        (
          $create_name => {
            type => _apply_modifier('list', $name),
            args => {
              input => { type => _apply_modifier('non_null',
                _apply_modifier('list',
                  _apply_modifier('non_null', "${name}CreateInput")
                )
              ) },
            },
          },
          $update_name => {
            type => _apply_modifier('list', $name),
            args => {
              input => { type => _apply_modifier('non_null',
                _apply_modifier('list',
                  _apply_modifier('non_null', "${name}MutateInput")
                )
              ) },
            },
          },
          $delete_name => {
            type => _apply_modifier('list', 'Boolean'),
            args => {
              input => { type => _apply_modifier('non_null',
                _apply_modifier('list',
                  _apply_modifier('non_null', "${name}MutateInput")
                )
              ) },
            },
          },
        )
      } grep !$name2isview{$_}, keys %name2type
    },
  };
  +{
    schema => GraphQL::Schema->from_ast(\@ast),
    root_value => \%root_value,
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
  my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(
    sub { Schema->connect }
  );
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
delete is to be ignored.

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

  input BlogMutateInput {
    id: Int!
    title: String
    language: String
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

  input ArticleMutateInput {
    id: Int!
    title: String!
    language: String
  }

  type Mutation {
    createBlog(input: [BlogCreateInput!]!): [Blog]
    createArticle(input: [ArticleCreateInput!]!): [Article]
    deleteBlog(input: [BlogMutateInput!]!): [Boolean]
    deleteArticle(input: [ArticleMutateInput!]!): [Boolean]
    updateBlog(input: [BlogMutateInput!]!): [Blog]
    updateArticle(input: [ArticleMutateInput!]!): [Article]
  }

  extends type Query {
    searchBlog(input: BlogSearchInput!): [Blog]
    searchArticle(input: ArticleSearchInput!): [Article]
  }

=head1 ARGUMENTS

To the C<to_graphql> method: a code-ref returning a L<DBIx::Class::Schema>
object. This is so it can be called during the conversion process,
but also during execution of a long-running process to e.g. execute
database queries, when the database handle passed to this method as a
simple value might have expired.

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
