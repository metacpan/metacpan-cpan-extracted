use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Logger::Syslog',
    VERSION_FROM    => 'lib/Logger/Syslog.pm',
    PREREQ_PM       => { 'Sys::Syslog' => '0.13' }
);
