# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use vars qw( @types $t );
BEGIN { 
    @types = qw( clf elf xlf squid );
    $| = 1; 
    print "1..", scalar( @types ) + 1, "\n"; 
    $t = 1;
}
END {print "not ok $t\n" unless $loaded;}
use HTTPD::Log::Filter;
$loaded = 1;
print "ok $t\n";
$t++;
for my $type ( @types )
{
    eval {
        my $filter = HTTPD::Log::Filter->new();
        open( LOG, "sample/access_log_$type" ) or die $!;
        while ( <LOG> )
        {
            my $line = $filter->filter( $_ );
            die "Invalid entry at line $. ($type)\n" unless defined $line;
        }
        close( LOG );
        undef $filter;
    };
    print STDERR $@ if $@;
    print $@ ? "not " : "", "ok $t\n";
    $t++;
}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
