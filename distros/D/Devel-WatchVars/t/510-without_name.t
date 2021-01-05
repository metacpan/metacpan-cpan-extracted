#!/usr/bin/env perl

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(t/lib lib);
use test_setup;

my $FILE = __FILE__;
my $LINE = __LINE__;

run_eponymous_test;

#################################################

sub test_without_name {
    banner;

    my $start = "mississippi";
    (my $munged = $start) =~ s/(\pL{2})/\u$1/g;

    my($stdout, $stderr) = capture {
        $LINE = __LINE__;
        my $tracy = $start; watch $tracy;
        isa_ok tied($tracy), [$TIE_PKG], "tracy tied to right class";
        say "tracy has $tracy.";
        $tracy =~ s/(\pL{2})/\u$1/g;
        say "Now, tracy has $tracy.";
        unwatch $tracy;
    };

    my $i = 1+$LINE;
    my $name = "some scalar variable watched at line $i of $FILE";

    is_lines $stdout, deQQ<<"END_OF_STDOUT", "stdout as expected";
        |QQ| tracy has $start.
        |QQ| Now, tracy has $munged.
END_OF_STDOUT

    is_lines $stderr, deQQ<<"END_OF_STDERR", "stderr as expected";
        |QQ| WATCH $name = $start at $FILE line @{[($i+=2)-2]}$DOT_Carp
        |QQ| FETCH $name --> $start at $FILE line @{[$i++]}$DOT_Carp
        |QQ| FETCH $name --> $start at $FILE line @{[$i+0]}$DOT_Carp
        |QQ| STORE $name <-- $munged at $FILE line @{[$i++]}$DOT_Carp
        |QQ| FETCH $name --> $munged at $FILE line @{[$i++]}$DOT_Carp
        |QQ| UNWATCH $name = $munged at $FILE line @{[$i++]}$DOT_Carp
END_OF_STDERR

    return 1;
}
