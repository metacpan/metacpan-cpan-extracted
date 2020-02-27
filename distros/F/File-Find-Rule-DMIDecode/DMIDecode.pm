package File::Find::Rule::DMIDecode;

use base qw(File::Find::Rule);
use strict;
use warnings;

use List::MoreUtils qw(any);
use Parse::DMIDecode;
use Perl6::Slurp;

our $VERSION = 0.03;

# Detect dmidecode file.
sub File::Find::Rule::dmidecode_file {
	my $file_find_rule = shift;
	my $self = $file_find_rule->_force_object;
	return $self->file->exec(sub{
		my $file = shift;

		my $data = slurp($file);
		my $dmidecode = Parse::DMIDecode->new;
		$dmidecode->parse($data);

		return $dmidecode->dmidecode_version ? 1 : 0;
	});
}

sub File::Find::Rule::dmidecode_handle {
	my ($file_find_rule, $handle) = @_;
	my $self = $file_find_rule->_force_object;
	return $self->file->exec(sub{
		my $file = shift;

		my $data = slurp($file);
		my $dmidecode = Parse::DMIDecode->new;
		$dmidecode->parse($data);

		return any { $_->handle eq $handle } $dmidecode->get_handles;
	});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

File::Find::Rule::DMIDecode - Common rules for searching for dmidecode files.

=head1 SYNOPSIS

 use File::Find::Rule;
 use File::Find::Rule::DMIDecode;

 my @files = File::Find::Rule->dmidecode_file->in($dir);
 my @files = File::Find::Rule->dmidecode_handle($handle)->in($dir);

=head1 DESCRIPTION

This Perl module contains File::Find::Rule rules for detecting dmidecode files.

dmidecode text file is output of dmidecode tool, which prints information about
DMI.

DMI (Desktop Management Interface) generates a standard framework for managing
and tracking components in a desktop, notebook or server computer, by
abstracting these components from the software that manages them.
See L<DMI on Wikipedia|https://en.wikipedia.org/wiki/Desktop_Management_Interface>.

=head1 SUBROUTINES

=head2 C<dmidecode_file>

 my @files = File::Find::Rule->dmidecode_file->in($dir);

The C<dmidecode_file()> rule detect dmidecode files by parsing of structure.

=head2 C<dmidecode_handle>

 my @files = File::Find::Rule->dmidecode_handle($handle)->in($dir);

The C<dmidecode_handle($handle)> rule detect dmidecode handle in file.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::DMIDecode;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 dir\n";
         exit 1;
 }
 my $dir = $ARGV[0];

 # Print all dmidecode files in directory.
 foreach my $file (File::Find::Rule->dmidecode_file->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 EXAMPLE2

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::DMIDecode;

 # Arguments.
 if (@ARGV < 2) {
         print STDERR "Usage: $0 dir handle\n";
         exit 1;
 }
 my $dir = $ARGV[0];
 my $handle = $ARGV[1];

 # Print all dmidecode handles in directory.
 foreach my $file (File::Find::Rule->dmidecode_handle($handle)->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 DEPENDENCIES

L<File::Find::Rule>,
L<List::MoreUtils>,
L<Parse::DMIDecode>,
L<Perl6::Slurp>.

=head1 SEE ALSO

=over

=item L<File::Find::Rule>

Alternative interface to File::Find

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/File-Find-Rule-DMIDecode>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.03

=cut
