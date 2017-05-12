#!/usr/bin/env perl

# Creation date: 2007-05-11 07:43:10
# Authors: don

use strict;
use Test;

# main
{
    use JSON::DWIW;

    my $tests = [ [ 0xe9, "\xc3\xa9" ],       # LATIN SMALL LETTER E WITH ACUTE
                  [ 0xe8, "\xc3\xa8" ],       # LATIN SMALL LETTER E WITH GRAVE
                  [ 0x1ec7, "\xe1\xbb\x87" ], # LATIN SMALL LETTER E WITH CIRCUMFLEX AND DOT BELOW
                  [ 0x4e2d, "\xe4\xb8\xad" ], # ZHONG1 (Chinese zhong1)
                ];

    plan tests => 10 + scalar(@$tests);
    
    ok(JSON::DWIW->is_valid_utf8("\x{706b}"));

    ok(not JSON::DWIW->is_valid_utf8("\xe9s"));

    my $str = "";
    ok(not JSON::DWIW->flagged_as_utf8($str));

    JSON::DWIW->flag_as_utf8($str);
    ok(JSON::DWIW->flagged_as_utf8($str));
    
    JSON::DWIW->unflag_as_utf8($str);
    ok(not JSON::DWIW->flagged_as_utf8($str));

    my $str1 = "blah";
    my $str2 = "caf\xe9";

    ok(JSON::DWIW->is_valid_utf8($str1));
    ok(not JSON::DWIW->is_valid_utf8($str2));

    JSON::DWIW->upgrade_to_utf8($str2);
    
    ok(JSON::DWIW->is_valid_utf8($str2));
    ok(JSON::DWIW->flagged_as_utf8($str2));

#     JSON::DWIW->upgrade_to_utf8($str1);
#     ok(JSON::DWIW->flagged_as_utf8($str1));
#     ok(JSON::DWIW->is_valid_utf8($str1));


    # Test utf8 sequences in hash keys.  In Perl 5.8, a utf8 key
    # that can be represented in latin1 will get converted to
    # latin1 at the C layer, breaking things if it is not checked
    # explicitly
    my $utf8_str = "\xc3\xa4";
    JSON::DWIW->flag_as_utf8($str);
    my %hash;
    $hash{$utf8_str} = 'blah';
    my ($json_str, $error) = JSON::DWIW->to_json(\%hash);
    ok(not $error);

    foreach my $test (@$tests) {
        $str = JSON::DWIW->code_point_to_utf8_str($test->[0]); # should be "\xc3\xa9"
        {
            use bytes;
            ok($str eq $test->[1]);
        }
    }
        
}

exit 0;

###############################################################################
# Subroutines

