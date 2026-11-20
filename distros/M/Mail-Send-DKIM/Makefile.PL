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
	'MIN_PERL_VERSION' => '5.016',
	dist => $dist,
	clean	=> { FILES => 'Mail-Send-DKIM-*' },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, 'EXE_FILES' => [
		'bin/dmarc-report.pl',
		'bin/dmarc-weekly.sh',
		'bin/dmarc-check-mail.pl',
		'bin/mail-dkim',
	],
	'PREREQ_PM' => {
		'IO::Compress::Gzip' => 0,
		'IO::Compress::Zip' => 0,
		'IO::Uncompress::Gunzip' => 0,
		'IO::Uncompress::Unzip' => 0,
		'Mail::DKIM' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0,
		'Readonly' => 0,
		'Sys::Syslog' => 0,
		'XML::PP' => 0,
	}, 'TEST_REQUIRES' => {
		'File::Temp' => 0,
		'Net::DNS' => 0,
		'Pod::Github' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
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
