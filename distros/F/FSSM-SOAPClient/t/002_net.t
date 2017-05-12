#-*-perl-*-
#$Id$

# FSSM::SOAPClient function tests (with networking)
use lib 'lib'; 
use Test::More tests => 10;
use Test::Exception;
use Module::Build;

my $build = Module::Build->current;

use_ok('FSSM::SOAPClient');

SKIP : {
    skip "Network tests not requested", 9 unless $build->notes('network');
    ok my $client = FSSM::SOAPClient->new(
	search => 'none',
	expansion => 'none',
	predictor => 'subtype B SI/NSI',
	seqtype => 'aa'
	), 'build factory';
    ok $client->attach_seqs('t/test.fas'), 'attach test seqs';
    my $result;
    eval {
	$result = $client->run;
    };
    if ($client->errcode and $client->errcode == 408) {
	diag("Server timed out. Run later.");
	ok 1;
    }
    !$result && diag("No result from server; skipping some tests");
    SKIP : {
	skip "No result from server, skipping...", 7 unless $result;
	ok $result, "result retrived";
	my @ids = (81707, 177995, 177998 );
	my @plabels = qw(NSI NSI NSI);
	    
	while (local $_ = $result->next_call) {
	    is $_->{seqid}, shift @ids, 'id';
	    is $_->{plabel}, shift @plabels, 'pred';
	}
    }

    1;

}
