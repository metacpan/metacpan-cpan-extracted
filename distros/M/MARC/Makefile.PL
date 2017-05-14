use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.004;

unless ($^O =~ /Win/i) {
    WriteMakefile(
        'NAME'	=> 'MARC',
        'VERSION_FROM' => 'MARC.pm', # finds $VERSION
        'SKIP'	=> [qw(tool_autosplit)],
        'clean'	=> {FILES => "*/output* output*"},
    );
    exit;
}

# On Windows, create substitute scripts for the "make deprived"

use File::Copy;
use File::Path;
use Pod::Html;
use File::Find;

    # clean up test and example result files
find(\&wanted, ".");

sub wanted {
    return unless (/^output/);
    unlink ($_);
}

my $version = simple_version("MARC.pm");
my $INST_LIBDIR = "./lib";
my $INST_HTMLDIR = "./html";
my $INST_FILES = "MARC.pm";
my $INST_NAME = "MARC";
my @HTML_FILES = "MARC";

print <<INTRO3;
                           MARC version $version

                      No 'Makefile' will be created
                      Test with:    perl test.pl
                      Install with: perl install.pl

INTRO3

my $dfile = "test.pl";
unlink $dfile;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<"TEST4";	# double quotes - need interpolation
# Created by Makefile.PL
# $INST_NAME Version $version
TEST4

print DEFAULT <<'TEST4';	# single quotes - minimize chaacter quoting
use Test::Harness;
runtests ("t/test1.t","t/test2.t","t/test3.t","t/test4.t","t/test5.t");

print "\nTo run individual tests, type:\n";
print "    C:\\> perl t/test?.t Page_Pause_Time (0..5)\n";
print "See README and other documentation for additional information.\n\n";
TEST4

close DEFAULT;

unless (-d $INST_LIBDIR) {
    File::Path::mkpath([ "$INST_LIBDIR" ],1,0777) or
        die "ERROR creating directories: ($!)\n";
}
unless (-d $INST_HTMLDIR) {
    File::Path::mkpath([ "$INST_HTMLDIR" ],1,0777) or
        die "ERROR creating directories: ($!)\n";
}
File::Copy::copy($INST_FILES,$INST_LIBDIR) or
    die "ERROR copying files: ($!)\n";

foreach $source (@HTML_FILES) {
    pod2html(
	     "--norecurse",
	     "--infile=$source.pm",
	     "--outfile=$INST_HTMLDIR/$source.html"
	    );
}

$dfile = "install.pl";
unlink $dfile, "pod2html-itemcache","pod2html-dircache";
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<"INST5";
# Created by Makefile.PL
# $INST_NAME Version $version
INST5

my $template = <<'INST5';

use Config qw(%Config);
use strict;
use ExtUtils::Install qw( install );

my $FULLEXT = "%s";	# $INST_NAME
my $INST_LIB = "./lib";
my $HTML_LIB = "./html";

my $html_dest = "";	# edit real html base here if autodetect fails

if (exists $Config{installhtmldir} ) {
    $html_dest = "$Config{installhtmldir}";
}
elsif (exists $Config{installprivlib} ) {
    $html_dest = "$Config{installprivlib}";
    $html_dest =~ s%\\lib%\\html%;
}

if ( length ($html_dest) ) {
    $html_dest .= '\lib\site';
}
else {
    die "Can't find html base directory. Edit install.pl manually.\n";
}

install({
	   read => "$Config{sitearchexp}/auto/$FULLEXT/.packlist",
	   write => "$Config{installsitearch}/auto/$FULLEXT/.packlist",
	   $INST_LIB => "$Config{installsitelib}",
	   $HTML_LIB => "$html_dest"
	  },1,0);

__END__
INST5

printf DEFAULT $template, $INST_NAME;
close DEFAULT;

    # a low-fat version of parse_version from ExtUtils::MM_Unix.
sub simple_version {
    my $parsefile = shift;
    my $result;
    open(FH,$parsefile) or die "Could not open '$parsefile': $!";
    my $inpod = 0;
    while (<FH>) {
	$inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
	next if $inpod;
	chop;
	next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
	my $eval = qq{
	    package ExtUtils::MakeMaker::_version;
	    no strict;

	    local $1$2;
	    \$$2=undef; do {
		$_
	    }; \$$2
	};
	local($^W) = 0;
	$result = eval($eval);
	die "Could not eval '$eval' in $parsefile: $@" if $@;
	$result = "undef" unless defined $result;
	last;
    }
    close FH;
    return $result;
}
