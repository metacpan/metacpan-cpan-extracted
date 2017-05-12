package Mac::Glue::Common;

BEGIN {
	use vars qw($SERIALIZER);
	# for MacPerl, use Storable for PPC and FreezeThaw for CFM68K;
	# won't work with plain 68K build; Storable for other platforms
	$SERIALIZER = $^O eq 'MacOS'
		? $MacPerl::Architecture eq 'MacPPC'
			? 'Storable'
			: $MacPerl::Architecture eq 'MacCFM68K'
				? 'FreezeThaw'
				: die("Must be using CFM68K or PPC build of MacPerl: $MacPerl::Architecture")
		: 'Storable';

}

use strict;
use File::Basename;
use File::Spec::Functions;
use Getopt::Std;
use MacPerl;
use Mac::AETE::App;
use Mac::AETE::Dialect;
use Mac::AETE::Format::Glue;

use base 'Exporter';
use vars qw(
	@EXPORT $REVISION $VERSION $MACGLUEDIR
	$PROGNAME $PROGVERSION $PROGDESC $PROGOPTS
);

@EXPORT = qw(glue is_osax is_dialect opts $MACGLUEDIR);
($REVISION) 	= ' $Revision: 1.6 $ ' =~ /\$Revision:\s+([^\s]+)/;
$VERSION	= '1.02';

$PROGNAME    ||= basename($0);
$PROGVERSION ||= $VERSION;
$PROGDESC    ||= '';
$PROGOPTS    ||= '';
$MACGLUEDIR    = $ENV{MACGLUEDIR};

if ($^O eq 'MacOS') {
	$MACGLUEDIR ||= "$ENV{MACPERL}site_perl:Mac:Glue:glues:";
	$MACGLUEDIR  .= ':' unless $MACGLUEDIR =~ /:$/;
} elsif (!$MACGLUEDIR) {
	my $dir = dirname $INC{'Mac/Glue/Common.pm'};
	unless (file_name_is_absolute($dir)) {
		require Cwd;
		$dir = catdir(Cwd::cwd(), $dir);
	}
	$MACGLUEDIR = catdir($dir, 'glues');
}

# in case old code uses it ...
$ENV{MACGLUEDIR} = $MACGLUEDIR;

sub glue {
	my($opts, $files, $type) = @_;
	$type ||= 'app';
	my($delete, %files);

	local $MacPerl::Target = '' if $^O ne 'MacOS';

	my @dirs = $MACGLUEDIR;
	my $class = 'Mac::AETE::App';
	if ($type eq 'dialect') {
		push @dirs, 'dialects';
		$class = 'Mac::AETE::Dialect';
	} elsif ($type eq 'addition') {
		push @dirs, 'additions';
	}

	if (ref $files eq 'ARRAY') { # convert to hash
		%files = map { ($_, $_) } @$files;
	} else {
		%files = %$files;
	}

	foreach my $drop (sort { lc basename($a) cmp lc basename($b) } keys %files) {
		$drop = readlink $drop while -l $drop;
		print "Making glue for '$drop'\n";

		# initialize
		(my $ddrop = $drop) =~ s|[/:]$||;  # is dir/package ?
		my($file, $dir) = fileparse($ddrop, '');

		if ($type eq 'dialect') {
			unless (is_dialect($files{$drop})) {
				warn "$file does not appear to be a dialect (skipped)\n";
				next;
			}
			$file =~ s/\s+Dialect$//;
		} elsif ($type eq 'addition') {
			unless (is_osax($files{$drop}, $file)) {
				warn "$file does not appear to be an addition (skipped)\n";
				if ($file =~ /\.app$/) {
					(my $path = $files{$drop}) =~ s|^(.+$drop).*$|$1|;
					(my $gluemac = $0) =~ s/scriptadds$/mac/;
					warn "  Try: $gluemac '$path'\n";
				}
				next;
			}
		}

		my $fixed = Mac::AETE::Format::Glue::fixname($file);
		$fixed =~ s/_(?:app|rsrc|osax)$//;

		if ($type eq 'app' && ! $opts->{I}) {
			$fixed = MacPerl::Ask("What is the glue name?", $fixed);
		}

		if (!$fixed) {
			warn "No name given for $file (skipped)\n";
			next;
		}

		my $output = catfile(@dirs, $fixed);

		if (-e $output && ! $opts->{I}) {
			if (! defined $delete) {
				$delete = MacPerl::Answer(
					'Overwrite existing glues if they exist?',
					qw(OK No Cancel)
				);
				exit if $delete == 0;
				$delete = 0 if $delete == 2;
			}
		}

		next unless my $aete = $class->new($files{$drop});
		my $conv = Mac::AETE::Format::Glue->new($output, !$delete);

		$aete->set_format($conv);
		$aete->read;
		$aete->write;
		$conv->finish;

		my $name = $file;
		$name .= ", v$aete->{VERSION}" if $aete->{VERSION};
		print "Created and installed \u$type glue for '$name' ($fixed)\n";
	}
}

sub is_osax {
	my($osax, $file) = @_;

	return unless -f $osax;
	# Mac OS X doesn't use file type/creator for this
	if ($^O ne 'MacOS') {
		return if $file !~ /\.osax$/;
	} else {
		my $type = MacPerl::GetFileInfo($osax);
		return if !$type || $type ne 'osax';
	}

	return 1;
}

sub is_dialect {
	my $dlct = shift;

	return unless -f $dlct;
	# Mac OS X doesn't use file type/creator for this
	return 1 if $^O ne 'MacOS';

	my($creator, $type) = MacPerl::GetFileInfo($dlct);
	return if !$type || !$creator || $creator ne 'ascr' ||
		($type ne 'shlb' && $type ne 'dlct' && $type ne 'thng');

	return 1;
}

sub opts {
	my %opts;
	my $opts = $PROGOPTS . 'hvI';
	usage('Options used incorrectly') unless getopts($opts, \%opts);
	usage() if $opts{'h'};
	version() if $opts{'v'};
	return \%opts;
}

sub usage {
	print "*** $_[0]\n" if $_[0];
	# Remember to doublecheck these match getopts()!
	print <<EOT;
Usage: $PROGNAME [OPTIONS] PATHS

$PROGDESC
	-h	Help (this message)
	-v	Version
	-I	Do not prompt, use defaults

EOT
	exit;
}


sub version {
	print <<EOT;
$PROGNAME $PROGVERSION

Copyright (c) 1998-2003 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

EOT
	exit;
}

1;

__END__
