# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTTPD::Log::Filter;
$loaded = 1;
print "ok 1\n";
eval {
    my $filter = HTTPD::Log::Filter->new();
    open( LOG, 'sample/access_log_clf' ) or die $!;
    open( OUT, '>/tmp/access_log_clf' ) or die $!;
    while ( <LOG> )
    {
        my $line = $filter->filter( $_ );
        if ( $line )
        {
            print OUT $line;
        }
        else
        {
            die "Invalid entry at line $.:\n$_\n", $filter->re, "\n",
            $filter->generic_re, "\n";
        }
    }
    close( LOG );
    close( OUT );
    my $diff = '/usr/bin/diff';
    if ( -x $diff )
    {
        my @diff = `$diff sample/access_log_clf /tmp/access_log_clf`;
        die @diff if @diff;
    }
    unlink( '/tmp/access_log_clf' );
};
print STDERR $@ if $@;
print $@ ? "not " : "", "ok 2\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
