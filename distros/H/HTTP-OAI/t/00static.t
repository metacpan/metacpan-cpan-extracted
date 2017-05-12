use Test::More tests => 21;

use strict;

use HTTP::OAI;
ok(1);

# This test harness checks that the library correctly supports
# transparent gateway to static repositories

my $fn = "file:".$ENV{PWD}."/examples/repository.xml";
my $repo = HTTP::OAI::Harvester->new(baseURL=>$fn);
ok($repo, "Harvester");

# Identify
my $id = $repo->Identify;
if( !$id->is_success )
{
	BAIL_OUT( "Error parsing static repository: " . $id->message );
}
ok($id->is_success, "Identify is_success");
ok($id->repositoryName && $id->repositoryName eq 'Demo repository');

ok($repo->Identify->version eq '2.0s');
# Removed this test, as paths screw up too much
#ok($repo->Identify->baseURL && $repo->Identify->baseURL eq 'file:///examples/repository.xml');

# ListMetadataFormats
my $lmdf = $repo->ListMetadataFormats;
ok($lmdf->is_success);
ok(my $mdf = $lmdf->next);
ok($mdf && $mdf->metadataPrefix && $mdf->metadataPrefix eq 'oai_dc');

# ListRecords
my $lr = $repo->ListRecords(metadataPrefix=>'oai_rfc1807');
ok($lr->is_success);
my $rec = $lr->next;
is(ref($rec), 'HTTP::OAI::Record', 'ListRecords::next returns Record');
ok($rec && $rec->identifier && $rec->identifier eq 'oai:arXiv:cs/0112017');

# ListIdentifiers
my $li = $repo->ListIdentifiers(metadataPrefix=>'oai_dc');
ok($li->is_success, 'ListIdentifiers: '.$li->message);
my @recs = $li->identifier;
ok(@recs && $recs[-1]->identifier eq 'oai:perseus:Perseus:text:1999.02.0084');

# ListSets
my $ls = $repo->ListSets();
ok($ls->is_success, 'ListSets');
my @errs = $ls->errors;
ok(@errs && $errs[-1]->code eq 'noSetHierarchy');

# GetRecord
my $gr = $repo->GetRecord(metadataPrefix=>'oai_dc',identifier=>'oai:perseus:Perseus:text:1999.02.0084');
ok($gr->is_success, 'GetRecord '.$gr->code." ".$gr->message);
$rec = $gr->next;
ok($rec && $rec->identifier eq 'oai:perseus:Perseus:text:1999.02.0084');

# Errors
$gr = $repo->GetRecord(metadataPrefix=>'oai_dc',identifier=>'invalid',force=>1);
ok($gr->is_error, 'GetRecord bad id');
@errs = $gr->errors;
is(eval { $errs[0]->code }, 'idDoesNotExist', 'idDoesNotExist');

$lr = $repo->ListRecords(metadataPrefix=>'invalid');
ok($lr->is_error, "invalid metadataPrefix is_error");
@errs = $lr->errors;
ok(@errs && $errs[0]->code eq 'cannotDisseminateFormat', "is_error is cannotDisseminateFormat");
