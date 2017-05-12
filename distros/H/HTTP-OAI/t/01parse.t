use Test::More tests => 5;

use IO::File;
use HTTP::OAI;
use HTTP::OAI::Metadata::OAI_DC;
ok(1);

my $fh;

my $r = HTTP::OAI::GetRecord->new(handlers=>{
	metadata=>'HTTP::OAI::Metadata::OAI_DC'
});
$fh = IO::File->new('examples/getrecord.xml','r')
	or BAIL_OUT( "Failed to open examples/getrecord.xml: $!" );
$r->parse_file($fh);
$fh->close();

my $rec = $r->next;
ok($rec);
ok($rec->metadata->dc->{creator}->[0] eq 'Aspinwall, Paul S.');

my $dom = $rec->metadata->dom;
my $md = HTTP::OAI::Metadata::OAI_DC->new;
$md->metadata( $dom );
ok($md->dc->{creator}->[0] eq 'Aspinwall, Paul S.');

$r = HTTP::OAI::Identify->new();
$fh = IO::File->new('examples/identify.xml','r')
	or BAIL_OUT( "Failed to open examples/identify.xml: $!" );
$r->parse_file($fh);
$fh->close();

ok($r->repositoryName eq 'citebase.eprints.org');
