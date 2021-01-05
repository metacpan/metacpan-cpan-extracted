#!/usr/bin/env perl

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(t/lib lib);
use test_setup;

my $FILE = __FILE__;
my $LINE = __LINE__;

run_eponymous_test;

#################################################

sub test_with_name {
    banner;

    my $start = "original value";
    chop(my $munged = $start);

    my $tracy = $start;
    my $name = "the traced variable";
    is tied($tracy), undef, "tracy is not tied";

    my($stdout, $stderr) = capture {
        $LINE = __LINE__;
        watch $tracy, "the traced variable";
        isa_ok tied($tracy), [$TIE_PKG], "tracy tied to right class";
        say "tracy has $tracy.";
        chop $tracy;
        unwatch $tracy;
    };

    my $i = 1+$LINE;

    is_lines $stdout, "tracy has $start.\n",  "stdout as expected";
    is_lines $stderr, deQQ<<"END_OF_TRACE",   "stderr as expected";
        |QQ| WATCH $name = $start at $FILE line @{[($i+=2)-2]}$DOT_Carp
        |QQ| FETCH $name --> $start at $FILE line @{[$i++]}$DOT_Carp
        |QQ| FETCH $name --> $start at $FILE line @{[$i+0]}$DOT_Carp
        |QQ| STORE $name <-- $munged at $FILE line @{[$i++]}$DOT_Carp
        |QQ| UNWATCH $name = $munged at $FILE line @{[$i++]}$DOT_Carp
END_OF_TRACE

    is tied($tracy), undef,  "tracy is no longer tied";
    is $tracy, $munged,      "tracy retains changes after tie broken";

    return 1;
}
