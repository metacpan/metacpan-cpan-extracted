package t::WriteHeader;

use warnings;
use strict;

use File::Spec ();
use IO::File 1.03 ();

our @todelete;
END { unlink @todelete; }

sub write_header($$$) {
	my($basename, $outdir, $prefix) = @_;
	require Devel::CallParser;
	no strict "refs";
	my $content = &{"Devel::CallParser::${basename}_h"}();
	my $h_file = File::Spec->catfile($outdir, "${prefix}_${basename}.h");
	push @todelete, $h_file;
	my $fh = IO::File->new($h_file, "w") or die $!;
	$fh->printflush($content) or die $!;
	$fh->close or die $!;
}

1;
