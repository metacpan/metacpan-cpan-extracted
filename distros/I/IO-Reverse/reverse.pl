#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

use lib qw(./lib);
use IO::Reverse;


my $fileName='';
my $help=0;

GetOptions(
	"filename=s" => \$fileName,
	"h|help!" => \$help
) or usage(1);

usage(1) if $help;

my $f = IO::Reverse->new( 
	FILENAME => $fileName
);

while ( my $line = $f->next ) {
	print "$line";
}

sub usage {

	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);

			
	print qq{
$basename

usage: $basename - read a file from the end to beginning

   $basename --file <filename> 

--file	  name of file to read

--help|-h  help

examples here:

   $basename --file DWDB_ora_63389.trc 

};

	exit eval { defined($exitVal) ? $exitVal : 0 };
}

