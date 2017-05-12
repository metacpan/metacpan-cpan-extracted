#!/usr/bin/perl -w

use strict;
use blib;
use Games::Cryptoquote;

my $quote     = join(' ', @ARGV) ||
'Omyreeohrmy jsvlrtd stpimf yjr hepnr ztpvesox yjsy yjod ztphtsx od brtu vppe!';
my $author    = @ARGV ? '' : q(Npn P'Mroee);

my $c = Games::Cryptoquote->new();

unless (-e 'patterns.txt')
{
	$c->write_patterns(
		dict_file => '/usr/share/dict/words',
		pattern_file => 'patterns.txt'
	) or die;
}
$c->build_dictionary(file => 'patterns.txt', type => 'patterns') or die;

$c->quote($quote);
$c->source($author);
$c->timeout(10);

my $time1     = time;
$c->solve();
my $time2     = time;

print  "Solution : ".$c->get_solution('quote')." -- ".
                     $c->get_solution('source')."\n";
printf "Took     : %f seconds\n", $time2 - $time1;

