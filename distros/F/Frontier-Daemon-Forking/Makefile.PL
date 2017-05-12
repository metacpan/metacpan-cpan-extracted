use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Frontier::Daemon::Forking',
    'VERSION_FROM'	=> 'Forking.pm',
    'PREREQ_PM'		=> {
                               'Frontier::RPC2' => 0,
                               'HTTP::Daemon'   => 0,
                               'HTTP::Status'   => 0,
                           },
    ($] >= 5.005 ?
      (AUTHOR     => 'Todd Caine <tcaine-at-pobox-dot-com>') : ()),
);
