use strict;
use warnings;

use ExtUtils::MakeMaker;

my %prereq_pm = (
    "Class::Accessor"    => 0,
    "DateTime::Locale"   => "0.45",
    "File::Which"        => 0,
    "HTML::ElementTable" => "1.18",
    "Time::Local"        => 0,
);

WriteMakefile(
  NAME         => 'HTML-CalendarMonth',
  VERSION_FROM => 'lib/HTML/CalendarMonth.pm',
  PREREQ_PM    => \%prereq_pm,
);
