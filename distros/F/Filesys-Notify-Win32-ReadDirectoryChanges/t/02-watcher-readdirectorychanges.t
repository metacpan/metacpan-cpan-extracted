#perl
use strict;
use 5.010;
use Test::More;

BEGIN {
    if( $^O !~ /MSWin32|cygwin/ ) {
        plan skip_all => "This module only works on Windows or Cygwin";
        exit;
    };
};

use Filesys::Notify::Win32::ReadDirectoryChanges;
use File::Temp 'tempfile';
use File::Basename;
use threads;

my ($fh1,$tempname1) = tempfile( UNLINK => 1 );
my $tempdir = dirname($tempname1);
my $wintempdir = $tempdir;
close $fh1;

# spirit the thread away in a subroutine so we
# don't close over the file watcher
sub do_stuff {

    my ($fh2,$tempname2) = tempfile(UNLINK => 0);
    close $fh2;

    my ($fh3,$tempname3) = tempfile(UNLINK => 0);
    close $fh3;
    my $rename_target = $tempname3 . '.' . $$ . '.tmp';

    my $t = async {
        note "Temp name 2: $tempname2";
        open $fh2, '>', $tempname2;
        print {$fh2} "Hello World\n";
        close $fh2;
        unlink $tempname2 or warn $!;

        rename $tempname3, $rename_target or warn $! ;
    };
    return ($tempname2,$t, $tempname3, $rename_target);
}

sub start_watchdog {
    my ($q) = @_;
    my $timeout = threads->create(sub { my $q = shift; sleep 5; diag "Timeout"; $q->enqueue({}); }, $q );
    return $timeout;
}

my $w = Filesys::Notify::Win32::ReadDirectoryChanges->new(
    directory => [$tempdir]
);
sleep 1;

note "Temp dir: $tempdir";
my ($tempname2,$t,$tempname3,$rename_target) = do_stuff();
start_watchdog( $w->queue )->detach;
sleep 1;

$w->unwatch_directory( path => $tempdir );

my @actions2 = ('added','modified','modified','removed');
my @actions3 = ('added','old_name','renamed');
my @actions4 = ('new_name');

plan tests => @actions2+@actions3+@actions4+1;

my $timeout = 0;
while ( my $ev = $w->queue->dequeue ) {
    if( ! $ev->{path} ) {
        # our timeout marker
        note "Timeout reached";
        $timeout = 1;
        last;
    }

    note "$ev->{path}: $ev->{action}";
    state $idx2 = 0;
    state $idx3 = 0;
    state $idx4 = 0;
    if( $ev->{path} eq $tempname2 ) {
        my $act = $actions2[$idx2++];
        is $ev->{action}, $act, "second tempfile: $act";
    };
    if( $ev->{path} eq $tempname3 ) {
        my $act = $actions3[$idx3++];
        is $ev->{action}, $act, "third tempfile: $act";
    };
    if( $ev->{path} eq $rename_target ) {
        my $act = $actions4[$idx4++];
        is $ev->{action}, $act, "rename to '$rename_target': $act";
    };
    last if ($idx2 == @actions2
        and $idx3 == @actions3
        and $idx4 == @actions4) or $timeout
        ;
}

is $timeout, 0, "No timeout during test run";

note "Cleanup";
$t->join;
note "GLOBAL destruction";
done_testing();
