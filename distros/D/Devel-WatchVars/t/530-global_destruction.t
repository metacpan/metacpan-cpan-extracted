#!/usr/bin/env perl

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(t/lib lib);
use test_setup;

my $FILE = __FILE__;
my $LINE = __LINE__;

run_eponymous_test;

sub test_global_destruction {
    banner;

    my @cmd = (
        $^X,
        qw[-Mstrict -Ilib],
       "-M$MAIN_PKG",
       "-le",
       deQ<<'END_OF_EXTERNAL_PROGRAM',
        |Q|     use warnings FATAL => "all";
        |Q|     our $var = "new";
        |Q|     watch $var, q($var);                    # line 3
        |Q|     print "I am ", $var++ for 1..4;         # line 4
        |Q|     print "Exiting when I am $var";         # line 5
        |Q|     () = time; # bump line count
END_OF_EXTERNAL_PROGRAM
    );

    $LINE = 3;

    my($stdout, $stderr, $wstat) = capture { system @cmd };

    my $from = "from externally run perl program";

    is $wstat, number(0), "successful exit $from";
    is_lines $stdout, deQ<<'END_OF_STDOUT', "got expected stdout $from";
        |Q| I am new
        |Q| I am nex
        |Q| I am ney
        |Q| I am nez
        |Q| Exiting when I am nfa
END_OF_STDOUT

    is_lines $stderr, deQQ<<"END_OF_STDERR", "got expected stderr $from";
        |QQ| WATCH \$var = new at -e line @{[$LINE++]}$DOT_Carp
        |QQ| @{[stutter "FETCH \$var --> new at -e line @{[$LINE+0]}$DOT_Carp\n"]}
        |QQ| STORE \$var <-- nex at -e line @{[$LINE+0]}$DOT_Carp
        |QQ| @{[stutter "FETCH \$var --> nex at -e line @{[$LINE+0]}$DOT_Carp\n"]}
        |QQ| STORE \$var <-- ney at -e line @{[$LINE+0]}$DOT_Carp
        |QQ| @{[stutter "FETCH \$var --> ney at -e line @{[$LINE+0]}$DOT_Carp\n"]}
        |QQ| STORE \$var <-- nez at -e line @{[$LINE+0]}$DOT_Carp
        |QQ| @{[stutter "FETCH \$var --> nez at -e line @{[$LINE+0]}$DOT_Carp\n"]}
        |QQ| STORE \$var <-- nfa at -e line @{[$LINE++]}$DOT_Carp
        |QQ| FETCH \$var --> nfa at -e line @{[$LINE++]}$DOT_Carp
        |QQ| DESTROY (during global destruction) \$var = nfa at -e line 0$DOT_Carp
END_OF_STDERR

    return 1;

}
