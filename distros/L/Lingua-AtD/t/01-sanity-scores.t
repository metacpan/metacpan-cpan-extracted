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
<scores>
  <metric>
    <type>spell</type>
    <key>hyphenate</key>
    <value>1</value>
  </metric>
  <metric>
    <type>spell</type>
    <key>misused words</key>
    <value>4</value>
  </metric>
  <metric>
    <type>spell</type>
    <key>raw</key>
    <value>28</value>
  </metric>
  <metric>
    <type>stats</type>
    <key>sentences</key>
    <value>351</value>
  </metric>
  <metric>
    <type>stats</type>
    <key>words</key>
    <value>4683</value>
  </metric>
  <metric>
    <type>stats</type>
    <key>bias language</key>
    <value>1</value>
  </metric>
  <metric>
    <type>style</type>
    <key>complex phrases</key>
    <value>7</value>
  </metric>
  <metric>
    <type>style</type>
    <key>hidden verbs</key>
    <value>1</value>
  </metric>
  <metric>
    <type>style</type>
    <key>passive voice</key>
    <value>7</value>
  </metric>
</scores>';

my $xml_exception = '<?xml version="1.0"?>
<results>
  <message>This is a description of what went wrong</message>
</results>';

use_ok('Lingua::AtD::Scores');
my $atd_results = Lingua::AtD::Scores->new( { xml => $xml_good } );
isa_ok( $atd_results, 'Lingua::AtD::Scores' );
is( $atd_results->get_xml(), $xml_good, ' get_xml() [good]' );
is( $atd_results->has_server_exception(), 0,
    ' has_service_exception() [good]' );
is( $atd_results->get_server_exception(),
    undef, ' get_service_exception() [good]' );
is( $atd_results->has_metrics(), 1, ' has_metrics() [good]' );
is( $atd_results->get_metrics(), 9, ' get_metrics() [good]' );

# Exceptions removed for now.
#throws_ok(
#    sub { Lingua::AtD::Scores->new( { xml => $xml_exception } ) },
#    'Lingua::AtD::ServiceException',
#    'Service Exception thrown'
#);
#my $atd_exception = Exception::Class->caught('Lingua::AtD::ServiceException');
#isa_ok( $atd_exception, 'Lingua::AtD::ServiceException' );
#is(
#    $atd_exception->description,
#    'Indicates the AtD service returned an error message.',
#    'description() [exception]'
#);
#is(
#    $atd_exception->service_message,
#    'This is a description of what went wrong',
#    'service_message() [exception]'
#);

done_testing;
