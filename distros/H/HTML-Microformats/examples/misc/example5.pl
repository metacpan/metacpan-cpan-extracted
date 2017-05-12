use lib "lib";
use lib "../XML-Atom-FromOWL/lib";
use HTML::Microformats;
use strict;
use JSON;
use Data::Dumper;
use RDF::TrineShortcuts;
use XML::Atom::FromOWL;

my $html = <<HTML;
	<div class="vevent">
		<span class="dtstart">2001-02-03</span>
		<span class="summary">3 Feb 2001</span>
	</div>
	<div class="hentry hnews" id="foo">
		<h1>Foo</h1>
		<p class="dateline">London, UK (<span class="geo">12.34,56.78</span>).</p>
		<p class="entry-summary entry-content">Foo bar.</p>
		<p class="vcard author"><a href="mailto:eve\@example.com" class="fn url">Eve</a></p>
		<a rel="tag" href="test">Test</a>
		<span class="updated published">2010-03-01T15:00:00+0000</span>
		<a rev="vote-against" href="http://evil.com/">I don't like Evil</a>.
	</div>
	<div class="vcalendar">
		<p class="vevent" id="bar">
			<span class="dtstart">2010-02-03</span>
			<span class="summary">3 Feb 2010</span>
			<span class="rrule">
				<i class="freq">Yearly</i>,
				every <i class="interval">10000</i> years.
			</span>
			<span class="rrule">freq=daily;interval=365220</span>
			<span class="geo">1;2</span>
			<span class="duration">PT24H</span>
			<span class="attendee vcard">
				<span class="cn">Toby Inkster</span>
				<span class="rsvp">true</span>
			</span>
		</p>
		<div class="vfreebusy">
			<span class="freebusy">
				<span class="fbtype">free</span>
				<span class="value">2001-01-01/P6M</span>
				<span class="value"><i class="start">2002-01-01</i> <i class="d">182</i></span>
			</span>
			<span class="summary">freetime</span>
		</div>
		<ul class="vtodo-list">
			<li id="a">Do this</li>
			<li id="b">Do that
				<ol>
					<li id="b1">Do that: part 1</li>
					<li id="b2">Do that: part 2 <a href="foo" rel="vcalendar-parent">p</a></li>
				</ol>
			</li>
		</ul>
		<p class="vevent">
			<b class="dtstart">
				<i class="value">13:00:00</i>
				<i class="value">2008-02-01</i>
				<i class="value">+0100</i>
			</b>
			<b class="dtend">
				<i class="value">15:00:00</i>
			</b>
		</p>
	</div>
HTML

my $doc    = HTML::Microformats->new_document($html, 'http://example.net/');
$doc->assume_all_profiles;

foreach ($doc->objects('hAtom'))
{
	print "=======================================================\n";
	print to_json($_->data, {pretty=>1,canonical=>1,convert_blessed=>1});
	print "-------------------------------------------------------\n";
	print to_json(from_json($_->serialise_model(as => 'RDF/JSON')), {pretty=>1,canonical=>1,convert_blessed=>1});
	print "-------------------------------------------------------\n";
	print $_->to_atom;
}

print "=======================================================\n";
print $doc->serialise_model(as => 'RDF/XML');
