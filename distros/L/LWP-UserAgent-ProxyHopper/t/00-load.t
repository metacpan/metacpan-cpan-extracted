#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
my $Test_URI = 'http://www.zoffix.com/new/lwp_ua_proxify_test.html';
BEGIN {
    use_ok('LWP::UserAgent');
    use_ok('LWP::UserAgent::ProxyHopper::Base');
	use_ok('LWP::UserAgent::ProxyHopper');
}

diag( "Testing LWP::UserAgent::ProxyHopper $LWP::UserAgent::ProxyHopper::VERSION, Perl $], $^X" );

my $o = LWP::UserAgent::ProxyHopper->new(
    timeout => 10,
    agent   => 'LWP_USER_AGENT_PROXIFY_TESTER',
);
isa_ok($o, 'LWP::UserAgent::ProxyHopper');
can_ok($o, qw(
    proxify_load
        proxify_list
    proxify_bad_list
    proxify_real_bad_list
    proxify_working_list
    proxify_schemes
    proxify_retries
    proxify_debug
    proxify_current
    _proxify_last_load_args
    _proxify_freeproxylists_obj
    _proxify_proxy4free_obj
    _proxify_try_request
    _proxify_set_proxy
    proxify_get
    proxify_post
    proxify_request
    proxify_head
    proxify_mirror
    proxify_simple_request
    get
    request
    head
    simple_request
));


exit unless -e 'lwp_ua_proxify_do_thorough_testing';

diag qq|\n\n\nNote: You will see a lot of "Failed blah blah" messages|
        . qq| disregard them as they appear so I would have some|
        . qq| extra data to evaluate in order to make the module|
        . qq| better and faster. Thank you.\n\n\n|;

sleep 3;

diag "\nproxify_load() start " . localtime() . "\n";
$o->proxify_load( proxy4free => 1, retries => 20, debug => 1 );
diag "\nproxify_load() end " . localtime() . "\n";

for ( 1..5 ) {
    diag "\nITER: $_ proxify_get() start" . localtime() . "\n";
    my $response = $o->proxify_get($Test_URI);
    diag "\nITER: $_ proxify_get() end" . localtime() . "\n";
    if ( $response->is_success ) {
        if ( $response->content =~ /^test success$/ ) {
            diag "\nSUCCESS!\n";
        }
        else {
            diag "FAILED CONTENT TEST:\n" . $response->content . "\n##END\n";
        }
    }
    else {
        diag "Got network error: " . $response->status_line;
    }
}

diag "\nproxify_post() start" . localtime() . "\n";
my $response = $o->proxify_post($Test_URI);
diag "\nproxify_post() end" . localtime() . "\n";
if ( $response->is_success ) {
    if ( $response->content =~ /^test success$/ ) {
        diag "\nSUCCESS!\n";
    }
    else {
        diag "FAILED CONTENT TEST:\n" . $response->content . "\n##END\n";
    }
}
else {
    diag "Got network error: " . $response->status_line;
}
