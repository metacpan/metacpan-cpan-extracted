use Test::More tests => 3;

use IO::File;
use HTTP::OAI;
use HTTP::OAI::Metadata::METS;

ok(1);

my $fh;

my $r = HTTP::OAI::GetRecord->new(handlers=>{
	metadata=>'HTTP::OAI::Metadata::METS'
});
$fh = IO::File->new('examples/mets.xml','r') or die "Unable to open examples/mets.xml: $!";
$r->parse_file($fh);
$fh->close();

my $rec = $r->record;

my @files = $rec->metadata->files;

is(scalar(@files), 4, 'file_count');

is($files[1]->{ url }, "http://dspace.mit.edu/bitstream/1721.1/8338/2/50500372-MIT.pdf", 'file_url');
