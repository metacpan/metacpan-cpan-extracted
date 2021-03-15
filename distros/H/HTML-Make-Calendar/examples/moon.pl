#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use HTML::Make::Calendar 'calendar';
use Astro::MoonPhase;
use Date::Calc 'Date_to_Time';
binmode STDOUT, ":encoding(utf8)";
my @moons = qw!🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘!;
my $cal = calendar (dayc => \&daymoon, cdata => \@moons);
print $cal->text ();
exit;

sub daymoon
{
    my ($moons, $date, $element) = @_;
    my $epochtime = Date_to_Time ($date->{year}, $date->{month},
				  $date->{dom}, 0, 0, 0);
    my ($phase) = phase ($epochtime);
    my $text = $moons->[int (8*$phase)] . " <b>$date->{dom}</b>";
    $element->add_text ($text);
}

