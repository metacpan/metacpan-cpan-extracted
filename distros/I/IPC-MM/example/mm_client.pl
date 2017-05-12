#!/usr/bin/perl

use strict;
use Socket;

use vars qw(%handlers);

$| = 1;

sub handler_scalar_fetch
{
	my ($fh) = @_;
	send $fh, "scalar-fetch\n", 0;
	send $fh, "\n", 0;
}

sub handler_scalar_store
{
	my ($fh, $val) = @_;
	send $fh, "scalar-store\n", 0;
	send $fh, "val: $val\n", 0;
	send $fh, "\n", 0;
}

sub handler_btree_fetch
{
	my ($fh, $key) = @_;
	send $fh, "btree-fetch\n", 0;
	send $fh, "key: $key\n", 0;
	send $fh, "\n", 0;
}

sub handler_btree_store
{
	my ($fh, $key, $val) = @_;
	send $fh, "btree-store\n", 0;
	send $fh, "key: $key\n", 0;
	send $fh, "val: $val\n", 0;
	send $fh, "\n", 0;
}

sub handler_btree_delete
{
	my ($fh, $key) = @_;
	send $fh, "btree-delete\n", 0;
	send $fh, "key: $key\n", 0;
	send $fh, "\n", 0;
}

sub handler_btree_clear
{
	my ($fh) = @_;
	send $fh, "btree-clear\n", 0;
	send $fh, "\n", 0;
}

sub handler_btree_exists
{
	my ($fh, $key) = @_;
	send $fh, "btree-exists\n", 0;
	send $fh, "key: $key\n", 0;
	send $fh, "\n", 0;
}

sub handler_btree_print
{
	my ($fh) = @_;
	send $fh, "btree-print\n", 0;
	send $fh, "\n", 0;
}

sub handler_mm_info
{
	my ($fh) = @_;
	send $fh, "mm-info\n", 0;
	send $fh, "\n", 0;
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

sub help
{
	print <<EOF;
Usage: mm_client.pl <command> [arg...]

valid commands are:
  scalar-fetch
  scalar-store <val>
  btree-fetch <key>
  btree-store <key> <val>
  btree-delete <key>
  btree-clear
  btree-exists <key>
  btree-print
  mm-info
EOF
}

sub main
{
	my $command = shift;
	my $handler = $handlers{$command};
	if ($handler) {
		my $host = 'localhost';
		my $port = 4343;
		my $iaddr = inet_aton($host) || die "no host: $host";
		my $paddr = sockaddr_in($port, $iaddr);
		my $proto = getprotobyname('tcp');
		socket(SOCK, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
		connect(SOCK, $paddr) || die "connect: $!";
		&$handler(\*SOCK, @_);
		while (my $line = <SOCK>) {
			print $line;
		}
		close(SOCK);
	} else {
		&help;
	}
}

&main(@ARGV);

