use strict;
use warnings;
package JSON::Schema::Draft201909::Document;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: One JSON Schema document

our $VERSION = '0.023';

use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use Mojo::URL;
use Carp 'croak';
use List::Util 1.29 'pairs';
use Safe::Isa;
use Moo;
use strictures 2;
use MooX::TypeTiny;
use MooX::HandlesVia;
use Types::Standard qw(InstanceOf HashRef Str Dict ArrayRef);
use namespace::clean;

extends 'Mojo::JSON::Pointer', 'Moo::Object';

has schema => (
  is => 'ro',
  required => 1,
);

has canonical_uri => (
  is => 'rwp',
  isa => InstanceOf['Mojo::URL'], # always fragmentless
  lazy => 1,
  default => sub { Mojo::URL->new },
  coerce => sub { $_[0]->$_isa('Mojo::URL') ? $_[0] : Mojo::URL->new($_[0]) },
  clearer => '_clear_canonical_uri',
);

has resource_index => (
  is => 'bare',
  isa => HashRef[Dict[
      canonical_uri => InstanceOf['Mojo::URL'],
      path => Str,  # always a json pointer, relative to the document root
    ]],
  handles_via => 'Hash',
  handles => {
    resource_index => 'elements',
    resource_pairs => 'kv',
    _add_resources => 'set',
    _get_resource => 'get',
    _remove_resource => 'delete',
  },
  init_arg => undef,
  lazy => 1,
  default => sub { {} },
);

has canonical_uri_index => (
  is => 'bare',
  isa => HashRef[InstanceOf['Mojo::URL']],
  handles_via => 'Hash',
  handles => {
    path_to_canonical_uri => 'get',
    _add_canonical_uri => 'set',
  },
  init_arg => undef,
  lazy => 1,
  default => sub { {} },
);

# for internal use only
has _serialized_schema => (
  is => 'rw',
  isa => Str,
  init_arg => undef,
);

has errors => (
  is => 'bare',
  handles_via => 'Array',
  handles => {
    errors => 'elements',
    has_errors => 'count',
  },
  writer => '_set_errors',
  isa => ArrayRef[InstanceOf['JSON::Schema::Draft201909::Error']],
  lazy => 1,
  default => sub { [] },
);

has evaluation_configs => (
  is => 'rwp',
  isa => HashRef,
  default => sub { {} },
);

around _add_resources => sub {
  my $orig = shift;
  my $self = shift;
  foreach my $pair (pairs @_) {
    my ($key, $value) = @$pair;
    if (my $existing = $self->_get_resource($key)) {
      croak 'uri "'.$key.'" conflicts with an existing schema resource'
        if $existing->{path} ne $value->{path}
          or $existing->{canonical_uri} ne $value->{canonical_uri};
    }

    # this will never happen, if we parsed $id correctly
    croak sprintf('a resource canonical uri cannot contain a plain-name fragment (%s)', $value->{canonical_uri})
      if ($value->{canonical_uri}->fragment // '') =~ m{^[^/]};

    $self->$orig($key, $value);
    $self->_add_canonical_uri($value->{path}, $value->{canonical_uri});
  }
};

# shims for Mojo::JSON::Pointer
sub data { goto \&schema }
sub FOREIGNBUILDARGS { () }

# for JSON serializers
sub TO_JSON { goto \&schema }

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  my $args = $class->$orig(@args);

  # evaluator is only needed for traversal in BUILD; a different evaluator may be used for
  # the actual evaluation.
  croak '_evaluator is not a JSON::Schema::Draft201909'
    if exists $args->{_evaluator} and not $args->{_evaluator}->$_isa('JSON::Schema::Draft201909');

  $args->{_evaluator} //= JSON::Schema::Draft201909->new;
  return $args;
};

sub BUILD {
  my ($self, $args) = @_;

  croak 'canonical_uri cannot contain a fragment' if defined $self->canonical_uri->fragment;

  my $original_uri = $self->canonical_uri->clone;
  my $state = $args->{_evaluator}->traverse($self->schema,
    { canonical_schema_uri => $self->canonical_uri->clone });

  $self->_set_canonical_uri($state->{canonical_schema_uri});

  if (@{$state->{errors}}) {
    $self->_set_errors($state->{errors});
    return;
  }

  # make sure the root schema is always indexed against *something*.
  $self->_add_resources($original_uri => { path => '', canonical_uri => $self->canonical_uri })
    if (not "$original_uri" and $original_uri eq $self->canonical_uri)
      or "$original_uri";

  $self->_add_resources(@{$state->{identifiers}});

  # overlay the resulting configs with those that were provided by the caller
  $self->_set_evaluation_configs(+{ %{$state->{configs}}, %{$self->evaluation_configs} });
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords subschema

=head1 NAME

JSON::Schema::Draft201909::Document - One JSON Schema document

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use JSON::Schema::Draft201909::Document;

    my $document = JSON::Schema::Draft201909::Document->new(
      canonical_uri => 'https://example.com/v1/schema',
      schema => $schema,
    );
    my $foo_definition = $document->get('/$defs/foo');
    my %resource_index = $document->resource_index;

=head1 DESCRIPTION

This class represents one JSON Schema document, to be used by L<JSON::Schema::Draft201909>.

=head1 ATTRIBUTES

=head2 schema

The actual raw data representing the schema.

=head2 canonical_uri

When passed in during construction, this represents the initial URI by which the document should
be known. It is overwritten with the root schema's C<$id> property when one exists, and as such
can be considered the canonical URI for the document as a whole.

=head2 resource_index

An index of URIs to subschemas (json path to reach the location, and the canonical URI of that
location) for all identifiable subschemas found in the document. An entry for URI C<''> is added
only when no other suitable identifier can be found for the root schema.

This attribute should only be used by L<JSON::Schema::Draft201909> and not intended for use
externally (you should use the public accessors in L<JSON::Schema::Draft201909> instead).

When called as a method, returns the flattened list of tuples (path, uri). You can also use
C<resource_pairs> which returns a list of tuples as arrayrefs.

=head2 canonical_uri_index

An index of json paths (from the document root) to canonical URIs. This is the inversion of
L</resource_index> and is constructed as that is built up.

=head2 errors

A list of L<JSON::Schema::Draft201909::Error> objects that resulted when the schema document was
originally parsed. (If a syntax error occurred, usually there will be just one error, as parse
errors halt the parsing process.) Documents with errors cannot be evaluated.

=head2 evaluation_configs

An optional hashref of configuration values that will be provided to the evaluator during
evaluation of this document. See the third parameter of L<JSON::Schema::Draft201909/evaluate>.
This should never need to be set explicitly. This is sometimes populated automatically after
creating a document object, depending on the keywords found in the schema, but they will never
override anything you have already explicitly set.

=head1 METHODS

=for Pod::Coverage FOREIGNBUILDARGS BUILDARGS BUILD

=head2 path_to_canonical_uri

=for stopwords fragmentless

Given a JSON path within this document, returns the canonical URI corresponding to that location.
Only fragmentless URIs can be looked up in this manner, so it is only suitable for finding the
canonical URI corresponding to a subschema known to have an C<$id> keyword.

=head2 contains

Check if L</"schema"> contains a value that can be identified with the given JSON Pointer.
See L<Mojo::JSON::Pointer/contains>.

=head2 get

Extract value from L</"schema"> identified by the given JSON Pointer.
See L<Mojo::JSON::Pointer/get>.

=head2 TO_JSON

Returns a data structure suitable for serialization. See L</schema>.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Draft201909/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.freenode.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
