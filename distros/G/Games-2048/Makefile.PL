use 5.012;
use strict;
use warnings;
use inc::Module::Install;

name     'Games-2048';
all_from 'lib/Games/2048.pm';
license  'perl';

perl_version 5.012;

resources (
	# homepage   => 'http://yourwebsitehere.com',
	# IRC        => 'irc://irc.perl.org/#Games-2048',
	license    => 'http://dev.perl.org/licenses/',
	repository => {
		type => 'git',
		url => 'git://github.com/Blaizer/Games-2048.git',
		web => 'https://github.com/Blaizer/Games-2048',
	},
	bugtracker => {
		url => 'https://github.com/Blaizer/Games-2048/issues',
	},
);

configure_requires (
);

build_requires (
);

test_requires (
);

requires (
	'Moo'               => 1.004,
	'strictures'        => 1.005,
	'Term::ReadKey'     => 2.31,
	'File::HomeDir'     => 1.00,
	('Win32::Console::ANSI' => 1.07) x ($^O eq 'MSWin32'),
);

install_script (
	'2048',
);

install_as_cpan;
WriteAll;
