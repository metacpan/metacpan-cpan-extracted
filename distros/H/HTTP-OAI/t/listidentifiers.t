use Test::More tests => 3;

use strict;
use HTTP::OAI;
use URI;

my $r = new HTTP::OAI::ListIdentifiers();

my $str = <<EOF;
<?xml version="1.0" encoding="UTF-8" ?>

<OAI-PMH  xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.openarchives.org/OAI/2.0/"><responseDate >2004-10-08T17:11:44Z</responseDate><request  verb="ListIdentifiers" resumptionToken="archive/8600/12552966">http://eprints.ecs.soton.ac.uk/perl/oai2</request><ListIdentifiers ><header status="deleted"><identifier >oai:eprints.ecs.soton.ac.uk:10009</identifier><datestamp >2004-10-07</datestamp><setSpec >7374617475733D707562</setSpec><setSpec >747970653D696E70726F63656564696E6773</setSpec><setSpec >66756C6C746578743D46414C5345</setSpec></header><header ><identifier >oai:eprints.ecs.soton.ac.uk:10010</identifier><datestamp >2004-10-08</datestamp><setSpec >7374617475733D707562</setSpec><setSpec >747970653D61727469636C65</setSpec><setSpec >66756C6C746578743D46414C5345</setSpec></header></ListIdentifiers></OAI-PMH>
EOF
chomp($str);

$r->parse_string($str);

ok(1);

my $ha = HTTP::OAI::Harvester->new(baseURL=>'http://domain.invalid/');
$r = $ha->ListRecords(metadataPrefix=>'oai_dc', from=>'2005-01-01');
my $uri = URI->new($r->request->uri);
my %args = $uri->query_form;
ok($args{metadataPrefix} eq 'oai_dc' && $args{'from'} eq '2005-01-01','Request arguments');

ok(1);
