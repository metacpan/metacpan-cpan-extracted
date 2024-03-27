#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IO::Reverse' ) || print "Bail out!\n";
}

diag( "Testing IO::Reverse $IO::Reverse::VERSION, Perl $], $^X" );

my $file='./' . int(rand(2**20)) . '.txt';

open F, '>', $file or die;

my $data='';
foreach my $i ( 1..1024 ) {
	$data .= 32 + int(rand 94);
}

foreach my $i ( 1..10 ) {
	print F $data x $i . "\n";
}

close F;

open F, '<', $file or die;

my @v=();

my $i=10;
while (<F>) {
	chomp;
	$v[$i--] = $_;
}

close F;

my @t=();

my $f = IO::Reverse->new(
	{
		'FILENAME' => $file
	}
);


while ( my $line = $f->next ) { 
	#print $line;
	chomp $line;
	push @t, $line;
}

my $isOK=1;

foreach my $i ( 1..10 ) {
	#diag( "v: $i t: $t[$i-1] \n");
	$isOK = 0 unless $i == $t[$i-1];
	last unless $isOK;
}

unlink $file;


