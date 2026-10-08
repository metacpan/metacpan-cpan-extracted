use strict;
use warnings;
use Test::More;
use Config;

BEGIN {
    if (!$Config{useithreads}) {
        plan skip_all => 'Perl not built with ithreads support';
    }
    eval { require threads; 1 }
        or plan skip_all => 'threads module not available';
}

use Deflate::Faster qw(gzip gunzip deflate inflate);

# CLONE_SKIP is defined and returns 1
ok(Deflate::Faster->can('CLONE_SKIP'), 'CLONE_SKIP is defined');
is(Deflate::Faster->CLONE_SKIP, 1, 'CLONE_SKIP returns 1');

# Existing object in parent before thread creation
my $parent_df = Deflate::Faster->new();
$parent_df->file_name("parent.txt");
$parent_df->mod_time(1234567890);

my @threads;
for my $i (1 .. 4) {
    push @threads, threads->create(sub {
        my $tid = shift;
        my $child_df = Deflate::Faster->new();
        $child_df->file_name("thread_$tid.txt");
        for my $j (1 .. 100) {
            my $payload = "Thread $tid iteration $j: " . ("ABC" x 50);
            my $gz = gzip($payload);
            my $un = gunzip($gz);
            die "gzip mismatch in thread $tid" unless $un eq $payload;

            my $def = deflate($payload, 9);
            my $inf = inflate($def);
            die "deflate mismatch in thread $tid" unless $inf eq $payload;

            my $ch_out = $child_df->zip($payload);
            my $ch_dec = gunzip($ch_out);
            die "child_df mismatch in thread $tid" unless $ch_dec eq $payload;
        }
        return 1;
    }, $i);
}

for my $th (@threads) {
    ok($th->join(), "Thread completed cleanly without race or crash");
}

# Verify parent object is fully intact and not corrupted by child thread DESTROY
is($parent_df->file_name(), "parent.txt", "parent object file_name preserved after child threads");
is($parent_df->mod_time(), 1234567890, "parent object mod_time preserved after child threads");
my $pz = $parent_df->zip("hello parent");
my $pu = Deflate::Faster->new();
is($pu->unzip($pz), "hello parent", "parent zip works after child thread joins");
is($pu->file_name(), "parent.txt", "unzipped name matches parent.txt");
is($pu->mod_time(), 1234567890, "unzipped mod_time matches 1234567890");

done_testing();
