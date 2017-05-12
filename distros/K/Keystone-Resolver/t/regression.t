# $Id: regression.t,v 1.5 2008-04-30 11:45:02 mike Exp $

use strict;
use Test;
use vars qw(@tests);

BEGIN {
    use IO::File;
    my $fh = new IO::File("<t/regression/Register")
	or die "can't open test register";
    while (my $line = <$fh>) {
	chomp($line);
	$line =~ s/#.*//;
	$line =~ s/\s+$//;
	next if !$line;
	last if $line eq "end";
	if ($line =~ s/^pass\t//) {
	    push @tests, $line;
	}
    }
    $fh->close();

    plan tests => 1 + scalar(@tests);
};

use Keystone::Resolver::Test;
ok(1); # If we made it this far, we're ok.

$ENV{KRuser} ||= "kr_read";
$ENV{KRpw} ||= "kr_read_3636";

foreach my $test (@tests) {
    my $status = Keystone::Resolver::Test::run_test({ xml => 1, nowarn => 1 },
						    "t/regression/$test", 1);
    if ($status == 1) {
	ok($status, 0, "generated XML did not match expected");
    } elsif ($status == 2) {
	ok($status, 0, "fatal error in resolver");
    } elsif ($status == 3) {
	ok($status, 0, "malformed test-case");
    } elsif ($status == 4) {
	ok($status, 0, "system error: $!");
    } else {
	ok($status, 0, "failed with status=$status");
    }
}
