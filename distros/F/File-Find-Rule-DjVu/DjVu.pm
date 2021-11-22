package File::Find::Rule::DjVu;

use base qw(File::Find::Rule);
use strict;
use warnings;

use DjVu::Detect qw(detect_djvu_chunk detect_djvu_file);

our $VERSION = 0.01;

sub File::Find::Rule::djvu {
	my $file_find_rule = shift;
	my $self = $file_find_rule->_force_object;
	return $self->file->exec(sub{
		my $file = shift;
		return detect_djvu_file($file);
	});
}

sub File::Find::Rule::djvu_chunk {
	my ($file_find_rule, $djvu_chunk) = @_;
	my $self = $file_find_rule->_force_object;
	return $self->file->exec(sub{
		my $file = shift;
		if (detect_djvu_file($file) && detect_djvu_chunk($file, $djvu_chunk)) {
			return 1;
		} else {
			return 0;
		}
	});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

File::Find::Rule::DjVu - Common rules for searching DjVu files.

=head1 SYNOPSIS

 use File::Find::Rule;
 use File::Find::Rule::DjVu;

 my @files = File::Find::Rule->djvu->in($dir);
 my @files = File::Find::Rule->djvu_chunk($chunk_name)->in($dir);

=head1 DESCRIPTION

This Perl module contains File::Find::Rule rules for detecting DjVu files.

See L<DjVu on Wikipedia|https://en.wikipedia.org/wiki/DjVu>.

This rule provides functionality for findrule script in directory with djvu
files in ways:

 findrule -djvu

 findrule -djvu_chunk INFO

=head1 SUBROUTINES

=head2 C<djvu>

 my @files = File::Find::Rule->djvu->in($dir);

The C<djvu> rule detect DjVu files.

=head2 C<djvu_chunk>

 my @files = File::Find::Rule->djvu_chunk($chunk_name)->in($dir);

The C<djvu_chunk($chunk_name)> rule detect DjVu files with chunk name (e.g. INFO).

=head1 EXAMPLE1

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::DjVu;

 # Arguments.
 if (@ARGV < 2) {
         print STDERR "Usage: $0 dir djvu_chunk\n";
         exit 1;
 }
 my $dir = $ARGV[0];
 my $djvu_chunk = $ARGV[1];

 # Print all DjVu files in directory with chunk.
 foreach my $file (File::Find::Rule->djvu_chunk($djvu_chunk)->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 EXAMPLE2

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::DjVu;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 dir\n";
         exit 1;
 }
 my $dir = $ARGV[0];

 # Print all DjVu files in directory.
 foreach my $file (File::Find::Rule->djvu->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 DEPENDENCIES

L<DjVu::Detect>,
L<File::Find::Rule>.

=head1 SEE ALSO

=over

=item L<DjVu::Detect>

Detect DjVu files.

=item L<File::Find::Rule>

Alternative interface to File::Find.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/File-Find-Rule-DjVu>

=head1 TEST FILES

Test file 11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu is generated from scanned
book edition from L<http://www.digitalniknihovna.cz/mzk/view/uuid:814e66a0-b6df-11e6-88f6-005056827e52?page=uuid:11a7ffc0-c61e-11e6-ac1c-001018b5eb5c>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021

BSD 2-Clause License

=head1 VERSION

0.01

=cut
