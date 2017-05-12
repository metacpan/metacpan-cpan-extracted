use CPAN::MakeMaker;

WriteMakefile(
              'NAME'         => 'Log::Dispatch::Jabber',
              ($[ >= 5.005) ?
              (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
               ABSTRACT => 'Log messages via Jabber') : (),
              'VERSION_FROM' => 'lib/Log/Dispatch/Jabber.pm',
              'PREREQ_PM'    => {
                                 Log::Dispatch       => '2.01',
                                 Net::Jabber::Client => '1.26',
                                },
              dist              => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
             );
