use strict;

# There should be more tests in this file.  Currently only the following
# are tested:
#   using Java::Build::JVM
#   some of its methods (with calls that should work):
#     destination
#     compile
# None of other methods in Java::Build::JVM are tested.  Even the above
# methods are only called once.  No error conditions are checked.

use Test::More tests => 9;

BEGIN {
    SKIP: {
        my $classpath = $ENV{CLASSPATH};
        skip("Couldn't find tools.jar in CLASSPATH environment variable", 9)
            unless ($classpath =~ /tools.jar/);

# The test is not that slow, it takes less than a minute for the whole file.
#        diag("");
#        diag("This test file is slow, it starts and uses two JVMs");
        use_ok('Java::Build::JVM');
    }
}

# The classpath variable is reexamined here since I could not figure out
# how to share it with the one above (I tried our, etc.)
my $classpath = $ENV{CLASSPATH};
if ($classpath =~ /tools.jar/) {
    my $compiler = Java::Build::JVM->getCompiler();

    isa_ok($compiler, 'Java::Build::JVM');

    $compiler->destination("t/compiled");
    my $compile_result = $compiler->compile([ 't/src/CompileTest.java' ]);

    isnt($compile_result, undef, "good compile return");

    diag("");
    diag("Testing bad compile calls.");
    diag("Ignore: Nothing to compile messages");

    my $greeting = `java -cp t/compiled CompileTest`;
    is($greeting, "Hello\n", "Hello program ran");

    unlink 't/compiled/CompileTest.class';

    $compile_result = $compiler->compile();
    is($compile_result, undef, "no arg to compile");

    $compile_result = $compiler->compile('hi.java');
    is($compile_result, undef, "non-list arg to compile");

    $compiler->classpath("t/src");
    my $cp = $compiler->classpath;
    is($cp, "t/src", "classpath set");

    $compiler->classpath("");
    $cp = $compiler->classpath();
    is($cp, "", "classpath reset");

    eval {
        $compiler->compile([ "t/errsrc/Hi.java" ]);
    };
    like($@, qr/cannot read/, 'compile errors');
}
