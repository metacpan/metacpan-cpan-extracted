use 5.006;
use strict;
use warnings;

package ELF::Extract::Sections::Meta::Scanner;

# ABSTRACT: Interface Contract for Scanners

our $VERSION = '1.001000';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( with requires );
with 'MooseX::Log::Log4perl';

requires 'open_file';
requires 'next_section';
requires 'section_offset';
requires 'section_size';
requires 'section_name';
requires 'can_compute_size';

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Extract::Sections::Meta::Scanner - Interface Contract for Scanners

=head1 VERSION

version 1.001000

=head1 Required Methods for Applying Roles

=head2 C<open_file>

  my $file = $scanner->open_file( file => FILE )

Must take a file name and assume a state reset.

=head2 C<next_section>

  my $boolean = $scanner->next_section

Must return true if a section was discovered.
Must return false otherwise.
This method is called before getting data out.

=head2 C<section_offset>

  my $offset = $scanner->section_offset;

Returns the offset as an Integer

=head2 C<section_size>

  my $size = $scanner->section_size;

Returns the sections computed size ( if possible )
If you can't compute the size, please call $self->log->logcroak()

=head2 C<section_name>

  my $name = $scanner->section_name;

Returns the sections name

=head2 C<can_compute_size>

  my $boolean = $scanner->can_compute_size;

This returns whether or not this code is capable of discerning section sizes on its own.
return 1 if true, return C<undef> otherwise.

This will make us try guessing how big sections are by sorting them.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
