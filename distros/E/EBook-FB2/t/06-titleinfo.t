#!perl -T

use Test::More tests => 11;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Description::TitleInfo;

my $author_data = <<__EOXML__;
<title-info>
  <author>
    <first-name>fname1</first-name>
    <last-name>lname1</last-name>
  </author>
  <author>
    <first-name>fname2</first-name>
    <last-name>lname2</last-name>
  </author>

  <translator>
    <first-name>tfname1</first-name>
    <last-name>tlname1</last-name>
  </translator>
  <translator>
    <first-name>tfname2</first-name>
    <last-name>tlname2</last-name>
  </translator>
  <translator>
    <first-name>tfname3</first-name>
    <last-name>tlname3</last-name>
  </translator>

  <book-title>title</book-title>
  <keywords>a,b,c</keywords>
  <date>1234-1234</date>
  <lang>ru</lang>
  <src-lang>en</src-lang>
  <genre match="98">fiction1</genre>
  <genre match="98">fiction2</genre>
  <genre match="98">fiction3</genre>
  <sequence name="seqname1" number="1"/>
  <sequence name="seqname2" number="1"/>
  <sequence name="seqname3" number="1"/>
  <sequence name="seqname4" number="1"/>
  <coverpage><image l:href="#cover1.jpg"/></coverpage>
  <coverpage><image l:href="#cover2.jpg"/></coverpage>
  <coverpage><image l:href="#cover3.jpg"/></coverpage>
  <coverpage><image l:href="#cover4.jpg"/></coverpage>
  <coverpage><image l:href="#cover5.jpg"/></coverpage>

  <annotation>test annotation</annotation>
</title-info>
__EOXML__


my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($author_data);
my $title_info = EBook::FB2::Description::TitleInfo->new;
my @nodes = $xp->findnodes("/title-info");
$title_info->load($nodes[0]);
is($title_info->authors, 2);
is($title_info->translators, 3);
is($title_info->genres, 3);
is($title_info->sequences, 4);
is($title_info->coverpages, 5);

is($title_info->keywords, 'a,b,c');
is($title_info->date, '1234-1234');
is($title_info->lang, 'ru');
is($title_info->src_lang, 'en');
is($title_info->book_title, 'title');
is($title_info->annotation->string_value, 'test annotation');
