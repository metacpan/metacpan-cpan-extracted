#!/usr/local/bin/perl -w
# $Log: ValuesDemo.pl,v $
# Revision 1.1.1.1  2005/01/10 05:23:52  sjs
# Import of Getopt::OO
#
use IO::File;
use Getopt::OO qw(Debug);

 my @argv = qw (-abcde b c0 d0 d1 e0 e1 -c c1 -e e2 es);
 my $h = Getopt::OO->new(\@argv,
	'usage' => 'Demo of returns by Values method.',
 	'die' => 1,	 # Die if parsing fails.
 	-a => {},
 	-b => { n_values => 1, },
 	-c => { n_values => 1, multiple => 1, },
 	-d => { n_values => 2, },
 	-e => { n_values => 2, multiple => 1, },
 );
 my $n_options = $h->Values();
 my $a = $h->Values('-a');
 my $b = $h->Values('-b');
 my @c = $h->Values('-c');
 my @d = $h->Values('-d');
 my @e = $h->Values('-e');

