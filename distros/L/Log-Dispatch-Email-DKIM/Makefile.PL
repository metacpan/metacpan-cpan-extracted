use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME			=> 'Log::Dispatch::Email::DKIM',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Log/Dispatch/Email/DKIM.pm',
	ABSTRACT_FROM	=> 'lib/Log/Dispatch/Email/DKIM.pm',
	LICENSE			=> 'gpl_2',	# the bundled LICENSE is GPL version 2
	PREREQ_PM => {
		'Carp' => 0,
		'Scalar::Util' => 0,
		'autodie' => 0,
		'base' => 0,
		'version' => 0,
		'Email::Address::XS' => 0,
		'File::Basename' => 0,
		'File::HomeDir' => 0,
		'File::Spec' => 0,
		'Log::Dispatch' => 0,
		'Params::Get' => 0,
		'Params::Validate::Strict' => 0,
		'Readonly' => 0,
		'Sub::Private' => '0.09',	# 0.09 for the enforce mode
		'Sub::Protected' => 0,
		# Mail::Send::DKIM brings Mail::DKIM, which does the signing
		'Mail::Send::DKIM' => '0.004.0',
	}, TEST_REQUIRES => {
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::More' => 0,
		'Test::Most' => 0,
		'Test::Returns' => 0,
		'File::Temp' => 0,
		'File::Path' => 0,
		'Config' => 0,
		'Errno' => 0,
	},
	clean => { FILES => 'Log-Dispatch-Email-DKIM-*' },
	dist => $dist,
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		prereqs => {
			test => { recommends => { 'Test::Pod' => '1.00' } },
		},
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/Log-Dispatch-Email-DKIM.git',
				web => 'https://github.com/nigelhorne/Log-Dispatch-Email-DKIM',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch-Email-DKIM',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch-Email-DKIM',
				# web => 'https://github.com/nigelhorne/Log-Dispatch-Email-DKIM/issues',
				# url => 'https://github.com/nigelhorne/Log-Dispatch-Email-DKIM/issues',
				mailto => 'bug-Log-Dispatch-Email-DKIM@rt.cpan.org'
			}
		},
	},
	CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
	MIN_PERL_VERSION	=> '5.026'	# Sub::Private needs 5.014 and Params::Validate::Strict 5.026
);
