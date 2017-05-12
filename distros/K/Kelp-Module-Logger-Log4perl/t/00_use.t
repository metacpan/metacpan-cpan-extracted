#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00_use.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl 00_use.t'
#   yakudza <twinhooker@gmail.com>     2016/11/13 20:17:45

#########################
use strict;
use warnings;
use Test::More;
use Kelp;
use Kelp::Test;
use Test::Output;
use Test::More;
use HTTP::Request::Common;

BEGIN {
    use_ok( 'Kelp::Module::Logger::Log4perl' );
    $ENV{KELP_REDEFINE} = 1;
}


#########################

my $standart_re = sub {
    my $test_type   = shift;
    my $standart_re = qr(DEBUG .* $test_type .*
                        ERROR .* $test_type .*
                        NOTICE .* $test_type .*
                        FATAL  .* $test_type .*
                        ALERT  .* $test_type .*
                        CRITICAL .* $test_type .*
                        OFF .*)msx;
    return $standart_re;
};

my $category_re = qr(ERROR .* category_selected .*
                     FATAL .* category_selected .*
                     ALERT .* category_selected .*
                     CRITICAL .* category_selected .*
                     OFF .*)msx;

for my $mode (qw(normal scalar_ref separate_file)) {
    stdout_like( sub { run_t( $mode ) }, $standart_re->( $mode ), "Output test $mode" );
}

stdout_like( sub { run_t( 'category_selected' ) }, $category_re, "Output test category_selected" );

done_testing;

sub run_t {
    my $test = shift;
    my $app  = Kelp->new(mode => $test);    
    
    can_ok $app, $_ for qw(error debug);
    
    my $t = Kelp::Test->new(app => $app);
    $app->add_route(
        '/log', sub {
            my $self = shift;
            $self->debug("Debug message with $test config.");
            $self->error("Error message with $test config.");

            $self->logger('notice', "Notice message with $test config.");

            $self->logger('fatal', "Fatal message with $test config.");
            $self->logger('alert', "Alert message with $test config.");
            $self->logger('critical', "Critical message with $test config.");
            $self->logger('always', "Always message with $test config.");
            "ok";
        }
    );
    $t->request(GET '/log')->code_is(200);
}

