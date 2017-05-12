#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use HTTP::Online ':skip_all';
use Test::More tests => 19;

use File::Spec      ();
use File::Remove    ();
use GitHub::Extract ();

# Set up the extract directory
use constant TO => 'data';
File::Remove::clear(TO);
ok( ! -d TO, 'Test directory cleared' );
mkdir(TO);
ok( -d TO, 'Test directory created' );





######################################################################
# Constructor and Accessors

my $github = GitHub::Extract->new(
	username   => 'adamkennedy',
	repository => 'PPI',
);
isa_ok( $github, 'GitHub::Extract' );
is( $github->username, 'adamkennedy', '->username' );
is( $github->repository, 'PPI', '->repository' );
is( $github->branch, 'master', '->branch defaults to master' );
is( $github->url, 'https://github.com/adamkennedy/PPI/zipball/master', '->url' );
isa_ok( $github->http, 'HTTP::Tiny' );
is( $github->archive, undef, '->archive undef before download' );
is( $github->archive_extract, undef, '->archive_extract undef before download' );





######################################################################
# Live Testing

my $result = $github->extract( to => TO );
ok( $result, $github->url );
ok( $github->archive, '->archive defined' );
ok( -f $github->archive, '->archive exists on disk' );
isa_ok( $github->archive_extract, 'Archive::Extract' );

ok( $github->extract_path, '->extract_path defined' );
ok( -d $github->extract_path, '->extract_path exists' );

my $files = $github->files;
is( ref($files), 'ARRAY', '->files returned an ARRAY reference' );
ok( scalar(@$files), 'Got at least one file' );

my @missing = grep {
	! -e File::Spec->catfile(TO, $_)
} @$files;
is( scalar(@missing), 0, 'Found all files' );
