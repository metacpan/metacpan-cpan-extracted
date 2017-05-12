use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
#!$^X -w

!GROK!THIS!

foreach my $dir (@INC) {
    print OUT qq{use lib '$dir';\n};
}

print OUT <<'!NO!SUBS!';


use strict;

use Getopt::Std;
use Pod::Usage;
use File::Copy 'cp';
use File::Find;
use IO::File;
use Devel::ModInfo::Util 'convert_modinfo_to_xml';

my %opts;
getopts('hri:o:x:', \%opts);

if ($opts{h}) {pod2usage(-verbose => 2)}

$opts{i} || $opts{r} || pod2usage(
	-verbose => 2, 
	-message => "-i and -r parameter missing.  Must provide input file nameor request recursive operation"
);

my @files;
if ($opts{r}) {
        find(\&file_found, '.');
	foreach my $file (@files) {
	    proc_file($file);
	}
}
else {
        proc_file($opts{i}, $opts{o});
}

sub file_found {
        if ($_ =~ /.pm$/) {
             my $in_path = $File::Find::name;
             return if $in_path =~ /\Q$opts{x}\E/;
             push(@files, $in_path);
        }
}

sub proc_file {
my ($in_path, $out_path) = @_;

my $out;
if ($out_path) {
        print "Processing $in_path to $out_path\n";
	$out = new IO::File("> $out_path");
	die "Failed to open $out_path for writing: $!" if $out->error;
}
else {
	$out_path = $in_path;
	$out_path =~ s/\.pm$/\.mfo/;
        print "Processing $in_path to $out_path\n";
	$out = new IO::File("> $out_path");
	die "Failed to open $out_path for writing: $!" if $out->error;
}

print $out convert_modinfo_to_xml($in_path);
close($out);
}

__END__

=head1 modinfo2xml.pl

modinfo2xml.pl: convert MODINFO directives in a Perl module into an XML file (an mfo file)

=head1 SYNOPSIS

perl modinfo2xml.pl -m MyModule.pm -o MyModule.mfo

or

perl pl2modinfo.pl -m MyModule.pm

=head1 OPTIONS

=over 4

=item -m           Name of the module to create mfo for

=item -o filename  Use this file as output (uses PackageName.mfo if -o not provided
                     where "PackageName" is the first package defined in the module file)

=back

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

ModInfo

Devel::ModInfo::Tutorial

modinfo2html.pl

pl2modinfo.pl

perl(1)

!NO!SUBS!
