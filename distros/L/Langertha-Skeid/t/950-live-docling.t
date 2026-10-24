use strict;
use warnings;
use Test::More;
use Test::Mojo;
use JSON::MaybeXS qw( decode_json );
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Live test against a real docling-serve (skeid ADR 0028). Skipped unless SKEID_LIVE_DOCLING_URL is
# set, e.g. http://10.230.30.250:5001 -- the node is a Python service, started and watched by
# xt/live/skeid-live (Perl for the management, Python for the AI work). SKEID_LIVE_DOCLING_KEY is the
# node's X-Api-Key.

my $URL = $ENV{SKEID_LIVE_DOCLING_URL}
  or plan skip_all => 'set SKEID_LIVE_DOCLING_URL to run against a real docling-serve';
my $KEY = $ENV{SKEID_LIVE_DOCLING_KEY};

# A two page PDF, built by hand: the answer must count two pages in json_content.
my @text = ( 'Skeid live test page one.', 'Second page of the live test.' );
my ( @obj, @kid );
$obj[1] = '<< /Type /Catalog /Pages 2 0 R >>';
$obj[3] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
my $n = 4;
for my $t (@text) {
  my $s = "BT /F1 18 Tf 72 700 Td ($t) Tj ET";
  my ( $c, $p ) = ( $n++, $n++ );
  $obj[$c] = "<< /Length " . length($s) . " >>\nstream\n$s\nendstream";
  $obj[$p] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents $c 0 R /Resources << /Font << /F1 3 0 R >> >> >>";
  push @kid, "$p 0 R";
}
$obj[2] = "<< /Type /Pages /Kids [@kid] /Count " . @kid . ' >>';
my ( $pdf, @off ) = ("%PDF-1.4\n");
for my $i ( 1 .. $#obj ) { $off[$i] = length $pdf; $pdf .= "$i 0 obj\n$obj[$i]\nendobj\n" }
my $xref = length $pdf;
$pdf .= "xref\n0 " . @obj . "\n0000000000 65535 f \n" . join( '', map { sprintf "%010d 00000 n \n", $off[$_] } 1 .. $#obj )
  . "trailer\n<< /Size " . @obj . " /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n";

my @usage;
my $skeid = Langertha::Skeid->new(
  config_reload_interval => 0,
  config_loader => sub { +{
    keys => { },
    nodes => [ { id => 'docling-live', url => $URL, kind => 'documents', max_conns => 2,
      ( defined $KEY ? ( api_key_env => q{SKEID_LIVE_DOCLING_KEY}, api_key_header => q{X-Api-Key} ) : () ) } ],
  } },
  store_usage_event => sub { push @usage, $_[1]; return { ok => 1 } },
);
my $t = Test::Mojo->new( Langertha::Skeid::Proxy->build_app( skeid => $skeid ) );
$t->ua->inactivity_timeout(300);

my $B = 'live-boundary-4711';
my $body = "--$B\r\nContent-Disposition: form-data; name=\"files\"; filename=\"live.pdf\"\r\nContent-Type: application/pdf\r\n\r\n$pdf\r\n"
  . join( '', map { "--$B\r\nContent-Disposition: form-data; name=\"to_formats\"\r\n\r\n$_\r\n" } qw( json md ) )
  . "--$B--\r\n";

$t->post_ok( '/v1/convert/file' => { 'Content-Type' => "multipart/form-data; boundary=$B" } => $body )
  ->status_is(200)->json_is( '/status' => 'success' );

my $doc = decode_json( $t->tx->res->body )->{document};
is_deeply [ sort keys %{ $doc->{json_content}{pages} } ], [ 1, 2 ], 'the real answer carries one pages entry per page';
like $doc->{md_content}, qr/page one/, 'markdown has the text of the first page';

is scalar(@usage), 1, 'one usage event';
is $usage[0]{pages}, 2, 'pages: counted off the real json_content';
is $usage[0]{documents}, 1, 'documents: one';
is $usage[0]{api_format}, 'docling', 'api_format docling';

done_testing;
