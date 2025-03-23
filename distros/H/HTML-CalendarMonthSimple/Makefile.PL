use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'HTML::CalendarMonthSimple',
    ABSTRACT_FROM => 'lib/HTML/CalendarMonthSimple.pm',
    VERSION_FROM  => 'lib/HTML/CalendarMonthSimple.pm',
    AUTHOR        => 'Michael R. Davis - MRDVT',
    PREREQ_PM     => {
                      'Test::Simple' => 0.44,
                      'Date::Calc'   => 0,
                     },
'META_MERGE' => {
    'meta-spec' => {
      'version' => 2
    },
    'resources' => {
      'repository' => {
        'url' => 'git@github.com:mrdvt92/perl-HTML-CalendarMonthSimple.git',
        'web' => 'https://github.com/mrdvt92/perl-HTML-CalendarMonthSimple.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-HTML-CalendarMonthSimple',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-HTML-CalendarMonthSimple/issues'
      }
    }
  },
);
