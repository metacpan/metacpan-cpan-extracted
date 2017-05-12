# $Id: test.pl,v 1.5 2000/07/22 11:54:22 lth Exp $

use strict;
use Test;

BEGIN { plan tests => 17 }

use DelayLine;

# simple constuction
ok( my $dl = DelayLine->new );

# simple constuction - alternative syntax
ok( my $dl = new DelayLine );

# construction via other object
my $dl = DelayLine->new('-delay' => 42);
ok( my $dl2 = $dl->new );

# different arg spelling
ok( my $dl = DelayLine->new('-delay' => 42) );
ok( my $dl = DelayLine->new('delay' => 42) );
ok( my $dl = DelayLine->new('Delay' => 42) );
ok( my $dl = DelayLine->new('DELAY' => 42) );

# unknown args
eval { my $dl = DelayLine->new('-badarg' => 42) };
ok($@, "/^DelayLine: Unknown argument '-badarg' at /");
eval { my $dl = DelayLine->new('-badarg' => 42, '-anotherbadarg' => 42) };
ok($@, "/^DelayLine: Unknown arguments /");

# check attributes
ok($dl->delay, 42);
ok($dl->debug, 0);

# check sequence
my $a = 'Hi, Mom!';
my $b = 'Look! No hands!';
$dl->in($a, 0);
$dl->in($b, 0);
ok($dl->out, $a);
ok($dl->out, $b);

# check delay
$dl->in($a, 2);
$dl->in($b, 0);
ok($dl->out, $b);  # b should be ready immediately
ok($dl->out, undef);  # a is not ready yet
sleep 2;
ok($dl->out, $a); # now a is ready

# event loop idiom
$dl->in($a, 3);
my $ob;
until ($ob = $dl->out) {
    sleep 1;
}
ok($ob, $a);
