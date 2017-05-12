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
    my $filter = HTTPD::Log::Filter->new(
        exclusions_file     => '/tmp/exclusions_clf',
        request_re          => "GET.*?",
        format              => "XLF",
    );
    $filter->format( 'CLF' );
    open( LOG, 'sample/access_log_clf' ) or die $!;
    open( OUT, '>/tmp/inclusions_clf' ) or die $!;
    while ( <LOG> )
    {
        my $line = $filter->filter( $_ );
        die "Invalid entry at line $.\n" unless defined $line;
        print OUT $line if $line;
    }
    close( LOG );
    close( OUT );
    undef $filter;
    my $diff = '/usr/bin/diff';
    if ( -x $diff )
    {
        for ( qw( inclusions_clf exclusions_clf ) )
        {
            my @diff = `$diff sample/$_ /tmp/$_`;
            die "sample/$_ and /tmp/$_ differ:\n@diff" if @diff;
        }
    }
    unlink( '/tmp/exclusions_clf', '/tmp/inclusions_clf' );
};
print STDERR $@ if $@;
print $@ ? "not " : "", "ok 2\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
