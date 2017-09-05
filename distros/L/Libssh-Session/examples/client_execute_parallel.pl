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

sub my_callback {
    my (%options) = @_;
    
    print "================================================\n";
    print "=== exit = " . $options{exit} . "\n";
    if ($options{exit} == SSH_OK || $options{exit} == SSH_AGAIN) { # AGAIN means timeout
        print "=== exit_code = " . $options{exit_code} . "\n";
        print "=== userdata = " . $options{userdata} . "\n";
        print "=== stdout = " . $options{stdout} . "\n";
        print "=== stderr = " . $options{stderr} . "\n";
    } else {
        printf("error: %s\n", $session->error(GetErrorSession => 1));
    }
    print "================================================\n";
    
    #$options{session}->add_command(command => { cmd => 'ls -l', callback => \&my_callback, userdata => 'cmd 3'});
}

$session->execute(commands => [ 
                    { cmd => 'ls -l', callback => \&my_callback, userdata => 'cmd ok'},
                    { cmd => 'ls wanterrormsg', callback => \&my_callback, userdata => 'cmd stderr'},
                    { cmd => 'ls -l; sleep 20; ls -l; sleep 20;', callback => \&my_callback, userdata => 'cmd timeout'},
                    { cmd => 'sleep 40', callback => \&my_callback, userdata => 'cmd timeout no data'},
                  ],
                  timeout => 20, timeout_nodata => 10, parallel => 4);

exit(0);