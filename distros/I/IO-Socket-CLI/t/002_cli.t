#!perl -T

# TODO: test what gets printed to STDERR and STDOUT. create a fake server for testing.

use strict;
use warnings;
use IO::Socket::CLI;
use Test::More;

if ($^O eq 'MSWin32') {
    plan skip_all => 'Tests fail randomly on MSWin32 - maybe just AMD?';
} else {
    plan tests => 65;	# total tests, including those in SKIP blocks.
}


my $server_tests = 0;
my $host = '127.0.0.1';
my $port = 25;

if (open my $fh, '<', "test.config") {
    while (<$fh>) {
        chomp;
        if (/^network_tests (\d)$/) {
            $server_tests = $1;
        } elsif (/^host (.+)$/) {
            $host = $1;
        } elsif (/^port (\d+)$/) {
            $port = $1;
        }
    }
    close $fh;
}

# fake STDIN. takes newline-terminated string, or 0, as arg.
my $stdin_orig;
sub fake_stdin {
    my $input = shift;
    if ($input) {
        open(my $stdin, '<', \$input) || die $!;
        $stdin_orig = *STDIN;
        *STDIN = $stdin;
    } else {
        close(STDIN);
        *STDIN = $stdin_orig;
    }
}

# capture STDOUT for reading from OUTIN, or turn off.
my $stdout_orig;
my $outin;
sub redirect_stdout {
    if (shift) {
        my $out = '';
        open(my $stdout, '+>', \$out) || die $!;
        open($outin, '<', \$out) || die $!;
        $stdout_orig = *STDOUT;
        *STDOUT = $stdout;
    } else {
        close(STDOUT);
        *STDOUT = $stdout_orig;
        close($outin);
    }
}

# capture STDERR for reading from ERRIN, or turn off.
my $stderr_orig;
my $errin;
sub redirect_stderr {
    if (shift) {
        my $err = '';
        open(my $stderr, '+>', \$err) || die $!;
        open($errin, '<', \$err) || die $!;
        $stderr_orig = *STDERR;
        *STDERR = $stderr;
    } else {
        close(STDERR);
        *STDERR = $stderr_orig;
        close($errin);
    }
}

note('verifying methods available');
can_ok('IO::Socket::CLI', qw(new read response print_resp is_open send prompt print_response prepend timeout delay bye debug socket close));


note('initializing');
my $object = IO::Socket::CLI->new(HOST => $host, PORT => $port); # TODO: test with the various options.
isa_ok($object, 'IO::Socket::CLI');
if ($server_tests) {
    sleep 1;
    $object->is_open() || BAIL_OUT("something wrong with server -- can't continue test");
}

note('test options');
is($object->{_HOST}, $host, '_HOST default'); # passed directly to IO::Socket::INET6
is($object->{_PORT}, $port, '_PORT default'); # should be >= 1 and <= 65535. passed directly to IO::Socket::INET6


note('testing methods which change initialized values'); # TODO: later test if the changes actually have the desired effect with other methods.

redirect_stderr(1);
my @ignored_errors = ();

is($object->print_response(), 1, 'print_response() default'); # also test floats, strings, and randomness

is($object->print_response(0), 0, 'print_response(0)');
push @ignored_errors, <$errin>;
is($object->print_response(2), 1, 'print_response(2) == default');
like(<$errin>, qr/warning: valid settings for print_response\(\) are 0 or 1 -- setting to /, 'print_response(2) throws warning');
is($object->print_response(-1), 1, 'print_response(-1) == default');
like(<$errin>, qr/warning: valid settings for print_response\(\) are 0 or 1 -- setting to /, 'print_response(-1) throws warning');

is($object->prepend(), 1, 'prepend() default'); # also test floats, strings, and randomness
is($object->prepend(0), 0, 'prepend(0)');
push @ignored_errors, <$errin>;
is($object->prepend(2), 1, 'prepend(2) == default');
like(<$errin>, qr/warning: valid settings for prepend\(\) are 0 or 1 -- setting to /, 'prepend(2) throws warning');
is($object->prepend(-1), 1, 'prepend(-1) == default');
like(<$errin>, qr/warning: valid settings for prepend\(\) are 0 or 1 -- setting to /, 'prepend(-1) throws warning');

is($object->timeout(), 5, 'timeout() default'); # also test floats, strings, and randomness
is($object->timeout(10), 10, 'timeout(10)');
is($object->timeout(0), 0, 'timeout(0)');
push @ignored_errors, <$errin>;
is($object->timeout(-2), 5, 'timeout(-2) == default');
like(<$errin>, qr/warning: timeout\(\) must be non-negative -- setting to /, 'timeout(-2) throws warning');

