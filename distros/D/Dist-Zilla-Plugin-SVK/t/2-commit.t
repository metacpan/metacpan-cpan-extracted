#!perl

use strict;
use warnings;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use Path::Class;
use Test::More   tests => 1;
use File::Basename;
use Try::Tiny;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t commit)),
});

my $project = $zilla->name;
my $version = $zilla->version;

my $tempdir = $zilla->tempdir;
my $depotname = basename( "$tempdir" );
try { system( "svnadmin create $tempdir/local" ); } catch {
	warn "Can't create $tempdir/local: $_" };

system( "svk depotmap -i $depotname $tempdir/local" );

chdir $zilla->tempdir->subdir('source');
system( "svk import -t -m 'dzil plugin tags' /$depotname/$project" );
system( "svk ignore $project-$version.tar.gz");
system( "svk commit -m 'ignore tarball built by release.'" );

# do a release, with changes and dist.ini updated
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
$zilla->release;

# check if dist.ini and changelog have been committed
my $log = qx/ svk log -r HEAD /;
like( $log, qr/v1.23\n\n - foo\n - bar\n - baz\n/, 'commit message taken from changelog' );

system( "svk depotmap -d $depotname" );

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
