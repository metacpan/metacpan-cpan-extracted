#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Log::Dynamic',
	AUTHOR              => 'James Conerly <jconerly@cpan.org>',
	VERSION_FROM        => 'lib/Log/Dynamic.pm',
	PREREQ_PM           => {
		'Carp'         => 0,
		'Test::More'   => 0,
		'Data::Dumper' => 0,
	},
);

__END__
