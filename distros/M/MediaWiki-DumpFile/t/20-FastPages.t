use strict;
use warnings;

use Test::Simple tests => 14;
use Data::Compare; 
use Data::Dumper;

use MediaWiki::DumpFile;

my $test_data = "t/pages_test.xml";

my $mw = MediaWiki::DumpFile->new;
my $p = $mw->fastpages($test_data);
test_suite($p);

die "die could not open $test_data: $!" unless open(INPUT, $test_data);
$p = $mw->fastpages(\*INPUT);
test_suite($p);

sub test_suite {
	my ($p) = @_;

	test_one($p->next);
	test_two($p->next);
	test_three($p->next);
	
	ok(! scalar($p->next));
}


sub test_one {
	my ($title, $text) = @_;
	
	ok($title eq 'Talk:Title Test Value');
	ok($text eq 'Text Test Value');
}

sub test_two {
	my ($title, $text) = @_;
	
	ok($title eq 'Title Test Value #2');
	ok($text eq '#redirect : [[fooooo]]');
}

sub test_three {
	my ($title, $text) = @_;
	
	ok($title eq 'Title Test Value #3');
	ok($text eq '#redirect [[fooooo]]');
}