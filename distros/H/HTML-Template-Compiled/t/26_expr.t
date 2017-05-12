use warnings;
use strict;
use lib 't';

use constant TESTS => 28;
use Test::More tests => TESTS + 1;
eval { require Parse::RecDescent; };
my $prd = $@ ? 0 : 1;
use_ok('HTML::Template::Compiled');
use HTC_Utils qw($cache $tdir &cdir);

sub HT_Utils::list { my @a = qw/ a b c /; return @a }
sub HT_Utils::each { my %a = ( a => 1, b => 2 ); return %a }
SKIP: {
    skip "No Parse::RecDescent installed", TESTS unless $prd;
    use_ok('HTML::Template::Compiled::Expr');
    my $htc;
    eval {
        $htc = HTML::Template::Compiled->new(
            scalarref => \<<'EOM',
[%= expr="(foo.count < 4)  && ( foo.count > 2)" %]
EOM
            use_expressions => 0,
            tagstyle => [qw/ -classic -comment -asp +tt /],
            loop_context_vars => 1,
        );
    };
    my $error = $@;
    #warn __PACKAGE__.':'.__LINE__.": $@\n";
    cmp_ok($error, '=~', qr/\QSyntax error in <TMPL_*> tag/, "No expressions allowed");
    my @tests = (
        [ q#[%= expr="(foo.count < 4)  && ( foo.count > 2)" %]#, 1],
        [ q#[%= expr="(foo.count > 4)  && ( foo.count % 2)" %]#, ''],
        [ q#[%= expr="lcfirst( .string )" %]#, 'aBC'],
        [ q#[%if expr="lcfirst( .string ) eq 'aBC'" %]23[%/if %]#, '23'],
        [ q#[%if expr="'string\'' eq 'string\''" %]23[%/if %]#, '23'],
        [ q#[%= expr="object.param('foo', .foo.count )" %]#, '424242'],
        [ q#[%if expr="0" %]zero[%elsif expr="foo.count < 4" %]< 4[%/if %]#, '< 4'],
        [ q#[%loop expr="list_object.list" context="list" %][%= _ %][%/loop %]#, 'abc'],
        [ q#[%each expr="list_object.each" context="list" %]k:[%= __key__ %] [%/each %]#, 'k:a k:b '],
        [ q#[%= expr=".foo{.name}" %]#, '3'],
        [ q#[%= expr=".foo{'count'}" %]#, '3'],
        [ q#[%= expr=".columns[.numbers[1]]" %]#, 'founded'],
        [ q#[%= expr=".a{'b'}{'c'}" %]#, 'd'],
        [ q#[%= expr=".bands[.numbers[1]]{'name'}" %]#, 'deine lakaien'],
        [ q#[%with name %][%= expr=".foo{_}" %][%/with %]#, '3'],
        [ q#[%= expr="'foo'.(2+5)" %]#, 'foo7'],
        [ q#[%= expr=".foo{('count'.2)}" %]#, '22'],
        [ q#[%= expr="3 * 4 / 2 + 7" %]#, '13'],
        [ q#[%= expr="('2' . '5' ) / 5" %]#, '5'],
        [ q#[%= expr="('2' . '4' ) % 20" %]#, '4'],
        [ q#[%= expr=".foobar" default="default value" %]#, 'default value'],
        [ q#[%loop list %][%= expr=".foo{_}" %] [%/loop %]#, 'foo a foo b foo c foo d '],
        [ q#[%loop list alias=item %][%= expr=".foo{$item}" %] [%/loop %]#, 'foo a foo b foo c foo d '],
        [ q#[%loop bands alias=band %][%= expr="$band{'name'}" %] [%/loop %]#, 'bauhaus deine lakaien '],
        [ q#[%loop bands %][%= expr="_{'name'}" %] [%/loop %]#, 'bauhaus deine lakaien '],
        [ q#[%loop bands alias=band %]
[%= __counter__ %]. 
[%loop .columns alias=column %]
[%= column %]: [%= expr="$band{column}" %] 
[%/loop %]
[%/loop %]#, '1. name: bauhaus founded: 1978 2. name: deine lakaien founded: 1985 '],
    );
    for my $i (0 .. $#tests) {
        my $test = $tests[$i];
        my ($tmpl, $exp) = @$test;
        $tmpl =~ tr/\r\n//d;
        my $htc = HTML::Template::Compiled->new(
            scalarref => \$tmpl,
            use_expressions => 1,
            debug => 0,
            tagstyle => [qw/ -classic -comment -asp +tt /],
            loop_context_vars => 1,
        );
        my $list_object = bless {}, 'HT_Utils';
        $htc->param(
            foo => {
                count => '3',
                count1 => '21',
                count2 => '22',
                count3 => '23',
                a => 'foo a',
                b => 'foo b',
                c => 'foo c',
                d => 'foo d',
            },
            object => bless ({ foo => 42 }, 'HTC::DUMMY'),
            string => 'ABC',
            list_object => $list_object,
            name => 'count',
            list => [qw/ a b c d /],
            bands => [
                { name => 'bauhaus', founded => 1978 },
                { name => 'deine lakaien', founded => 1985 },
            ],
            columns => [qw/ name founded /],
            numbers => [0,1],
            a => { b => { c => 'd' } },
        );
        my $out = $htc->output;
        #print "out: $out\n";
        cmp_ok($out, 'eq', $exp, "Expressions $i $tmpl");
    }
}

sub HTC::DUMMY::param {
    return $_[0]->{ $_[1] } x $_[2]
}
