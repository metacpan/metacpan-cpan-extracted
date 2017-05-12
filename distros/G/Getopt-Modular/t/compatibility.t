#!/usr/bin/perl

# We provide a convenience method of obtaining all the parameters
# at once during initial parsing.  This reduces the change required
# going from Getopt::Long to Getopt::Modular.  However, it's not a full
# compatibility layer, that's both impossible and, IMO, undesirable
# (you're not going to gain anything with the same interface, that's the
# whole point of GM).

# So, let's do some tests on that.

use strict;
use warnings;
use Getopt::Modular -namespace => 'GM';
use Test::Deep;
use Test::Exception;
use Test::More;

my %called;
my $gm = GM->new(); # so we can hack a bit.

GM->acceptParam(
                'a' => {
                    spec => '=s',
                    validate => sub {
                        ++$called{a};
                    },
                },
                'b' => {
                    spec => '=s',
                    default => sub {
                        ++$called{b_d};
                        'bar'
                    },
                },
               );

@ARGV = qw( -a foo );
lives_ok { GM->parseArgs(); };

ok($called{a});
ok(!$called{b_d});
is(GM->getOpt('a'), 'foo');
is(GM->getOpt('b'), 'bar');

%called = (); # reset.
delete $gm->{options};

@ARGV = qw( -a foo );
GM->parseArgs(\ my %opt);
ok($called{a});
ok($called{b_d}); # called this time
is(GM->getOpt('a'), 'foo');
is(GM->getOpt('b'), 'bar');
cmp_deeply(\%opt, {a=>foo=>b=>bar=>}); #populated

done_testing();