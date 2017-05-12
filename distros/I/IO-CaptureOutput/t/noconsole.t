use strict;
use Symbol qw/gensym/;
my ($save_out, $save_err);
BEGIN { 
    $save_out = gensym();
    $save_err = gensym();
    open $save_out, ">&main::STDOUT";
    open $save_err, ">&main::STDERR";
}

use Test::More tests => 7;

#--------------------------------------------------------------------------#
# close and restore console
#--------------------------------------------------------------------------#

sub _close_console {
    close STDOUT or die "Can't close STDOUT";
    close STDERR or die "Can't close STDERR";
    return;
}

sub _restore_console {
    open STDOUT, ">&" . fileno($save_out) or die "Can't restore STDOUT";
    open STDERR, ">&" . fileno($save_err) or die "Can't restore STDERR";
    return;
}

#--------------------------------------------------------------------------#
# _test_print
#--------------------------------------------------------------------------#

sub _test_print {
    print STDOUT "Test to STDOUT\n";
    print STDERR "Test to STDERR\n";
    return;
}

#--------------------------------------------------------------------------#

my ($stdout, $stderr, $err);

BEGIN{ use_ok("IO::CaptureOutput", "capture") }

eval { capture \&_test_print, \$stdout, \$stderr; };
$err = $@;

is( $err, q{}, "no errors capturing with console open" );
is( $stdout, "Test to STDOUT\n", "STDOUT test with console open" );
is( $stderr, "Test to STDERR\n", "STDERR test with console open" );
$stdout = $stderr = q{};

_close_console;

eval { capture \&_test_print, \$stdout, \$stderr; };
$err = $@;

_restore_console;

is( $err, q{}, "no errors capturing with console closed" );
is( $stdout, "Test to STDOUT\n", "STDOUT test with console closed" );
is( $stderr, "Test to STDERR\n", "STDERR test with console closed" );


