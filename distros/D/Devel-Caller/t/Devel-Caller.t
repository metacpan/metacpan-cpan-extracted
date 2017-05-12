#!perl -w
use strict;
use Test::More tests => 72;

BEGIN { use_ok( 'Devel::Caller', qw( caller_cv caller_args caller_vars called_with called_as_method ) ) }

package CV;
use Test::More;

my $cv;
$cv = sub {
    is( ::caller_cv(0), $cv, "caller_cv" );
};
$cv->();

sub foo { bar(my $bar) }
sub bar { baz(my $baz) }
sub baz { check(my $check) }
sub check {
    my $i = 0;
    for (qw( check baz bar foo )) {
        is(         ::caller_cv($i),    \&{"CV::$_"}, "caller_cv $i is $_" );
        is_deeply( [::called_with($i,1)], [ "\$$_" ], "called_with $i is \$$_" );
        ++$i;
    }
}
foo(my $foo);

package main;

my (@foo, %foo);
sub called_lex {
    my @called = called_with(0);
    is( scalar @called, 3, "right count");
    is( $called[0], \$foo, "with lexical \$foo" );
    is( $called[1], \@foo, "with lexical \@foo" );
    is( $called[2], \%foo, "with lexical \%foo" );
}
called_lex($foo, @foo, %foo);

sub called_lex_names {
    my @called = called_with(0, 1);
    is( @called, 3, "right count");
    is( $called[0], '$foo', "with lexical name \$foo" );
    is( $called[1], '@foo', "with lexical name \@foo" );
    is( $called[2], '%foo', "with lexical name \%foo" );
}
called_lex_names($foo, @foo, %foo);

# called_with muddied with assignments
my @expect;
my $what;
sub called_assign {
    is_deeply([ called_with(0, 1) ], \@expect,
              "$what called_assign(".join(', ', map { $_ || "undef"} @expect).")");
}

$what = 'constant';
{
    my $foo;
    @expect = undef;                called_assign('foo');
    @expect = (undef, '$foo');      called_assign('foo', $foo);
    @expect = (undef, '$foo');      called_assign(['foo'], $foo);
}

$what = 'lexical create';
{ # test scalars
    @expect = qw( $bar );           called_assign(my $bar = q(some value));
    @expect = qw( $baz );           called_assign(my $baz = $foo);
    @expect = qw( $quux $bar );     called_assign(my $quux = $foo, $bar);
}
{ # same again for arrays
    @expect = qw( @bar );           called_assign(my @bar = qw(some values));
    @expect = qw( @baz );           called_assign(my @baz = @foo);
    @expect = qw( @quux @bar );     called_assign(my @quux = @foo, @bar);
    @expect = qw( @flange );        called_assign(my @flange = (@foo, @bar));
}
{ # and again for hashes
    @expect = qw( %bar );           called_assign(my %bar = qw(some values));
    @expect = qw( %baz );           called_assign(my %baz = %foo);
    @expect = qw( %quux %bar );     called_assign(my %quux = %foo, %bar);
    @expect = qw( %flange );        called_assign(my %flange = (%foo, %bar));
}

$what = 'lexical prexist';
{ # test scalars
    my ($bar, $baz, $quux);
    @expect = qw( $bar );           called_assign($bar = q(some value));
    @expect = qw( $baz );           called_assign($baz = $foo);
    @expect = qw( $quux $bar );     called_assign($quux = $foo, $bar);
}
{ # same again for arrays
    my (@bar, @baz, @quux, @flange);
    @expect = qw( @bar );           called_assign(@bar = qw(some values));
    @expect = qw( @baz );           called_assign(@baz = @foo);
    @expect = qw( @quux @bar );     called_assign(@quux = @foo, @bar);
    @expect = qw( @flange );        called_assign(@flange = (@foo, @bar));
}
{ # and again for hashes
    my (%bar, %baz, %quux, %flange);
    @expect = qw( %bar );           called_assign(%bar = qw(some values));
    @expect = qw( %baz );           called_assign(%baz = %foo);
    @expect = qw( %quux %bar );     called_assign(%quux = %foo, %bar);
    @expect = qw( %flange );        called_assign(%flange = (%foo, %bar));
}

use vars qw( $quux @quux %quux );
sub called {
    my @called = caller_vars(0);
    is( scalar @called, 3, "right count");
    is( $called[0], \$quux, "with \$quux" );
    is( $called[1], \@quux, "with \@quux" );
    is( $called[2], \%quux, "with \%quux" );
}
called($quux, @quux, %quux);


sub called_names {
    my @called = called_with(0, 1);
    is( scalar @called, 3, "right count");
    is( $called[0], '$main::quux', "with name 0" );
    is( $called[1], '@main::quux', "with name 1" );
    is( $called[2], '%main::quux', "with name 2" );
}

called_names($quux, @quux, %quux);
sub called_globs {
    my @called = called_with(0, 1);
    is( scalar @called, 3, "right count");
    is( $called[0], '*main::STDIN',  "with name 0" );
    is( $called[1], '*main::STDOUT', "with name 1" );
    is( $called[2], '*main::STDERR', "with name 2" );
}

called_globs(*STDIN, *STDOUT, *STDERR);

package T;
$what = 'package';
*called_assign = \&::called_assign;

{ # test scalars
    use vars qw( $bar $baz $quux );
    @expect = qw( $T::bar );           called_assign($bar = q(a value));
    @expect = qw( $T::baz );           called_assign($baz = $foo);
    @expect = qw( $T::quux $T::bar );  called_assign($quux = $foo, $bar);
}
{ # same again for arrays
    use vars qw( @bar @baz @quux @flange );
    {
        local $::TODO = "splitops under 5.00503"
          if $] < 5.006;
        @expect = qw( @T::bar );       called_assign(@bar = qw(some values));
    }
    @expect = qw( @T::baz );           called_assign(@baz = @foo);
    @expect = qw( @T::quux @T::bar );  called_assign(@quux = @foo, @bar);
    @expect = qw( @T::flange );        called_assign(@flange = (@foo, @bar));
}
{ # and again for hashes
    use vars qw( %bar %baz %quux %flange );
    @expect = qw( %T::bar );           called_assign(%bar = qw(1 2));
    @expect = qw( %T::baz );           called_assign(%baz = %foo);
    @expect = qw( %T::quux %T::bar );  called_assign(%quux = %foo, %bar);
    @expect = qw( %T::flange );        called_assign(%flange = (%foo, %bar));
}


package main;
# were we called as a method or a sub
my $called;
sub maybe_method {
    is( called_as_method(), $called, "called_as_method" );
}
maybe_method();
$called = 1;
main->maybe_method();
my $name = 'maybe_method';
main->$name();


sub args {
    is_deeply( \@_, [ caller_args(0) ] );
}

args('foo', 'bar');

# rt.cpan.org 2878
my $coy = rand 6;
print "# cunning coy tests\n";
real( $coy, $coy );
print "# concat\n";

print "# print ", real( $coy, $coy ), "\n";

sub real {
    is_deeply( [ called_with(0,1) ], [qw( $coy $coy )], 'real( $coy, $coy )' );
}
