#!/usr/bin/env perl

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(t/lib lib);
use test_setup;

my $FILE = __FILE__;
my $LINE = __LINE__;

run_eponymous_test;

#################################################

sub test_without_unwatch {
    banner;
    my $start = "rumplestiltskin";
    (my $munged_1 = $start    ) =~ s/(\pL{3})/\u$1/g;
    (my $munged_2 = $munged_1 ) =~ s/(\pL{2})/\u$1/g;
    my $munged   = $munged_2 . "ny";

    my $name = q(my $tracy);

    my($stdout, $stderr) = capture {
        $LINE = __LINE__;
        my $tracy = $start; watch $tracy, $name;
        isa_ok tied($tracy), [$TIE_PKG], "tracy tied to right class";
        say "tracy has $tracy.";
        $tracy =~ s/(\pL{3})/\u$1/g;
        $tracy =~ s/(\pL{2})/\u$1/g;
        $tracy .= "ny";
        say "Now, tracy has $tracy.";
        () = time;  # just to bump the line count by one
        () = time;  # just to bump the line count by one
        () = time;  # just to bump the line count by one
    };

    my $i = 1+$LINE;

    is_lines $stdout, deQQ<<"END_OF_STDOUT", "stdout as expected";
        |QQ| tracy has $start.
        |QQ| Now, tracy has $munged.
END_OF_STDOUT

    my $fudge_count = $^V lt v5.23 ? 3 : 2;

    is_lines $stderr, deQQ<<"END_OF_STDERR", "stderr as expected";
        |QQ| WATCH $name = $start at $FILE line @{[($i+=2)-2]}$DOT_Carp
        |QQ| FETCH $name --> $start at $FILE line @{[$i++]}$DOT_Carp
        |QQ| FETCH $name --> $start at $FILE line @{[$i+0]}$DOT_Carp
        |QQ| STORE $name <-- $munged_1 at $FILE line @{[$i++]}$DOT_Carp
        |QQ| FETCH $name --> $munged_1 at $FILE line @{[$i+0]}$DOT_Carp
        |QQ| STORE $name <-- $munged_2 at $FILE line @{[$i++]}$DOT_Carp
        |QQ| FETCH $name --> $munged_2 at $FILE line @{[$i+0]}$DOT_Carp
        |QQ| STORE $name <-- $munged at $FILE line @{[$i++]}$DOT_Carp
        |QQ| FETCH $name --> $munged at $FILE line @{[$i++]}$DOT_Carp
        |QQ| DESTROY $name = $munged at $FILE line @{[$i+=$fudge_count]}$DOT_Carp
END_OF_STDERR

    return 1;
}
