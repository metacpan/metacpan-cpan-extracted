use strict;
use warnings;
package JSON::Schema::Modern::Vocabulary::MetaData;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Implementation of the JSON Schema Meta-Data vocabulary

our $VERSION = '0.587';

use 5.020;
use Moo;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use JSON::Schema::Modern::Utilities qw(assert_keyword_type annotate_self);
use namespace::clean;

with 'JSON::Schema::Modern::Vocabulary';

sub vocabulary {
  'https://json-schema.org/draft/2019-09/vocab/meta-data' => 'draft2019-09',
  'https://json-schema.org/draft/2020-12/vocab/meta-data' => 'draft2020-12';
}

sub evaluation_order { 5 }

sub keywords ($class, $spec_version) {
  return (
    qw(title description default),
    $spec_version ne 'draft7' ? 'deprecated' : (),
    qw(readOnly writeOnly examples),
  );
}

sub _traverse_keyword_title ($class, $schema, $state) {
  return if not assert_keyword_type($state, $schema, 'string');
  return 1;
}

sub _eval_keyword_title ($class, $data, $schema, $state) {
  annotate_self($state, $schema);
}

sub _traverse_keyword_description { goto \&_traverse_keyword_title }

sub _eval_keyword_description { goto \&_eval_keyword_title }

sub _traverse_keyword_default { 1 }

sub _eval_keyword_default { goto \&_eval_keyword_title }

sub _traverse_keyword_deprecated ($class, $schema, $state) {
  return if not assert_keyword_type($state, $schema, 'boolean');
  return 1;
}

sub _eval_keyword_deprecated { goto \&_eval_keyword_title }

sub _traverse_keyword_readOnly { goto \&_traverse_keyword_deprecated }

sub _eval_keyword_readOnly { goto \&_eval_keyword_title }

sub _traverse_keyword_writeOnly { goto \&_traverse_keyword_deprecated }

sub _eval_keyword_writeOnly { goto \&_eval_keyword_title }

sub _traverse_keyword_examples ($class, $schema, $state) {
  return if not assert_keyword_type($state, $schema, 'array');
  return 1;
}

sub _eval_keyword_examples { goto \&_eval_keyword_title }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Modern::Vocabulary::MetaData - Implementation of the JSON Schema Meta-Data vocabulary

=head1 VERSION

version 0.587

=head1 DESCRIPTION

=for Pod::Coverage vocabulary evaluation_order keywords

=for stopwords metaschema

Implementation of the JSON Schema Draft 2020-12 "Meta-Data" vocabulary, indicated in metaschemas
with the URI C<https://json-schema.org/draft/2020-12/vocab/meta-data> and formally specified in
L<https://json-schema.org/draft/2020-12/json-schema-validation.html#section-9>.

Support is also provided for

=over 4

=item *

the equivalent Draft 2019-09 keywords, indicated in metaschemas with the URI C<https://json-schema.org/draft/2019-09/vocab/meta-data> and formally specified in L<https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-validation-02#section-9>.

=item *

the equivalent Draft 7 keywords that correspond to this vocabulary and are formally specified in L<https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-validation-01#section-10>.

=back

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

=cut
