#!/usr/local/bin/perl -w
# $Log: HelpDemo.pl,v $
# Revision 1.1.1.1  2005/01/10 05:23:52  sjs
# Import of Getopt::OO
#
use IO::File;
use Getopt::OO qw(Debug);

my $h = Getopt::OO->new(
	\@ARGV,
	usage => [
		'This is a simple function that demos how to use',
		'help for the Getopt::OO module.'
	],
	-a => {
		help => 'option -a help',
	},
	-b => {
		help => 'option -b help',
		n_values => 1,
	},
	-c => {
		help => 'option -c help',
		n_values => 1,
		multiple => 1,
	},
	-d => {
		help => 'option -d help',
		n_values => 2,
	},
	-h => {
		help => 'option -h help',
		n_values => 2,
		multiple => 1,
	},
	'--help' => {
		help => "print this message and exit.",
		callback => sub {print $_[0]->Help(); exit 0;},
	},
);
