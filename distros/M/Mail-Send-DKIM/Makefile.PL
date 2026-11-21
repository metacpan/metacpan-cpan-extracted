#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

# Mail::DKIM needs Crypt::OpenSSL::RSA, and that and its own prerequisites
# (Crypt::OpenSSL::Random and ::Bignum) do not link on Windows: Strawberry
# Perl's static libcrypto wants crypt32, which their Makefile.PLs leave out.
# Say so here, in the form CPAN Testers reads as "not applicable" rather than
# as a failure, instead of letting the install die part-way through.
die 'OS unsupported' if($^O eq 'MSWin32');

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	'NAME' => 'Mail::Send::DKIM',
	'VERSION_FROM' => 'lib/Mail/Send/DKIM.pm',
	'ABSTRACT' => 'Sign mail with DKIM, and summarise DMARC reports',
	'AUTHOR' => 'Nigel Horne <njh@nigehorne.com>',
	'LICENSE' => 'gpl_2',
	# Params::Validate::Strict, which Sub::Private and Sub::Protected need too,
	# will not install on anything older (checked with 5.16.3).
	'MIN_PERL_VERSION' => '5.026',
	dist => $dist,
	clean	=> { FILES => 'Mail-Send-DKIM-*' },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, 'EXE_FILES' => [
		'bin/dmarc-report.pl',
		'bin/dmarc-summary',
		'bin/dmarc-weekly.sh',
		'bin/dmarc-check-mail.pl',
		'bin/mail-dkim',
	],
	'PREREQ_PM' => {
		'autodie' => 0,
		'Carp' => 0,
		'Errno' => 0,
		'File::Basename' => 0,
		'File::Spec' => 0,
		'FindBin' => 0,
		'Getopt::Long' => 0,
		'IO::Compress::Gzip' => 0,
		'IO::Compress::Zip' => 0,
		'IO::Uncompress::Gunzip' => 0,
		'IO::Uncompress::Unzip' => 0,
		'IPC::System::Simple' => 0,	# autodie's :system
		'Mail::Address' => 0,
		'Mail::DKIM' => 0,
		'Mail::DKIM::Signer' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0,
		'Params::Validate::Strict' => '0.43',
		'Pod::Usage' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'Scalar::Util' => 0,
		'Sub::Private' => '0.09',	# the { mode => 'enforce' } import
		'Sub::Protected' => '0.03',
		'Sys::Hostname' => 0,
		'Sys::Syslog' => 0,
		'XML::PP' => 0,
	}, 'TEST_REQUIRES' => {
		'Config' => 0,
		'Cwd' => 0,
		'File::Copy' => 0,
		'File::Find' => 0,
		'File::Path' => 0,
		'File::Temp' => 0,
		'Net::DNS' => 0,
		'Pod::Github' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => '0.14',
		'Test::Most' => 0,
		'Test::Needs' => '0.002010',
		'Test::Returns' => '0.05',
		'Time::HiRes' => 0,
	},
	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Mail::Send::DKIM',
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Mail-Send-DKIM.git',
				web => 'https://github.com/nigelhorne/Mail-Send-DKIM',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-Send-DKIM',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-Send-DKIM',
				# web => 'https://github.com/nigelhorne/Mail-Send-DKIM/issues',
				# url => 'https://github.com/nigelhorne/Mail-Send-DKIM/issues',
				mailto => 'bug-Mail-Send-DKIM@rt.cpan.org'
			}
		},
	},
);
