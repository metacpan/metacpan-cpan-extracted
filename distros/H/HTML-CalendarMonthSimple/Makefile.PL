use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'HTML::CalendarMonthSimple',
    ABSTRACT_FROM => 'lib/HTML/CalendarMonthSimple.pm',
    VERSION_FROM  => 'lib/HTML/CalendarMonthSimple.pm',
    AUTHOR        => 'Michael R. Davis (qw{perl michaelrdavis com})',
    PREREQ_PM     => {
                      'Test::Simple' => 0.44,
                      'Date::Calc'   => 0,
                     },
);
