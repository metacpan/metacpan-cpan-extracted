use strict;
use warnings;
package JSON::Schema::Draft201909::Annotation;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Contains a single annotation from a JSON Schema evaluation

our $VERSION = '0.023';

use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use Moo;
use strictures 2;
use MooX::TypeTiny;
use Types::Standard 'Str';
use namespace::clean;

has [qw(
  keyword
  instance_location
  keyword_location
)] => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has absolute_keyword_location => (
  is => 'ro',
  isa => Str, # always a uri (absolute uri or uri reference)
  coerce => sub { "$_[0]" },
);

# https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.7.7.1
has annotation => (
  is => 'ro',
  required => 1,
);

sub TO_JSON {
  my $self = shift;
  return +{
    # note that locations are json pointers, not uri fragments!
    instanceLocation => $self->instance_location,
    keywordLocation => $self->keyword_location,
    !defined($self->absolute_keyword_location) ? ()
      : ( absoluteKeywordLocation => $self->absolute_keyword_location ),
    annotation => $self->annotation,
  };
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords schema fragmentless

=head1 NAME

JSON::Schema::Draft201909::Annotation - Contains a single annotation from a JSON Schema evaluation

=head1 VERSION

version 0.023

=head1 SYNOPSIS

  use JSON::Schema::Draft201909;
  my $js = JSON::Schema::Draft201909->new;
  my $result = $js->evaluate($data, $schema);
  my @annotations = $result->annotations;

  my $value = $annotations[0]->annotation;
  my $instance_location = $annotations[0]->instance_location;

  my $annotations_encoded = encode_json(\@annotations);

=head1 DESCRIPTION

An instance of this class holds one annotation from evaluating a JSON Schema with
L<JSON::Schema::Draft201909>.

=head1 ATTRIBUTES

=head2 keyword

The keyword that produced the annotation.

=head2 instance_location

The path in the instance where the annotation was produced; encoded as per the JSON Pointer
specification (L<RFC 6901|https://tools.ietf.org/html/rfc6901>).

=head2 keyword_location

The schema path taken during evaluation to arrive at the annotation; encoded as per the JSON Pointer
specification (L<RFC 6901|https://tools.ietf.org/html/rfc6901>).

=head2 absolute_keyword_location

The canonical URI or URI reference of the location in the schema where the error occurred; not
defined, if there is no base URI for the schema and no C<$ref> was followed. Note that this is not
actually fragmentless URI in most cases, as the indicated error will occur at a path
below the position where the most recent identifier had been declared in the schema. Further, if the
schema never declared an absolute base URI (containing a scheme), this URI won't be absolute either.

=head2 annotation

The actual annotation value (which may or may not be a string).

=head1 METHODS

=head2 TO_JSON

Returns a data structure suitable for serialization. Corresponds to one output unit as specified in
L<https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.10.4.2> and
L<https://json-schema.org/draft/2019-09/output/schema>, except that C<instanceLocation> and
C<keywordLocation> are json pointers, B<not> URI fragments. (See the
C<strict_basic> L<JSON::Schema::Draft201909/output_format>
if the distinction is important to you.)

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
