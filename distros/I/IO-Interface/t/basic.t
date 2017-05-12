# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Socket;
use IO::Interface ':flags';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print defined(IFF_LOOPBACK) ? 'ok ':'not ok ',2,"\n";
my $s = IO::Socket::INET->new(Proto => 'udp');

my @if = $s->if_list;
print @if ? 'ok ': 'not ok ',3,"\n";

# find loopback interface
my @loopback;
foreach (@if) {
	next unless $s->if_flags($_) & IFF_UP;
	push @loopback,$_ if $s->if_flags($_) & IFF_LOOPBACK;
}

print @loopback ? 'ok ':'not ok ',4,"\n";
my @local = grep {$s->if_addr($_) eq '127.0.0.1'} @loopback;

print @local ? 'ok ': 'not ok ',5,"\n";


