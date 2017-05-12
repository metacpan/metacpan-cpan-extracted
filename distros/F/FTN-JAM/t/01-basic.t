#!/usr/bin/perl -T
#
# Test basic operations of FTN::JAM

use Test::More tests => 8;
use FTN::JAM;

use strict;
use warnings;

my $handle;

BEGIN {
    my $mb = 't/TEST1';
    my $basemsgnum = '1';

    $handle = FTN::JAM::CreateMB($mb,$basemsgnum);

    ok( defined $handle, 'Create MB' );

    my %baseheader;
    ok (FTN::JAM::ReadMBHeader($handle,\%baseheader), 'MB Header' );

    is( $baseheader{'BaseMsgNum'}, q{1}, 'MB BaseMsgNum' );
    is( $baseheader{'ActiveMsgs'}, q{0}, 'MB ActiveMsgs' );

    my $nummsgs;
    ok( FTN::JAM::GetMBSize($handle,\$nummsgs), 'MB Size' );
    is( $nummsgs, q{0}, 'Empty MB' );

    ok( FTN::JAM::CloseMB($handle), 'Close MB' );

    ok( FTN::JAM::RemoveMB('t/TEST1'), 'Remove MB' );
}

