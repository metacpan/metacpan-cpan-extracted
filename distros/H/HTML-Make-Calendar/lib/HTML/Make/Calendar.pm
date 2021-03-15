package HTML::Make::Calendar;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/calendar/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

our $VERSION = '0.01';

use Date::Calc ':all';
use HTML::Make;
use Table::Readable 'read_table';
#use Data::Dumper;

# Default HTML elements and classes.

my @dowclass = (undef, "mon", "tue", "wed", "thu", "fri", "sat", "sun");

# Read the configuration file.

my $html_file = __FILE__;
$html_file =~ s!\.pm!/html.txt!;
my @html = read_table ($html_file);
my %html;
for (@html) {
    $html{$_->{item}} = $_
}

# Add an HTML element defined by $thing to $parent.

sub add_el
{
    my ($parent, $thing, $override) = @_;
    my $class = $thing->{class};
    my $type = $thing->{element};
    if ($override) {
	$type = $override;
    }
    my $element;
    if ($class) {
	$element = $parent->push ($type, class => $class);
    }
    else {
	# Allow non-class elements if the user doesn't want a class.
	$element = $parent->push ($type);
    }
    return $element;
}

sub add_month_heading
{
    my ($o, $tbody) = @_;
    # Add the title to the calendar
    my $titler = $tbody->push ('tr');
    my $titleh = $titler->push ('th', attr => {colspan => 7});
    my $my;
    if ($o->{monthc}) {
	my $date = {month => $o->{month}, year => $o->{year}};
	$my = &{$o->{monthc}} ($o->{cdata}, $date, $titleh);
    }
    else {
	$my = Month_to_Text ($o->{month}) . " $o->{year}";
	$titleh->add_text ($my);
    }
    # To do: Allow the caller to override this.
    my $wdr = $tbody;
    if (! $o->{weekless}) {
	$wdr = $tbody->push ('tr');
    }
    for my $col (1..7) {
	my $dow = $o->{col2dow}{$col};
	my $wdt = $o->{daynames}[$dow];
	my $dow_el = add_el ($wdr, $html{dow});
	$dow_el->add_text ($wdt);
    }
}

sub option
{
    my ($o, $options, $what) = @_;
    if ($options->{$what}) {
	if ($o->{verbose}) {
	    vmsg ("Setting $what to $options->{$what}");
	}
	$o->{$what} = $options->{$what};
	delete $options->{$what};
    }
}

sub check_first
{
    my ($o) = @_;
    if ($o->{first} != 1) {
	if (int ($o->{first}) != $o->{first} ||
	    $o->{first} < 1 ||
	    $o->{first} > 7) {
	    carp "Use a number between 1 (Monday) and 7 (Sunday) for first";
	    $o->{first} = 1;
	}
    }
}

# Map from columns of the calendar to days of the week, e.g. 1 -> 7 if
# Sunday is the first day of the week.

sub map_dow2col
{
    my ($o) = @_;
    my %col2dow;
    for (1..7) {
	my $col2dow = $_ + $o->{first} - 1;
	if ($col2dow > 7) {
	    $col2dow -= 7;
	}
	$col2dow{$_} = $col2dow;
    }
    my %dow2col = reverse %col2dow;
    $o->{col2dow} = \%col2dow;
    $o->{dow2col} = \%dow2col;
}

