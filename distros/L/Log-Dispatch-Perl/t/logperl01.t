
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 5 + (2*2) + (2*2) + (2*2) + (2*2);
use strict;
use warnings;

use_ok( 'Log::Dispatch::Perl' );
can_ok( 'Log::Dispatch::Perl',qw(
 new
 log_message
) );

my $dispatcher = Log::Dispatch->new;
isa_ok( $dispatcher,'Log::Dispatch' );

my $channel = Log::Dispatch::Perl->new( qw(name default min_level debug) );
isa_ok( $channel,'Log::Dispatch::Perl' );

$dispatcher->add( $channel );
is( $dispatcher->output( 'default' ),$channel,'Check if channel activated' );

my $warn;
$SIG{__WARN__} = sub { $warn .= "@_" };

foreach my $method (qw(debug info)) {
    $warn = '';
    eval { $dispatcher->$method( "This is a '$method' action" ) };
    ok( !$@,"Check if no error in eval for '$method': $@" );
    ok( !$warn,"Check if no warning occurred: $warn" );
}

foreach my $method (qw(notice warning)) {
    $warn = '';
    eval { $dispatcher->$method( "This is a '$method' action" ) };
    ok( !$@,"Check if no error in eval for '$method': $@" );
    is( $warn,"This is a '$method' action\n","Check if warning occurred" );
}

foreach my $method (qw(error critical)) {
    $warn = '';
    eval { $dispatcher->$method( "This is a '$method' action" ) };
    is( $@,"This is a '$method' action\n",
     "Check if no error in eval for '$method'" );
    ok( !$warn,"Check if no warning occurred: $warn" )
}

foreach my $method (qw(alert emergency)) {
    $warn = '';
    eval { $dispatcher->$method( "This is a '$method' action" ) };
    like( $@,qr#eval \{\.\.\.} called at $0 line \d+#,
     "Check if no error in eval for '$method'" );
    ok( !$warn,"Check if no warning occurred: $warn" )
}
