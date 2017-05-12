#!perl

use 5.010;
use strict;
use warnings;

use Getopt::Long::Negate::EN qw(
                                   negations_for_option
                     );
use Test::More 0.98;

is_deeply([negations_for_option('foo')], ['no-foo', 'nofoo']);
#is_deeply(negations_for_option({wordsep=>''}, 'foo')], ['nofoo']);
#is_deeply(negations_for_option({wordsep=>'_'}, 'foo')], ['no_foo']);

#is_deeply([negations_for_option('has-foo')], ['hasnt-foo']);
#is_deeply([negations_for_option('hasnt_foo')], ['has-foo']);

is_deeply([negations_for_option('with_foo')], ['without_foo']);
is_deeply([negations_for_option('without-foo')], ['with-foo']);

is_deeply([negations_for_option('is-foo')], ['isnt-foo']);
is_deeply([negations_for_option('isnt_foo')], ['is_foo']);
is_deeply([negations_for_option('are-foo')], ['arent-foo']);
is_deeply([negations_for_option('arent_foo')], ['are_foo']);

is_deeply([negations_for_option('has-foo')], ['hasnt-foo']);
is_deeply([negations_for_option('hasnt_foo')], ['has_foo']);
is_deeply([negations_for_option('have-foo')], ['havent-foo']);
is_deeply([negations_for_option('havent_foo')], ['have_foo']);

is_deeply([negations_for_option('can-foo')], ['cant-foo']);
is_deeply([negations_for_option('cant_foo')], ['can_foo']);

is_deeply([negations_for_option('disabled-foo')], ['enabled-foo']);
is_deeply([negations_for_option('enabled_foo')], ['disabled_foo']);
is_deeply([negations_for_option('disable-foo')], ['enable-foo']);
is_deeply([negations_for_option('enable_foo')], ['disable_foo']);

is_deeply([negations_for_option('disallowed-foo')], ['allowed-foo']);
is_deeply([negations_for_option('allowed_foo')], ['disallowed_foo']);
is_deeply([negations_for_option('disallow-foo')], ['allow-foo']);
is_deeply([negations_for_option('allow_foo')], ['disallow_foo']);

is_deeply([negations_for_option('no-foo')], ['foo']);
is_deeply([negations_for_option('no_foo')], ['foo']);

DONE_TESTING:
done_testing;
