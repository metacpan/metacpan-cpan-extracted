package ELF::Writer::Linux_x86;
use Moo 2;
use namespace::clean;
extends 'ELF::Writer';

# ABSTRACT: ELF::Writer with defaults for Linux on x86


has '+class'    => ( default => sub { 1 } );
has '+data'     => ( default => sub { 1 } );
has '+osabi'    => ( default => sub { 3 } );
has '+machine'  => ( default => sub { 0x3 } );


sub _apply_segment_defaults {
	my ($self, $seg)= @_;
	$seg->align(4096) unless $seg->align;
	$self->SUPER::_apply_segment_defaults($seg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Writer::Linux_x86 - ELF::Writer with defaults for Linux on x86

=head1 VERSION

version 0.011

=head1 DESCRPTION

This module is the same as L<ELF::Writer>, but supplies the following defaults
when constructed:

=head2 ELF attributes

=over 16

=item class

C<"32-bit">

=item data

C<"little-endian">

=item osabi

C<"Linux">

=item machine

C<"i386">

=back

=head2 Segment attributes

=over 16

=item align

4096

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
