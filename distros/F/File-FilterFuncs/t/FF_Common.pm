package t::FF_Common;
use strict;
use warnings;
use POSIX qw(tmpnam);
use Exporter ();
use File::Spec::Functions;
use Fatal qw(open close);

BEGIN {
	our @ISA = qw(Exporter);
	our @EXPORT = qw(%Common slurp_file unslurp_file);
	our @EXPORT_OK = @EXPORT;
}


our $DEBUG;
our %Common;


sub init {
	if ("@_" =~ /\bdebug\b/) {
		$DEBUG = 1;
	}

	my $tmpnam = $DEBUG ? '/tmp/ff.test.dir' : tmpnam();
	%Common = (
		tempdir => $tmpnam,
		tempin => catfile($tmpnam,'input'),
		tempout => catfile($tmpnam,'output'),
	);

	return if (-d $Common{tempdir});
	mkdir $Common{tempdir};
}



sub cleanup {
	return if $DEBUG;

	unlink $Common{tempin};
	unlink $Common{tempout};
	my @temps = glob(catfile($Common{tempdir},'t.*'));
	unlink @temps;
	rmdir $Common{tempdir};
}

sub slurp_file {
	my $filename = shift;
	my $fh;
	local $/;

	open $fh, '<:raw', $filename;
	my $data = <$fh>;
	close $fh;
	$data;
}

sub unslurp_file {
	my $filename = shift;
	my $data = join('',@_);
	my $fh;

	open $fh, '>:raw', $filename;
	print $fh $data;
	close $fh;
	1;
}


1;

