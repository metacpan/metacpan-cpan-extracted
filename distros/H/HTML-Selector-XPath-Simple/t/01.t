use strict;
use warnings;
use Carp;
use Test::More tests => 10;
use Test::NoWarnings;
use HTML::Selector::XPath::Simple;

my $xml =<<'END_XML';
<div class="vcard">
  <span class="fn">Foo Bar</span>
  <span class="tel">
    <span class="type">home</span>
    <span class="value">+81-12-3456-7890</span>
  </span>
  <span class="tel">
    <span class="type">work</span>
    <span class="value">+81-98-7654-3210</span>
  </span>
</div>
END_XML

my $selector = HTML::Selector::XPath::Simple->new($xml);

is $selector->select('.vcard .fn'), 'Foo Bar';

is $selector->select('.vcard .tel .type'), 'home';
is $selector->select('.vcard .tel .value'), '+81-12-3456-7890';

my @types = $selector->select('.vcard .tel .type');
is @types, 2;

is $types[0], 'home';
is $types[1], 'work';

my @values = $selector->select('.vcard .tel .value');
is @values, 2;

is $values[0], '+81-12-3456-7890';
is $values[1], '+81-98-7654-3210';
