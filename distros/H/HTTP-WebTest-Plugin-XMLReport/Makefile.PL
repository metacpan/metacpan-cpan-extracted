use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'HTTP::WebTest::Plugin::XMLReport',
    'VERSION_FROM'  => 'lib/HTTP/WebTest/Plugin/XMLReport.pm',
    'PREREQ_PM'     => {
                        'HTTP::WebTest' => 2.00,
                        'XML::Writer'   => 0.4,
                        'IO::Scalar'    => 2.0,
                        'Test::More'    => 0,
                       },
    'AUTHOR'        => 'Johannes la Poutre <japh@lapoutre.com>',
    'ABSTRACT_FROM' => 'lib/HTTP/WebTest/Plugin/XMLReport.pm',
);
