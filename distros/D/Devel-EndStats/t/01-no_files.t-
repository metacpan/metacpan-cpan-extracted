#!perl

use Devel::EndStats;
$Devel::EndStats::opts{_quiet}++;

END {
    print "1..1\n";
    print +($Devel::EndStats::stats =~ /# BEGIN stats.=^# Total number of required files loaded: 0\n.+^# END stats/m ? "ok" : "not ok"),
        " 1 - report zero files when no modules are loaded\n";
}
