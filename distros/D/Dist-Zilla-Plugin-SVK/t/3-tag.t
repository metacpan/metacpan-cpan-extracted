#!perl

use strict;
use warnings;

# use lib 'lib';

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use SVN::Repos;
use Path::Class;
use Test::More   tests => 2;
use File::Basename;
use Try::Tiny;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t tag)),
});

my $project = $zilla->name;
my $project_dir = lc $project;
$project_dir =~ s/::/-/g;
my $version = $zilla->version;

my $tempdir = $zilla->tempdir;
my $depotname = basename( "$tempdir" );
try { system( "svnadmin create $tempdir/local" ); } catch {
	warn "Can't create $tempdir/local: $_" };

system( "svk depotmap -i $depotname $tempdir/local" );
system( "svk mkdir -m 'top-level project directory' /$depotname/$project_dir" );

chdir $zilla->tempdir->subdir('source');
system( "svk import -t -m 'dzil plugin tags' /$depotname/$project_dir/trunk" );
system( "svk ignore $project-$version.tar.gz");
system( "svk commit -m 'ignore tarball built by release.'" );

system( "svk mkdir -m 'tags dir' /$depotname/$project_dir/tags" );
# do the release
$zilla->release;

# check if tag has been correctly created
my $taglog = qx "svk log -r HEAD /$depotname/$project_dir/tags/";
like( $taglog, qr/v1\.23/, 'new tag created after new version' );

# attempting to release again should fail
eval { $zilla->release };

like($@, qr/tag v1\.23 already exists/, 'prohibit duplicate tag');

system( "svk depotmap -d $depotname" );

