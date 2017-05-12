use strict;
use Test::More tests => 12;

use FileHandle;
use HTML::XSSLint;

my $port = 8000 + int(rand(1000));
!system("$^X t/test-httpd.pl $port &") or die "Can't start httpd at $port";

sleep 1;			# wait for httpd startup
my $agent = HTML::XSSLint->new;

{
    my $result = $agent->audit("http://localhost:$port/secure");
    ok !$result->vulnerable, "not vulnerable";
}

{
    my @result = $agent->audit("http://localhost:$port/vulnerable");
    is scalar @result, 2, "2 forms";
    for my $result (@result) {
	ok $result->vulnerable, "is vulnerable";
	is $result->action, "http://localhost:$port/vulnerable-form";
	is_deeply [ sort $result->names ], [ qw(email name) ], "name & email";
	like $result->example, qr!name=%3Cs%3Etest%3C%2Fs%3E!;
	like $result->example, qr!email=%3Cs%3Etest%3C%2Fs%3E!;
    }
}

END {
    my $file = "t/test-httpd.pid";
    my $try;
    my $max = 10;
    while (-e $file && $try++ <= $max) {
	my $pid = do {
	    my $in = FileHandle->new($file);
	    <$in>;
	};
	kill 2 => $pid if $pid;
	sleep 1;
    }
    unlink $file if -e $file;
}

