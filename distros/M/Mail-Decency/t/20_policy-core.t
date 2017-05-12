#!/usr/bin/perl

use strict;
use Test::More tests => 10;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use MIME::QuotedPrint;

BEGIN {
    use_ok( "Mail::Decency::Policy" ) or die;
}
use TestPolicy;
use TestMisc;

my $policy;

CREATE_POLICY: {
    eval {
        $policy = TestPolicy::create();
    };
    ok( !$@ && $policy, "Policy lodaded" ) or die( "Problem: $@" );
}


CHECK_THROW_REJECT: {
    TestPolicy::session_init( $policy );
    eval {
        $policy->go_final_state( Dummy => 'REJECT' );
    };
    ok_for_reject( $policy, $@, "Reject throws error" );
}


CHECK_THROW_OK: {
    TestPolicy::session_init( $policy );
    eval {
        $policy->go_final_state( Dummy => 'OK' );
    };
    ok_for_ok( $policy, $@, "OK throws error" );
}


CHECK_PASSING: {
    TestPolicy::session_init( $policy );
    eval {
        $policy->go_final_state( Dummy => 'DUNNO' );
    };
    ok_for_dunno( $policy, $@, "Dunno passes" );
}


CHECK_FINAL: {
    TestPolicy::session_init( $policy );
    eval {
        $policy->add_response_message( "THE REASON 123" );
        $policy->go_final_state( Dummy => 'REJECT' );
    };
    my $res = decode_qp( $policy->session_cleanup );
    ok( $res eq "REJECT THE REASON 123", "Response message injection" );
}


CHECK_PREPEND_BUILDING: {
    TestPolicy::session_init( $policy );
    $policy->add_spam_score( M1 => 123 );
    $policy->add_spam_score( M2 => -23 );
    $policy->session_data->set_flag( 'test' );
    $policy->session_data->set_flag( 'xxx' );
    my $res = decode_qp( $policy->session_cleanup );
    my @res = split( /\|/, $res );
    ok( $res[0] =~ /^PREPEND X-Decency-Instance/, "Prepend generated" );
    ok( $res[2] eq '100', "Weighting appended" );
    ok( $res[4] eq 'test,xxx', "Flag appended" );
    ok( $res[5] eq 'Module: M1; Score: 123' && $res[6] eq 'Module: M2; Score: -23', "Info appended" );
}



TestMisc::cleanup( $policy );
