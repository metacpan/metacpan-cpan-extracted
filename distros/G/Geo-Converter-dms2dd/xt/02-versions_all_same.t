#!perl

#  make sure all biodiverse modules are of the same version

use strict;
use warnings;


use Test::More;

#my @files;
use FindBin qw { $Bin };
use File::Spec;
use File::Find;  #  should switch to use File::Next

use rlib;

#  list of files
our @packages;

my $wanted = sub {
    # only operate on Perl modules
    return if $_ !~ m/\.pm$/;

    my $filename = $File::Find::name;
    $filename =~ s/\.pm$//;
    $filename =~ s{/}{::}g;
    if ($filename =~ /lib::(Geo.*)$/) { #  get the package part - very clunky
        $filename = $1;
    }
    

    push @packages, $filename;
};

my $lib_dir = File::Spec->catfile( $Bin, '..', 'lib' );
find ( $wanted,  $lib_dir );

require Geo::Converter::dms2dd;

my $version = $Geo::Converter::dms2dd::VERSION;

note ( "Testing Geo::Converter::dms2dd $version, Perl $], $^X" );

my $blah = $Geo::Converter::dms2dd::VERSION;

while (my $file = shift @packages) {
    my $loaded = eval qq{ require $file };
    my $msg_extra = q{};
    if (!$loaded) {
        $msg_extra = " (Unable to load $file).";
    }
    my $this_version = eval '$' . $file . q{::VERSION};
    my $msg = "$file is $version." . $msg_extra;
    is ( $this_version, $version, $msg );
}

done_testing();
