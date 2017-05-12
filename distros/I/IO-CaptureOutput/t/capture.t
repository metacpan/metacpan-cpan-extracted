#!/usr/bin/perl -w
#$Id: capture.t,v 1.3 2004/11/22 19:51:09 simonflack Exp $
use strict;
use Test::More 0.62 tests => 21;
use IO::CaptureOutput qw/capture/;
use Config;

my $is_cl = $Config{cc} =~ /cl/i;

my ($out, $err, $out2, $err2);
sub _reset { $_ = '' for ($out, $err, $out2, $err2); 1};

# Basic test
_reset && capture sub {print __PACKAGE__; print STDERR __FILE__}, \$out, \$err;
is($out, __PACKAGE__, 'captured stdout from perl function');
is($err, __FILE__, 'captured stderr from perl function');

# merge STDOUT and STDERR
_reset && capture sub {print __PACKAGE__; print STDERR __FILE__}, \$out, \$out;
like($out, q{/^} . quotemeta(__PACKAGE__) . q{/}, 
    'captured stdout into one scalar');
like($out, q{/} . quotemeta(__FILE__) . q{$/}, 
    'captured stderr into same scalar');

# nesting and passing ref to undef to get passthrough
_reset && capture sub {
    capture sub { print __PACKAGE__; print STDERR __FILE__}, \undef, \$err2;
}, \$out, \$err;
like($out, q{/^} . quotemeta(__PACKAGE__) . q{/}, 
    'stdout passed through to outer capture');
like($err2, q{/} . quotemeta(__FILE__) . q{$/}, 
    'captured stderr in inner');
is($err, q{}, 'outer stderr empty');

# repeat with error
_reset && capture sub {
    capture sub { print __PACKAGE__; print STDERR __FILE__}, \$out2, \undef;
}, \$out, \$err;
like($out2, q{/^} . quotemeta(__PACKAGE__) . q{/}, 
    'captured stdout in inner');
like($err, q{/} . quotemeta(__FILE__) . q{$/}, 
    'stderr passed through to outer capture');
is($out, q{}, 'outer stdout empty');


# Check we still get return values
_reset;
my @arg = capture sub {print 'Testing'; return (1,2,3)}, \$out, \$err;
ok($out eq 'Testing' && eq_array(\@arg, [1,2,3]),
   'capture() proxies the return values');

# Check that the captured sub is called in the right context
my $context = capture sub {wantarray};
ok(defined $context && ! $context,
   'capture() calls subroutine in scalar context when appropriate');

($context) = capture sub {wantarray};
ok($context, 'capture() calls subroutine in list context when appropriate');

capture sub {$context = wantarray};
ok(! defined($context), 'capture() calls subroutine in void context when appropriate');

# Test external program, see t/capture_exec.t for more
_reset;
capture sub {system($^X, '-V:osname')}, \$out;
like($out, "/$^O/", 'capture() caught stdout from external command');

# check we still get stdout/stderr if the code dies
eval {
    capture sub {print "."; print STDERR "5..4..3..2..1.."; die "self-terminating"}, \$out,\$err;
};
like($@, "/^self-terminating at " . quotemeta(__FILE__) . "/", 
    '$@ still available after capture');
ok($out eq '.' && $err eq '5..4..3..2..1..', 
    'capture() still populates output and error variables if the code dies');

SKIP: {
    my $can_fork = $Config{d_fork} || $Config{d_pseudofork}
      || ( $^O eq "MSWin32" && $Config{useithreads} && $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS\b/ );
    skip "fork not available", 1 unless $can_fork;
    # test fork()
    sub forked_output {
        fork or do {
            print "forked";
            print STDERR "Child pid $$";
            exit;
        };
        select undef, undef, undef, 0.2;
    }
    capture \&forked_output, \$out, \$err;
    ok($out eq 'forked' && $err =~ /^Child pid /, 'capture() traps fork() output');
}

# Test printing via C code
SKIP: {
    eval "require Inline::C";
    skip "Inline::C not available", 3 if $@;
    eval {
        my $c_code = do {local $/; <DATA>};
#        Inline->bind( 'C' => $c_code, FORCE_BUILD => 1, BUILD_NOISY => 1 );
        Inline->bind( 'C' => $c_code, FORCE_BUILD => 1);
    };
    skip "Inline->bind failed : $@", 3 if $@;
    ok(test_inline_c(), 'Inline->bind succeeded');

    _reset && capture sub { 
        $is_cl ? cl_print_stdout("Hello World") 
               : print_stdout("Hello World");
    }, \$out, \$err;
    is($out, 'Hello World', 'captured stdout from C function');

    _reset && capture sub { 
        $is_cl ? cl_print_stderr("Testing stderr") 
               : print_stderr("Testing stderr");
    }, \$out, \$err;
    is($err, 'Testing stderr', 'captured stderr from C function');
}


__DATA__
// A basic sub to test that the bind() succeeded
#include <stdio.h>
int test_inline_c () { return 42; }

// print to stdout -- regular
void print_stdout (char* text) { printf("%s", text); fflush(stdout); }

// print to stdout -- for MSVC
void cl_print_stdout (const char *template, ... ) { 
    va_list ap;
    va_start( ap, template );
    vfprintf( stdout, template, ap );
    va_end( ap );
    fflush(stdout);
}

// print to stdout -- regular
void print_stderr (char* text) { fprintf(stderr, "%s", text); fflush(stderr); }

// print to stderr -- for MSVC
// avoiding fprintf because of segfaults on MSWin32 with some versions of
// ActiveState and some combinations of MSVC compiler
void cl_print_stderr (const char *template, ... ) { 
    va_list ap;
    va_start( ap, template );
    vfprintf( stderr, template, ap );
    va_end( ap );
    fflush(stderr);
}
