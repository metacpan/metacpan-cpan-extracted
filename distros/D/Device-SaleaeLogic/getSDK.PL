#!/usr/bin/env perl
use strict;
use warnings;
use LWP;
use LWP::Simple;
use Archive::Zip qw(:ERROR_CODES);
use POSIX qw(uname);

my $SDKVER = '1.1.14';

sub get_lib_names {
    my ($s, $n, $r, $v, $m) = POSIX::uname();
    return ('libSaleaeDevice64.so') if $m =~ /x86_64/i and $s =~ /Linux/i;
    return ('libSaleaeDevice.so') if $s =~ /Linux/i;
    return ('libSaleaeDevice.dylib') if $s =~ /Darwin/i;
    return ('SaleaeDevice.dll', 'SaleaeDevice.lib') if $s =~ /Windows|Cygwin/i;
    die 'No support for OS';
}

sub get_header_name {
    return ('SaleaeDeviceApi.h');
}

my $url = "http://downloads.saleae.com/SDK/SaleaeDeviceSdk-$SDKVER.zip";
my $zipfile = 'saleaesdk.zip';
print "Downloading $url into $zipfile\n" if $ENV{DEBUG};
unless (-e $zipfile) {
    my $rc = getstore($url, $zipfile);
    die "Unable to download SDK from $url" unless is_success($rc);
} else {
    print "$zipfile already exists, so skipping the download\n" if $ENV{DEBUG};
}

print "Unzipping $zipfile and finding the required files\n" if $ENV{DEBUG};
my $zip = Archive::Zip->new;
die "Unable to unzip downloaded SDK $zipfile" unless ($zip->read($zipfile) == AZ_OK);
my @files = get_lib_names();
push @files, get_header_name();
foreach my $f (@files) {
    my @members = $zip->membersMatching($f);
    foreach (@members) {
        my $fname = $_->fileName();
        $fname = $1 if $fname =~ /\/([\.\w]+)$/;
        $fname =~ s/64\.so/\.so/g;
        unless (-e $fname) {
            $zip->extractMemberWithoutPaths($_, $fname);
            warn "Unable to extract $fname into $fname" unless -e $fname;
            if ($ENV{DEBUG} and -e $fname) {
                print "Extracted $fname from $zipfile\n";
            }
        } else {
            print "$fname already exists. not extracting from $zipfile\n" if
            $ENV{DEBUG};
        }
    }
    die "no member for $f" unless scalar @members;
}
