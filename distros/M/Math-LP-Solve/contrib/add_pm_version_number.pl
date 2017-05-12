#!/freeware/bin/perl -w
use strict;
require 5.005;
use vars qw($VERSION $package_name $package_version $package_file);
use Getopt::Long;
use Pod::Usage;
use IO;
use File::Temp qw(tempfile);
use File::Copy;
use AtExit;
$VERSION = sprintf('%d.%02d', q{ $Revision: 1.2 $ } =~ /(\d+)\.(\d+)/);

# command line processing
Getopt::Long::Configure('no_ignore_case');
GetOptions(
    'package=s' => \$package_name,
    'version=s' => \$package_version,
    'pm-file=s' => \$package_file,
    'Version'   => sub { print $VERSION, "\n"; exit 0; },
    'help|?'    => sub { pod2usage(exitval => 0, verbose => 1) }, # SYNOPSIS, OPTIONS and ARGUMENTS
    'man'       => sub { pod2usage(exitval => 0, verbose => 2) }, # whole manpage
) or pod2usage(verbose => 2);
defined($package_name)    or pod2usage(msg => "ERROR: no package name specified");
defined($package_version) or pod2usage(msg => "ERROR: no package version specified");
defined($package_file)    or pod2usage(msg => "ERROR: no .pm file specified");

# copy the pm-file to a temporary file, inserting the package version where needed
my $f_in = new IO::File;
$f_in->open("<$package_file") or die "Cannot read `$package_file': $!\n";
my ($f_tmp,$tmpname) = tempfile("tmpfileXXXXX");
atexit(sub { unlink $tmpname }, "removes temporary file `$tmpname'");
my $pkg_hits = 0;
while(<$f_in>) {
    print $f_tmp $_;
    if(/^package\s+$package_name\;/o && $pkg_hits++ == 0) { # first occurence of the package declaration
	print $f_tmp "*VERSION = \\\'$package_version\'; #'\n"; # writes an unmodifiable $VERSION
    }
}
close($f_in);
close($f_tmp);
$pkg_hits > 0 or die "No such package `$package_name' declared in file `$package_file'.\n";

# overwrite the original package file
copy($tmpname,$package_file) or die "Copying of `$tmpname' to `$package_file' failed: $!\n";

__END__

=head1 NAME

add_pm_version_number.pl - utility to add a version number to Perl modules

=head1 SYNOPSIS

    add_pm_version_number.pl --package=<string> --version=<string> --pm-file=<file>
          [--help] [-?] [--man] [--Version]

Runs through the pm-file and adds the requested $VERSION line after the 1st
declaration of the package.

=head1 OPTIONS

Following options and unique abbreviations of them are accepted:

=over 4

=item B<--package>

name of the package for which the version number needs to be added

=item B<--version>

string with the version number that needs to be added

=item B<--pm-file>

name of the perl module in which the version number will be added

=item B<--help> or B<-?>

prints a brief help message and exits

=item B<--man>

prints an extended help message and exits

=item B<--Version>

prints the version number and exits

=back

=head1 ARGUMENTS

No arguments are accepted. All needed parameters are passed as options.

=head1 RELEASE

$Id: add_pm_version_number.pl,v 1.2 2000/11/07 15:17:19 verhaege Exp $

=head1 AUTHOR

Wim Verhaegen E<lt>wim.verhaegen@ieee.orgE<gt>

=cut
