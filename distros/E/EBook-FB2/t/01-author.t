#!perl -T

use Test::More tests => 12;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Description::Author;

my $author_data = <<__EOXML__;
<author>
  <first-name>first</first-name>
  <middle-name>middle</middle-name>
  <last-name>last</last-name>
  <nickname>nickname</nickname>
  <home-page>homepage1</home-page>
  <home-page>homepage2</home-page>
  <home-page>homepage3</home-page>
  <id>id</id>
  <email>email1</email>
  <email>email2</email>
</author>
__EOXML__


my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($author_data);
my $author = EBook::FB2::Description::Author->new;
my @nodes = $xp->findnodes("/author");
$author->load($nodes[0]);
is($author->first_name, 'first');
is($author->middle_name, 'middle');
is($author->last_name, 'last');
is($author->nickname, 'nickname');
is($author->id, 'id');
# emails
is($author->emails, 2);
is(($author->emails)[0], 'email1');
is(($author->emails)[1], 'email2');
#homepages
is($author->home_pages, 3);
is(($author->home_pages)[0], 'homepage1');
is(($author->home_pages)[1], 'homepage2');
is(($author->home_pages)[2], 'homepage3');
