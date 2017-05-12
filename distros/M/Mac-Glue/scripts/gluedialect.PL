#!perl
use Config;
use File::Basename qw(basename dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl} -w
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
use strict;

BEGIN {
	($Mac::Glue::Common::PROGVERSION) =
		' $Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;
	$Mac::Glue::Common::PROGDESC = <<'EOT';
Creates dialect glues for use with Mac::Glue.  Optionally pass in paths
to dialect resource files on the command line, else the program
will try to find the installed dialect to create a glue for.

Read the documentation for created glues with the gluedoc program (for
dialects, use the -d switch).
EOT
}

use File::Spec::Functions;
use Mac::Files;
use Mac::Glue::Common;
use Mac::Gestalt qw[Gestalt gestaltSystemVersion];

my $opts = opts();
if (!@ARGV) {
	if (Gestalt(gestaltSystemVersion) >= hex(1000)) {
		push @ARGV, catfile(
			FindFolder(kSystemDomain, kComponentsFolderType),
			'AppleScript.component', 'Contents', 'Resources',
			'AppleScript.rsrc'
		);
	} elsif (Gestalt(gestaltSystemVersion) >= hex(900)) {
		push @ARGV, catfile(
			FindFolder(kOnSystemDisk, kExtensionFolderType),
			'AppleScript'
		);
	} elsif (Gestalt(gestaltSystemVersion) >= hex(800)) {
		push @ARGV, catdir(
			FindFolder(kOnSystemDisk, kScriptingAdditionsFolderType),
			'Dialects'
		);
	} else {
		push @ARGV, catdir(
			FindFolder(kOnSystemDisk, kExtensionFolderType),
			'Scripting Additions',
			'Dialects'
		);
	}
}


if (@ARGV == 1 && -d $ARGV[0]) {
	chdir $ARGV[0] or die $!;
	opendir DIR, $ARGV[0] or die $!;
	@ARGV = map { catfile($ARGV[0], $_) } readdir DIR;
}

glue($opts, \@ARGV, 'dialect');

__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
