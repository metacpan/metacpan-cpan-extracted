#!/usr/bin/perl

use strict;
use warnings;
use Libssh::Session qw(:all);
use Libssh::Sftp qw(:all);
use Data::Dumper;

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

# sftp session
my $sftp = Libssh::Sftp->new(session => $session);
if (!defined($sftp)) {
    print Libssh::Sftp::error() . "\n";
    exit(1);
}
my $result = $sftp->list_dir(dir => '.');
if ($result->{code} == SSH_ERROR) {
    print $sftp->error() . "\n";
} else {
    print Data::Dumper::Dumper($result);
}

exit(0);
