#!perl

use strict;
use warnings;

use lib qw'lib';

use Dist::Zilla     1.093250;
use Dist::Zilla::Tester;
use Path::Class;
use Test::More      tests => 3;
use Test::Exception;
use File::Basename;
use Try::Tiny;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t check)),
});

my $project = $zilla->name;
my $version = $zilla->version;

my $tempdir = $zilla->tempdir;
my $depotname = basename( "$tempdir" );
try { system( "svnadmin create $tempdir/local" ); } catch {
	warn "Can't create $tempdir/local: $_" };

system( "svk depotmap -i $depotname $tempdir/local" );

chdir $zilla->tempdir->subdir('source');
system( "svk import -t -m 'dzil plugin check' /$depotname/$project" );

# ignore archive created by zilla at release
system("svk ignore $project-$version.tar.gz");
system( "svk commit -m 'ignore tarball built by release.'" );

# untracked files
open VIRGIN, '>', 'version.txt'; print VIRGIN "\n\n"; close VIRGIN;
throws_ok { $zilla->release } qr/unversioned files/,
								'no unversioned files allowed';
system( "svk add version.txt" );

# modified files
append_to_file('foobar', "an uncommitted change\n");
throws_ok { $zilla->release } qr/modified files/,
					'no uncommitted files allowed';
system( "svk commit -m 'initial commit'" );

# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
lives_ok { $zilla->release } 'Modified Changes and dist.ini allowed';

system( "svk depotmap -d $depotname" );

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}

