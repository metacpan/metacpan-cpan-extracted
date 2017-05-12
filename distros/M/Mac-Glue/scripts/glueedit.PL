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
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
use strict;
use warnings;

BEGIN {
	($Mac::Glue::Common::PROGVERSION) =
		' $Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;
	$Mac::Glue::Common::PROGDESC = <<'EOT';
Creates dump files from glue files for editing, then saves those dump files
back to the glue files.

If passed filename matches the regular expression /^glueedit-.+\.txt$/,
the input is assumed to be an edited glue dump, and it is saved back to
the original glue file (the path to which is the first line of the dump).

Otherwise, the passed filename is assumed to be a glue file.  The path
to the POD can be retrieved with `gluedoc -l GLUENAME`; remove ".pod"
from the result and pass that to glueedit.

If the glue is somehow corrupted during all this, just recreate it with
gluemac.  You're responsible to make your own backups, if desired.
EOT
	$Mac::Glue::Common::PROGOPTS = '';
}

use Cwd;
use DB_File;
use Data::Dumper;
use File::Basename;
use File::Spec::Functions;
use MLDBM;
use Mac::Glue::Common;

my $opts = opts();

for my $name (@ARGV) {
	if (basename($name) =~ /^glueedit-.+\.txt$/) {
		save_glue($name);
	} else {
		get_glue($name);
	}
}

sub save_glue {
	my($file) = @_;
	my $glue = { Mac::AETE::Format::Glue::_init(), DELETE => 1 };

	open my $fh, '<', $file or die "Can't open $file: $!";

	chomp($glue->{OUTPUT} = <$fh>);
	my $dump;
	{	local $/;
		our $VAR1;
		$dump = eval <$fh>;
		warn $@ if $@;
	}
	close $fh;

	$glue->{N}			= $dump->{ENUM};
	$glue->{C}			= $dump->{CLASS};
	$glue->{E}			= $dump->{EVENT};
	$glue->{P}			= $dump->{COMPARISON};
	$glue->{_parser}{ID}		= $dump->{CREATOR_ID} || $dump->{ID};
	$glue->{_parser}{BUNDLE_ID}	= $dump->{BUNDLE_ID};
	$glue->{_parser}{APPNAME}	= $dump->{APPNAME};
	$glue->{_parser}{VERSION}	= $dump->{VERSION};

	Mac::AETE::Format::Glue::finish($glue, 1);	# 1 == no pod

	print <<EOT;
Created glue $glue->{OUTPUT}
   from file $file

EOT
}

sub get_glue {
	my($glue) = @_;
	tie my %db, 'MLDBM', $glue, O_RDONLY or die "Can't tie '$glue': $!";

	my $file = get_filename(basename($glue));

	open my $fh, '>', $file or die "Can't open $file: $!";
	print $fh $glue, "\n";
	print $fh Dumper \%db;
	untie %db;

	print <<EOT;
Created file $file
    for glue $glue

EOT
}


sub get_filename {
	my($id) = @_;
	my $c = '';
	$c++ while -e "glueedit-$id$c.txt";
	return "glueedit-$id$c.txt";
}

__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
