use strict;
use warnings;
package JSON::Schema::Draft201909::Vocabulary::Format;
# vim: set ts=8 sts=2 sw=2 tw=100 et :

our $VERSION = '0.017';

use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
use JSON::Schema::Draft201909::Utilities qw(is_type E A assert_keyword_type);
use Moo;
use strictures 2;
use namespace::clean;

with 'JSON::Schema::Draft201909::Vocabulary';

sub vocabulary { 'https://json-schema.org/draft/2019-09/vocab/format' }

sub keywords {
  qw(format);
}

sub _traverse_keyword_format {
  my ($self, $schema, $state) = @_;
  return if not assert_keyword_type($state, $schema, 'string');
}

sub _eval_keyword_format {
  my ($self, $data, $schema, $state) = @_;

  return if not assert_keyword_type($state, $schema, 'string');

  # TODO: instead of checking 'validate_formats', we should be referring to the metaschema's entry
  # for $vocabulary: { <format url>: <bool> }
  if ($state->{validate_formats}
      and my $spec = $self->evaluator->_get_format_validation($schema->{format})) {
    return E($state, 'not a%s %s', $schema->{format} =~ /^[aeio]/ ? 'n' : '', $schema->{format})
      if is_type($spec->{type}, $data) and not $spec->{sub}->($data);
  }

  return A($state, $schema->{format});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Draft201909::Vocabulary::Format

=head1 VERSION

version 0.017

=head1 SYNOPSIS

=for Pod::Coverage vocabulary keywords

=for stopwords metaschema

Implementation of the JSON Schema Draft 2019-09 "format" vocabulary, indicated in metaschemas
with the URI C<https://json-schema.org/draft/2019-09/vocab/format> and formally specified in
L<https://json-schema.org/draft/2019-09/json-schema-validation.html#rfc.section.7>.

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
