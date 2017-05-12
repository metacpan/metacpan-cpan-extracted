#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

# Having to trustme these is obnoxious.  It would be nice if there was a base
# class for mailers.  Then again, whatever.  -- rjbs, 2006-07-06
all_pod_coverage_ok({
  trustme => [ qw(send is_available get_env_sender get_env_recipients) ],
  coverage_class => 'Pod::Coverage::CountParents'
});
