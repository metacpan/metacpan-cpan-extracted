use strict;
use warnings;
package JSON::Schema::Modern::Vocabulary::FormatAnnotation;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Implementation of the JSON Schema Format-Annotation vocabulary

our $VERSION = '0.544';

use 5.020;
use Moo;
use strictures 2;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use JSON::Schema::Modern::Utilities qw(is_type E A assert_keyword_type);
use Feature::Compat::Try;
use namespace::clean;

with 'JSON::Schema::Modern::Vocabulary';

sub vocabulary {
  'https://json-schema.org/draft/2019-09/vocab/format' => 'draft2019-09',
  'https://json-schema.org/draft/2020-12/vocab/format-annotation' => 'draft2020-12';
}

sub evaluation_order { 3 }

sub keywords {
  qw(format);
}

sub _traverse_keyword_format ($self, $schema, $state) {
  return if not assert_keyword_type($state, $schema, 'string');
  return 1;
}

sub _eval_keyword_format ($self, $data, $schema, $state) {
  return A($state, $schema->{format});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Modern::Vocabulary::FormatAnnotation - Implementation of the JSON Schema Format-Annotation vocabulary

=head1 VERSION

version 0.544

=head1 DESCRIPTION

=for Pod::Coverage vocabulary evaluation_order keywords

=for stopwords metaschema

Implementation of the JSON Schema Draft 2020-12 "Format-Annotation" vocabulary, indicated in metaschemas
with the URI C<https://json-schema.org/draft/2020-12/vocab/format-annotation> and formally specified in
L<https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-00#section-7>.

Support is also provided for

=over 4

=item *

the equivalent Draft 2019-09 keyword, indicated in metaschemas with the URI C<https://json-schema.org/draft/2019-09/vocab/format> and formally specified in L<https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-validation-02#section-7>.

=item *

the equivalent Draft 7 keyword, as formally specified in L<https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-validation-01#section-7>.

=back

=head1 SEE ALSO

=over 4

=item *

L<JSON::Schema::Modern/Format Validation>

=back

=for stopwords OpenAPI

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Modern/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

You can also find me on the L<JSON Schema Slack server|https://json-schema.slack.com> and L<OpenAPI Slack
server|https://open-api.slack.com>, which are also great resources for finding help.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
