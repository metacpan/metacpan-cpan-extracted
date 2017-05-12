#!/usr/bin/env perl
use strict;
use warnings;

use XML::Parser;
 
use Bench;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $self = Bench::ExpatHandler->new;
my $fh;

my $parser = XML::Parser->new(Handlers => {
	Start => sub { $self->starthandler(@_) },
	End => sub { $self->endhandler(@_) },
	Char => sub { $self->char_handler(@_) },
});

if(scalar(@ARGV)) {
	my ($file) = @ARGV;
	die "could not open $file: $!" unless open($fh, $file);
} else {
	$fh = \*STDIN;
}

my $nb = $parser->parse_start;

while(1) {
	my ($buf, $ret);
	
	$ret = read($fh, $buf, 32768);
	
	if (! defined($ret)) {
		die "could not read: $!";
	} elsif ($ret == 0) {
		$nb->parse_done;
		last;
	} else {
		$nb->parse_more($buf);
	}
}
