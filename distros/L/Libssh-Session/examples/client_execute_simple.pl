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

if ($session->auth_publickey_auto() != SSH_AUTH_SUCCESS) {
    printf("auth issue pubkey: %s\n", $session->error(GetErrorSession => 1));
    if ($session->auth_password(password => $ssh_pass) != SSH_AUTH_SUCCESS) {
        printf("auth issue: %s\n", $session->error(GetErrorSession => 1));
        exit(1);
    }
}

print "== authentification succeeded\n";

my $ret = $session->execute_simple(cmd => 'ls', timeout => 60, timeout_nodata => 30);
# Example with input
#my $ret = $session->execute_simple(cmd => 'cat -n > /tmp/test_input.txt', input_data => 'YES!!!', timeout => 60, timeout_nodata => 30);

print "================================================\n";
print "=== exit = " . $ret->{exit} . "\n";
if ($ret->{exit} == SSH_OK || $ret->{exit} == SSH_AGAIN) { # AGAIN means timeout
    print "=== exit_code = " . $ret->{exit_code} . "\n";
    print "=== userdata = " . $ret->{userdata} . "\n";
    print "=== stdout = " . $ret->{stdout} . "\n";
    print "=== stderr = " . $ret->{stderr} . "\n";
} else {
    printf("error: %s\n", $ret->{session}->error(GetErrorSession => 1));
}
print "================================================\n";

exit(0);
