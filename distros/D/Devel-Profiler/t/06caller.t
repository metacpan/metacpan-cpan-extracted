use Test::More tests => 8;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

profile_code(<<'END', "make sure overridden caller() works");
sub foo {
    die unless (caller(1))[3] eq 'main::bar';
}
sub bar {
    foo();
}
bar;
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::bar
   main::foo
END



profile_code(<<'END', "make sure overridden caller() works");
sub foo {
    die unless (caller(1))[3] eq 'main::bar';
    die unless (caller(2))[3] eq 'main::baz';
}
sub bar {
    foo();
    die unless (caller(1))[3] eq 'main::baz';
}
sub baz {
    bar();
    die unless caller() eq 'main';
}
baz;
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::baz
   main::bar
      main::foo
END


# check that the calling package is correct
profile_code(<<'END', "check caller() package setting");
package Foo;
sub foo { Bar::bar(); }
package Bar;
sub bar { 
    die unless caller() eq 'Foo' 
}
package main;
Foo::foo();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
Foo::foo
   Bar::bar
END

# test a program that pulls a full stack trace
profile_code(<<'END', "check caller() package setting");
sub foo { my @stack; while (my @s = caller($i++)) {push @stack, \@s} die unless @stack }
foo();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::foo
END
