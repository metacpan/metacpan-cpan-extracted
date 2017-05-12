use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HTTP::Daemon::App',
    VERSION_FROM      => 'lib/HTTP/Daemon/App.pm', 
    PREREQ_PM         => {
        'version'           => 0,
        'Unix::PID'         => 0.0.9,
        'HTTP::Daemon'      => 0,
        'HTTP::Daemon::SSL' => 0,
        'HTTP::Status'      => 0,
        'HTTP::Response'    => 0,
        'Acme::Spork'       => 0,
        'Unix::PID'         => 0,
        'File::Spec'        => 0,
    },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/HTTP/Daemon/App.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
