#!/usr/bin/env perl -wT
use strict;

# Shamelessly stolen from Authen::Captcha distribution.
# This file includes the contents of "1.t" test file with
# some fixes related to GD::SecurityImage::AC.

# figure out where we are, and where we will be storing stuff
use File::Basename;
use File::Spec;
my $file = __FILE__;
my $this_dir = dirname($file);
my @this_dirs = File::Spec->splitdir( $this_dir );
my $tainted_temp_dir = File::Spec->catdir(@this_dirs,'captcha_temp');
my $tainted_temp_datadir = "$tainted_temp_dir/data";
my $tainted_temp_outputdir = "$tainted_temp_dir/img";

my $temp_dir = _untaint($tainted_temp_dir);
my $temp_datadir = _untaint($tainted_temp_datadir);
my $temp_outputdir = _untaint($tainted_temp_outputdir);

# we set this only for testing, it is not actually used
my $temp_imagesdir = 'Captcha/images';

use Test; # (tests => 28);

plan tests => 32;

use GD::SecurityImage::AC;
ok(1); # If we made it this far, we are fine.
my $captcha = Authen::Captcha->new();
$captcha->images_folder('FOOBAR'); # faker. we can not set to undef.
ok( defined $captcha, 1, 'new() did not return anything' );
ok( $captcha->isa('Authen::Captcha') );

# make temp directories
ok( (-e $temp_dir) || mkdir($temp_dir) ); # made temp dir
ok( (-e $temp_datadir) || mkdir($temp_datadir) ); # made temp data dir
ok( (-e $temp_outputdir) || mkdir($temp_outputdir) ); # made temp image dir

my $captcha2 = Authen::Captcha->new(
	debug    	=> 1,
	data_folder	=> $temp_datadir,
	output_folder	=> $temp_outputdir,
	expire  	=> 301,
	width   	=> 26,
	height  	=> 36,
	keep_failures	=> 1,
	);
ok( defined $captcha2, 1, 'new() did not return anything' );
ok( $captcha2->isa('Authen::Captcha') );

$captcha->debug(1);
ok( $captcha->debug(), '1', "couldn't set debug to 1" );
ok( $captcha2->debug(), '1', "couldn't set debug to 1" );

$captcha->data_folder($temp_datadir);
ok( $captcha->data_folder(), $temp_datadir, "couldn't set data folder to $temp_datadir" );
ok( $captcha2->data_folder(), $temp_datadir, "couldn't set data folder to $temp_datadir" );

$captcha->output_folder($temp_outputdir);
ok( $captcha->output_folder(), $temp_outputdir, "couldn't set data folder to $temp_outputdir" );
ok( $captcha2->output_folder(), $temp_outputdir, "couldn't set data folder to $temp_outputdir" );

$captcha->expire(301);
ok( $captcha->expire(), '301', "couldn't set expire to 301" );
ok( $captcha2->expire(), '301', "couldn't set expire to 301" );

$captcha->width(26);
ok( $captcha->width(), '26', "couldn't set width to 26" );
ok( $captcha2->width(), '26', "couldn't set width to 26" );

$captcha->height(36);
ok( $captcha->height(), '36', "couldn't set height to 36" );
ok( $captcha2->height(), '36', "couldn't set height to 36" );

$captcha->keep_failures(1);
ok( $captcha->keep_failures(), '1', "couldn't set keep_failures to 1" );
ok( $captcha2->keep_failures(), '1', "couldn't set keep_failures to 1" );

my $default_images_folder = $captcha->images_folder();
$captcha->images_folder($temp_imagesdir);
ok( $captcha->images_folder(), $temp_imagesdir, "Couldn't override the images_folder to $temp_imagesdir");
$captcha->images_folder($default_images_folder);
ok( $captcha->images_folder(), $default_images_folder, "Couldn't set the images_folder back to $default_images_folder");

my ($md5sum,$code) = $captcha->generate_code(5);
ok( sub { return 1 if (length($code) == 5) }, 1, "didn't set the number of captcha characters correctly" );

# we have keep_failures on, so this should not get rid of the database entry
my $bad_results = $captcha2->check_code($code . 'x',$md5sum);
ok( sub { return 1 if ($bad_results == -3) }, 1, "Failed on check_code: it did not fail correctly" );
$captcha2->keep_failures(0);

my $results = $captcha2->check_code($code,$md5sum);
# check for different error states
ok( sub { return 1 if ($results != -3) }, 1, "Failed on check_code: invalid code (code does not match crypt)" );
ok( sub { return 1 if ($results != -2) }, 1, "Failed on check_code: invalid code (not in database)" );
ok( sub { return 1 if ($results != -1) }, 1, "Failed on check_code: code expired" );
ok( sub { return 1 if ($results !=  0) }, 1, "Failed on check_code: code not checked (file error)" );
ok( $results,  1, "Failed on check_code, didn't return 1, but didn't return the other error codes either." );

# we disabled keep_failures, so the check should fail
my $bad_results2 = $captcha2->check_code($code,$md5sum);
ok( sub { return 1 if ($bad_results2 == -2) }, 1, "Failed on check_code: disabling keep_failures did not work right, it failed incorrectly" );

# We need to be able to turn tainted off for our output_folder et al

sub _untaint { # This doesn't make things safe. It just removes the taint flag. 
	my ($value) = @_;
	my ($untainted_value) = $value =~ m/^(.*)$/s;
	return $untainted_value;
}

