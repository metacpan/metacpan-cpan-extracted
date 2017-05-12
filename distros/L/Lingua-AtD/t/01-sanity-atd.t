#!/usr/bin/perl -w
#
# This file is part of Lingua-AtD
#
# This software is copyright (c) 2011 by David L. Day.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::More;
use Test::Exception;

plan tests => 13;

use_ok('Lingua::AtD');
my $atd              = Lingua::AtD->new();
my $default_throttle = $atd->get_throttle();

isa_ok( $atd, 'Lingua::AtD' );
is(
    $atd->get_service_host(),
    'service.afterthedeadline.com',
    ' get_service_host()'
);
is( $atd->get_service_port(), 80, ' get_service_port()' );
is(
    $atd->get_service_url(),
    'http://service.afterthedeadline.com:80/',
    ' get_service_url()'
);
is( $atd->get_throttle(),   $default_throttle, ' get_throttle()' );
is( $atd->set_throttle(10), $default_throttle, ' set_throttle()' );
is( $atd->set_throttle($default_throttle), 10, ' set_throttle()' );

my $atd_bogus = Lingua::AtD->new( { host => '500.500.500', port => 200200 } );
isa_ok( $atd_bogus, 'Lingua::AtD' );
is( $atd_bogus->get_service_host(),
    '500.500.500', ' get_service_host() [bogus]' );
is( $atd_bogus->get_service_port(), 200200, ' get_service_port() [bogus]' );
is( $atd_bogus->get_service_url(),
    'http://500.500.500:200200/', ' get_service_url() [bogus]' );
is( $atd_bogus->get_throttle(), $default_throttle, ' get_throttle()' );

# Exceptions removed for now.
#throws_ok( sub { $atd_bogus->stats('should throw an exception') },
#    'Lingua::AtD::HTTPException', 'HTTP Exception thrown' );
#my $atd_exception = Exception::Class->caught('Lingua::AtD::HTTPException');
#isa_ok( $atd_exception, 'Lingua::AtD::HTTPException' );
#is(
#    $atd_exception->description(),
#    'Indicates a problem connecting to the AtD service.',
#    'description() [exception]'
#);
#like(
#    $atd_exception->http_status(),
#    qr/^500 Can't connect to 500.500.500:200200/,
#    'http_status() [exception]'
#);
#is(
#    $atd_exception->service_url(),
#    'http://500.500.500:200200/stats',
#    'service_url() [exception]'
#);

done_testing;
