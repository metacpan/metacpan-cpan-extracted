#!/usr/bin/perl -T

# This script tests HTML::DOM features that are not part of the DOM inter-
# faces.

# See css.t for css_url_fetcher.

# ~~~ I need a test that makes sure HTML::TreeBuilder doesn’t spit out
#     warnings because of hash deref overloading.

use strict; use warnings; use utf8; use lib 't';

use Test::More tests => reverse 54;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2-3: constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

# weaken_response
{
 require HTTP::Response;
 my $res = new HTTP::Response;
 my $doc = new HTML::DOM response => $res, weaken_response => 1;
 require Scalar'Util;
 Scalar'Util'weaken $res;
 is $res, undef, 'weaken_response';
}

# -------------------------#
# Tests 4-24: elem_handler, parse, eof and write

# It is important that this
# 18 May, 2010: I’ve just discovered the previous line, which I apparently
# wrote five months ago; but I have no idea what it was going to say.
$doc->elem_handler(script => sub {
	eval($_[1]->firstChild->data);
	$@ and die;
});

$doc->write(<<'-----');

<body><p>Para 1
<p>Para 2
<script type='application/x-perl'>
$doc->write('<p>Para ' . ($doc->body->childNodes->length+1))
</script>
<p>Para 4
<p>Para 5
<script type='application/x-perl'>
$doc->write('<p>Para ' . ($doc->body->childNodes->length+1))
</script>
</body>

-----

$doc->close;

