#!perl

use Test::More tests => 9; #qw(no_plan); # tests => 1;
use Data::Dumper;

BEGIN {
    use_ok( 'Getopt::Modular', -namespace => 'GM' );
}


# autosplit of aliases
GM->acceptParam(
                 'fullname|fn|f' => {
                 }
                );

# this isn't the right way to load this, but should be a good approximate
# test of the right way.
my $secret = Getopt::Modular::_self_or_global(['GM']);
is(ref $secret, 'GM', 'Check Derivation') or
    diag(Dumper $secret);

is_deeply(
          $secret->{accept_opts}{fullname}{aliases},
          [ qw(fn f) ],
          'autosplit of aliases: key',
         ) or
    diag(Dumper $secret);

# autosplit of aliases 2
GM->acceptParam(
                 'big' => {
                     aliases => 'b|frobnicator',
                 },
                );
is_deeply(
          $secret->{accept_opts}{big}{aliases},
          [ qw(b frobnicator) ],
          'autosplit of aliases: inside parameter hash'
         ) or
    diag(Dumper $secret);

GM->acceptParam(
                 'big2' => {
                     aliases => [ 'Z|blah', 'boing' ],
                 },
                );
is_deeply(
          $secret->{accept_opts}{big2}{aliases},
          [ qw(Z blah boing) ],
          'autosplit of aliases: inside parameter hash via array ref'
         ) or
    diag(Dumper $secret);

# eval *shouldn't* be needed ... but if we do have an error and want
# a good TAP message, trap it anyway.
eval {
    GM->acceptParam(
                     'big2' => {
                         aliases => [ 'Z|blah' ],
                     },
                    );
};
ok(!$@, 'reuse aliases with the same param name is ok.') or
    diag($@, Dumper $secret);

eval {
    GM->acceptParam(
                     'big3' => {
                         aliases => [ 'Z|foo' ],
                     },
                    );
};
ok($@, 'reuse aliases with the different param name dies.') or
    diag(Dumper $secret);

GM->unacceptParam('big2');
ok(! exists $secret->{all_opts}{Z}, 'clean up of aliases') or
    diag(Dumper($secret));

# restore the parameter
GM->acceptParam('big2');
ok(exists $secret->{all_opts}{Z}, 'restoring of aliases') or
    diag(Dumper($secret));

