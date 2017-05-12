use ExtUtils::MakeMaker;
eval {
    local $SIG{__DIE__};
    require B::Deparse; # as of Perl 5.6
    die "B::Deparse 0.60 or newer needed" if ($B::Deparse::VERSION < 0.6);
};
warn("B::Deparse 0.60 or newer is needed for writing CODE tests as XML\n") if $@;
WriteMakefile(
    'NAME' => 'HTTP::WebTest::XMLParser',
    'VERSION_FROM' => 'lib/HTTP/WebTest/XMLParser.pm',
    'PREREQ_PM' => { HTTP::WebTest => 2.01,
                     XML::SAX => 0,
                     XML::Writer => 0,
                   },
    'ABSTRACT_FROM' => 'lib/HTTP/WebTest/XMLParser.pm',
    'AUTHOR' => 'Johannes la Poutre <japh@lapoutre.com>',
);
