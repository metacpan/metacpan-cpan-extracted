use strict;
use warnings;
package JSON::Schema::Types; # git description: f55a51a
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Create Type::Tiny types defined by JSON Schemas
# KEYWORDS: JSON Schema types

our $VERSION = '0.001';

use 5.020;
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

sub new ($class) {
  die 'not yet implemented';
}

sub json_schema_type ($class) {
  die 'not yet implemented';
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords schema subschema

=head1 NAME

JSON::Schema::Types - Create Type::Tiny types defined by JSON Schemas

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use JSON::Schema::Types ':all';

  my $my_type = json_schema_type({
    type => 'object',
    properties => {
      foo => { type => 'integer' },
      bar => { type => 'string' },
    }
  });

  my $second_type = JSON::Schema::Types->new(
    validate_formats => 0,
    schema => false,
  );

  # prints 'data is valid'
  say 'data is ', $my_type->check({ foo => 1, bar => 'hello' }) ? 'valid' : 'invalid';

  # prints 'data is invalid'
  say 'data is ', $second_type->check(1) ? 'valid' : 'invalid' ? 'valid' : 'invalid';

=head1 DESCRIPTION

Generates L<Type::Tiny> types for you that use a JSON Schema to validate the data.

=head1 FUNCTIONS/METHODS

=head2 json_schema_type

Creates a type value for you using the provided schema. No custom behaviour is available.

=head2 new

Creates a type value for you, with customization options. Options available are:

=over 4

=item *

schema: Required. Contains the JSON Schema to use.

=item *

max_traversal_depth: Optional. more later.

=item *

scalarref_booleans: Optional. more later.

=item *

short_circuit: Optional. Whenever possible, each subschema will end evaluation as soon as a true or false result can be determined. When enabled, This obviously does not affect the overall valid/invalid result, but the error list will be incomplete.

=item *

specification_version: Optional. Defaults to the latest release version of the JSON Schema specification, currently C<draft2020-12>.

=item *

stringy_numbers: Optional. more later.

=item *

validate_formats: Optional. Enables or disables format validation. Defaults to C<true>.

=back

=head1 SEE ALSO

=over 4

=item *

L<https://json-schema.org>

=item *

L<Understanding JSON Schema|https://json-schema.org/understanding-json-schema>: tutorial-focused documentation

=item *

L<JSON::Schema::Modern>

=item *

L<JSON::Schema::Tiny>

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Types/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
