#!/usr/bin/perl

use strict;
use warnings;
use Libssh::Session qw(:all);

my $ssh_host = "127.0.0.1";
my $ssh_port = 22;
my $ssh_user = "root";
my $ssh_pass = "centreon";

my $session = Libssh::Session->new();
if ($session->options(host => $ssh_host, port => $ssh_port, user => $ssh_user) != SSH_OK) {
    print $session->error() . "\n";
    exit(1);
}

if ($session->connect() != SSH_OK) {
    print $session->error() . "\n";
    exit(1);
}

$session->auth_none(); # prerequisite for getting auth_list
unless ($session->auth_list() & SSH_AUTH_METHOD_INTERACTIVE) {
	print "SSH server doesn't support keyboard-interactive authentication.\n";
	exit(1);
}

my $ret = $session->auth_kbdint();
while ($ret == SSH_AUTH_INFO) {
	my $name        = $session->auth_kbdint_getname();
	my $instruction = $session->auth_kbdint_getinstruction();
	my $nprompts    = $session->auth_kbdint_getnprmopts();

	print "$name\n"        if (defined $name);
	print "$instruction\n" if (defined $instruction);

	for (my $i = 0; $i < $nprompts; $i++) {
		my $answer;
		my $prompt = $session->auth_kbdint_getprompt(index => $i);
		if ($prompt->{text} =~ /Password:/) {
			$answer = $ssh_pass;
		} else {
			print "$prompt " if ($prompt->{echo});
			chomp($answer = <STDIN>);
			$answer .= "\0";
		}
		if ($session->auth_kbdint_setanswer(index => $i, answer => $answer) < 0) {
			printf("setting answer issue: %s\n", $session->error());
			exit(1);
		}
	}
	$ret = $session->auth_kbdint();
}

if ($ret == SSH_AUTH_SUCCESS) {
	print "== authentification succeeded\n";
} else {
	my $error = $session->error();
	print "$error\n" if ($error);
	print "== failed to authenticate: rc = $ret\n";
	exit(1);
}

exit(0);
