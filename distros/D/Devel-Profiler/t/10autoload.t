use Test::More tests => 6;
use Devel::Profiler::Test qw(profile_code check_tree get_times write_module);

SKIP: {

skip("profiling AUTOLOAD not working yet", 6);

profile_code(<<'END', "test effect of AUTOLOAD");
package Foo;
our $AUTOLOAD;
sub AUTOLOAD {
   return $AUTOLOAD;
}
package main;
Foo::bar();
Foo::bar();
Foo::bar();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
Foo::AUTOLOAD
Foo::AUTOLOAD
Foo::AUTOLOAD
END


profile_code(<<'END', "test effect of Fcntl-style AUTOLOAD");
package Foo;
our $AUTOLOAD;
sub constant { return $_[0] }
sub AUTOLOAD {
    (my $constname = $AUTOLOAD) =~ s/.*:://;
    print STDERR "AUTOLOAD: $AUTOLOAD\n CONSTNAME: $constname\n";
    my $val = constant($constname, 0);
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}
package main;
Foo::bar();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
Foo::AUTOLOAD
Foo::AUTOLOAD
Foo::AUTOLOAD
END

# setup module file for test below
write_module("Exporting", <<'END');
package Exporting;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(foo bar);
sub bar { "Exporting::bar" }
sub AUTOLOAD { our $AUTOLOAD; return $AUTOLOAD }
1;
END

profile_code(<<'END', "test effect of AUTOLOAD with non-existent export");
use Exporting qw(foo bar);
die unless bar() eq 'Exporting::bar';
die unless foo() eq 'Exporting::foo';
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
Exporting::foo
Exporting::bar
END

cleanup_module("Exporting");

}
