#!perl -T

use Test::More tests => 9;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Description::DocumentInfo;

my $author_data = <<__EOXML__;
<document-info>
  <author>
    <first-name>fname</first-name>
    <last-name>lname</last-name>
  </author>
  <author>
    <first-name>fname2</first-name>
    <last-name>lname2</last-name>
  </author>
  <program-used>perl</program-used>
  <date>1234</date>
  <src-url>url1</src-url>
  <src-url>url2</src-url>
  <src-url>url3</src-url>
  <src-ocr>ocr</src-ocr>
  <id>777</id>
  <version>1.0</version>
  <history>hist</history>
  <publisher>publisher1</publisher>
  <publisher>publisher2</publisher>
  <publisher>publisher3</publisher>
  <publisher>publisher4</publisher>
</document-info>

__EOXML__


my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($author_data);
my $document_info = EBook::FB2::Description::DocumentInfo->new;
my @nodes = $xp->findnodes("/document-info");
$document_info->load($nodes[0]);
is($document_info->authors, 2);
is($document_info->src_urls, 3);
is($document_info->publishers, 4);

is($document_info->program_used, 'perl');
is($document_info->date, '1234');
is($document_info->src_ocr, 'ocr');
is($document_info->id, '777');
is($document_info->version, '1.0');
is($document_info->history, 'hist');
