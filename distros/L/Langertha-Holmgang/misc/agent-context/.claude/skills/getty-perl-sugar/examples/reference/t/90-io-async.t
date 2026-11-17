use strict;
use warnings;
use Test::More;
BEGIN {
  eval { require Future; require IO::Async::Loop; 1 } or do {
    BAIL_OUT('Future and IO::Async are required by strict integration mode') if $ENV{SUGAR_REQUIRE_INTEGRATIONS};
    plan skip_all => 'Future and/or IO::Async is not installed';
  };
}
my $loop=IO::Async::Loop->new;
my @trace;
my @futures=map {
  my $key=$_;
  push @trace,"start-$key";
  $loop->delay_future(after=>0.01)->then(sub {
    push @trace,"finish-$key";
    return Future->done({key=>$key});
  });
} qw(a b);
is_deeply(\@trace,[qw(start-a start-b)],'both operations started before either timer completes');
my $all=Future->needs_all(@futures);
$loop->await($all);
is_deeply([$all->get],[{key=>'a'},{key=>'b'}],'real event-loop futures complete');
is(scalar @trace,4,'both completion callbacks run');
done_testing;
