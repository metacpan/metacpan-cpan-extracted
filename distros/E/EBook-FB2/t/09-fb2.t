#!perl -T

use Test::More tests => 2;
use EBook::FB2;
use File::Temp qw/ tempfile /;



my $data = <<__EOXML__;
<FictionBook>
    <description>
      <title-info></title-info>
      <document-info>
          <date></date>
          <id></id>
      </document-info>
    </description>
    <body><section>1</section></body>
    <body><section>4</section></body>
    <binary id="id1.png" content-type="content/type">dGVzdHRlc3Q=</binary>
    <binary id="id2.png" content-type="content/type">dGVzdHRlc3Q=</binary>
    <binary id="id3.png" content-type="content/type">dGVzdHRlc3Q=</binary>
</FictionBook>

__EOXML__


my ($fh, $filename) = tempfile();
print $fh $data;
close $fh;
my $fb2 = EBook::FB2->new;
$fb2->load($filename);
unlink $filename;

is($fb2->bodies, 2);
is($fb2->binaries, 3);
