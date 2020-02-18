use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Kelp::Module::WebSocket::AnyEvent',
	VERSION_FROM => 'lib/Kelp/Module/WebSocket/AnyEvent.pm',
	MIN_PERL_VERSION => '5.010',

	TEST_REQUIRES => {
		'Twiggy::Server' => 0,
		'Test::TCP' => 0,
		'LWP::UserAgent' => 0,
		'HTTP::Message' => 0,
		'AnyEvent::WebSocket::Client' => 0,
	},

	PREREQ_PM => {
		'Kelp' => '>= 1',
		'Kelp::Module::Symbiosis' => '>= 1',
		'Plack::App::WebSocket' => '>= 0.08',
		'Try::Tiny' => 0,
	},

	ABSTRACT_FROM => 'lib/Kelp/Module/WebSocket/AnyEvent.pm',
	AUTHOR => 'Bartosz Jarzyna <brtastic.dev@gmail.com>',
	LICENSE => 'perl',
);
