#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempfile tempdir /;

use Dist::Data;

BEGIN {

	my $tempdir = tempdir;

	{
		my $dist = Dist::Data->new({
			filename => "$Bin/data/My-Sample-Distribution-0.003.tar.gz",
			dir => $tempdir,
		});

		isa_ok($dist,'Dist::Data');
	}
	
	ok(-f "$tempdir/dist.ini",'Checking if file still exist');
	is((stat("$tempdir/dist.ini"))[7],214,'Checking if its the right filesize');

	my $dist_from_dir = Dist::Data->new($tempdir);

	is($dist_from_dir->name,'My-Sample-Distribution','Checking name from meta of the directory distribution');
	ok(-f $dist_from_dir->file('dist.ini'),'Checking if file exist really from the directory distribution');

	is_deeply($dist_from_dir->packages, {
		'My::Sample::Distribution' => {
			file => 'lib/My/Sample/Distribution.pm',
			version => 0.003,
		},
	},'Checking packages from the directory distribution');

}

done_testing;
