#!perl
use warnings;
use strict;
use Test::More tests => 19;
use Test::XML;

#######################################################################
# This tests to confirm that the transformation walkers work correctly.
#######################################################################


use Data::Dumper;

use Froody::Walker;
use Froody::Walker::XML;
use Froody::Walker::Terse;

my $xml_driver = Froody::Walker::XML->new;
my $terse_driver = Froody::Walker::Terse->new;

ok( my $walker = Froody::Walker->new({
  spec => {
    top => { text => 1},
  }
}), "created very simple walker" );
ok( $walker->from($xml_driver)->to($terse_driver) );

is $walker->walk( <<'XML' ), 'foo', 'Simple text returns just the content of "top"';
<top>foo</top>
XML
{
  my $log = Test::Logger->expect
    (['froody.walker.xml',
      warn => qr"bad element 'evil' in node 'top' \(not in spec\)"]);
  is $walker->walk( <<'XML' ), '';
<top><evil>haxxor</evil></top>
XML
}

{
  my $log = Test::Logger->expect
    (['froody.walker.xml',
      warn => qr"bad attr 'foo' in node 'top' \(not in spec\)"]);
  is $walker->walk( <<'XML' ), 'bar';
<top foo="wobble">bar</top>
XML
}

ok ($walker->from($terse_driver)->to($xml_driver) );

{
  my $log = Test::Logger->expect
    (['froody.walker.terse',
      warn => qr"unknown key 'foo' defined"]);
  is_xml $walker->walk({
    foo => 'wooble',
    -text => 'bar'
  })->toString, <<'XML';
<top>bar</top>
XML
}
is_xml $walker->walk({
  -text => "\x{e9}",
})->toString, <<'XML';
<top>&#233;</top>
XML

ok( my $complex_walker = Froody::Walker->new({
  spec => {
    top => {
      elts => [qw/ foo /],
      text => 0,
      attr => [],
    },
    'top/foo' => {
      elts => [],
      attr => [qw/ bar /],
      text => 1,
      multi => 1,
    },
  }
}), "created more complex walker");

ok( $complex_walker->from($terse_driver)->to($xml_driver), "Setting drivers" );

my $multi_xml = <<'TEXT';
<top>
  <foo>1</foo>
  <foo>2</foo>
  <foo>3</foo>
</top>
TEXT


is_xml $complex_walker->walk({
  foo => [ 1,2,3 ],
})->toString, $multi_xml, "got multi in xml";

is_xml $complex_walker->walk({
  foo => [
    { -text => 1, bar => 4 },
    { -text => 2, bar => 5 },
    { -text => 3, bar => 6 },
  ]
})->toString, <<'COMPLEX', "more complex structure works as well";
<top>
  <foo bar="4">1</foo>
  <foo bar="5">2</foo>
  <foo bar="6">3</foo>
</top>
COMPLEX

# try the other way
ok ( $complex_walker->from($xml_driver)->to($terse_driver) );
my $result = $complex_walker->walk($multi_xml);
is_deeply( $result, { foo => [
  { -text => 1 },
  { -text => 2 },
  { -text => 3 },
] }, "and goes back again") or die Dumper($result);

# suppose that the list of elements is empty?
ok ( $complex_walker->from($terse_driver)->to($terse_driver) );
$result = $complex_walker->walk({ foo => [] });
is_deeply( $result, { foo => [] }, "empty list is preserved.");

