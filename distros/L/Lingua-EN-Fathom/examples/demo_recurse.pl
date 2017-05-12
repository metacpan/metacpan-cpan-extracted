#! /usr/local/bin/perl
# demo_recurse.pl script for usew with Lingua::EN::Fathom.pm

use Lingua::EN::Fathom;
use File::Find;

@ARGV = ('.') unless @ARGV;
my $text = new Lingua::EN::Fathom;

find(\&analyse, @ARGV);
print($text->report);

sub analyse 
{
	return unless ( -T and -s );
	print("Analysing file: $File::Find::name\n");
	$text->analyse_file($File::Find::name,1);
}




