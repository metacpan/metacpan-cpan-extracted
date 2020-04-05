package Dicom::File::Detect;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(dicom_detect_file);
Readonly::Scalar our $DCM_MAGIC => qw{DICM};

our $VERSION = 0.04;

# Detect DICOM file.
sub dicom_detect_file {
	my $file = shift;

	my $dcm_flag = 0;
	open my $fh, '<', $file or err "Cannot open file '$file'.";
	my $seek = seek $fh, 128, 0;
	my $magic;
	my $read = read $fh, $magic, 4;
	close $fh or err "Cannot close file '$file'.";

	if ($magic eq $DCM_MAGIC) {
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

Dicom::File::Detect - Detect DICOM file through magic string.

=head1 SYNOPSIS

 use Dicom::File::Detect qw(dicom_detect_file);

 my $dcm_flag = dicom_detect_file($file);

=head1 DESCRIPTION

This Perl module detect DICOM file through magic string.
DICOM (Digital Imaging and Communications in Medicine) is a standard for
handling, storing, printing, and transmitting information in medical imaging.
See L<DICOM on Wikipedia|https://en.wikipedia.org/wiki/DICOM>.

=head1 SUBROUTINES

=head2 C<dicom_detect_file>

 my $dcm_flag = dicom_detect_file($file);

Detect DICOM file.

Returns 1/0.

=head1 ERRORS

 dicom_detect_file():
         Cannot close file '%s'.
         Cannot open file '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Dicom::File::Detect qw(dicom_detect_file);
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);
 use MIME::Base64;

 # Data in base64.
 my $data = <<'END';
 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 AAAAAAAAAAAAAAAAAABESUNNCg==
 END

 # Temp file.
 my (undef, $temp_file) = tempfile();

 # Save data to file.
 barf($temp_file, decode_base64($data));

 # Check file.
 my $dcm_flag = dicom_detect_file($temp_file);

 # Print out.
 if ($dcm_flag) {
         print "File '$temp_file' is DICOM file.\n";
 } else {
         print "File '$temp_file' isn't DICOM file.\n";
 }

 # Output like:
 # File '%s' is DICOM file.

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Dicom::File::Detect qw(dicom_detect_file);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 file\n";
         exit 1;
 }
 my $file = $ARGV[0];

 # Check file.
 my $dcm_flag = dicom_detect_file($file);

 # Print out.
 if ($dcm_flag) {
         print "File '$file' is DICOM file.\n";
 } else {
         print "File '$file' isn't DICOM file.\n";
 }

 # Output:
 # Usage: dicom-detect-file file

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<File::Find::Rule::Dicom>

Common rules for searching for DICOM things.

=item L<Task::Dicom>

Install the Dicom modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Dicom-File-Detect>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
