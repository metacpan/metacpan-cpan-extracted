use warnings;
use strict;
use lib 't';
use Test::More tests => 5;
use_ok('HTML::Template::Compiled');
use HTC_Utils qw($cache $tdir &cdir);

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
test <%= .array[0][0] %>
Count outer:   <%= .array# %>
Count undef:   <%= .undef# %>
Count inner 1: <%= .array[0]# %>
Count inner 2: <%= .array[1]# %>
EOM
        debug    => 0,
    );

    $htc->param(
        array => [
            [qw(a b c)],
            [qw(d e f g)],
        ],
    );
    my $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, '=~', "Count outer: +2", "array count 1");
    cmp_ok($out, '=~', "Count inner 1: +3", "array count 2");
    cmp_ok($out, '=~', "Count inner 2: +4", "array count 3");
    cmp_ok($out, '=~', "Count undef: +0", "undef array count");

}


