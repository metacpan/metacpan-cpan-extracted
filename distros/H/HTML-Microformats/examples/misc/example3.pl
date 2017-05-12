use lib "lib";
use HTML::Microformats;
use strict;
use JSON;
use Data::Dumper;
use RDF::TrineShortcuts;

my $html = <<HTML;
	<head profile="http://example.com/smeg http://xen.adactio.com/">
	<a rel="license" href="../l">License 4.0</a>
	<div class="vcard" lang="en" id="joe">
		<a class="fn url" href="http://joe.example.org/">Joe Bloggs</a> (<span class="gender">male</span>)
		<span class="anniversary">Anniversary: <time class="value" datetime="20061014">14 Oct</time></span>
		<span class="note">Joe Bloggs</span>
		<a href="joe" rel="contact met friend" class="url">joe</a>
		<p class="tel">
			<span class="type">Home</span>
			<span class="type">isdn</span>
			<span class="value">+441234</span>
			<span class="value">567</span>
			<span class="value">890</span>
		<p class="tel">
			<b class="type">cell</b> 07005 123 456
		<p class="email">joe @ example.org
		<p class="organization-name">Test Company
		<div class="adr">
			<span class="type">intl</span>:
			<span class="country-name">France</span>
			<span class="geo">
				12.34,   56.78
			</span>
		</div>
		<div class="agent vcard">
			<span class="fn">007</span>
			<a rel="me" href="foo" class="url">foo</a>
			<a rel="tag" href="Spy">Spy</a>
			<span class="category">British</span>
			<a class="category" rel="tag" href="Fictional">Fictional</a>
		</div>
		<a href="/foo/tag/person" rel="tag">person</a>
		<i class="biota zoology">
			<span class="order">Homo</span>
			<span class="species">sapiens</span>
			<span class="subspecies">sapiens</span>
		</i>
	</div>

	<a href="mailto:alice\@example.net" rev="child">Alice</a>

	<p class="vcard">
	<a href="mailto:eve\@example.com" rel="enemy" class="fn url">Eve</a>

	<p class="hmeasure">1.84 m <span class="type">height</span>
	<a href="http://tallthing.com/" class="item">Tall Thing</a></p>

	<a href="enc" rel="enclosure" type="image/bmp">Picture of Enc</a>


  <div class="vcard">
    <h1 class="fn org">My Org</h1>
    <p>
      <b>General Enquiries:</b>
      <span class="tel">01234 567 890</span>
    </p>
    <p class="agent vcard">
      <span class="org">
        <abbr class="organization-name" title="My Org"></abbr>
        <b class="organization-unit fn">Help Desk</b>
      </span>
      <span class="tel">01234 567 899</span>
    </p>
  </div>

HTML

my $doc    = HTML::Microformats->new_document($html, 'http://example.net/');
$doc->assume_all_profiles;

$doc->objects('hCard')->[0]->get_agent->[0]->set_fn('James Bond');

print $doc->json(pretty=>1,canonical=>1)."\n";

print rdf_string($doc->model, 'rdfxml')."\n";

#print Dumper($doc);
