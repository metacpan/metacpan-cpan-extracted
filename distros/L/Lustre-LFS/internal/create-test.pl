#!/usr/bin/perl

use strict;
use Data::Dumper;
use Lustre::LFS::Dir;


die "You shouldn't run this script: This is just used for testing by adrian. If you really would like to run it, suppliy I_AM_STUPID as first argument\n" if $ARGV[0] ne 'I_AM_STUPID';



my $dir_cwd = Lustre::LFS::Dir->new(".") or die;
my $dir_err = Lustre::LFS::Dir->new("/tmp") or die;


$dir_cwd->delete_stripe && warn "OK (DEL_CWD)\n";
$dir_err->delete_stripe || warn "OK (DEL_ERR)\n";


$dir_cwd->set_stripe(Count=>9) && warn("OK (SET_CWD)\n");
$dir_err->set_stripe(Count=>3) || warn("OK (SET_ERR)\n");

my $x = $dir_cwd->get_stripe or die;
die "Wrong stripe count\n" if $x->{stripe_count} != 9;
print "OK (STRIPE_COUNT)\n";

$dir_cwd->delete_stripe or die;
$x = $dir_cwd->get_stripe or die;
die "Not default?!" unless $x->{inherit_default};
print "OK (RESTORE_DEFAULTS)\n";


$dir_cwd->set_stripe(Pool=>'adrian', Size=>65536*10) or die;
$x = $dir_cwd->get_stripe or die;

die "Wrong pool!\n" if $x->{pool_name} ne 'adrian';
die "Wrong size\n"  if $x->{stripe_size} != 65536*10;
print "OK (POOL/SIZE)\n";

print "-- all passed! restoring defaults on .\n";

$dir_cwd->delete_stripe or die;



print ">> TESTING FILE MODULE\n";

use Lustre::LFS::File;
my $fname = "foo.file";

my $fh = Lustre::LFS::File->new;
unlink($fname);


my $rv = $fh->lfs_create(File=>$fname, Count=>3) && warn("CREATE WAS OK\n");

my $stripe = $fh->get_stripe or die "Wow! could not read stripe info!\n";

die "Wrong stripe count!\n" if $stripe->{info}->{stripe_count} != 3;
print "STRIPE_COUNT is ok\n";


$fh->close;
$fh->lfs_create(File=>"/tmp/invalid", Count=>3) || warn("CREATE FAILED (OK!)\n");
$fh->close;

$fh->open("< /etc/hosts") or die "Could not open hosts file\n";

$fh->get_stripe or warn "GetStripe failed (OK)\n";

print "-- all passed!\n";