{
	no warnings 'deprecated';
	local $[ = 1;
	use warnings 'deprecated';
	my @p_tags = $doc->body->childNodes;
	for(1..6){ 
		is $p_tags[$_]->tagName, 'P',
			"body\'s child node no. $_ is a P elem";
		isa_ok $p_tags[$_]->firstChild, 'HTML::DOM::Text',
			"first child of para $_";
		like $p_tags[$_]->firstChild->data, qr/Para $_\b/,
			"contents of para $_";
	}
}

{
 my $script = $doc->createElement('script');
 $script->appendChild($doc->createTextNode('$doc->title("scred")'));
 $doc->body->appendChild($script);
 is $doc->title, 'scred', "elem_handlers are triggered on node insertion";
}

{
 # Test that elements are accessible as soon as they are written (i.e.,
 # that write is not actually buffered, even though we call it that). This
 # was fixed in 0.040.
 $doc->write(<<' -----');
  <script>
   # This is based on a horrid piece of code at
   # http://www.tmxmoney.com/en/scripts/homepage.js
   $doc->write("<img id='img1' height='1' width='1'>");
   $doc->getElementById("img1")->src(
    "http://beacon.securestudies.com/scripts/beacon.dll?blah-blah-blah..."
   );
  </script>
 -----
 $doc->close;
 is $doc->find('img')->src,
   'http://beacon.securestudies.com/scripts/beacon.dll?blah-blah-blah...',
   'so-called buffered write is not actually buffered' 
}

{
 # Test that we don’t get errors when the document’s root element is
 # detached inside an elem handler just before a write.  Fixed in 0.051
 my$ h = new HTML::DOM;
 $h->elem_handler(script => sub { 
         $h->removeChild($h->firstChild); $h->write("foo") }
 );
 ok eval { $h->write("<script></script>"); 1 },
  'no error from writing inside an elem handler when there is no doc root';
}

# -------------------------#
# Tests 25-37: parse_file & charset

use File::Basename;
use File::Spec::Functions 'catfile';

is $doc->charset, undef, 'undefined charset';
ok +($doc = new HTML::DOM) # clobber the existing one
   ->parse_file(catfile(dirname ($0),'test.html')),
	'parse_file returns true';
is $doc->charset, 'utf-8', 'charset';

sub traverse($) {
	my $thing = shift;
	[ map {
		nodeName $_,
		{
			defined(attributes $_)
				? do {
					my $attrs = attributes $_;
					map +($attrs->item($_)->name,
					      $attrs->item($_)->value),
						0..$attrs->length-1;
				}  :()  ,
			$_->isa('HTML::DOM::CharacterData') ?
				(data => data $_)  :()  ,
			hasChildNodes $_ ? (children => &traverse($_))  :()
		}
	} childNodes $thing ]
}

is_deeply traverse $doc, [
  HTML => {
    children => [
      HEAD => {
        children => [
          META => {
            'http-equiv' => 'Content-Type',
             content     => 'text/html; charset=utf-8',
          }
        ],
      },
      BODY => {
        children => [
          P => {
            children => [
              '#text' => {
                data => 'Para 1',
              },
            ],
          },
          P => {
            id => 'aoeu',
            children => [
              '#text' => {
                data => 'Para ',
              },
              B => {
                children => [
                  '#text' => {
                    data => '2',
                  },
                ],
              },
            ],
          },
          P => {
            children => [
              '#text' => {
                data => 'Para ',
              },
              I => {
                children => [
                  '#text' => {
                    data => '3',
                  },
                ],
              },
            ],
          },
          P => {
            children => [
              '#text' => {
                data => 'Para ',
              },
              SPAN => {
                class => 'ssalc',
                children => [
                  '#text' => {
                    data => '4',
                  },
                ],
              },
              '#text' => {
                data => '‼',
              },
              '#text' => {
                data => "\n", # the line break after </html>
              },
            ],
          }
        ],
      },
    ],
  },
], 'parse_file';

ok !(new HTML::DOM)
 ->parse_file(catfile(dirname ($0),'I know this file does not exist.')),
	'parse_file can return false';

($doc = new HTML::DOM charset => 'x-mac-roman') # clobber the existing one
   ->parse_file(catfile(dirname ($0),'test.html'));
like $doc->getElementsByTagName('p')->[-1]->as_text, qr/‚Äº/,
	'parse_file respects existing charset';

# Pathological cases (fixed in 0.036):
{
 my $filename = catfile(dirname ($0),'test.html');
 $doc->open; $doc->close;
 ok eval { $doc->parse_file($filename); 1 },
   'parse_file does not die when close has been called' or diag $@;
 like $doc->innerHTML, qr/ssalc/, 'parse_file works after close';
 $doc->open;
 $doc->removeChild($doc->documentElement);
 ok eval { $doc->parse_file($filename); 1 },
   'parse_file does not die when the root element has been removed';
 like $doc->innerHTML, qr/ssalc/,
  'parse_file works after the removal of the root';
} 

$doc = new HTML::DOM charset => 'iso-8859-1';
is $doc->charset, 'iso-8859-1', 'charset in constructor';
is $doc->charset('utf-16be'), 'iso-8859-1', 'charset get/set';
is $doc->charset, 'utf-16be', 'get charset after set';

# -------------------------#
# Test 38: another elem_handler test with nested <script> elems
#          This was causing infinite recursion before version 0.004.

{
	my $counter; my $doc = new HTML::DOM;
	$doc->elem_handler(script => sub {
		++$counter == 3 and die; # avoid infinite recursion
		(my $data = $_[1]->firstChild->data) =~ s/\\\//\//g;
		$doc->write($data);
		$@ and die;
	});

	eval {
	$doc->write(<<'	-----');
		<script>
			<script>stuff<\/script>
		</script>
	-----
	$doc->close;
	};

	is $counter,2,  'nested <script> elems';
}

# -------------------------#
# Test 39: Yet another elem_handler test, this time with '*' for the tag.
#          I broke this in 0.009 and fixed it in 0.010.

{
	my $counter; my $doc = new HTML::DOM;
	$doc->elem_handler('*' => sub {
		++$counter;
	});

	$doc->write('<p><b><i></i></b></p>');

	is $counter,3,  'elem_handler(*)';
}


# -------------------------#
# Tests 40-43: event_parent

{
	my $doc = new HTML::DOM;
	my $thing = bless[];
	is $doc->event_parent, undef, 'event_parent is initially undef';
	is $doc->event_parent($thing), undef,
		'event parent returns undef when setting the first time';;
	is $doc->event_parent, $thing,, 'and setting it actually worked';
	require Scalar'Util;
	Scalar'Util'weaken($thing);
	is $thing, undef, 'event_parent holds a weak reference';
}

# -------------------------#
# Tests 44-51: base

{
 my $doc = new HTML::DOM url => 'file:///';
 $doc->open, $doc->close;
 is $doc->base, 'file:///', '->base with no <base>';
 $doc->find('head')->innerHTML('<base href="file:///Volumes/">');
 is $doc->base, 'file:///Volumes/', '->base from <base>';
 $doc->find('base')->getAttributeNode('href'); # autoviv the attr node
 ok !ref $doc->base, 'base returns a plain scalar';

 require HTTP'Response;
 $doc = new HTML::DOM response => new HTTP'Response 200, OK => [
  content_type => 'text/html',
  content_base => 'http://websms.rogers.page.ca/skins/rogers-oct2009/',
 ], '';
 is $doc->base, 'http://websms.rogers.page.ca/skins/rogers-oct2009/',
     'base from response object';

 $doc->innerHTML("<base target=_blank><base href='http://rext/'>");
 is $doc->base, "http://rext/",
  'retval of base when <base target> comes before <base href>';

 "z" =~ /z/;  # (test for weird bug introduced in 0.033 & fixed in 0.034)
 is $doc->base, "http://rext/",
  'base after regexp match that does not match the base';

 # base with data URLs
 $doc  = new HTML::DOM url => "data:text/html,blahblahblah";
 is $doc->base, "data:text/html,blahblahblah", 'base with data URL';
 # This one was fixed in 0.057:
 my $r = new HTTP'Response 200, OK => [content_type=>'text/html'], '';
 require HTTP'Request;
 request $r new HTTP'Request GET => 'data:text/html,blooblah';
 $doc = new HTML::DOM response => $r;
 is $doc->base, 'data:text/html,blooblah';
}

# -------------------------#
# Test 52-4:  Yet another elem_handler test, for when elem_handlers orphan
#             the <html> element.  This also makes sure elem_handers  are
#             called even without closing tags. (Both were fixed 0.036.)


{
	my $doc = new HTML::DOM;
	my $accum = '';
	my $doc_elem;
	$doc->elem_handler('p' => sub {
	 $accum .= 'p';
	 my $doc = shift;
	 if(my $de = $doc->documentElement) {
	  $doc_elem = $de;
	  $doc->removeChild($de)
	 }
	});

	ok eval { $doc->write('<p><p>'); $doc->close; 1; },
	 'orphaning the doc elem does not stop parsing';
	is $accum,'pp',  'implicit closing tags trigger elem_handler';
	is $doc_elem->innerHTML,'<head></head><body><p></p><p></p></body>',
	  'parsing continues in the orphaned element';
}
