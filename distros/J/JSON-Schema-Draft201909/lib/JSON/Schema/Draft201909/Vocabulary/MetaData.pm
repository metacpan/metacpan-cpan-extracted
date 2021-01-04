use strict;
use warnings;
package JSON::Schema::Draft201909::Vocabulary::MetaData;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Implementation of the JSON Schema Draft 2019-09 Meta-Data vocabulary

our $VERSION = '0.020';

use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
use JSON::Schema::Draft201909::Utilities qw(assert_keyword_type annotate_self);
use Moo;
use strictures 2;
use namespace::clean;

with 'JSON::Schema::Draft201909::Vocabulary';

sub vocabulary { 'https://json-schema.org/draft/2019-09/vocab/meta-data' }

sub keywords {
  qw(title description default deprecated readOnly writeOnly examples);
}

sub _traverse_keyword_title {
  my ($self, $schema, $state) = @_;
  return if not assert_keyword_type($state, $schema, 'string');
}

sub _eval_keyword_title {
  my ($self, $data, $schema, $state) = @_;
  annotate_self($state, $schema);
}

sub _traverse_keyword_description { goto \&_traverse_keyword_title }

sub _eval_keyword_description { goto \&_eval_keyword_title }

sub _eval_keyword_default { goto \&_eval_keyword_title }

sub _traverse_keyword_deprecated {
  my ($self, $schema, $state) = @_;
  return if not assert_keyword_type($state, $schema, 'boolean');
}

sub _eval_keyword_deprecated { goto \&_eval_keyword_title }

sub _traverse_keyword_readOnly { goto \&_traverse_keyword_deprecated }

sub _eval_keyword_readOnly { goto \&_eval_keyword_title }

sub _traverse_keyword_writeOnly { goto \&_traverse_keyword_deprecated }

sub _eval_keyword_writeOnly { goto \&_eval_keyword_title }

sub _traverse_keyword_examples {
  my ($self, $schema, $state) = @_;
  return if not assert_keyword_type($state, $schema, 'array');
}

sub _eval_keyword_examples { goto \&_eval_keyword_title }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Draft201909::Vocabulary::MetaData - Implementation of the JSON Schema Draft 2019-09 Meta-Data vocabulary

=head1 VERSION

version 0.020

=head1 DESCRIPTION

=for Pod::Coverage vocabulary keywords

=for stopwords metaschema

Implementation of the JSON Schema Draft 2019-09 "Meta-Data" vocabulary, indicated in metaschemas
with the URI C<https://json-schema.org/draft/2019-09/vocab/meta-data> and formally specified in
L<https://json-schema.org/draft/2019-09/json-schema-validation.html#rfc.section.9>.

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
