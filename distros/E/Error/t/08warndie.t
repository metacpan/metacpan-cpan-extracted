#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 21;

use Error qw/ :warndie /;

# Turn on full stack trace capture
$Error::Debug = 1;

# This file's name - for string matching. We need to quotemeta it, because on
# Win32, the filename is t\08warndie.t, and we don't want that accidentally
# matching an (invalid) \08 octal digit
my $file = qr/\Q$0\E/;

# Most of these tests are fatal, and print data on STDERR. We therefore use
# this testing function to run a CODEref in a child process and captures its
# STDERR and note whether the CODE block exited
my ( $s, $felloffcode );
my $linekid = __LINE__ + 15; # the $code->() is 15 lines below this one
sub run_kid(&)
{
    my ( $code ) = @_;

    # Win32's fork() emulation can't correctly handle the open("-|") case yet
    # So we'll implement this manually - inspired by 'perldoc perlfork'
    pipe my $childh, my $child or die "Cannot pipe() - $!";
    defined( my $kid = fork() ) or die "Cannot fork() - $!";

    if ( !$kid ) {
        close $childh;
        close STDERR;
        open(STDERR, ">&=" . fileno($child)) or die;

        $code->();

        print STDERR "FELL OUT OF CODEREF\n";
        exit(1);
    }

    close $child;

    $s = "";
    while( defined ( $_ = <$childh> ) ) {
        $s .= $_;
    }

    close( $childh );
    waitpid( $kid, 0 );

    $felloffcode = 0;
    $s =~ tr/\r//d; # Remove Win32 \r linefeeds to make RE tests easier
    if( $s =~ s/FELL OUT OF CODEREF\n$// ) {
        $felloffcode = 1;
    }
}

ok(1, "Loaded");

run_kid {
    print STDERR "Print to STDERR\n";
};

is( $s, "Print to STDERR\n", "Test framework STDERR" );
is( $felloffcode, 1, "Test framework felloffcode" );

my $line;

$line = __LINE__;
run_kid {
    warn "A warning\n";
};

my ( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^A warning at $file line $linea\.?:
\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('?CODE\(0x[0-9a-f]+\)'?\) called at $file line $lineb
$/, "warn \\n-terminated STDERR" );
is( $felloffcode, 1, "warn \\n-terminated felloffcode" );

$line = __LINE__;
run_kid {
    warn "A warning";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^A warning at $file line $linea\.?:
\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('?CODE\(0x[0-9a-f]+\)'?\) called at $file line $lineb
$/, "warn unterminated STDERR" );
is( $felloffcode, 1, "warn unterminated felloffcode" );

$line = __LINE__;
run_kid {
    die "An error\n";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^
Unhandled perl error caught at toplevel:

  An error

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('?CODE\(0x[0-9a-f]+\)'?\) called at $file line $lineb

$/, "die \\n-terminated STDERR" );
is( $felloffcode, 0, "die \\n-terminated felloffcode" );

$line = __LINE__;
run_kid {
    die "An error";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^
Unhandled perl error caught at toplevel:

  An error

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('?CODE\(0x[0-9a-f]+\)'?\) called at $file line $lineb

$/, "die unterminated STDERR" );
is( $felloffcode, 0, "die unterminated felloffcode" );

$line = __LINE__;
run_kid {
    throw Error( -text => "An exception" );
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^
Unhandled exception of type Error caught at toplevel:

  An exception

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('?CODE\(0x[0-9a-f]+\)'?\) called at $file line $lineb

$/, "Error STDOUT" );
is( $felloffcode, 0, "Error felloffcode" );

# Now custom warn and die functions to ensure the :warndie handler respects them
$SIG{__WARN__} = sub { warn "My custom warning here: $_[0]" };
$SIG{__DIE__}  = sub { die  "My custom death here: $_[0]" };

# First test them
$line = __LINE__;
run_kid {
    warn "A warning";
};

$linea = $line + 2;
like( $s, qr/^My custom warning here: A warning at $file line $linea\.?
$/, "Custom warn test STDERR" );
is( $felloffcode, 1, "Custom warn test felloffcode" );

$line = __LINE__;
run_kid {
    die "An error";
};

$linea = $line + 2;
like( $s, qr/^My custom death here: An error at $file line $linea\.?
/, "Custom die test STDERR" );
is( $felloffcode, 0, "Custom die test felloffcode" );

# Re-install the :warndie handlers
import Error qw( :warndie );

$line = __LINE__;
run_kid {
    warn "A warning\n";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^My custom warning here: A warning at $file line $linea\.?:
\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('?CODE\(0x[0-9a-f]+\)'?\) called at $file line $lineb
$/, "Custom warn STDERR" );
is( $felloffcode, 1, "Custom warn felloffcode" );

$line = __LINE__;
run_kid {
    die "An error";
};

my $WS = ' ';
( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^My custom death here:$WS
Unhandled perl error caught at toplevel:

  An error

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('?CODE\(0x[0-9a-f]+\)'?\) called at $file line $lineb

$/, "Custom die STDERR" );
is( $felloffcode, 0, "Custom die felloffcode" );

# Done
