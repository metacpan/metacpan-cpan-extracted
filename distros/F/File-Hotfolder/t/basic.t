use strict;
use warnings;
use v5.10;

use Test::More;
use File::Temp qw(tempdir);
use File::Hotfolder;

unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'skipped unless RELEASE_TESTING is set';
    exit;
}

sub touch($) {
    my $f; open($f, '>', shift) ? close($f) : die "open: $!";
}

my $dir = tempdir( CLEANUP => 1 );

my (@queue, @logs);
my $hf = File::Hotfolder->new(
    watch    => $dir,
    delete   => 1,
    print    => DELETE_FILE,
    logger   => sub { push @logs, { @_ } },
    callback => sub { push @queue, $_[0]; $_[0] =~ /b$/ ? 1 : die; },
    catch    => 1,
);
$hf->inotify->blocking(0);

touch "$dir/a";
$hf->inotify->poll;
mkdir "$dir/foo"; 
$hf->inotify->poll;
touch "$dir/foo/b";
$hf->inotify->poll;

is_deeply \@queue, ["$dir/a","$dir/foo/b"], 'watch recursively';

is_deeply \@logs, [ {
        event   => DELETE_FILE,
        path    => "$dir/foo/b",
        message => "delete $dir/foo/b"
    } ], 'log deletion';

done_testing;
