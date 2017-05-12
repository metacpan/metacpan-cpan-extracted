#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use Libssh::Session qw(:all);
use Libssh::Event;

my $ssh_host = "127.0.0.1";
my $ssh_port = 22;
my $ssh_user = "root";
my $ssh_pass_wrong = "foo";
my $ssh_pass_good = "centreon";

my $session = Libssh::Session->new();
if (!$session->options(host => $ssh_host, port => $ssh_port, user => $ssh_user)) {
    print $session->error() . "\n";
    exit(1);
}

if ($session->connect() != SSH_OK) {
    print $session->error() . "\n";
    exit(1);
}

# wrong password
#if ($session->auth_password(password => $ssh_pass_wrong) != SSH_AUTH_SUCCESS) {
#    printf("auth issue: %s\n", $session->error(GetErrorSession => 1));
#}
if ($session->auth_publickey_auto() != SSH_AUTH_SUCCESS) {
    printf("auth issue pubkey: %s\n", $session->error(GetErrorSession => 1));
    if ($session->auth_password(password => $ssh_pass_good) != SSH_AUTH_SUCCESS) {
        printf("auth issue: %s\n", $session->error(GetErrorSession => 1));
        exit(1);
    }
    exit(1);
}

print "== authentification succeeded\n";

my $banner = $session->get_issue_banner();
printf("== server banner: %s\n", defined($banner) ? $banner : '-');

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
                    { cmd => 'ls -l', callback => \&my_callback, userdata => 'cmd 1'},
                    { cmd => 'ls pokdpsqkodsq', callback => \&my_callback, userdata => 'cmd 2 error'},
                    { cmd => 'ls -l', callback => \&my_callback, userdata => 'cmd 3'},
                    { cmd => 'ls -l', callback => \&my_callback, userdata => 'cmd 4'},
                    { cmd => 'ls -l', callback => \&my_callback, userdata => 'cmd 5'},
                    { cmd => 'ls -l', callback => \&my_callback, userdata => 'cmd 6'},
                    { cmd => 'ls -l; sleep 20; ls -l; sleep 20; ls -l; sleep 20; ', callback => \&my_callback, userdata => 'cmd timeout'},
                    { cmd => 'sleep 40', callback => \&my_callback, userdata => 'cmd timeout no data'},
                  ],
                  timeout => 60, timeout_nodata => 30, parallel => 4);

print Data::Dumper::Dumper($session->execute_simple(cmd => 'ls', timeout => 60, timeout_nodata => 30));
                  
# Test event
#my $event = Libssh::Event->new();
#$event->add_session(session => $session);
#$event->add_channel_exit_status_callback(channel => $session->get_channel(channel_id => $channel_id));

#do {
#    printf("dopoll ret value = %s\n", $event->dopoll(timeout => 30000));
#} while (!$session->is_closed_channel(channel_id => $channel_id));

exit(0);
