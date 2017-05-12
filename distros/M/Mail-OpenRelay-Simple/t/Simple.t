use Test::More tests => 1;
BEGIN { use_ok('Mail::OpenRelay::Simple') };

my $host = "127.0.0.1";

my $scan = Mail::OpenRelay::Simple->new({
	host       => $host,
	timeout    => 5,
	from_email => "test\@foobar.com",
	rcpt_email => "test\@foobar.com",
	banner     => 0,
	debug      => 0
});

print "$host open relay\n" if $scan->check;

exit(0);
