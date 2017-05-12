#!/usr/bin/perl

use strict;
use Socket;
use Carp;
use IPC::MM qw(
	mm_create
	mm_make_scalar
	mm_make_btree_table
	mm_display_info
	mm_error
);

use vars qw(%handlers);

$| = 1;

sub error
{
	print "@_: ", mm_error(), "\n";
	exit 1;
}

sub logmsg
{
	print "$0 $$: @_ at ", scalar localtime, "\n";
}

sub reaper
{
	my $pid = wait;
	$SIG{CHLD} = \&reaper;
	logmsg "reaped $pid" . ($? ? " with exit $?" : '');
}

sub handler_scalar_fetch
{
	my ($mm, $scalar, $btree, $input) = @_;
	print Client "contents of scalar: '$$scalar'\n";
}

sub handler_scalar_store
{
	my ($mm, $scalar, $btree, $input) = @_;
	$$scalar = $input->{val};
	print Client "new contents of scalar: '$$scalar'\n";
}

sub handler_btree_fetch
{
	my ($mm, $scalar, $btree, $input) = @_;
	my $key = $input->{key};
	print Client "contents of btree: key '$key' val '$btree->{$key}'\n";
}

sub handler_btree_store
{
	my ($mm, $scalar, $btree, $input) = @_;
	my $key = $input->{key};
	$btree->{$key} = $input->{val};
	print Client "new contents of btree: key '$key' val '$btree->{$key}'\n";
}

sub handler_btree_delete
{
	my ($mm, $scalar, $btree, $input) = @_;
	my $key = $input->{key};
	my $val = delete $btree->{$key};
	print Client "delete key $key returned '$val'\n";
}

sub handler_btree_clear
{
	my ($mm, $scalar, $btree, $input) = @_;
	%$btree = ();
	print Client "btree cleared\n";
}

sub handler_btree_exists
{
	my ($mm, $scalar, $btree, $input) = @_;
	my $key = $input->{key};
	my $val = exists $btree->{$key};
	print Client "exists key $key returned '$val'\n";
}

sub handler_btree_print
{
	my ($mm, $scalar, $btree, $input) = @_;
	print Client "contents of btree\n";
	while (my ($key, $val) = each %$btree) {
		print Client "key '$key' val '$val'\n";
	}
}

sub handler_mm_info
{
	my ($mm, $scalar, $btree, $input) = @_;
	open(STDERR, ">&Client") || die "can't dup client to stdout";
	print Client mm_display_info($mm);
}

%handlers = (
	'scalar-fetch' => \&handler_scalar_fetch,
	'scalar-store' => \&handler_scalar_store,
	'btree-fetch' => \&handler_btree_fetch,
	'btree-store' => \&handler_btree_store,
	'btree-delete' => \&handler_btree_delete,
	'btree-clear' => \&handler_btree_clear,
	'btree-exists' => \&handler_btree_exists,
	'btree-print' => \&handler_btree_print,
	'mm-info' => \&handler_mm_info
);

sub input
{
	my ($fh) = @_;
	my %data = ();
	while (my $line = <$fh>) {
		$line =~ s/[\r\n]//g;
		last if not $line;
		if (not %data) {
			$data{first_line} = $line;
		} elsif ($line =~ m/^(.+):\s*(.*)$/) {
			$data{$1} = $2;
		}
	}
	return(\%data);
}

sub spawn
{
	my ($mm, $scalar, $btree) = @_;
	my $pid;
	if (!defined($pid = fork)) {
		logmsg "cannot fork: $!";
		return;
	} elsif ($pid) {
		# parent
		logmsg "begat $pid";
		return;
	}
	$| = 1;
	my $input = &input(\*Client);
	my $cmd = $input->{first_line};
	my $handler = $handlers{$cmd};
	if ($handler) {
		&$handler($mm, $scalar, $btree, $input);
	} else {
		print Client "invalid command\n";
	}
	exit 0;
}

sub main
{
	my $port = shift || 4343;

	my $mm = mm_create(65536, 'mm_file') or error("mm_create");
	my $scalar = mm_make_scalar($mm) or error("mm_make_scalar");
	my $btree = mm_make_btree_table($mm) or error("mm_make_btree_table");

	my $tie_scalar;
	tie $tie_scalar, 'IPC::MM::Scalar', $scalar;
	my %tie_btree;
	tie %tie_btree, 'IPC::MM::BTree', $btree;

	my $proto = getprotobyname('tcp');
	socket(Server, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
	setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) || die "setsockopt: $!";
	bind(Server, sockaddr_in($port, INADDR_ANY)) || die "bind: $!";
	listen(Server, SOMAXCONN) || die "listen: $!";
	logmsg "server started on port $port";

	$SIG{CHLD} = \&reaper;

	for(;;) {
		my $paddr = accept(Client, Server);
		next if not $paddr;
		my ($port, $iaddr) = sockaddr_in($paddr);
		my $name = gethostbyaddr($iaddr, AF_INET);
		logmsg "connection from $name [", inet_ntoa($iaddr), "] at port $port";
		&spawn($mm, \$tie_scalar, \%tie_btree);
		close Client;
	}
}

&main(@ARGV);

