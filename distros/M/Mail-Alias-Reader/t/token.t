# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Test::More ( 'tests' => 77 );

use Mail::Alias::Reader::Token ();

my %TESTS = (
    '#foo' => {
        'is_value'     => 0,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'value'        => 'foo',
        'to_string'    => '# foo'
    },

    '"/Mail Spools/foo\0173bar\0175/Test \x2b 123"' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 1,
        'value'        => '/Mail Spools/foo{bar}/Test + 123',
        'to_string'    => '"/Mail Spools/foo{bar}/Test + 123"'
    },

    ',' => {
        'is_value'     => 0,
        'is_punct'     => 1,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ','
    },

    ':' => {
        'is_value'     => 0,
        'is_punct'     => 1,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ':'
    },

    '   ' => {
        'is_value'     => 0,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ' '
    },

    ':fail:' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 1,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ':fail:',
        'value'        => ''
      },

    ':test:/value' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 1,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ':test:/value',
        'value'        => '/value'
    },

    '/foo/bar/baz' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 1,
        'to_string'    => '/foo/bar/baz',
        'value'        => '/foo/bar/baz'
    },

    '|foo' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 1,
        'is_file'      => 0,
        'to_string'    => '|foo',
        'value'        => 'foo'
    },

    '"|append \"\r\n\t\""' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 1,
        'is_file'      => 0,
        'to_string'    => '"|append \"\r\n\t\""',
        'value'        => qq(append "\r\n\t")
    }
);

foreach my $test ( keys %TESTS ) {
    my $checks = $TESTS{$test};
    my $token  = Mail::Alias::Reader::Token->tokenize($test)->[1];

    foreach my $method ( keys %{$checks} ) {
        my $expected = $checks->{$method};

        is( $token->$method(), $expected, qq(Mail::Alias::Reader::Token->$method() for "$test" is $expected) );
    }
}
