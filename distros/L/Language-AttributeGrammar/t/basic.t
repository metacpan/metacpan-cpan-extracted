use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

my $m; BEGIN { use_ok($m = 'Language::AttributeGrammar') }

can_ok($m, "new");
can_ok($m, "apply");

sub mkg { $m->new(shift) }
sub mko { my $c = shift; bless { @_ }, $c }
sub apply { mkg(shift)->apply(@_) }

{
    my $g = mkg('Foo: $/.gorch = { 42 }');

    my $r;
    lives_ok { $r = $g->apply(mko("Foo"), 'gorch') } "ok to access valid attribute";
    is($r, 42, "the attribute's value");

    dies_ok { $r->apply(mko("Foo"), 'swick') } "fatal to access invalid attribute";
}

{
    my $g = mkg(<<'EOG');
Foo: $/.gorch = { 42 }
   | $/.bar   = { $/.gorch / 2 }
EOG

    is($g->apply(mko("Foo"), 'bar'), 21, "dependent attributes on the same node");
}

{
    my $g = mkg(<<'EOG');
Foo: $/.value = { 3 * $<bar>.value }
Bar: $/.value = { 4 }
EOG

    is($g->apply(mko("Foo", bar => mko("Bar")), 'value'), 12, 
        "one level of synthesized attributes");
}


{
    my $o = mko(Foo => child => mko(Foo => child => mko(Foo => child => mko('Bar'))));
    my $g = mkg(<<'EOG');
Foo: $/.value = { 3 * $<child>.value }
Bar: $/.value = { 4 }
EOG

    is($g->apply($o, 'value'), 3 * 3 * 3 * 4, "N levels of synthesized attributes");
}

{
    my $g = mkg(<<'EOG');
Foo: $<bar>.parent_value = { 3 }
   | $/.value        = { $<bar>.value }
Bar: $/.value        = { 4 * $/.parent_value }
EOG

    is($g->apply(mko("Foo", bar => mko("Bar")), 'value'), 12, 
        "one level of inherited attributes");
}

{
    my $o = mko(Root => child => mko(Foo => child => mko(Foo => child => mko(Foo => child => mko("Bar")))));
    my $g = mkg(<<'EOG');
Root: $<child>.parent_value = { 1 }
    | $/.value = { $<child>.value }

Foo: $<child>.parent_value = { 3 * $/.parent_value }
   | $/.value = { $<child>.value }

Bar: $/.value = { 4 * $/.parent_value }
EOG

    is($g->apply($o, 'value'), 3 * 3 * 3 * 4, "N levels of inherited attributes");
}

{
    my $g = mkg(<<'EOG');
ROOT: $/.foo = { 5 }
Foo: $<child>.bar = { $/.foo }
   | $/.bah = { $<child>.bah }
Bar: $/.bah = { $/.bar + 10 }
EOG
    is($g->apply(mko(Foo => child => mko('Bar')), 'bah'), 15, "ROOT inherits");
}

TODO: {
    local $TODO = 'I suppose ROOT should override if there is an overlap';
    my $g = mkg(<<'EOG');
ROOT: $/.foo = { 5 }
Foo: $/.foo = { $<child>.bar }
Bar: $/.bar = { 10 }
EOG
    eval {
        my $r = $g->apply(mko(Foo => child => mko('Bar')), 'foo');
        is($r, 5, "definition under ROOT overrides definition over class"); 1;
    } or ok(0, "definition under ROOT overrides definition over class");
}

{
    sub Foo::getchild {
        my ($foo) = @_;
        $foo->{child}
    }
    my $g = mkg(<<'EOG');
Foo: $/.foo = { `$/->getchild`.foo[0] }
Bar: $/.foo = { $<value> }
EOG
    my $r = $g->apply(mko(Foo => child => mko(Foo => child => mko(Bar => value => 42))), 'foo');
    is($r, 42, 'backticks');
}

# vim: ft=perl :
