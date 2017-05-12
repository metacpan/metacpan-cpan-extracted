#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Spec;

opendir( my $dh, 't' ) || die "can't opendir 't': $!";
my @test_files = sort grep { /^05-tests-/ && -f File::Spec->catfile( 't', $_ ) } readdir($dh);
closedir $dh;

foreach my $test_file ( @test_files ) {
    system( sprintf( "%s %s %s %s", $^X, File::Spec->catfile( 'bin', 'encrypt.pl' ), File::Spec->catfile( 't', $test_file ), File::Spec->catfile( 't', sprintf( '%s.t', $test_file ) ) ) );
}

ok( 1, 'Files encrypted' );

done_testing();
