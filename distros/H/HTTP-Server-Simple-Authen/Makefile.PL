use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'HTTP::Server::Simple::Authen',
    'VERSION_FROM' => 'lib/HTTP/Server/Simple/Authen.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Authen::Simple => 0.04,
        HTTP::Server::Simple => 0.16,
    },
);
