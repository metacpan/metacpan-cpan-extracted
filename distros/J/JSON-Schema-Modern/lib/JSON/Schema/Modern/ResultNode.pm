use strict;
use warnings;
package JSON::Schema::Modern::ResultNode;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Common code for nodes of a JSON::Schema::Modern::Result

our $VERSION = '0.614';

use 5.020;
use Moo::Role;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use Safe::Isa;
use Types::Standard qw(Str Undef InstanceOf);
use Types::Common::Numeric 'PositiveOrZeroInt';
use JSON::Schema::Modern::Utilities 'jsonp';
use namespace::clean;

has [qw(
  instance_location
  keyword_location
)] => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has absolute_keyword_location => (
  is => 'ro',
  isa => InstanceOf['Mojo::URL']|Undef,
  lazy => 1,
  default => sub ($self) {
    # _uri contains data as populated from A() and E():
    # [ $state->{initial_schema_uri}, $state->{schema_path}, @extra_path, $state->{effective_base_uri} ]
    # we do the equivalent of:
    # canonical_uri($state, @extra_path)->to_abs($state->{effective_base_uri});
    if (my $uri_bits = delete $self->{_uri}) {
      my $effective_base_uri = pop @$uri_bits;
      my ($initial_schema_uri, $schema_path, @extra_path) = @$uri_bits;

      return($initial_schema_uri eq '' && $self->{keyword_location} eq '' ? undef : $initial_schema_uri)
        if not @extra_path and not length($schema_path) and not length $effective_base_uri;

      my $uri = $initial_schema_uri->clone;
      my $fragment = ($uri->fragment//'').(@extra_path ? jsonp($schema_path, @extra_path) : $schema_path);
      undef $fragment if not length($fragment);
      $uri->fragment($fragment);

      $uri = $uri->to_abs($effective_base_uri) if length $effective_base_uri;

      undef $uri if $uri eq '' and $self->{keyword_location} eq ''
        or ($uri->fragment // '') eq $self->{keyword_location} and $uri->clone->fragment(undef) eq '';
      return $uri;
    }

    return;
  },
);

has keyword => (
  is => 'ro',
  isa => Str|Undef,
  required => 1,
);

has depth => (
  is => 'ro',
  isa => PositiveOrZeroInt,
  required => 1,
);

# TODO: maybe need to support being passed an already-blessed object

sub BUILD ($self, $args) {
  $self->{_uri} = $args->{_uri} if exists $args->{_uri};
}

sub TO_JSON ($self) {
  my $thing = $self->__thing;  # annotation or error

  return +{
    # note that locations are JSON pointers, not uri fragments!
    instanceLocation => $self->instance_location,
    keywordLocation => $self->keyword_location,
    !defined($self->absolute_keyword_location) ? ()
      : ( absoluteKeywordLocation => $self->absolute_keyword_location->to_string ),
    $thing => $self->$thing,  # TODO: allow localization in error message
  };
}

sub dump ($self) {
  my $encoder = JSON::Schema::Modern::_JSON_BACKEND()->new
    ->utf8(0)
    ->convert_blessed(1)
    ->canonical(1)
    ->indent(1)
    ->space_after(1);
  $encoder->indent_length(2) if $encoder->can('indent_length');
  $encoder->encode($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Modern::ResultNode - Common code for nodes of a JSON::Schema::Modern::Result

=head1 VERSION

version 0.614

=head1 SYNOPSIS

  use Moo;
  with JSON::Schema::Modern::ResultNode;

=head1 DESCRIPTION

This module is for internal use only.

=for Pod::Coverage BUILD TO_JSON absolute_keyword_location depth dump instance_location keyword keyword_location

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Modern/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=for stopwords OpenAPI

You can also find me on the L<JSON Schema Slack server|https://json-schema.slack.com> and L<OpenAPI Slack
server|https://open-api.slack.com>, which are also great resources for finding help.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Some schema files have their own licence, in share/LICENSE.

=cut
