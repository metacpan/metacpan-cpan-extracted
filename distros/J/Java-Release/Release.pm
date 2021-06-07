package Java::Release;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Java::Release::Obj;
use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(parse_java_jdk_release);

our $VERSION = 0.06;

# Parse Java JDK release.
sub parse_java_jdk_release {
	my $release_name = shift;

	my $obj;

	# j2sdk-1_3_1_20-linux-i586.bin
	if ($release_name =~ m/^j2sdk-([0-9]+)_([0-9]+)_([0-9]+)_([0-9]+)-(linux)-(i586).bin$/ms) {
		$obj = Java::Release::Obj->new(
			arch => $6,
			interim => $3,
			os => $5,
			release => $2,
			update => $4,
		);

	# jdk-8u151-linux-i586.tar.gz
	} elsif ($release_name =~ m/^jdk-([0-9]+)(u([0-9]+))?-(linux)-(i586|x64|amd64|arm-vfp-hflt|arm32-vfp-hflt|arm64-vfp-hflt)\.(bin|tar\.gz)$/ms) {
		$obj = Java::Release::Obj->new(
			arch => $5,
			os => $4,
			release => $1,
			update => $3,
		);

	# jdk-13.0.2_linux-x64_bin.tar.gz
	} elsif ($release_name =~ m/^jdk-([0-9]+)(\.([0-9]+))?(\.([0-9]+))?(\.([0-9]+))?_(linux)-(i586|x64|amd64|arm-vfp-hflt|arm32-vfp-hflt|arm64-vfp-hflt)_bin.tar.gz$/ms) {
		$obj = Java::Release::Obj->new(
			arch => $9,
			interim => $3,
			os => $8,
			patch => $7,
			release => $1,
			update => $5,
		);
	} else {
		err "Unsupported release.",
			'release_name', $release_name;
	}

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Java::Release - Parse Java release archive.

=head1 SYNOPSIS

 use Java::Release qw(parse_java_jdk_release);

 my $release_hr = parse_java_jdk_release($file);

=head1 SUBROUTINES

=head2 C<parse_java_jdk_release>

 my $release_hr = parse_java_jdk_release($file);

Parse Java JDK release name.

Returns reference to hash with information about release.

=head1 ERRORS

 parse_java_jdk_release():
         Unsupported release.
                 release_name: %s

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Printer;
 use Java::Release qw(parse_java_jdk_release);

 if (@ARGV < 1) {
        print STDERR "Usage: $0 java_jdk_release\n";
        exit 1;
 }
 my $java_jdk_release = $ARGV[0];

 # Parse Java JDK release name.
 my $release_hr = parse_java_jdk_release($java_jdk_release);

 p $release_hr;

 # Output like:
 # Usage: qr{\w+} java_jdk_release

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Java-Release>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 DEDICATION

Thanks for L<java-package|https://salsa.debian.org/java-team/java-package.git> project.

=head1 VERSION

0.06

=cut
