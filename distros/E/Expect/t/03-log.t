use strict;
use warnings;

use Test::More tests => 11;
use File::Temp qw(tempdir);
use Expect;

my $tempdir = tempdir( CLEANUP => 1 );
my $logfile = "$tempdir/expect_output_file";

my $e = Expect->new;
$e->raw_pty(1);
$e->log_stdout(0);
$e->spawn($^X . q{ -ne 'sleep 1; chomp; print scalar reverse; print "\n"' });

my @reply;

diag "Test created for https://rt.cpan.org/Ticket/Display.html?id=62359 related to clear_accum";

{
	$e->send("abc\n");
	$e->expect(3, [qr/cba/ => sub { push @reply, 'cba' } ]);
}

{
	$e->log_file($logfile, "w");
	$e->send("hello\n");
	$e->expect(3, [qr/olleh/ => sub { push @reply, 'olleh' } ]);

	my $log_before = slurp($logfile);
	is $log_before, "olleh\n", 'logfile';  # I am not sure if we can really expect this to be already written (buffering?)

	$e->log_file(undef);
	my $log = slurp($logfile);
	is $log, "olleh\n", 'logfile';
}

{
	$e->send("world\n");
	$e->expect(3, [qr/dlrow/ => sub { push @reply, 'dlrow' } ]);
	#$e->log_file(undef);
	my $log = slurp($logfile);
	is $log, "olleh\n", 'logfile';
}

{
	$e->log_file($logfile, "w");
	$e->send("zorg\n");
	$e->expect(3, [qr/groz/ => sub { push @reply, 'groz' } ]);

	$e->log_file(undef);
	my $log = slurp($logfile);
	is $log, "groz\n", 'logfile';
}

# code example from https://rt.cpan.org/Ticket/Display.html?id=62359
{
	$e->send("first\n");
	is $e->clear_accum(), "\n", 'nothing to clear yet';
	$e->log_file(undef);
	$e->log_file($logfile, "w");
	$e->send("second\n");
	$e->expect(3, "other");
	my $log = slurp($logfile);
	is $log, "tsrif\ndnoces\n", 'logfile';
}

# accum will only have data *after* we called ->expect.
{
	$e->send("one\n");
	$e->expect(2, "other");  # added call - wait 2
	is $e->clear_accum(), "tsrif\ndnoces\neno\n";
	$e->log_file(undef);
	$e->log_file($logfile, "w");
	$e->send("two\n");
	$e->expect(3, "other");
	my $log = slurp($logfile);
	is $log, "owt\n", 'logfile';
}

# but even calling ->expect is not enough. Stuff the AUT sends after
# that first call to ->expect times out will not be in the accumulator
# and thus clear_accum wont remove it.
{
	$e->send("first\n");
	$e->expect(0, "other");  # added call wait 0
	is $e->clear_accum(), "owt\n"; # from the previous block
	$e->log_file(undef);
	$e->log_file($logfile, "w");
	$e->send("second\n");
	$e->expect(3, "other");
	my $log = slurp($logfile);
	is $log, "tsrif\ndnoces\n", 'logfile';
}


is_deeply \@reply, ['cba', 'olleh', 'dlrow', 'groz'], 'reply';


sub slurp {
	my ($filename) = @_;
	open my $fh, '<', $filename or die;
	local $/;
	return scalar <$fh>;
}

