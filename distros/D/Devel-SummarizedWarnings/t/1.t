# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More tests => 4;
BEGIN { use_ok('Devel::SummarizedWarnings') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

delete $SIG{'__WARN__'};
Devel::SummarizedWarnings::install_handler();
ok( $SIG{'__WARN__'}, 'SIGWARN is trapped' );
ok( $SIG{'__WARN__'} == $Devel::SummarizedWarnings::INSTALLED_HANDLER,
    'SIGWARN is trapped by D::SW' );

warn 'foo';
ok( pop(@Devel::SummarizedWarnings::LOGGED_WARNINGS) =~ /^foo /,
    'string saved' );