is($object->delay(), 10, 'delay() default'); # also test floats, strings, and randomness
is($object->delay(5), 5, 'delay(5)');
push @ignored_errors, <$errin>;
is($object->delay(0), 10, 'delay(0) == default');
like(<$errin>, qr/warning: delay\(\) must be positive -- setting to /, 'delay(0) throws warning');
is($object->delay(-2), 10, 'delay(-2) == default');
like(<$errin>, qr/warning: delay\(\) must be positive -- setting to /, 'delay(-2) throws warning');

is($object->bye(), qr'^\* BYE( |\r?$)', 'BYE default'); # also test randomness
is($object->bye(qr'^(?:221|421)(?: |\r?$)'), qr'^(?:221|421)(?: |\r?$)', 'BYE eq "qr\'^(?:221|421)(?: |\r?$)\'"');
push @ignored_errors, <$errin>;
is($object->bye("invalid string"), qr'^\* BYE( |\r?$)', 'BYE default');
like(<$errin>, qr/warning: bye\(\) must be a regexp-like quote: qr\/STRING\/ -- setting to /, 'bye("invalid string") throws warning');

is($object->debug(), 0, 'debug() default'); # also test floats, strings, and randomness
is($object->debug(1), 1, 'debug(0)');
push @ignored_errors, <$errin>;
is($object->debug(2), 1, 'debug(2) == 1');
like(<$errin>, qr/warning: valid settings for debug\(\) are 0 or 1 -- setting to /, 'debug(2) throws warning');
is($object->debug(-1), 1, 'debug(-1) == 1');
like(<$errin>, qr/warning: valid settings for debug\(\) are 0 or 1 -- setting to /, 'debug(-1) throws warning');
is($object->debug(0), 0, 'debug() default');
push @ignored_errors, <$errin>;
is(@ignored_errors, 0, '@ignored_errors == 0');

redirect_stderr(0);

SKIP: {
    skip "Not running IMAP $host:$port tests", 26 unless $server_tests;

    note("IMAP testing on $host:$port");

    redirect_stdout(1);

    cmp_ok($object->response(), '==', 0, 'response() before read()');

    my @read = $object->read();
    cmp_ok(@read, '>=', 0, 'read()'); # can't guarantee a response.
    my @read_stdout = <$outin>;

    my @response = $object->response();
    cmp_ok(@response, '>=', 0, 'response() after read()'); # can't guarantee a response.
    is_deeply(\@response, \@read, '@response eq @read');

    eval { $object->print_resp() };  is($@, '', 'print_resp()');
    my @print_resp_stdout = <$outin>;
    is_deeply(\@print_resp_stdout, \@read_stdout, '@print_resp_stdout eq @read_stdout');

    is($object->is_open(), 1, 'is_open()');

    my $tag = 0;

    eval { $object->send(++$tag . " capability") }; is($@, '', "send(\"$tag capability\")");

    redirect_stdout(0);

    # fake sending capability from STDIN
    fake_stdin(++$tag . " capability\n");

    $object->prepend(0); # to prevent TAP syntax errors caused by prompt
    eval { $object->prompt() }; is($@, '', 'prompt()');
    $object->prepend(1);
    cmp_ok($object->read(), '>=', 0, 'read()'); # can't guarantee a response.
    is($object->command(), "$tag capability", 'command()');

    fake_stdin(0);

    isa_ok($object->socket(), 'IO::Socket::INET6');

    # send capability and test STDIN and STDOUT:
    SKIP: {
        my $command = ++$tag . " capability";
        my $is_open = $object->is_open();
        is($is_open, 1, 'is_open()');
        skip "connection is closed", 7 unless $is_open;

        redirect_stdout(1);

        eval { $object->send("$command") }; is($@, '', "send(\"$command\") SKIP");
        is(<$outin>, "C: $command\r\n", 'command string on STDOUT');
        cmp_ok($object->read(), '>=', 0, 'read()'); # can't guarantee a response.
        like(join('', <$outin>), qr/S: \* CAPABILITY.*\r\nS: $tag OK(?: |\r$)/, 'response string on STDOUT');
        cmp_ok($object->response(), '>=', 0, 'response() after read()'); # can't guarantee a response.
        eval { $object->print_resp() }; is($@, '', 'print_resp()');
        like(join('', <$outin>), qr/S: $tag OK/, 'response string on STDOUT');

        redirect_stdout(0);
    }

    # LOGOUT:
    SKIP: {

        my $is_open = $object->is_open();
        is($is_open, 1, 'is_open()');
        skip "connection is closed", 4 unless $is_open;

        redirect_stdout(1);

        eval { $object->send("final LOGOUT") }; is($@, '', "send(\"final LOGOUT\")");
        is(<$outin>, "C: final LOGOUT\r\n", 'command string on STDOUT');
        cmp_ok($object->read(), '>=', 0, 'read()'); # can't guarantee a response.
        like(<$outin>, qr/S: \* BYE(?: |\r?$)/, 'response string on STDOUT');

        redirect_stdout(0);
    }

    is($object->close(), 1, 'close()');

}

done_testing();
