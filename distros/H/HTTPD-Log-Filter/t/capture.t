# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTTPD::Log::Filter;
$loaded = 1;
print "ok 1\n";
# Capture only (constructor)
eval {
    my $filter = HTTPD::Log::Filter->new( capture => [ 'host' ] );
    open( OUT, '>/tmp/capture' ) or die $!;
    open( LOG, 'sample/access_log_clf' ) or die $!;
    while ( <LOG> )
    {
        next unless $filter->filter( $_ );
        print OUT "HOST: ", $filter->host(), "\n";
    }
    close( LOG );
    close( OUT );
    my $diff = '/usr/bin/diff';
    if ( -x $diff )
    {
        my @diff = `$diff sample/capture /tmp/capture`;
        die @diff if @diff;
    }
    unlink( '/tmp/capture' );
};
print STDERR $@ if $@;
print $@ ? "not " : "", "ok 2\n";
# Capture only (method)
eval {
    my $filter = HTTPD::Log::Filter->new();
    $filter->capture( [ 'host' ] );
    open( OUT, '>/tmp/capture' ) or die $!;
    open( LOG, 'sample/access_log_clf' ) or die $!;
    while ( <LOG> )
    {
        next unless $filter->filter( $_ );
        print OUT "HOST: ", $filter->host(), "\n";
    }
    close( LOG );
    close( OUT );
    my $diff = '/usr/bin/diff';
    if ( -x $diff )
    {
        my @diff = `$diff sample/capture /tmp/capture`;
        die @diff if @diff;
    }
    unlink( '/tmp/capture' );
};
print STDERR $@ if $@;
print $@ ? "not " : "", "ok 3\n";
# Capture and filter
eval {
    my $filter = HTTPD::Log::Filter->new( host_re => '192.168.1.20', capture => [ 'host' ] );
    open( OUT, '>/tmp/capture_and_filter' ) or die $!;
    open( LOG, 'sample/access_log_clf' ) or die $!;
    while ( <LOG> )
    {
        next unless $filter->filter( $_ );
        print OUT "HOST: ", $filter->host(), "\n";
    }
    close( LOG );
    close( OUT );
    my $diff = '/usr/bin/diff';
    if ( -x $diff )
    {
        my @diff = `$diff sample/capture_and_filter /tmp/capture_and_filter`;
        die @diff if @diff;
    }
    unlink( '/tmp/capture_and_filter' );
};
print STDERR $@ if $@;
print $@ ? "not " : "", "ok 4\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
