use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use EV;
use EV::mysql;

plan tests => 2;

{
    my $weak;
    {
        my $m = EV::mysql->new(on_error => sub {});
        ok(defined $m, 'object created');
        $weak = $m;
        weaken($weak);
    }
    ok(!defined $weak, 'object destroyed on scope exit');
}
