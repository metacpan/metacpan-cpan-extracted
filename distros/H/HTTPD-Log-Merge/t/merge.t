# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTTPD::Log::Merge;
$loaded = 1;
print "ok 1\n";
eval {
    open( FH, ">/tmp/merged_access_log" );
    my $merge = HTTPD::Log::Merge->new(
        logfile => [ map { "sample/access_log_$_"} ( 1,2,3 ) ],
        verbose => 1,
        out_fh => \*FH,
    );
    $merge->merge;
    close( FH );
    my $diff = '/usr/bin/diff';
    if ( -x $diff )
    {
        my @diff = `$diff sample/merged_access_log /tmp/merged_access_log`;
        die @diff if @diff;
    }
    unlink( '/tmp/merged_access_log' );
};
print STDERR $@ if $@;
print $@ ? "not " : "", "ok 2\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
