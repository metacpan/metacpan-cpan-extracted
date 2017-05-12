print "1..1\n";

use strict;
use HTTP::OAI;

my $r = new HTTP::OAI::ListMetadataFormats();
my $mf = new HTTP::OAI::MetadataFormat(
	metadataPrefix=>'oai_dc',
	schema=>'http://www.openarchives.org/OAI/2.0/oai_dc.xsd',
	metadataNamespace=>'http://www.openarchives.org/OAI/2.0/oai_dc/',
);
$r->metadataFormat($mf);

print "ok 1\n";
