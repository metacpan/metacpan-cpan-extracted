# vim: filetype=perl :
use strict;
use warnings;

use Test::More;    # last test to print
use Log::Log4perl::Tiny qw< get_logger LOGLOCAL >;

my $default = get_logger();

ok !exists($default->{loglocal}), 'no "loglocal" by default';

is LOGLOCAL('foo'), undef, 'non-existent thing returns undef';
ok exists($default->{loglocal}), 'loglocal created by autovivification';
ok !exists($default->{loglocal}{foo}), 'sub-key foo does not exist anyway';

is LOGLOCAL(foo => 'bar'), undef, 'previous value still undef';
ok exists($default->{loglocal}{foo}), 'sub-key foo added';
is $default->{loglocal}{foo}, 'bar', 'sub-key has right value';

is LOGLOCAL(foo => 'baz'), 'bar', 'previous value as expected';
ok exists($default->{loglocal}{foo}), 'sub-key foo still there';
is $default->{loglocal}{foo}, 'baz', 'current value set correctly';

{
   my $alt = new_ok 'Log::Log4perl::Tiny';
   $alt->loglocal(foo => 'ouch');
   ok exists($alt->{loglocal}{foo}), 'sub-key foo set in alt logger';
   is $alt->{loglocal}{foo},     'ouch', 'current value (alt logger)';
   is $default->{loglocal}{foo}, 'baz',  'current value (default logger)';
}

{
   my $alt = new_ok 'Log::Log4perl::Tiny',
     [loglocal => {foo => 1, bar => 2, baz => undef}];
   ok exists($alt->{loglocal}), 'loglocal is set';
   is_deeply $alt->{loglocal}, {foo => 1, bar => 2, baz => undef},
     'loglocal initialization';
   is $default->{loglocal}{foo}, 'baz', 'current value (default logger)';
}

is LOGLOCAL('foo'), 'baz', 'getting last value as expected';
ok !exists($default->{loglocal}{foo}), 'sub-key foo removed';

done_testing();
