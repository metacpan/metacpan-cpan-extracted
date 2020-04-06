package File::Find::Rule::DWG;

use base qw(File::Find::Rule);
use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);

our $VERSION = 0.01;

# Detect DWG.
sub File::Find::Rule::dwg {
	my $file_find_rule = shift;
	my $self = $file_find_rule->_force_object;
	return $self->file->exec(sub{
		my $file = shift;
		return detect_dwg_file($file);
	});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

File::Find::Rule::DWG - Common rules for searching DWG files.

=head1 SYNOPSIS

 use File::Find::Rule;
 use File::Find::Rule::DWG;

 my @files = File::Find::Rule->dwg->in($dir);

=head1 DESCRIPTION

This Perl module contains File::Find::Rule rules for detecting DWG files.

See L<.dwg on Wikipedia|https://en.wikipedia.org/wiki/.dwg>.

=head1 SUBROUTINES

=head2 C<dwg>

 my @files = File::Find::Rule->dwg->in($dir);

The C<dwg()> rule detect DWG files.

=head1 EXAMPLE

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::DWG;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 dir\n";
         exit 1;
 }
 my $dir = $ARGV[0];

 # Print all DWG files in directory.
 foreach my $file (File::Find::Rule->dwg->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 DEPENDENCIES

L<CAD::AutoCAD::Detect>,
L<File::Find::Rule>.

=head1 SEE ALSO

=over

=item L<File::Find::Rule>

Alternative interface to File::Find.

=item L<CAD::AutoCAD::Version>

Class which work with AutoCAD versions.

=item L<CAD::AutoCAD::Detect>

Detect AutoCAD files through magic string.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/File-Find-Rule-DWG>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.01

=cut
