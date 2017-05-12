#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite::XML::Parser;
use Template::Test;

#$Kite::XML::Parser::DEBUG = 1;

my $parser = Kite::XML::Parser->new();
ok( $parser );

my $kite = $parser->parse(<<EOF);
<kite name="bbk1" title="Big Bad Kite">
<part name="part 1">
  <outline>
    <curve>
      <point x="10" y="20"/>
    </curve>
  </outline>
  <markup>
    <curve> 
      <point x="50" y="20"/>
      <point x="40" y="20"/>
      <point x="50" y="30"/>
      <text font="Times-Roman">Blah blah blah</text>
      <text>blah</text>
    </curve>
  </markup>
  <layout x="0" y="20"/>
</part>
<part name="part 2">
</part>
</kite>
EOF

ok( $kite );
ok( ref $kite eq 'Kite::XML::Node::Kite' );

test_expect(\*DATA, undef, { kite => $kite });

__DATA__
-- test --
[% kite.name %]: [% kite.title %]
-- expect --
bbk1: Big Bad Kite

-- test --
[% kite.part.0.name %]
[% kite.part.1.name %]
-- expect --
part 1
part 2

-- test --
[% point = kite.part.0.outline.curve.0.point.0 -%]
([% point.x %], [% point.y %])
-- expect --
(10, 20)
