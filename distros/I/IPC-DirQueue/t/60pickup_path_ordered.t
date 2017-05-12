#!/usr/bin/perl -w

use Test; BEGIN { plan tests => 93; };

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;
use File::Path;
use strict;

sub visitor {
    my ($context,$job) = @_;
    push @$context, $job->{pathqueue};
}

mkdir ("log");
rmtree ("log/qdir");
my $bq = IPC::DirQueue->new({ dir => 'log/qdir', ordered => 0 });
ok ($bq);

my $COUNT = 30;
for my $j (1 .. $COUNT) {
    ok ($bq->enqueue_string ("hello world! $j $$", { foo => "bar $$" }));
}

my @pathqueues;
$bq->visit_all_jobs(\&visitor,\@pathqueues);

ok @pathqueues,$COUNT;

# shuffle the array (from perldoc -q shuffle, yes, its slow)
srand;
my @new = ();
while (@pathqueues) {
    push(@new, splice(@pathqueues, rand @pathqueues, 1));
}

for (@new) {
    my $job = $bq->pickup_queued_job(path => $_);
    ok $job;
    ok $job->{pathqueue}, $_;
    $job->finish if $job; # cancel job
}

my $any_more = $bq->pickup_queued_job;

ok !$any_more;

1;

