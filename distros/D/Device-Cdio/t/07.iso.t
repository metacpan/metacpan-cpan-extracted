#!/usr/bin/env perl
# Test some low-level ISO9660 routines
# This is basically the same thing as libcdio's testiso9660.c

use strict;
use warnings;
use Config;
use lib '../lib';
use blib;

use perliso9660;
use Test::More tests => 15;
note 'Test low-level ISO9660 routines';

sub is_eq($$) {
    my ($a_ref, $b_ref) = @_;
    return 0 if @$a_ref != @$b_ref;
    for (my $i=0; $i<@$a_ref; $i++) {
	if ($a_ref->[$i] != $b_ref->[$i]) {
	    printf "position %d: %d != %d\n", $i, $a_ref->[$i], $b_ref->[$i];
	    return 0 ;
	}
    }
    return 1;
}

###################################
# Test ACHAR and DCHAR
###################################

my @achars = ('!', '"', '%', '&', '(', ')', '*', '+', ',', '-', '.',
	   '/', '?', '<', '=', '>');

my $bad = 0;
for (my $c=ord('A'); $c<=ord('Z'); $c++ ) {
    if (!perliso9660::is_dchar($c)) {
	printf "Failed iso9660_is_achar test on %c\n", $c;
	$bad++;
    }
    if (!perliso9660::is_achar($c)) {
	printf "Failed iso9660_is_achar test on %c\n", $c;
	$bad++;
    }
}

ok($bad==0, 'is_dchar & is_achar A..Z');

$bad=0;
for (my $c=ord('0'); $c<=ord('9'); $c++ ) {
    if (!perliso9660::is_dchar($c)) {
	printf "Failed iso9660_is_dchar test on %c\n", $c;
	$bad++;
    }
    if (!perliso9660::is_achar($c)) {
	printf "Failed iso9660_is_achar test on %c\n", $c;
	$bad++;
    }
}

ok($bad==0, 'is_dchar & is_achar 0..9');

$bad=0;
for (my $i=0; $i<=13; $i++ ) {
    my $c=ord($achars[$i]);
    if (perliso9660::is_dchar($c)) {
	printf "Should not pass is_dchar test on %c\n", $c;
	$bad++;
    }
    if (!perliso9660::is_achar($c)) {
	printf "Failed is_achar test on symbol %c\n", $c;
	$bad++;
    }
}

ok($bad==0, 'is_dchar & is_achar symbols');

my $dst;
#####################################
# Test perliso9660::strncpy_pad
#####################################

SKIP: 
{
    # skip("strncpy_pad broken too often. Volunteers for fixing?.", 2);
	# if 'cygwin' eq $Config{osname};

    $dst = perliso9660::strncpy_pad("1_3", 5, $perliso9660::DCHARS);
    ok($dst eq "1_3  ", "strncpy_pad DCHARS");
    
    $dst = perliso9660::strncpy_pad("ABC!123", 2, $perliso9660::ACHARS);
    ok($dst eq "AB", "strncpy_pad ACHARS truncation");
}

#####################################
# Test perliso9660::dirname_valid_p 
#####################################

$bad=0;
if ( perliso9660::dirname_valid_p("/NOGOOD") ) {
    printf("/NOGOOD should fail perliso9660::dirname_valid_p\n");
    $bad++;
}
ok($bad==0, 'perliso9660::dirname_valid_p - invalid name - bad symbol');

$bad=0;
if ( perliso9660::dirname_valid_p("LONGDIRECTORY/NOGOOD") ) {
    printf("LONGDIRECTORY/NOGOOD should fail perliso9660::dirname_valid_p\n");
    $bad++;
}
ok($bad==0, 'perliso9660::dirname_valid_p - invalid long name');

$bad=0;
if ( !perliso9660::dirname_valid_p("OKAY/DIR") ) {
    printf("OKAY/DIR should pass perliso9660::dirname_valid_p\n");
    $bad++;
}
ok($bad==0, 'perliso9660::dirname_valid_p - valid with directory');

$bad=0;
if ( perliso9660::dirname_valid_p("OKAY/FILE.EXT") ) {
    printf("OKAY/FILENAME.EXT should fail perliso9660::dirname_valid_p\n");
    $bad++;
}
ok($bad==0, 'perliso9660::dirname_valid_p - invalid with .EXT');

#####################################
# Test perliso9660::pathname_valid_p
#####################################

$bad=0;
if ( !perliso9660::pathname_valid_p("OKAY/FILE.EXT") ) {
    printf("OKAY/FILE.EXT should pass perliso9660::dirname_valid_p\n");
    $bad++;
}
ok($bad==0, 'perliso9660::pathname_valid_p - valid');

$bad=0;
if ( perliso9660::pathname_valid_p("OKAY/FILENAMETOOLONG.EXT") ) {
    printf("OKAY/FILENAMETOOLONG.EXT should fail perliso9660::dirname_valid_p\n");
    $bad++;
}
ok($bad==0, 'perliso9660::pathname_valid_p - invalid, long basename');

$bad=0;
if ( perliso9660::pathname_valid_p("OKAY/FILE.LONGEXT") ) {
    printf("OKAY/FILE.LONGEXT should fail perliso9660::dirname_valid_p\n");
    $bad++;
}
ok($bad==0, 'perliso9660::pathname_valid_p - invalid, long extension');

$bad=0;
$dst = perliso9660::pathname_isofy("this/file.ext", 1);
if ($dst ne "this/file.ext;1") {
    printf("Failed iso9660_pathname_isofy\n");
    $bad++;
}
ok($bad==0, 'perliso9660::pathname_isofy');

my @tm = localtime(0);
my $dtime = perliso9660::set_dtime($tm[0], $tm[1], $tm[2], $tm[3], $tm[4],
				   $tm[5]);
my ($bool, @new_tm) = perliso9660::get_dtime($dtime, 0);

ok(is_eq(\@new_tm, \@tm), 'get_dtime(set_dtime())');

# @tm = gmtime(0);
# my $ltime = perliso9660::set_ltime($tm[0], $tm[1], $tm[2], $tm[3], $tm[4],
# 				   $tm[5]);
# ($bool, @new_tm) =  perliso9660::get_ltime($ltime);
# ok(is_eq(\@new_tm, \@tm), 'get_ltime(set_ltime())');

@tm = gmtime();
my $ltime = perliso9660::set_ltime($tm[0], $tm[1], $tm[2], $tm[3], $tm[4],
				   $tm[5]);
($bool, @new_tm) =  perliso9660::get_ltime($ltime);
if($new_tm[8] =! $tm[8]) { #isdst flag
    diag(' isdst flags differ '. $new_tm[8]. ' '.$tm[8]);
    $new_tm[8] = $tm[8];
}
ok(is_eq(\@new_tm, \@tm), 'get_ltime(set_ltime())');

