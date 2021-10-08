use strict;
use warnings;
package JSON::Schema::Draft201909; # git description: v0.129-5-g0e1dd16
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: (DEPRECATED) Validate data against a schema
# KEYWORDS: JSON Schema data validation structure specification

our $VERSION = '0.130';

use 5.016;  # for fc, unicode_strings features
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use strictures 2;
use Moo;
use namespace::clean;

extends 'JSON::Schema::Modern';

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  return $class->$orig(
    @args == 1 && ref $args[0] eq 'HASH' ? %{$args[0]} : @args,
    specification_version => 'draft2019-09',
  );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Draft201909 - (DEPRECATED) Validate data against a schema

=head1 VERSION

version 0.130

=head1 DESCRIPTION

This module is deprecated in favour of L<JSON::Schema::Modern>. It is a simple subclass of that module,
adding C<< specification_version => 'draft2019-09' >> to the constructor call to allow existing code
to continue to work.

=for Pod::Coverage BUILDARGS

=head1 SEE ALSO

=over 4

=item *

L<JSON::Schema::Modern>

=item *

L<https://json-schema.org>

=item *

L<RFC8259: The JavaScript Object Notation (JSON) Data Interchange Format|https://tools.ietf.org/html/rfc8259>

=item *

L<RFC3986: Uniform Resource Identifier (URI): Generic Syntax|https://tools.ietf.org/html/rfc3986>

=item *

L<Test::JSON::Schema::Acceptance>: contains the official JSON Schema test suite

=item *

L<JSON::Schema::Tiny>: a more minimal implementation of the specification, with fewer dependencies

=item *

L<https://json-schema.org/draft/2019-09/release-notes.html>

=item *

L<Understanding JSON Schema|https://json-schema.org/understanding-json-schema>: tutorial-focused documentation

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/JSON-Schema-Draft201909/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
