#!perl -T

use Test::More tests => 6;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Description::PublishInfo;

my $author_data = <<__EOXML__;
<publish-info>
  <book-name>name</book-name>
  <publisher>Samizdat</publisher>
  <city>Vancouver</city>
  <year>2009</year>
  <isbn>0120123456789</isbn>
  <sequence name="seqname2" number="1"/>
  <sequence name="seqname3" number="1"/>
</publish-info>
__EOXML__


my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($author_data);
my $publish_info = EBook::FB2::Description::PublishInfo->new;
my @nodes = $xp->findnodes("/publish-info");
$publish_info->load($nodes[0]);
is($publish_info->sequences, 2);

is($publish_info->book_name, 'name');
is($publish_info->publisher, 'Samizdat');
is($publish_info->city, 'Vancouver');
is($publish_info->year, '2009');
is($publish_info->isbn, '0120123456789');
