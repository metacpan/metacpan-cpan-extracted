use strict;
use warnings FATAL => 'all';
use Test::More;
use HTML::FillInForm;

# See http://www.w3.org/TR/html5/forms.html#the-input-element

my %data = (
  tel => '00-0000-0000',
  search => 'search word',
  url => 'http://localhost',
  email => 'foo@example.com',
  datetime => '2012-10-10T00:00Z',
  date => '2012-10-10',
  month => '2012-10',
  week => '2012-W10',
  time => '00:00',
  'datetime-local' => '2012-10-10T00:00',
  number => 1,
  range => 10,
  color => '#000000',
);

plan tests => scalar keys %data;

my $html =
  '<!doctype html><html><body><form>' .
  (join '', map { qq/<input type="$_" name="$_">/ } keys %data) .
  '</form></body></html>';


my $result = HTML::FillInForm->new->fill(\$html, \%data);

for my $key (keys %data) {
  my ($input) = $result =~ /(<input[^>]+type="$key"[^>]*>)/;
  like $input => qr/value="$data{$key}"/, "filled $key";
}
