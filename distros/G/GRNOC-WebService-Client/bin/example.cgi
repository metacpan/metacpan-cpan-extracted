#!/usr/bin/perl
use strict;
use GRNOC::WebService;

use strict;
use GRNOC::WebService;
use JSON;
use Data::Dumper;

#----- callback
sub number_echo{
        my $mthod_obj = shift;
        my $params    = shift;

        my %results;

        ok ( defined $params->{'number'},'callback gets expected param');

        $results{'text'} = "input text: ".$params->{'number'}{'value'};

        #--- as number is the only input parameter, lets make sure others dont get past.
        ok( ! defined $params->{'foobar'}, 'callback does not get unexpected param');
        return \%results;
}


#------ wrap callback in service method object
my $method = GRNOC::WebService::Method->new(
                                                name            => "number_echo",
                                                description     => "descr",
                                                callback        => \&number_echo
                                                );

#------- define the parameters we will allow into this callback
$method->add_input_parameter(
                                name            => 'number',
                                pattern         => '^(\d+)$',
                                required        => 1,
                                description     => "integer input"
                        );



#------- create Dispatcher
my $svc = GRNOC::WebService::Dispatcher->new(
                                );

#------- bind our method
my $res = $svc->register_method($method);

#------- go to town
my $res2  = $svc->handle_request();

