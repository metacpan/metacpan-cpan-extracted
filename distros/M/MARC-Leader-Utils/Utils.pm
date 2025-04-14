package MARC::Leader::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(any);
use Scalar::Util qw(blessed);
use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(material_type);

our $VERSION = 0.01;

sub material_type {
	my $leader = shift;

	if (! defined $leader
		|| ! blessed($leader)
		|| ! $leader->isa('Data::MARC::Leader')) {

		err "Leader object must be a Data::MARC::Leader instance.";
	}

	my $material_type;
	if ((any { $leader->type eq $_ } qw(a t))
		&& (any { $leader->bibliographic_level eq $_ } qw(a c d m))) {

		$material_type = 'book';
	} elsif ($leader->type eq 'm') {
		$material_type = 'computer_file';
	} elsif (any { $leader->type eq $_ } qw(e f)) {
		$material_type = 'map';
	} elsif (any { $leader->type eq $_ } qw(c d i j)) {
		$material_type = 'music';
	} elsif ($leader->type eq 'a'
		&& (any { $leader->bibliographic_level eq $_ } qw(b i s))) {

		$material_type = 'continuing_resource';
	} elsif (any { $leader->type eq $_ } qw(g k o r)) {
		$material_type = 'visual_material';
	} elsif ($leader->type eq 'p') {
		$material_type = 'mixed_material';
	} else {
		err "Unsupported material type.";
	}

	return $material_type;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Leader::Utils - Utilities for MARC::Leader.

=head1 SYNOPSIS

 use MARC::Leader::Utils qw(material_type);

 my $material_type = material_type($leader_obj);

=head1 DESCRIPTION

The Perl module with common utilities for work with MARC leader field.

=head1 SUBROUTINES

=head2 C<material_type>

 my $material_type = material_type($leader_obj);

Get material type.
This process is defined in MARC 008 field.

C<$leader_obj> variable is L<Data::MARC::Leader> instace.

Returned strings are:

=over 8

=item * book
=item * computer_file
=item * continuing_resource
=item * map
=item * mixed_material
=item * music
=item * visual_material

=back

Returns string.

=head1 ERRORS

 material_type():
         Leader object must be a Data::MARC::Leader instance.
         Unsupported material type.

=head1 EXAMPLE

=for comment filename=material_type.pl

 use strict;
 use warnings;

 use MARC::Leader;
 use MARC::Leader::Utils qw(material_type);

 if (@ARGV < 1) {
         print STDERR "Usage: $0 leader_string\n";
         exit 1;
 }
 my $leader_string = $ARGV[0];

 my $leader = MARC::Leader->new->parse($leader_string);

 my $material_type = material_type($leader);

 print "Leader: |$leader_string|\n";
 print "Material type: $material_type\n";

 # Output for '     nem a22     2  4500':
 # Leader: |     nem a22     2  4500|
 # Material type: map

=head1 DEPENDENCIES

L<Error::Pure>
L<Exporter>
L<File::Spec::Functions>,
L<File::Share>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Data::MARC::Leader>

Data object for MARC leader.

=item L<MARC::Leader>

MARC leader class.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Leader-Utils>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
