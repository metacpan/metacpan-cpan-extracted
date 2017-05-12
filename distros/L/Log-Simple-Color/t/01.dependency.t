use Test::More tests => 3;

BEGIN {
use_ok( 'Log::Simple::Color' );
}

diag( "Testing Log::Simple::Color $Log::Simple::Color::VERSION" );

SKIP: {
    skip( 'Term::ANSIColor is not required for win32 systems', 1 ) if $^O eq 'MSWin32';
    use_ok( 'Term::ANSIColor' );
}

SKIP: {
    skip( 'Win32::Console is not required for non win32 systems', 1 ) if $^O ne 'MSWin32';
    use_ok( 'Win32::Console' );
}
