use strict;
use warnings;
use Carp 'croak';
use Benchmark ':hireswallclock', 'cmpthese';
#use File::Slurp 'read_file';

sub read1 {
	my ($filename, $encoding, %options) = @_;
	$encoding |= 'utf-8';
	my $extra = $options{crlf} ? ':crlf' : '';

	open my $fh, "<$extra:encoding($encoding)", $filename or croak "Couldn't open $filename: $!";
	my $size = -s $fh;
	my ($pos, $read, $buf) = 0;
	do {
		defined($read = read $fh, $buf, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
		$pos += $read;
	} while ($read && $pos < $size);
}

sub read2 {
	my ($filename, $encoding, %options) = @_;
	$encoding |= 'utf-8';
	my $extra = $options{crlf} ? ':crlf' : '';

	open my $fh, "<$extra:encoding($encoding)", $filename or croak "Couldn't open $filename: $!";
	my $buf_ref = do { local $/; <$fh> };
}

my $filename = shift or die "No argument given";
my $count = shift || 100;
my $factor = 1;

print "Slurping utf8\n";
cmpthese($count * $factor, {
#	slurp => sub { read_file($filename, binmode => ':encoding(utf-8)') },
	smart => sub { read1($filename) },
	dump  => sub { read2($filename) },
});
