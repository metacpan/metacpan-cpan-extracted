use strict;
use warnings;
use Test::More tests => 2;
use Test::Requires qw(Sys::Trace);
use File::Temp qw(:mktemp);

my $target1 = File::Temp->new(TEMPLATE => ".target.$$.XXXXXX");
my $target2 = File::Temp->new(TEMPLATE => ".target.$$.XXXXXX");
my $name    = mktemp(".name.$$.XXXXXX");
diag "$name\n";
END { unlink $name or warn "Couldn't unlink $name: $!" }

subtest 'non-atomic' => sub {
    plan tests => 2;
    my $non_atomic_trace = Sys::Trace->new(
        exec => [$^X, '-Ilib', '-E', "symlink '$target1', '$name';"]
    );
    $non_atomic_trace->start;
    $non_atomic_trace->wait;

    my $non_atomic_results = $non_atomic_trace->results;
    ok do { grep { $_->{call} eq 'symlink' } @$non_atomic_results }, 'symlink system call seen';
    ok do {!grep { $_->{call} eq 'rename'  } @$non_atomic_results }, 'no rename system call seen';
};

subtest 'atomic' => sub {
    plan tests => 4;
    my $atomic_trace = Sys::Trace->new(
        exec => [$^X, '-Ilib', '-E', "use File::Symlink::Atomic; symlink '$target2', '$name';"]
    );
    $atomic_trace->start;
    $atomic_trace->wait;

    my $atomic_results = $atomic_trace->results;
    ok do { grep { $_->{call} eq 'symlink' } @$atomic_results }, 'symlink system call seen';
    is do { grep { $_->{call} eq 'rename'  } @$atomic_results }, 1, 'rename system call seen';
    
    my @rename_calls = do { grep { $_->{call} eq 'rename'  } @$atomic_results };
    like $rename_calls[0]->{args}->[0], qr/\Q$name/, 'correct parameters';
    like $rename_calls[0]->{args}->[1], qr/\Q$name/, 'correct parameters';
};
