# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN {plan test => 3;}
END {print "not ok 1\n" unless $loaded;}
use HTML::PrettyPrinter;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $e = HTML::Element->new_from_lol
  (['html',
    ' ',
    ['head',
     ['title', 'Test HTML PrettyPrinter' ],
     ['base',{'href' => 'http://localhost/test.html'}]
    ],
    ' ',
    ['body',
     {'lang', 'en-US'},
     ' stuff ä ',
     ['p', 'um, p < 4!', {'class' => 'par123'}, 
      ['a',{'href' => 'b'},'link']
     ],
     ['div', {foo => 'bar'}, '123 ',
      ['ul',{'compact' => 'compact'},
       ['li','item1 '],
       ['li','item2 ',{'type' => 'SQUARE'}],
      ]
     ]
    ]
   ]
  );


sub compare {
  my ($lar,$expected) = @_;
  my @ela = split(/\n/,$expected);
  
  my $ok = 1;
  if (scalar(@{$lar}) == scalar(@ela)) {
    my $i = 0;
    while (@ela) {
      $i++;
      my ($s,$es) = (shift @{$lar}, shift @ela);
      chomp $s;
      if ($s ne $es) {
	$ok = 0;
	print "line $i:\n\tgot      '$s',\n\texpected '$es'\n";
      }
    }
  }
  else {
    $ok = 0;
    print "got ".scalar(@{$lar})." lines, expected ".scalar(@ela)."\n";
  }
  ok $ok, 1;
}
      
# === Test 1 === Default ===
my $hpp = HTML::PrettyPrinter->new('uppercase' => 1);


my $html1 = << "EOF";
<HTML>
  <HEAD><TITLE>Test HTML PrettyPrinter</TITLE><BASE
      HREF="http://localhost/test.html"></HEAD>
  <BODY LANG=en-US> stuff ä
    <P CLASS=par123>um, p &lt; 4!<A HREF=b>link</A></P><DIV FOO=bar>123
      <UL COMPACT><LI>item1 </LI><LI TYPE=SQUARE>item2
\t</LI></UL></DIV></BODY></HTML>
EOF
compare($hpp->format($e),$html1);

# === Test2 ===
$hpp->tabify(0);
$hpp->allow_forced_nl(1);
$hpp->quote_attr(1);

my $html2 = << 'EOF';
<HTML>
  <HEAD>
    <TITLE>Test HTML PrettyPrinter</TITLE>
    <BASE HREF="http://localhost/test.html">
  </HEAD>
  <BODY LANG="en-US"> stuff ä
    <P CLASS="par123">um, p &lt; 4!<A HREF="b">link</A></P>
    <DIV FOO="bar">123
      <UL COMPACT>
        <LI>item1 </LI>
        <LI TYPE="SQUARE">item2 </LI>
      </UL>
    </DIV>
  </BODY>
</HTML>
EOF

compare($hpp->format($e),$html2);

# === Test3 ===
$hpp->entities($hpp->entities().'ä');
$hpp->min_bool_attr(0);
$e->address("0.1.1")->attr('_hpp_skip',1);

my $html3 = << 'EOF';
<HTML>
  <HEAD>
    <TITLE>Test HTML PrettyPrinter</TITLE>
  </HEAD>
  <BODY LANG="en-US"> stuff &auml;
    <P CLASS="par123">um, p &lt; 4!<A HREF="b">link</A></P>
    <DIV FOO="bar">123
      <UL COMPACT="compact">
        <LI>item1 </LI>
        <LI TYPE="SQUARE">item2 </LI>
      </UL>
    </DIV>
  </BODY>
</HTML>
EOF

compare($hpp->format($e),$html3);


