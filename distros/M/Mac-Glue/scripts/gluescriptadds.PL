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
Creates scripting addition (OSAX) glues for use with Mac::Glue.  Optionally
pass in paths to OSAX resource files on the command line, else the program
will try to find the installed OSAX to create glues for.

Read the documentation for created glues with the gluedoc program (for
additions, use the -a switch).
EOT
}

use File::Find;
use File::Spec::Functions;
use Mac::Files;
use Mac::Glue::Common;
use Mac::Gestalt;
use Mac::Resources;

my $opts = opts();

my %adds;
if (!@ARGV) {
	if (Gestalt(gestaltSystemVersion) >= hex(1000)) {
		my @dirs;
		for my $domain (kSystemDomain, kLocalDomain, kNetworkDomain, kUserDomain) {
			push @dirs, FindFolder($domain, kScriptingAdditionsFolderType)
				if FindFolder($domain, kScriptingAdditionsFolderType);
		}

		for my $dir (@dirs) {
			find(sub {
				my $file = $File::Find::name;
				my $rf;
				if ($rf = FSOpenResourceFile($file, 'rsrc', fsRdPerm) ||
				          FSOpenResourceFile($file, 'data', fsRdPerm)) {
					if (CountResources('aete')) {
						(my $name = $file) =~ s|^\Q$dir\E/?([^/]+)/.*$|$1|;
						push @{$adds{$name}}, $file;
					}
					CloseResFile($rf);
				}
			}, $dir);
		}

		for my $add (keys %adds) {
			if (is_osax($adds{$add}[0], $add) && @{$adds{$add}} > 1) {
				my @locales = map {
					m|/(\w+)\.lproj/Localized.rsrc$|;
					$1;
				} grep {
					m|/Localized.rsrc$|;
				} @{$adds{$add}};
				if (@locales) {
					my $locale = MacPerl::Pick(
						"Pick a locale for $add",
						sort { lc $a cmp lc $b } @locales
					);
					$locale ||= 'English';
					($adds{$add}) = grep { m|/\Q$locale\E\.lproj/Localized.rsrc$| } @{$adds{$add}};
				} else {
					$adds{$add} = $adds{$add}[0];
				}
			} else {
				$adds{$add} = $adds{$add}[0];
			}
		}

	} elsif (Gestalt(gestaltSystemVersion) >= hex(800)) {
		push @ARGV, FindFolder(kOnSystemDisk, kScriptingAdditionsFolderType);
	} else { # 900
		push @ARGV, catdir(
			FindFolder(kOnSystemDisk, kExtensionFolderType),
			'Scripting Additions'
		);
	}
}

if (@ARGV == 1 && -d $ARGV[0]) {
	chdir $ARGV[0] or die $!;
	opendir DIR, $ARGV[0] or die $!;
	@ARGV = map { catfile($ARGV[0], $_) } readdir DIR;
}

if (! keys %adds) {
	@adds{@ARGV} = @ARGV;
}

glue($opts, \%adds, 'addition');

__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
