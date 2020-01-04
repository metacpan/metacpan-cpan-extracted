#!/usr/bin/env perl
use strict;
use warnings;
our $VERSION = 0.001_000;

use Test::More tests => 8;
use Test::Exception;

BEGIN {
    if ( $ENV{RPERL_VERBOSE} ) {
        diag("[[[ Beginning Dependency Tests ]]]");
    }
}

BEGIN {
    lives_and( sub { use_ok('ExtUtils::MakeMaker'); }, q{use_ok('ExtUtils::MakeMaker') lives} );
}
lives_and( sub { require_ok('ExtUtils::MakeMaker'); }, q{require_ok('ExtUtils::MakeMaker') lives} );

BEGIN {
    lives_and( sub { use_ok('Test::Exception'); }, q{use_ok('Test::Exception') lives} );
}
lives_and( sub { require_ok('Test::Exception'); }, q{require_ok('Test::Exception') lives} );

BEGIN {
    lives_and( sub { use_ok('Test::CPAN::Changes'); }, q{use_ok('Test::CPAN::Changes') lives} );
}
lives_and( sub { require_ok('Test::CPAN::Changes'); }, q{require_ok('Test::CPAN::Changes') lives} );

BEGIN {
    lives_and( sub { use_ok('RPerl'); }, q{use_ok('RPerl') lives} );
}
lives_and( sub { require_ok('RPerl'); }, q{require_ok('RPerl') lives} );

done_testing();
