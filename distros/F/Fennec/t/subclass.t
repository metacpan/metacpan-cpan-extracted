#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    package My::Fennec;
    $INC{'My/Fennec.pm'} = __FILE__;
    use base 'Fennec';
    
    sub after_import {
        my $class = shift;
        my ($info) = @_;
   
        # The first arg to add case should be an array matching the return of
        # caller. The idea is to give us the start and end line, as well as
        # file name where the case is defined. normally the exports from
        # Test::Workflow provide that for you, but at this low-level we need to
        # provide it ourselfs. Since we define the subs here, we give current
        # line/file. Use the importer for package name.
        $info->{layer}->add_case([$info->{importer}, __FILE__, __LINE__], case_a => sub { $main::CASE_A = 1 });
        $info->{layer}->add_case([$info->{importer}, __FILE__, __LINE__], case_b => sub { $main::CASE_B = 1 });
    }
}

use My::Fennec;

tests both_cases => sub {
    ok( $main::CASE_A || $main::CASE_B, "In a case" );
    ok( !($main::CASE_A && $main::CASE_B), "Not in both cases" );
};

done_testing;
