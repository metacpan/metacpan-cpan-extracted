use Test::More tests => 13; # should add some more
use HTML::Microformats;

my $html = <<'HTML';
<html lang=en>

	<p class="vevent">
		<i class="dtstart">2001-02-03T01:02:03+0100</i>
		<i class="summary">Event 01 - basic</i>
	</p>
	<p class="vevent">
		<i class="dtstart"><b class="value-title" title="2001-02-03T01:02:03+0100"></b> 3 Feb</i>
		<i class="summary">Event 02 - value-title</i>
	</p>
	<p class="vevent">
		<i class="dtstart">  <b class="value-title" title="2001-02-03T01:02:03+0100"></b> 3 Feb</i>
		<i class="summary">Event 03 - value-title with space</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">2001-02-03</b>
			<b class="value">01:02:03</b>
			<b class="value">+0100</b>
		</i>
		<i class="summary">Event 04 - splitting things up</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01:02:03</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">Event 05 - mixing them up</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">Z</b>
			<b class="value">01:02:03</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">Event 06 - testing 'Z' timezone</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">1am</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">Event 07 - test 1am</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">1 pm</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">Event 08 - test 1pm</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01.02 p.  M.</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">Event 09 - test 01.02 p.M.</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01.02.03 p.M.</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="summary">Event 10 - test 01.02.03 p.M.</i>
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
		<i class="summary">Event 11 - dtend feedthrough from dtstart (with 'value')</i>
	</p>
	<p class="vevent">
		<i class="dtstart">
			<b class="value">+0100</b>
			<b class="value">01.02.03 p.M.</b>
			<b class="value">2001-02-03</b>
		</i>
		<i class="dtend">13:07:03</i>
		<i class="summary">Event 12 - dtend feedthrough from dtstart (no 'value')</i>
	</p>
	<p class="vtodo">
		<i class="dtstart">XXX <b class="value-title" title="2001-02-03T01:02:03+0100"></b> 3 Feb</i>
		<i class="summary">Todo 01 - invalid value-title</i>
	</p>

HTML

my $document = HTML::Microformats->new_document($html, 'http://example.com/');
$document->assume_all_profiles;

my ($calendar) = $document->objects('hCalendar');
my @events = sort { $a->data->{summary} cmp $b->data->{summary} }
	@{ $calendar->get_vevent };

is($events[0]->get_dtstart,
	'2001-02-03T01:02:03+0100',
	$events[0]->get_summary);

is($events[1]->get_dtstart,
	'2001-02-03T01:02:03+0100',
	$events[1]->get_summary);

is($events[2]->get_dtstart,
	'2001-02-03T01:02:03+0100',
	$events[2]->get_summary);

is($events[3]->get_dtstart,
	'2001-02-03T01:02:03+0100',
	$events[3]->get_summary);

is($events[4]->get_dtstart,
	'2001-02-03T01:02:03+0100',
	$events[4]->get_summary);

is($events[5]->get_dtstart,
	'2001-02-03T01:02:03+0000',
	$events[5]->get_summary);

is($events[6]->get_dtstart,
	'2001-02-03T01:00+0100',
	$events[6]->get_summary);

is($events[7]->get_dtstart,
	'2001-02-03T13:00+0100',
	$events[7]->get_summary);

is($events[8]->get_dtstart,
	'2001-02-03T13:02+0100',
	$events[8]->get_summary);

is($events[9]->get_dtstart,
	'2001-02-03T13:02:03+0100',
	$events[9]->get_summary);

is($events[10]->get_dtend,
	'2001-02-03T13:07:03+0100',
	$events[10]->get_summary);

is($events[11]->get_dtend,
	'2001-02-03T13:07:03+0100',
	$events[11]->get_summary);

my @todos = sort { $a->data->{summary} cmp $b->data->{summary} }
	@{ $calendar->get_vtodo };

is($todos[0]->get_dtstart,
	undef,
	$todos[0]->get_summary);

