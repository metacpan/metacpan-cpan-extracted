use strict;
use warnings;
use Test::More;
BEGIN {
  eval { require Future; 1 } or do {
    BAIL_OUT('Future is required by strict integration mode') if $ENV{SUGAR_REQUIRE_INTEGRATIONS};
    plan skip_all => 'Future is not installed';
  };
}
my ($a,$b)=(Future->new,Future->new);
my $both=Future->needs_all($a,$b);
$b->done({b=>2});
ok(!$both->is_ready,'needs_all waits for both');
$a->done({a=>1});
is_deeply([$both->get],[{a=>1},{b=>2}],'success results follow input order, not completion order');
my ($bad,$pending)=(Future->new,Future->new);
my $joined=Future->needs_all($bad,$pending);
$bad->fail('failed');
ok($joined->is_failed,'failure propagates');
ok($pending->is_cancelled,'ordinary pending sibling is cancelled');
$joined->failure; # acknowledge the failure
my @trace;
sub wrapped_sync {
  my ($key)=@_;
  push @trace,"start-$key";
  push @trace,"finish-$key";
  return Future->done({key=>$key});
}
my @wrapped=map {wrapped_sync($_)} qw(a b);
Future->needs_all(@wrapped)->get;
is_deeply(\@trace,[qw(start-a finish-a start-b finish-b)],'wrapping synchronous bodies does not interleave them');
done_testing;
