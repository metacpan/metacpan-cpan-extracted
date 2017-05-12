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
use Devel::ModInfo::Util 'parse_modinfo_file';

my %opts;
getopts('hwcei:o:', \%opts);

if ($opts{h}) {pod2usage(-verbose => 2)}
if ($opts{w}) {$opts{c} = 1}

$opts{i} ||= \*STDIN;

my $out;
if ($opts{o}) {
	$out = new IO::File("> $opts{o}");
	die "Failed to open $opts{o} for writing: $!" if $out->error;
}
elsif ($opts{w} and $opts{i}) {
	$out = new IO::File("> $opts{i}.tmp");
	die "Failed to open $opts{i} for writing: $!" if $out->error;
}
else {
	$out = \*STDOUT;
}
print $out parse_modinfo_file($opts{i}, $opts{c}, $opts{w});

close($out);

if ($opts{w}) {
	cp("$opts{i}.tmp", $opts{i});
	unlink("$opts{i}.tmp");
}

__END__

=head1 pl2modinfo.pl

pl2modinfo.pl: automatically stub out a perl module with MODINFO directives

=head1 SYNOPSIS

perl pl2modinfo.pl -ce -i MyModule.pm -o results.txt

or

perl pl2modinfo.pl -cew -i MyModule.pm

=head1 OPTIONS

=over 4

=item -e           Return undef and set error property instead of dying 
                     when errors occur

=item -c           Include the original perl code from the module in the 
                     output

=item -i filename  Use this file as input (uses STDIN if -i is not provided)

=item -o filename  Use this file as output (uses STDOUT if neither -o or 
                     -w are provided)

=item -w           Overwrite original file with output (Use with caution!) 
                     Ignored if -o is provided or -i is not provided

=back

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

ModInfo

Devel::ModInfo::Tutorial

modinfo2html.pl

modinfo2xml.pl

perl(1)

!NO!SUBS!
