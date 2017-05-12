#!/usr/bin/perl

# Tests date patterns

use strict;
use lib "lib";
use HTML::Microformats;

# Uses VTODO for components which are *supposed* to fail.

my $html = <<HTML;
	<p class="vevent">
		<i class="dtstart">2001-02-03T01:02:03+0100</i>
		<i class="summary">basic</i>
	</p>
	<p class="vevent">
		<i class="dtstart"><b class="value-title" title="2001-02-03T01:02:03+0100"></b> 3 Feb</i>
		<i class="summary">value-title</i>
	</p>
	<p class="vevent">
		<i class="dtstart">  <b class="value-title" title="2001-02-03T01:02:03+0100"></b> 3 Feb</i>
		<i class="summary">value-title with space</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">2001-02-03</b>
			<b class="value">01:02:03</b>
			<b class="value">+0100</b>
		</i>
		<i class="summary">splitting things up</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01:02:03</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">mixing them up</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">Z</b>
			<b class="value">01:02:03</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">testing 'Z' timezone</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">1am</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">test 1am</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">1 pm</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">test 1pm</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01.02 p.  M.</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">test 01.02 p.M.</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01.02.03 p.M.</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">test 01.02.03 p.M.</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01.02.03 p.M.</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="dtend">
			<b class="value">1.7.3 pm</b>
		</i>
		<i class="summary">dtend feedthrough from dtstart (with 'value')</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01.02.03 p.M.</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="dtend">13:07:03</i>
		<i class="summary">dtend feedthrough from dtstart (no 'value')</i>
	</p>
	<p class="vtodo">
		<i class="dtstart">XXX <b class="value-title" title="2001-02-03T01:02:03+0100"></b> 3 Feb</i>
		<i class="summary">invalid value-title</i>
	</p>

HTML

my $doc    = HTML::Microformats->new_document($html, 'http://example.net/');
$doc->assume_profile('hCalendar');
print $doc->json(pretty=>1,canonical=>1)."\n";

