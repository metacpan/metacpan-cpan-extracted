#!/usr/bin/perl -w

use Test::More tests => 6;

use strict;
use warnings;

use HTTP::OAI;

my @repos = qw(
http://eprints.ecs.soton.ac.uk/cgi/oai2
http://www.citebase.org/oai2
http://memory.loc.gov/cgi-bin/oai2_0
);
@repos = qw(
http://eprints.ecs.soton.ac.uk/cgi/oai2
);

my $h = HTTP::OAI::Harvester->new(baseURL=>$repos[int(rand(@repos))]);

my $r;

my $dotest = defined($ENV{"HTTP_OAI_NETTESTS"});

SKIP : {
	skip "Skipping flakey net tests (set HTTP_OAI_NETTESTS env. variable to enable)", 6 unless $dotest;

	#$r = $h->GetRecord(identifier=>'oai:eprints.ecs.soton.ac.uk:23',metadataPrefix=>'oai_dc');
	#ok($r->is_success());

	
	$r = $h->Identify();
	ok($r->is_success(), "Identify: ".$r->message);

	$r = $h->ListIdentifiers(metadataPrefix=>'oai_dc');
	ok($r->is_success(), "ListIdentifiers: ".$r->message);

	$r = $h->ListMetadataFormats();
	ok($r->is_success(), "ListMetadataFormats: ".$r->message);

	$r = $h->ListRecords(metadataPrefix=>'oai_dc');
	ok($r->is_success(), "ListRecords: ".$r->message);

	$r = $h->ListSets();
	ok($r->is_success(), "ListSets: ".$r->message);

	$r = $h->ListIdentifiers(metadataPrefix => 'oai_dc');
	my $ok = 0;
	while(1)
	{
		last if $r->is_error;
		my $uri = $r->request->uri;
		my $rec = $r->next;
		$ok = 1, last if $uri ne $r->request->uri;
	}
	ok($ok, "Auto-resumption RT #69337");
}
