#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME                => 'Lingua::EN::NameCase',
	# AUTHOR              => 'Barbie <barbie@cpan.org>',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM        => 'lib/Lingua/EN/NameCase.pm',
	ABSTRACT            => "Correctly case a person's name from UPERCASE or lowcase",
	LICENSE             => 'artistic_2',
	PL_FILES            => {},
	MIN_PERL_VERSION    => '5.010',
	CONFIGURE_REQUIRES  => { 'ExtUtils::MakeMaker' => '6.64' },
	PREREQ_PM => {
		'Carp'                  => '0',
		'Exporter'              => '0',
		'List::Util'            => '0',
		'Readonly'              => '0',
		'autodie'               => '0',
		'IPC::System::Simple'   => '0',    # needed by "use autodie qw(:all)"
	}, TEST_REQUIRES => {
		'Config' => '0',
		'Cwd' => '0',
		'Encode' => '0',
		'Errno' => '0',
		'File::Find' => '0',
		'File::Path' => '0',
		'File::Spec' => '0',
		'File::Temp' => '0',
		'FindBin' => '0',
		'IO::File' => '0',
		'JSON::PP' => '0',
		'POSIX' => '0',
		'Scalar::Util' => '0',
		'Test::DescribeMe' => '0',
		'Test::Memory::Cycle' => '0',
		'Test::Mockingbird' => '0',
		'Test::More' => '0',
		'Test::Most' => '0',
		'Test::Needs' => '0',
		'Test::Which' => '0',
		'Test::Without::Module' => '0',
		'Time::HiRes' => '0',
	}, 'LIBS'              => [''],   # e.g., '-lm'
	'DEFINE'            => '',     # e.g., '-DHAVE_SOMETHING'
	'INC'               => '',     # e.g., '-I/usr/include/other'
	dist => $dist,
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		prereqs => {
			runtime => { recommends => { 'Sub::Private' => '0.09' } },
			test => { recommends => {
				'IPC::Run' => '0',
				'IPC::Run3' => '0',
				'Test::Mockingbird::TimeTravel' => '0',
				'Test::Returns' => '0',
				'YAML::XS' => '0',
			} },
		},
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Lingua-EN-NameCase.git',
				web => 'https://github.com/nigelhorne/Lingua-EN-NameCase',
				repository => 'https://github.com/nigelhorne/Lingua-EN-NameCase',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-EN-NameCase',
				# mailto => 'bug-Lingua-EN-NameCase@rt.cpan.org'
				web => 'https://github.com/nigelhorne/Lingua-EN-NameCase/issues',
				url => 'https://github.com/nigelhorne/Lingua-EN-NameCase/issues',
			}
		},
	},
);
