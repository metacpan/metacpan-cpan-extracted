#!/usr/local/bin/perl

use lib '/u/jonh/fom24dev/lib';

use lib '/tmp';

use FAQ::OMatic::API;

my $fom = new FAQ::OMatic::API();
#$fom->{'debug'} = 1;
$fom->setURL('http://localhost/~jonh/cgi-bin/fom-test.cgi');
#$fom->setAuth('test-login@test.dartmouth.edu', 'testpass');
$fom->setAuth('query');

# test of fuzzy matching
my ($rc, $cat) = $fom->fuzzyMatch(['maintenance$b']);
die $cat if (not $rc);
print map {"reply: $_\n"} @{$cat};

($rc, my $msg) = $fom->newAnswer($cat->[0], 'New Maintenance Info',
	"B-sized parts are twice as big as A-sized parts, so use the correct\n"
	."paper tray.\n");
die $msg if (not $rc);
print "success!\n";

#my ($rc, $cats) = $fom->catnames();
#print map {"cat: ".join(" : ", @{$_})."\n"} @{$cats};

#my ($rc, $msg) = $fom->getItem('1');
#print "msg: ".$msg."\n";
#print $msg->displayHTML({'render'=>'text'});
#print "$rc: ".$msg->getTitle()."\n";
