package Java::Release;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(parse_java_jdk_release);

our $VERSION = 0.03;

# Parse Java JDK release.
sub parse_java_jdk_release {
	my $release_name = shift;

	my $release_hr = {};
	if ($release_name =~ m/^jdk-([0-9]+)(u([0-9]+))?-linux-(i586|x64|amd64|arm-vfp-hflt|arm32-vfp-hflt|arm64-vfp-hflt)\.(bin|tar\.gz)$/ms) {
		$release_hr->{j2se_release} = $1;
		$release_hr->{j2se_update} = $3;
		$release_hr->{j2se_arch} = $4;
		$release_hr->{j2se_version} = $release_hr->{j2se_release};
		$release_hr->{j2se_version_name} = $release_hr->{j2se_release};
		if ($release_hr->{j2se_update}) {
			$release_hr->{j2se_version_name}
				.= ' Update '.$release_hr->{j2se_update};
			$release_hr->{j2se_version}
				.= 'u'.$release_hr->{j2se_update}
		} else {
			$release_hr->{j2se_version_name} .= ' GA';
		}
	} elsif ($release_name =~ m/^jdk-([0-9]+)(\.([0-9]+))?(\.([0-9]+))?(\.([0-9]+))?_linux-(i586|x64|amd64|arm-vfp-hflt|arm32-vfp-hflt|arm64-vfp-hflt)_bin.tar.gz$/ms) {
		$release_hr->{j2se_release} = $1;
		$release_hr->{j2se_interim} = $3;
		$release_hr->{j2se_update} = $5;
		$release_hr->{j2se_patch} = $7;
		$release_hr->{j2se_arch} = $8;
		$release_hr->{j2se_version} = $release_hr->{j2se_release};
		if (defined $release_hr->{j2se_interim}) {
			$release_hr->{j2se_version} .= '.'.$release_hr->{j2se_interim};
			if (defined $release_hr->{j2se_update}) {
				$release_hr->{j2se_version} .= '.'.$release_hr->{j2se_update};
				if (defined $release_hr->{j2se_patch}) {
					$release_hr->{j2se_version} .= '.'.$release_hr->{j2se_patch};
				}
			}
		}
		$release_hr->{j2se_version_name} = $release_hr->{j2se_release};
		if ($release_hr->{j2se_update}) {
			$release_hr->{j2se_version_name}
				.= ' Update '.$release_hr->{j2se_update};
		} else {
			$release_hr->{j2se_version_name} .= ' GA';
		}
	} else {
		err "Unsupported release.",
			'release_name', $release_name;
	}

	return $release_hr;
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

© 2020 Michal Josef Špaček

BSD 2-Clause License

=head1 DEDICATION

Thanks for L<java-package|https://salsa.debian.org/java-team/java-package.git> project.

=head1 VERSION

0.03

=cut
