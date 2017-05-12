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

plan tests => 7;

my $xml_good = '<?xml version="1.0"?>
<results>
  <error>
    <string>to be</string>
    <description>Passive voice</description>
    <precontext>want</precontext>
    <type>grammar</type>
    <url>http://service.afterthedeadline.com/info.slp?text=to+be</url>
  </error>
  <error>
    <string>wether</string>
    <description>Did you mean...</description>
    <precontext>determine</precontext>
    <suggestions>
        <option>whether</option>
        <option>weather</option>
    </suggestions>
    <type>spelling</type>
    <url>http://service.afterthedeadline.com/info.slp?text=wether</url>
  </error>
</results>';

my $xml_exception = '<?xml version="1.0"?>
<results>
  <message>This is a description of what went wrong</message>
</results>';

use_ok('Lingua::AtD::Results');
my $atd_results = Lingua::AtD::Results->new( { xml => $xml_good } );
isa_ok( $atd_results, 'Lingua::AtD::Results' );
is( $atd_results->get_xml(), $xml_good, ' get_xml() [good]' );
is( $atd_results->has_server_exception(), 0,
    ' has_service_exception() [good]' );
is( $atd_results->get_server_exception(),
    undef, ' get_service_exception() [good]' );
is( $atd_results->has_errors(), 1, ' has_errors() [good]' );
is( $atd_results->get_errors(), 2, ' get_errors() [good]' );

# Exceptions removed for now.
#throws_ok(
#    sub { Lingua::AtD::Results->new( { xml => $xml_exception } ) },
#    'Lingua::AtD::ServiceException',
#    'Service Exception thrown'
#);

#my $atd_exception = Exception::Class->caught('Lingua::AtD::ServiceException');
#isa_ok( $atd_exception, 'Lingua::AtD::ServiceException' );
#is(
#    $atd_exception->description(),
#    'Indicates the AtD service returned an error message.',
#    'description() [exception]'
#);
#is(
#    $atd_exception->service_message(),
#    'This is a description of what went wrong',
#    'service_message() [exception]'
#);

done_testing;
