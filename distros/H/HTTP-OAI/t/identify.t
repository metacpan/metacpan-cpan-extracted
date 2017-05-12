use Test;

BEGIN { plan tests => 8; }

use warnings;
use strict;
use HTTP::OAI;
ok(1);

my $r = new HTTP::OAI::Identify(
	baseURL=>'http://citebase.eprints.org/cgi-bin/oai2',
	adminEmail=>'tdb01r@ecs.soton.ac.uk',
	repositoryName=>'oai:citebase.eprints.org',
	granularity=>'YYYY-MM-DD',
	deletedRecord=>'transient',
);

ok($r->baseURL,'http://citebase.eprints.org/cgi-bin/oai2');
ok($r->adminEmail,'tdb01r@ecs.soton.ac.uk');
ok($r->repositoryName,'oai:citebase.eprints.org');
ok($r->granularity,'YYYY-MM-DD');
ok($r->deletedRecord,'transient');

$r = HTTP::OAI::Identify->new();

open my $fh, "<examples/identify.xml";
my $xml = join '', <$fh>;
close $fh;

$r->parse_string($xml);

ok($r->adminEmail,'mailto:tdb01r@ecs.soton.ac.uk');

my $xml_out = $r->toDOM->toString;

ok($xml_out);
