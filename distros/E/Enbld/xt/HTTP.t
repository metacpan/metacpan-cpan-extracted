#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

require_ok( 'Enbld::HTTP' );

use File::Spec;
use File::Temp;

my $dir = File::Temp->newdir;

my $archivefile         = '01mailrc.txt.gz';
my $url_archivefile     = 'http://cpan.perl.org/authors/';
my $path_archivefile    = File::Spec->catfile( $dir, '01mailrc.txt.gz' );

my $url_site    = 'http://cpan.perl.org';

# download
my $downloaded = Enbld::HTTP->download( $url_archivefile, $path_archivefile );
ok( -e $downloaded, 'download file' );

my @filestat_downloaded = stat $downloaded;

my $twice = Enbld::HTTP->download( $url_archivefile, $path_archivefile );
my @filestat_twice = stat $twice;
is( $filestat_downloaded[9], $filestat_twice[9], 'not downloaded' );

# get
my $content = Enbld::HTTP->get( $url_site );
like( $content, qr/The Comprehensive Perl Archive Network/, 'get html' );

done_testing();
