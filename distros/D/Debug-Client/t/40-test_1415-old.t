#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 12 );


#Top
use t::lib::Debugger;

start_script('t/eg/test_1415.pl');
my $debugger;
$debugger = start_debugger();
$debugger->get;



#Body
$debugger->__send( 'w ' . '@fonts' );

#diag('show watches '.$debugger->__send_np('L w') );
# diag('buffer show watches '.$debugger->get_buffer );
#p $debugger->__send_np('L w');
#p $debugger->__send('L w');
#p $debugger->get_buffer;

like( $debugger->__send('L w'), qr/fonts/, 'set watchpoints for @fonts' );

#this is 'unlike' as it's a side affect of using a wantarry
unlike( my @list = $debugger->run, qr/Watchpoint/, 'Watchpoint value changed' );
like( $debugger->get_buffer, qr/fonts changed/, 'check buffer for fonts changed' );
unlike( $debugger->module, qr/TERMINATED/, 'module still alive' );

#tell D::C to get cursor position info_line
$debugger->get_lineinfo;
like( $debugger->get_filename, qr/test_1415/, 'check where we are filename' );
is( $debugger->get_row, 19, 'check where we are row 19' );
like( $debugger->get_stack_trace(), qr/ANON/, 'O look, we are in an ANON sub' );

#ToDo test the response, 5.17.6 and 5.16.2 below
#p $debugger->get_y_zero;
# @fonts = (
   # 0  ARRAY(0x9ef7970)
      # 0  'Helvetica'
      # 1  14
   # 1  HASH(0x9f39d50)
      # 'Luxi Sans' => 13
# )
# @fonts = (
   # 0  ARRAY(0x95709e8)
      # 0  'Helvetica'
      # 1  14
   # 1  HASH(0x98f3068)
      # 'Luxi Sans' => 13
# )

#ToDo need a test for the value of @fonts
# like( $debugger->get_value('@fonts'), qr/fred/, 'view contents of @fonts');
# $debugger->get_value("@fonts");
# diag( $debugger->get_buffer );
# cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'view contents of @fonts' );

like( $debugger->run, qr/Watchpoint/, 'stoped for watchpoint' );
like( $debugger->get_buffer, qr/fonts changed/, 'check buffer for fonts changed' );
unlike( $debugger->module, qr/TERMINATED/, 'module still alive' );

#tell D::C to get cursor position info_line
$debugger->get_lineinfo;
like( $debugger->get_filename, qr/test_1415/, 'check where we are filename' );
is( $debugger->get_row, 27, 'check where we are row 27' );

#ToDo test the response, 5.17.6 and 5.16.2 below
#p $debugger->get_y_zero;
# $hw = CODE(0x9570a08)
   # -> &main::__ANON__[t/eg/test_1415.pl:21] in t/eg/test_1415.pl:13-21
# $hw = CODE(0x9bacc70)
   # -> &main::__ANON__[t/eg/test_1415.pl:21] in t/eg/test_1415.pl:13-21


#Tail
$debugger->run;
$debugger->quit;
done_testing();

1;

__END__


#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 8 );


#Top
use t::lib::Debugger;

start_script('t/eg/test_1415.pl');
my $debugger;
$debugger = start_debugger();
$debugger->get;


#Body
$debugger->__send( 'w' . '@fonts' );

# diag( $debugger->__send('L w') );
like( $debugger->__send('L w'), qr/fonts/, 'set watchpoints for @fonts' );

#this is 'unlike' as it's a side affect of using a wantarry
unlike( my @list = $debugger->run, qr/Watchpoint/, 'Watchpoint value changed' );

like( $debugger->get_buffer, qr/fonts changed/, 'check buffer' );
unlike( $debugger->module, qr/TERMINATED/, 'module still alive' );

$debugger->get_lineinfo;
like( $debugger->get_filename, qr/test_1415/, 'check where we are filename' );
is( $debugger->get_row, 19, 'check where we are row' );
like( $debugger->get_stack_trace(), qr/ANON/, 'O look, we are in an ANON sub' );

#ToDo need a test for the value of @fonts
# like( $debugger->get_value('@fonts'), qr/fred/, 'view contents of @fonts');
# $debugger->get_value("@fonts");
# diag( $debugger->get_buffer );
# cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'view contents of @fonts' );

like( $debugger->run, qr/Watchpoint/, 'stoped for watchpoint' );


#Tail
$debugger->quit;
done_testing();

1;

__END__

