use strict;
use warnings;

use Test::Simple tests => 89;
use Data::Compare; 
use Data::Dumper;

use MediaWiki::DumpFile;

our $TEST = 'file';

my $test_data = "t/pages_test.xml";

my $mw = MediaWiki::DumpFile->new;
my $p = $mw->pages($test_data);
test_suite($p);

$TEST = 'filehandle';

die "die could not open $test_data: $!" unless open(INPUT, $test_data);
$p = $mw->pages(\*INPUT);
test_suite($p);

sub test_suite {
	my ($p) = @_;
	my %namespace_test_values = new_namespace_data();
	my %namespace_test_against;
	
	ok($p->version eq '0.3');
	ok($p->sitename eq 'Sitename Test Value');
	ok($p->base eq 'Base Test Value');
	ok($p->case eq 'Case Test Value');
	%namespace_test_against = $p->namespaces;
	ok(Compare(\%namespace_test_values, \%namespace_test_against));
	
	ok(defined($p->current_byte));
	ok($p->current_byte != 0);
	
	if ($TEST ne 'filehandle') {
		ok($p->size == 2259);
	}

	test_one($p->next);
	test_two($p->next);
	test_three($p->next);
	ok(! defined($p->next));
}

sub new_namespace_data {
	return (
		'-1' => 'Special',
		'0' => '',
		'1' => 'Talk',
	);
}

sub test_one {
	my ($page) = @_;
	my $revision = $page->revision;
		
	ok($page->title eq 'Talk:Title Test Value');
	ok($page->id == 1);
	ok($revision->text eq 'Text Test Value');
	ok($revision->id == 47084);
	ok($revision->timestamp eq '2005-07-09T18:41:10Z');
	ok($revision->comment eq ''); #bug #55758
	ok($revision->minor == 1);
	ok($page->revision->contributor->username eq 'Username Test Value');
	ok($page->revision->contributor->id == 1292);
	ok(! defined($page->revision->contributor->ip));
	ok($page->revision->contributor->astext eq 'Username Test Value');
	ok($page->revision->contributor eq 'Username Test Value');
}

sub test_two {
	my ($page) = @_;
	my @revisions = $page->revision;
	my $revision;
	
	ok($page->title eq 'Title Test Value #2');
	ok($page->id == 2);
	
	$revision = shift(@revisions);
	ok($revision->id == 47085);
	ok($revision->timestamp eq '2005-07-09T18:41:10Z');
	ok($revision->comment eq 'Comment Test Value 2');
	ok($revision->text eq '#redirect : [[fooooo]]');
	ok($revision->minor == 1);
	
	
	$revision = shift(@revisions);
	ok($revision->id == 12345);
	ok($revision->timestamp eq '2006-07-09T18:41:10Z');
	ok($revision->comment eq 'Comment Test Value 3');
	ok($revision->text eq 'more test data');
	ok($revision->minor == 0);
	
}

sub test_three {
	my ($page) = @_;
	my $revision = $page->revision;
	
	ok($page->title eq 'Title Test Value #3');
	ok($page->id == 3);
	
	ok($revision->id == 57086);
	ok($revision->timestamp eq '2008-07-09T18:41:10Z');
	ok($revision->comment eq 'Second Comment Test Value');
	ok($revision->text eq 'Expecting this data');
	ok($revision->minor == 1);
	ok($revision->contributor->ip eq '194.187.135.27');
	ok(! defined($revision->contributor->username));
	ok(! defined($revision->contributor->id));
	ok($revision->contributor->astext eq '194.187.135.27');
	ok($revision->contributor eq '194.187.135.27');	
}