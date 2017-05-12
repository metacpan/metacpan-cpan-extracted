use 5.006;
use strict;
use warnings;

package ELF::Extract::Sections::Meta::Types;

# ABSTRACT: Generic Type Constraints for E:E:S

our $VERSION = '1.001000';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use MooseX::Types::Moose (qw( Object ));
use MooseX::Types -declare => [ 'FilterField', 'ElfSection' ];

## no critic (ProhibitCallsToUndeclaredSubs)
subtype FilterField, as enum( [ 'name', 'offset', 'size', ] );

subtype ElfSection, as Object, where { $_->isa('ELF::Extract::Sections::Section') };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Extract::Sections::Meta::Types - Generic Type Constraints for E:E:S

=head1 VERSION

version 1.001000

=head1 Types

=head2 C<FilterField>

ENUM: name, offset, size

=head2 C<ElfSection>

An object that is a ELF::Extract::Sections::Section

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
