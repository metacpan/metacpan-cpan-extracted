#!/usr/bin/perl
use strict;
my @scripts;

use Data::Dumper;
use Test::More tests => 30;

# Helper routine to load text from a file
sub readfile {
    my $filename = shift || return undef;
    open(FILE, "<$filename")
        || (warn "ERROR:  Can't open '$filename' for reading: $!\n" && return undef);
    my @contents = <FILE>;
    my $contents = join("",@contents);
    close(FILE)
        || (warn "ERROR:  Can't close '$filename': $!\n" && return undef);
    return $contents;
}

sub filecmp {
    my ($file_a, $file_b) = @_;
    my $a = readfile($file_a) || return -2;
    my $b = readfile($file_b) || return 2;

    return $a cmp $b;
}

my $infile  = $0;  $infile  =~ s/t$/in/;
my $outfile = $0;  $outfile =~ s/t$/out/;

ok ( -e "./$infile", "Verifying existance of $infile")
   or diag("No input config file found for '$0'");

use Linux::Bootloader::Grub;

my @config;
my $bootloader = new Linux::Bootloader::Grub;
ok ( defined $bootloader, "Creation of Linux::Bootloader::Grub object");

ok( ! $bootloader->read("non-existant file") , "Loading a non-existant file" );

ok( $bootloader->read("./$infile"), "Loading a valid '$infile' file" );

ok (! $bootloader->print_info("./$infile", -1) );
ok (! $bootloader->print_info("./$infile", 10000) );
ok (! $bootloader->print_info("./$infile", -42) );

my $info = Dumper ($bootloader->_info());
open FILE, ">$outfile";
print FILE $info;
close FILE;
ok( filecmp($outfile, $outfile.".2") == 0);

ok ( defined $bootloader->write($outfile), "Writing '$outfile'" );
ok ( filecmp($outfile, $outfile.".1") == 0, "Checking contents of $outfile" );
ok( $bootloader->get_default() == 2, "Default 2");

ok( ! $bootloader->set_default(-24) );
ok( ! $bootloader->set_default(-1) );
ok( ! $bootloader->set_default(10000) );
ok( $bootloader->set_default(1) );
my $default = $bootloader->get_default();
ok( defined($default) && ($default == 1), "Default 1");

my %params;
ok( ! $bootloader->add(%params), "Calling without defined add-kernel or title" );

$params{'add-kernel'} = 'non-existant\n kernel \nfile';
ok( ! $bootloader->add(%params), "Calling without invalid add-kernel" );

# /etc/hosts ought to exist; obviously it's not a kernel image, but since
# add() only checks that the file exists, it should be good enough for the
# purpose of our test.
$params{'add-kernel'} = "/etc/hosts";
ok( ! $bootloader->add(%params), "Calling without specifying config-file" );

$params{'config_file'} = "./$outfile.3";
$params{'title'} = 'Gentoo - old';
ok( ! $bootloader->add(%params), "Calling with already existing title" );

$params{'title'} = "Linux::Bootloader testing";
$params{'initrd'} = 'non-existant initrd file';
ok( ! $bootloader->add(%params), "Calling without invalid initrd" );

undef($params{'initrd'});
$params{args} = "profile=2";
$params{root} = "/dev/sdb3";
$params{boot} = "(hd1,0)";

ok( $bootloader->add(%params) );
ok( defined $bootloader->write($outfile), "Writing '$outfile'" );

ok( filecmp($outfile, $outfile.".4") == 0, "Checking contents of $outfile" );

ok( $bootloader->read("./$infile"), "Loading a valid '$infile' file" );
ok( ! $bootloader->remove(-1) );
ok( ! $bootloader->remove(100) );
ok( $bootloader->remove(2) );
ok( defined $bootloader->write($outfile), "Writing '$outfile'" );
ok( filecmp($outfile, $outfile.".5") == 0, "Checking contents of $outfile" );

