#!/usr/bin/perl

# A protected test webservice. The conf file should have this protected by the auth_file file in the same directory.
# The username is "dummy" and the password is "banana"

use strict;
use warnings;

use GRNOC::WebService::Dispatcher;
use GRNOC::WebService::Method;

my $web_svc = GRNOC::WebService::Dispatcher->new();

sub test{
    my $method    = shift;
    my $p_ref     = shift;
    my $state_ref = shift;

    return {'results' => {'success' => 1}};
}


my $test_meth = GRNOC::WebService::Method->new(
					       name           => 'test',
					       description    => 'test webservice',
					       expires        => "-1d",
					       callback       =>  \&test,
					     );


$web_svc->register_method($test_meth);


my $status = $web_svc->handle_request();