sub calendar
{
    my (%options) = @_;
    my $o = {};
    bless $o;
    $o->option (\%options, 'verbose');
    ($o->{year}, $o->{month}, undef) = Today ();
    $o->option (\%options, 'year');
    $o->option (\%options, 'month');
    $o->option (\%options, 'dayc');
    $o->option (\%options, 'monthc');
    $o->option (\%options, 'cdata');
    $o->{first} = 1;
    $o->option (\%options, 'first');
    $o->check_first ();
    $o->option (\%options, 'weekless');
    $o->option (\%options, 'daynames');
    # To do: Allow the user to use their own HTML tags.
    $o->{month_html} = $html{month}{element};
    $o->{week_html} = $html{week}{element};
    $o->{day_html} = $html{day}{element};
    $o->option (\%options, 'month_html');
    $o->option (\%options, 'week_html');
    $o->option (\%options, 'day_html');
    if ($o->{daynames}) {
	if (defined $o->{daynames}[0] && scalar (@{$o->{daynames}}) == 7) {
	    # Off-by-one
	    unshift @{$o->{daynames}}, '';
	}
    }
    else {
	for (1..7) {
	    $o->{daynames}[$_] = substr (Day_of_Week_to_Text ($_), 0, 2);
	}
    }
#    $o->option (\%options, 'html_month');
#    $o->option (\%options, 'html_week');
    for my $k (sort keys %options) {
	if ($options{$k}) {
	    carp "Unknown option '$k'";
	    delete $options{$k};
	}
    }
    $o->map_dow2col ();
    my $dim = Days_in_Month ($o->{year}, $o->{month});
    if ($o->{verbose}) {
	vmsg ("There are $dim days in month $o->{month} of $o->{year}");
    }
    my @col;
    # The number of weeks
    my $weeks = 1;
    my $prev = 0;
    for my $day (1..$dim) {
	my $dow = Day_of_Week ($o->{year}, $o->{month}, $day);
	my $col = $o->{dow2col}{$dow};
	$col[$day] = $col;
	if ($col < $prev) {
	    $weeks++;
	}
	$prev = $col;
    }
    # The number of empty cells we need at the start of the month.
    $o->{fill_start} = $col[1] - 1;
    $o->{fill_end} = 7 - $col[-1];
    if ($o->{verbose}) {
	vmsg ("Start $o->{fill_start}, end $o->{fill_end}, weeks $weeks");
    }
    my @cells;
    # To do: Allow the user to colour or otherwise alter empty cells,
    # for example with a callback or with a user-defined class.
    for (1..$o->{fill_start}) {
	push @cells, {};
    }
    for (1..$dim) {
	my $col = $col[$_];
	push @cells, {dom => $_, col => $col, dow => $o->{col2dow}{$col}};
    }
    for (1..$o->{fill_end}) {
	push @cells, {};
    }
    my $calendar = HTML::Make->new ($o->{month_html},
				    class => $html{month}{class});
    my $tbody = $calendar;
    my $table;
    if ($o->{month_html} eq 'table') {
	$tbody = $calendar->push ('tbody');
	$table = 1;
    }
    if (! $o->{weekless}) {
	if ($table) {
	    $o->add_month_heading ($tbody);
	}
    }
    # wom = week of month
    for my $wom (1..$weeks) {
	my $week = $tbody;
	if (! $o->{weekless}) {
	    $week = add_el ($tbody, $html{week}, $o->{week_html});
	}
	for my $col (1..7) {
	    # dow = day of week
	    my $dow = $o->{col2dow}{$col};
	    my $day = add_el ($week, $html{day}, $o->{day_html});
	    my $cell = shift @cells;
	    # dom = day of month
	    my $dom = $cell->{dom};
	    if (defined $dom) {
		$day->add_class ('cal-' . $dowclass[$dow]);
		if ($o->{dayc}) {
		    &{$o->{dayc}} ($o->{cdata},
			  {
			      year => $o->{year},
			      month => $o->{month},
			      dom => $dom,
			      dow => $dow,
			      wom => $wom,
			  }, 
			  $day);
		}
		else {
		    $day->push ('span', text => $dom, class => 'cal-dom');
		}
	    }
	    else {
		$day->add_class ('cal-noday');
	    }
	    # To do: allow a callback on the packing cells
	}
    }
    return $calendar;
}

# To do: Add caller line numbers rather than just use print.
sub vmsg
{
    print "@_\n";
}

1;
