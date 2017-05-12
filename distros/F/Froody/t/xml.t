#!/usr/bin/perl

########################################################################
# Test the XML loader for stange behavior.  While api.t checks that
# propely formed stuff is loaded okay, this test checks that if you do
# random things with a Froody::API::XML class you get the right errors
########################################################################

use strict;
use warnings;

use Test::Exception;

# start the tests
use Test::More tests => 24;

use_ok("Froody::API::XML");
use Froody::Error qw(err);

#### bad calls to methods ####

dies_ok
  { Froody::API::XML->load_method("Foo"); }
  "try random text in 'load_method'";
ok(err("perl.methodcall.param"), "right error thrown");

dies_ok
  { Froody::API::XML->load_errortype("Foo"); }
  "try random text in 'load_error'";
ok(err("perl.methodcall.param"), "right error thrown");

dies_ok
  { Froody::API::XML->load_method(bless {}, "wibble"); }
  "try random object in 'load_method'";
ok(err("perl.methodcall.param"), "right error thrown");

dies_ok
  { Froody::API::XML->load_errortype(bless {}, "wibble"); }
  "try random object in 'load_errortype'";
ok(err("perl.methodcall.param"), "right error thrown");

### bad xml ###

throws_ok {
  Froody::API::XML->load_spec();
} qr{No xml passed to load_spec}, "passing nothing";
ok(err("perl.methodcall.param"), "right error thrown")
 or diag $@->code;
 
throws_ok {
  Froody::API::XML->load_spec("");
} qr{No xml passed to load_spec}, "parsing empty string";
ok(err("perl.methodcall.param"), "right error thrown")
 or diag $@->code;

throws_ok {
  Froody::API::XML->load_spec("not xml");
} qr{Invalid}, "something not xml";
ok(err("froody.xml.invalid"), "right error thrown")
 or diag $@->code;

throws_ok {
  Froody::API::XML->load_spec("<wibble><wobble></wibble></wobble>");
} qr{Invalid}, "badly formed";
ok(err("froody.xml.invalid"), "right error thrown")
 or diag $@->code;

throws_ok {
  Froody::API::XML->load_spec("<spec></spec>");
} qr{no methods found in spec!}, "missing <methods>";
ok(err("froody.xml.nomethods"), "right error thrown")
 or diag $@->code;

throws_ok {
  Froody::API::XML->load_spec("<spec><methods></methods></spec>");
} qr{no methods found in spec!}, "missing <methods>";
ok(err("froody.xml.nomethods"), "right error thrown")
 or diag $@->code;

throws_ok {
  Froody::API::XML->load_spec("<spec><methods><method/></methods></spec>");
} qr{Can't find the attribute 'name'}, "missing 'name' on methods";
ok(err("froody.xml"), "right error thrown")
 or diag $@->code;

lives_ok {
  Froody::API::XML->load_spec(<<'XML');
<spec>
  <methods>
    <method name="ima.rdf.feed">
      <response>
<rdf:RDF 
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns="http://purl.org/rss/1.0/"
>

  <channel rdf:about="http://www.xml.com/xml/news.rss">
    <title>XML.com</title>
    <link>http://xml.com/pub</link>
    <description>
      XML.com features a rich mix of information and services 
      for the XML community.
    </description>

    <image rdf:resource="http://xml.com/universal/images/xml_tiny.gif" />

    <items>
      <rdf:Seq>
        <rdf:li resource="http://xml.com/pub/2000/08/09/xslt/xslt.html" />
        <rdf:li resource="http://xml.com/pub/2000/08/09/rdfdb/index.html" />
      </rdf:Seq>
    </items>

    <textinput rdf:resource="http://search.xml.com" />

  </channel>
    <image rdf:about="http://xml.com/universal/images/xml_tiny.gif">
    <title>XML.com</title>
    <link>http://www.xml.com</link>
    <url>http://xml.com/universal/images/xml_tiny.gif</url>
  </image>
    <item rdf:about="http://xml.com/pub/2000/08/09/xslt/xslt.html">
    <title>Processing Inclusions with XSLT</title>
    <link>http://xml.com/pub/2000/08/09/xslt/xslt.html</link>
    <description>
     Processing document inclusions with general XML tools can be 
     problematic. This article proposes a way of preserving inclusion 
     information through SAX-based processing.
    </description>
  </item>
    <item rdf:about="http://xml.com/pub/2000/08/09/rdfdb/index.html">
    <title>Putting RDF to Work</title>
    <link>http://xml.com/pub/2000/08/09/rdfdb/index.html</link>
    <description>
     Tool and API support for the Resource Description Framework 
     is slowly coming of age. Edd Dumbill takes a look at RDFDB, 
     one of the most exciting new RDF toolkits.
    </description>
  </item>

  <textinput rdf:about="http://search.xml.com">
    <title>Search XML.com</title>
    <description>Search XML.com's XML collection</description>
    <name>s</name>
    <link>http://search.xml.com</link>
  </textinput>

</rdf:RDF>
      </response>
    </method>
  </methods>
</spec>
XML
};
