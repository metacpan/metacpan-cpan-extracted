use strict;
use warnings;
package JSON::Schema::Draft201909::Vocabulary::Validation;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: (DEPRECATED) Implementation of the JSON Schema Draft 2019-09 Validation vocabulary

our $VERSION = '0.129';

use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use strictures 2;
use Moo;
use namespace::clean;

extends 'JSON::Schema::Modern::Vocabulary::Validation';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Draft201909::Vocabulary::Validation - (DEPRECATED) Implementation of the JSON Schema Draft 2019-09 Validation vocabulary

=head1 VERSION

version 0.129

=head1 DESCRIPTION

This module is deprecated in favour of L<JSON::Schema::Modern::Vocabulary::Validation>.

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
