package DjVu::Detect;

use base qw(Exporter);
use strict;
use warnings;

use Alien::DjVuLibre;
use Error::Pure qw(err);
use File::Spec::Functions qw(catfile);

Readonly::Array our @EXPORT_OK => qw(detect_djvu_chunk detect_djvu_file);

our $VERSION = 0.05;

sub detect_djvu_chunk {
	my ($file, $chunk_name) = @_;

	my $djvudump = catfile(Alien::DjVuLibre->bin_dir, 'djvudump');
	if (! -e $djvudump) {
		err "Program 'djvudump' doesn't exists.";
	}

	my $djvudump_output = `$djvudump $file`;

	if ($djvudump_output =~ m/$chunk_name/ms) {
		return 1;
	} else {
		return 0;
	}
}

# Detect DjVu file.
sub detect_djvu_file {
	my $file = shift;

	my $dwg_flag = 0;
	open my $fh, '<', $file or err "Cannot open file '$file'.";
	my $magic;
	my $read = read $fh, $magic, 8;
	close $fh or err "Cannot close file '$file'.";

	if ($read == 8 && $magic eq 'AT&TFORM') {
		return 1;
	} else {
		return 0;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

DjVu::Detect - Detect DjVu files.

=head1 SYNOPSIS

 use DjVu::Detect qw(detect_djvu_file detect_djvu_chunk);

 my $has_djvu_chunk = detect_djvu_chunk($file, $chunk_name);
 my $is_djvu = detect_djvu_file($file);

=head1 DESCRIPTION

This Perl module detect DjVu files through magic string and detect if DjVu file
has chunk type.

List of supported files: djvu

=head1 SUBROUTINES

=head2 C<detect_djvu_chunk>

 my $has_djvu_chunk = detect_djvu_chunk($file, $chunk_name);

Detect if DjVu file contain DjVu chunk.

Returns 1/0.

=head2 C<detect_djvu_file>

 my $is_djvu = detect_djvu_file($file);

Detect if file is DjVu file by magic string of IFF and first 'FORM' chunk.

Returns 1/0.

=head1 ERRORS

 detect_djvu_chunk():
         Program 'djvudump' doesn't exists.

 detect_dwg_file():
         Cannot close file '%s'.
         Cannot open file '%s'.

=head1 EXAMPLE1

=for comment filename=detect_djvu_file_on_djvu.pl

 use strict;
 use warnings;

 use DjVu::Detect qw(detect_djvu_file);
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);
 use MIME::Base64;

 # Data in base64.
 my $data = <<'END';
 QVQmVEZPUk0=
 END

 # Temp file.
 my (undef, $temp_file) = tempfile();

 # Save data to file.
 barf($temp_file, decode_base64($data));

 # Check file.
 my $is_djvu = detect_djvu_file($temp_file);

 # Print out.
 if ($is_djvu) {
         print "File '$temp_file' is DjVu file.\n";
 } else {
         print "File '$temp_file' isn't DjVu file.\n";
 }

 # Output like:
 # File '%s' is DjVu file.

=head1 EXAMPLE2

=for comment filename=detect_djvu_file.pl

 use strict;
 use warnings;

 use DjVu::Detect qw(detect_djvu_file);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 file\n";
         exit 1;
 }
 my $file = $ARGV[0];

 # Check DjVu file.
 my $is_djvu = detect_djvu_file($file);

 # Print out.
 if ($is_djvu) {
         print "File '$file' is DjVu file.\n";
 } else {
         print "File '$file' isn't Djvu file.\n";
 }

 # Output:
 # Usage: __SCRIPT__ file

=head1 DEPENDENCIES

L<Alien::DjVuLibre>,
L<Error::Pure>,
L<Exporter>,
L<File::Spec::Functions>.

=head1 SEE ALSO

=over

=item L<File::Find::Rule::DjVu>

Common rules for searching DjVu files.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/DjVu-Detect>

=head1 TEST FILES

Test file 11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu is generated from scanned
book edition from L<http://www.digitalniknihovna.cz/mzk/view/uuid:814e66a0-b6df-11e6-88f6-005056827e52?page=uuid:11a7ffc0-c61e-11e6-ac1c-001018b5eb5c>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
