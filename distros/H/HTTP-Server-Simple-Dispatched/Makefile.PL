use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'HTTP::Server::Simple::Dispatched',
	AUTHOR              => 'Paul Driver <frodwith@cpan.org>',
	VERSION_FROM        => 'lib/HTTP/Server/Simple/Dispatched.pm',
	ABSTRACT_FROM       => 'lib/HTTP/Server/Simple/Dispatched.pm',
	PL_FILES            => {},
	PREREQ_PM => {
		'Test::More' => 0,

		'Moose' => 0,

		'HTTP::Server::Simple' => 0,
		'HTTP::Request'        => 0,
		'HTTP::Response'       => 0,

		'URI'         => 0, 
		'URI::Escape' => 0,
		'MIME::Types' => 0,

		'File::Spec::Functions' => 0,

		'Data::Dumper'      => 0,
		'Devel::StackTrace' => 0,       
		'Carp'              => 0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'HTTP-Server-Simple-Dispatched-*' },
);
