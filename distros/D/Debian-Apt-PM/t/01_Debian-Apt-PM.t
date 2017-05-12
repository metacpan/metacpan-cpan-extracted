#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 12;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'Debian::Apt::PM' ) or exit;
}

exit main();

sub main {
	INTERNAL_parse_perl_modules: {
		my $t1 = " MM (0.001001)\n";
		my $t2 = " \n M1 (1)\n M3 (3)\n M2 (2)\n";
		my $t3 = " \n BackupManager::Dialog (0)\n BackupManager::Config (0)\n BackupManager::Logger (0)\n";
		
		is_deeply(
			{ Debian::Apt::PM::_parse_perl_modules($t1) },
			{ 'MM' => '0.001001' },
			'parsing Perl-Modules'
		);
		
		is_deeply(
			{ Debian::Apt::PM::_parse_perl_modules($t2) },
			{
				'M1' => '1',
				'M2' => '2',
				'M3' => '3',
			},
			'parsing Perl-Modules'
		);

		is_deeply(
			{ Debian::Apt::PM::_parse_perl_modules($t3) },
			{
				'BackupManager::Dialog' => '0',
				'BackupManager::Config' => '0',
				'BackupManager::Logger' => '0',
			},
			'parsing Perl-Modules'
		);
	}
	
	INTERNAL_modules_index: {
		my $aptpm = Debian::Apt::PM->new(sources => [ File::Spec->catfile($Bin, 'PerlPackages.bz2') ]);
		
		my %deb1 = (
			'version'      => '5.230-1',
			'package'      => 'libanyevent-perl',
			'arch'         => 'all',
			'distribution' => 'testing',
			'component'    => 'main',
		);
		my %deb2 = (
			'version'      => '0.21-1',
			'package'      => 'libclass-c3-perl',
			'arch'         => 'all',
			'distribution' => 'testing',
			'component'    => 'main',
		);

		eq_or_diff(
			$aptpm->_modules_index,
			{
				'Class::C3' => { '0.21' => \%deb2 },
				'AnyEvent::Impl::EventLib' => { '0' => \%deb1 },
				'AnyEvent::Strict' => { '0' => \%deb1 },
				'AnyEvent::CondVar' => { '0' => \%deb1 },
				'AnyEvent::TLS' => { '0' => \%deb1 },
				'AnyEvent::Impl::Qt::Io' => { '0' => \%deb1 },
				'AnyEvent::Impl::Tk' => { '0' => \%deb1 },
				'AnyEvent::Impl::Irssi' => { '0' => \%deb1 },
				'AnyEvent::Impl::IOAsync' => { '0' => \%deb1 },
				'AnyEvent::CondVar::Base' => { '0' => \%deb1 },
				'AnyEvent::Util' => { '0' => \%deb1 },
				'AnyEvent::Base' => { '0' => \%deb1 },
				'AnyEvent::Impl::Qt' => { '0' => \%deb1 },
				'AnyEvent::Handle' => { '0' => \%deb1 },
				'AnyEvent::Impl::Perl' => { '0' => \%deb1 },
				'AnyEvent' => { '5.23' => \%deb1 },
				'AnyEvent::DNS' => { '0' => \%deb1 },
				'AnyEvent::Impl::Qt::Timer' => { '0' => \%deb1 },
				'AnyEvent::Impl::EV' => { '0' => \%deb1 },
				'AnyEvent::Debug::shell' => { '0' => \%deb1 },
				'AnyEvent::Debug' => { '0' => \%deb1 },
				'AnyEvent::Impl::POE' => { '0' => \%deb1 },
				'AnyEvent::Impl::Event' => { '0' => \%deb1 },
				'AE' => { '0' => \%deb1 },
				'AnyEvent::Socket' => { '0' => \%deb1 },
				'AnyEvent::Impl::Glib' => { '0' => \%deb1 }
	        },
			'building modules index'
		);

		my $aptpm2 = Debian::Apt::PM->new(sources => [
			File::Spec->catfile($Bin, 'PerlPackages.bz2'),
			File::Spec->catfile($Bin, 'PerlPackages2.bz2'),
		]);

		my %deb3 = (
			'version'      => '1.000-1',
			'package'      => 'libanyevent-perl',
			'arch'         => 'all',
			'distribution' => 'testing',
			'component'    => 'main',
		);
		my %deb4 = (
			'version'      => '0.22-1',
			'package'      => 'libclass-c3-perl',
			'arch'         => 'all',
			'distribution' => 'testing',
			'component'    => 'main',
		);
		my %deb5 = (
			'version'      => '4.00-1',
			'package'      => 'libclass-c4-perl',
			'arch'         => 'all',
			'distribution' => 'testing',
			'component'    => 'main',
		);
		my %result2 = (
			'Class::C3' => {
				'0.21' => \%deb2,
				'0.22' => \%deb4,
			},
			'AnyEvent::Impl::EventLib' => { '0' => \%deb3 },
			'AnyEvent::Strict' => { '0' => \%deb3 },
			'AnyEvent::CondVar' => { '0' => \%deb3 },
			'AnyEvent::TLS' => { '0' => \%deb3 },
			'AnyEvent::Impl::Qt::Io' => { '0' => \%deb3 },
			'AnyEvent::Impl::Tk' => { '0' => \%deb3 },
			'AnyEvent::Impl::Irssi' => { '0' => \%deb3 },
			'AnyEvent::Impl::IOAsync' => { '0' => \%deb3 },
			'AnyEvent::CondVar::Base' => { '0' => \%deb3 },
			'AnyEvent::Util' => { '0' => \%deb3 },
			'AnyEvent::Base' => { '0' => \%deb3 },
			'AnyEvent::Impl::Qt' => { '0' => \%deb3 },
			'AnyEvent::Handle' => { '0' => \%deb3 },
			'AnyEvent::Impl::Perl' => { '0' => \%deb3 },
			'AnyEvent' => {
				'1.000' => \%deb3,
				'5.23'  => \%deb1,
			},
			'AnyEvent::DNS' => { '0' => \%deb3 },
			'AnyEvent::Impl::Qt::Timer' => { '0' => \%deb3 },
			'AnyEvent::Impl::EV' => { '0' => \%deb3 },
			'AnyEvent::Debug::shell' => { '0' => \%deb3 },
			'AnyEvent::Debug' => { '0' => \%deb3 },
			'AnyEvent::Impl::POE' => { '0' => \%deb3 },
			'AnyEvent::Impl::Event' => { '0' => \%deb3 },
			'AE' => { '0' => \%deb3 },
			'AnyEvent::Socket' => { '0' => \%deb3 },
			'AnyEvent::Impl::Glib' => { '0' => \%deb3 },
			'Class::C4' => { '4.00' => \%deb5 },
		);

		eq_or_diff(
			$aptpm2->_modules_index,
			\%result2,
			'building combined modules index'
		);

		my $aptpm3 = Debian::Apt::PM->new(sources => [
			File::Spec->catfile($Bin, 'PerlPackages2.bz2'),
			File::Spec->catfile($Bin, 'PerlPackages.bz2'),
		]);
		eq_or_diff(
			$aptpm3->_modules_index,
			\%result2,
			'building combiner modules index (reverse input files order)'
		);
	}
	
	INTERNAL_etc_apt_sources: {
		my $aptpm = Debian::Apt::PM->new();
		my @web_sources;
		lives_ok { @web_sources = $aptpm->_etc_apt_sources } 'call parsing of /etc/apt/sources';
		note('web sources on this machine:', "\n", join("\n", @web_sources));
	};

	FIND: {
		my $aptpm = Debian::Apt::PM->new(sources => [
			File::Spec->catfile($Bin, 'PerlPackages.bz2'),
			File::Spec->catfile($Bin, 'PerlPackages2.bz2'),
		]);
		
		eq_or_diff(
			$aptpm->find('AnyEvent'), {
				'1.000' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '1.000-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'5.23' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				}
			},
			'find()',
		);

		eq_or_diff(
			$aptpm->find('AnyEvent', '0.01'), {
				'1.000' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '1.000-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'min' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '1.000-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'5.23' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'max' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
			},
			'find(min 0.01)',
		);

		eq_or_diff(
			$aptpm->find('AnyEvent', '1.50'), {
				'1.000' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '1.000-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'min' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'5.23' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'max' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
			},
			'find(min 1.50)',
		);

		eq_or_diff(
			$aptpm->find('AnyEvent', '5.3'), {
				'1.000' => {
					arch => 'all',
					package => 'libanyevent-perl',
					version => '1.000-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'5.23' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'max' => {
					'arch'         => 'all',
					'package'      => 'libanyevent-perl',
					'version'      => '5.230-1',
					'distribution' => 'testing',
					'component'    => 'main',
				},
				'min' => undef,
			},
			'find(min 5.3)',
		);
	}
	
	return 0;
}

