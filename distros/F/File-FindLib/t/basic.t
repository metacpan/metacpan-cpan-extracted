#!/usr/bin/perl -w
use strict;
use File::Basename          qw< dirname >;
use File::Spec::Functions   qw< rel2abs >;
use lib dirname(__FILE__) . '/../inc';

use MyTest  qw< plan Okay SkipIf Lives Dies >;

BEGIN {
    plan(
        tests => 7,
        # todo => [ 2, 3 ],
    );

    require File::FindLib;
    Okay( 1, 1, 'Load module' );
}

Okay( !1, ! File::FindLib->import('t'), 'Import t should return true value' );
Okay( rel2abs(dirname(__FILE__)), $INC[0], 'Unshifted t dir onto @INC' );

Okay( !1, ! File::FindLib->import('t/FindMe.pm'),
    'Import FindMe should return true value' );
Okay( $FindMe::VERSION, $File::FindLib::VERSION, 'Found right FindMe' );
Okay( 1, require FindMe, 'require FindMe gives 1' );
{ no warnings 'once';
Okay( 1, $FindMe::loaded, 'FindMe loaded once' ); }
