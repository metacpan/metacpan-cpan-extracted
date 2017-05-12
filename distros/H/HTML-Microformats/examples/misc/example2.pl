use lib "lib";
use HTML::Microformats;
use RDF::TrineShortcuts;
use strict;

my $html = <<'HTML';
	
	<div class="vcard" lang="en">
		<span class="fn">Joe Bloggs</span>
		<span class="anniversary">Anniversary: <time class="value" datetime="20061014">14 Oct</time></span>
		<span class="note">Joe Bloggs</span>
		<p class="tel">
			<span class="type">Home</span>
			<span class="type">isdn</span>
			<span class="value">tel:+441234</span>
			<span class="value">567</span>
			<span class="value">890</span>
		<p class="organization-name">Test Company</p>
		<p class="tel"><span class="type" title="work">Tel.: </span><abbr title="+18196234310;ext=5451" class="value">819 623-4310 p.5451</abbr></p>
		<p class="tel"><a href="tel:+18196234310;ext=5452" class="value">819 623-4310 p.5452</a></p>
		<div class="adr">
			<span class="type">intl</span>:
			<span class="country-name">France</span>
			<span class="geo">
				<!-- <span class="reference-frame">My crazy <span class="body">Earth</span> co-ordinates</span> -->
				12.34,   56.78
			</span>
		</div>
		<div class="agent vcard">
			<span class="fn">007</span>
		</div>
	</div>

<div class="figure">
  <img class="image" src="photo.jpeg" alt="">
  <p class="legend">
    <a rel="tag" href="http://en.wikipedia.org/wiki/Photography">Photo</a>
    of <span class="subject">Albert Einstein</span> by
    <span class="vcard credit">
      <span class="fn">Paul Ehrenfest</span>
      (<span class="role">photographer</span>)
    </span>
  </p>
</div>

<div class="vcard" id="celso-hcard">
 <span class="fn n">
  Olá! Meu nome é <span class="given-name">Celso</span>
    <span class="family-name">Fontes</span> 
  </span><br/>
  Meu email é: <span class="email"> celsowm@gmail.com </span>
</div>

HTML

my $doc  = HTML::Microformats->new_document($html, 'http://example.net/');
$doc->assume_all_profiles;
print $doc->json(pretty=>1, convert_blessed=>1);
print rdf_string($doc->model, 'rdfxml');

foreach my $hcard ($doc->objects('hCard'))
{
	print "# ---\n";
	print $hcard->to_vcard;
	print "# -\n";
	print $hcard->to_vcard4;
	print "# -\n";
	print $hcard->to_vcard4_xml;
}

foreach my $g ($doc->objects('geo'))
{
	print "# ---\n";
	print $g->to_kml;
}
