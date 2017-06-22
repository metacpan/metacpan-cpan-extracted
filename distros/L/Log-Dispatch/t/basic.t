## no critic (Modules::ProhibitExcessMainComplexity)
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;

use File::Spec;
use File::Temp qw( tempdir );
use Module::Runtime qw( use_module );
use Try::Tiny;

use Log::Dispatch;

my %tests;

BEGIN {
    local $@ = undef;
    foreach (qw( MailSend MIMELite MailSendmail MailSender )) {
        ## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
        eval "use Log::Dispatch::Email::$_";
        $tests{$_} = !$@;
        $tests{$_} = 0 if $ENV{LD_NO_MAIL};
    }
}

my %TestConfig;
if ( my $email_address = $ENV{LOG_DISPATCH_TEST_EMAIL} ) {
    %TestConfig = ( email_address => $email_address );
}

my @syswrite_strs;

BEGIN {
    if ( $] >= 5.016 ) {
        my $syswrite = \&CORE::syswrite;
        *CORE::GLOBAL::syswrite = sub {
            my ( $fh, $str, @other ) = @_;
            push @syswrite_strs, $_[1];

            return $syswrite->( $fh, $str, @other );
        };
    }
}

use Log::Dispatch::File;
use Log::Dispatch::Handle;
use Log::Dispatch::Null;
use Log::Dispatch::Screen;

use IO::File;

my $tempdir = tempdir( CLEANUP => 1 );

subtest(
    'Test Log::Dispatch::File',
    sub {
        my $dispatch = Log::Dispatch->new;
        ok( $dispatch, 'created Log::Dispatch object' );

        my $emerg_log = File::Spec->catdir( $tempdir, 'emerg.log' );

        $dispatch->add(
            Log::Dispatch::File->new(
                name      => 'file1',
                min_level => 'emerg',
                filename  => $emerg_log
            )
        );

        $dispatch->log( level => 'info',  message => "info level 1\n" );
        $dispatch->log( level => 'emerg', message => "emerg level 1\n" );

        my $debug_log = File::Spec->catdir( $tempdir, 'debug.log' );

        $dispatch->add(
            Log::Dispatch::File->new(
                name      => 'file2',
                min_level => 'debug',
                syswrite  => 1,
                filename  => $debug_log
            )
        );

        my %outputs = map { $_->name() => ref $_ } $dispatch->outputs();
        is_deeply(
            \%outputs, {
                file1 => 'Log::Dispatch::File',
                file2 => 'Log::Dispatch::File',
            },
            '->outputs() method returns all output objects'
        );

        $dispatch->log( level => 'info',  message => "info level 2\n" );
        $dispatch->log( level => 'emerg', message => "emerg level 2\n" );

        # This'll close them filehandles!
        undef $dispatch;

        ## no critic (InputOutput::RequireBriefOpen)
        open my $emerg_fh, '<', $emerg_log
            or die "Can't read $emerg_log: $!";
        open my $debug_fh, '<', $debug_log
            or die "Can't read $debug_log: $!";

        my @log = <$emerg_fh>;
        is(
            $log[0], "emerg level 1\n",
            q{First line in log file set to level 'emerg' is 'emerg level 1'}
        );

        is(
            $log[1], "emerg level 2\n",
            q{Second line in log file set to level 'emerg' is 'emerg level 2'}
        );

        @log = <$debug_fh>;
        is(
            $log[0], "info level 2\n",
            q{First line in log file set to level 'debug' is 'info level 2'}
        );

        is(
            $log[1], "emerg level 2\n",
            q{Second line in log file set to level 'debug' is 'emerg level 2'}
        );

        close $emerg_fh or die $!;
        close $debug_fh or die $!;

    SKIP:
        {
            ## no critic (ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions)
            skip 'This test requires Perl 5.16+', 1
                unless $] >= 5.016;
            is_deeply(
                \@syswrite_strs,
                [
                    "info level 2\n",
                    "emerg level 2\n",
                ],
                'second LD object used syswrite',
            );
        }
    }
);

subtest(
    'max_level',
    sub {
        my $max_log = File::Spec->catfile( $tempdir, 'max.log' );

        my $dispatch = Log::Dispatch->new;
        $dispatch->add(
            Log::Dispatch::File->new(
                name      => 'file1',
                min_level => 'debug',
                max_level => 'crit',
                filename  => $max_log
            )
        );

        $dispatch->log( level => 'emerg', message => "emergency\n" );
        $dispatch->log( level => 'crit',  message => "critical\n" );

        undef $dispatch;    # close file handles

        open my $fh, '<', $max_log
            or die "Can't read $max_log: $!";
        my @log = <$fh>;
        close $fh or die $!;

        is(
            $log[0], "critical\n",
            q{First line in log file with a max level of 'crit' is 'critical'}
        );
    }
);

subtest(
    'Handle output',
    sub {
        my $handle_log = File::Spec->catfile( $tempdir, 'handle.log' );

        my $fh = IO::File->new( $handle_log, 'w' )
            or die "Can't write to $handle_log: $!";

        my $dispatch = Log::Dispatch->new;
        $dispatch->add(
            Log::Dispatch::Handle->new(
                name      => 'handle',
                min_level => 'debug',
                handle    => $fh
            )
        );

        $dispatch->log( level => 'notice', message => "handle test\n" );

        # close file handles
        undef $dispatch;
        undef $fh;

        open $fh, '<', $handle_log
            or die "Can't open $handle_log: $!";

        my @log = <$fh>;

        close $fh or die $!;

        is(
            $log[0], "handle test\n",
            q{Log::Dispatch::Handle created log file should contain 'handle test\\n'}
        );
    }
);

subtest(
    'Email::MailSend output',
    sub {
    SKIP:
        {
            skip 'Cannot do MailSend tests', 1
                unless $tests{MailSend} && $TestConfig{email_address};

            my $dispatch = Log::Dispatch->new;

            $dispatch->add(
                Log::Dispatch::Email::MailSend->new(
                    name      => 'Mail::Send',
                    min_level => 'debug',
                    to        => $TestConfig{email_address},
                    subject   => 'Log::Dispatch test suite'
                )
            );

            $dispatch->log(
                level => 'emerg',
                message =>
                    "Mail::Send test - If you can read this then the test succeeded (PID $$)"
            );

            diag(
                "Sending email with Mail::Send to $TestConfig{email_address}.\nIf you get it then the test succeeded (PID $$)\n"
            );
            undef $dispatch;

            ok( 1, 'sent email via MailSend' );
        }
    }
);

subtest(
    'Email::MailSendmail output',
    sub {
    SKIP:
        {
            skip 'Cannot do MailSendmail tests', 1
                unless $tests{MailSendmail} && $TestConfig{email_address};

            my $dispatch = Log::Dispatch->new;

            $dispatch->add(
                Log::Dispatch::Email::MailSendmail->new(
                    name      => 'Mail::Sendmail',
                    min_level => 'debug',
                    to        => $TestConfig{email_address},
                    subject   => 'Log::Dispatch test suite'
                )
            );

            $dispatch->log(
                level => 'emerg',
                message =>
                    "Mail::Sendmail test - If you can read this then the test succeeded (PID $$)"
            );

            diag(
                "Sending email with Mail::Sendmail to $TestConfig{email_address}.\nIf you get it then the test succeeded (PID $$)\n"
            );
            undef $dispatch;

            ok( 1, 'sent email via MailSendmail' );
        }
    }
);

subtest(
    'Email::MIMELite output',
    sub {
    SKIP:
        {

            skip 'Cannot do MIMELite tests', 1
                unless $tests{MIMELite} && $TestConfig{email_address};

            my $dispatch = Log::Dispatch->new;

            $dispatch->add(
                Log::Dispatch::Email::MIMELite->new(
                    name      => 'Mime::Lite',
                    min_level => 'debug',
                    to        => $TestConfig{email_address},
                    subject   => 'Log::Dispatch test suite'
                )
            );

            $dispatch->log(
                level => 'emerg',
                message =>
                    "MIME::Lite - If you can read this then the test succeeded (PID $$)"
            );

            diag(
                "Sending email with MIME::Lite to $TestConfig{email_address}.\nIf you get it then the test succeeded (PID $$)\n"
            );
            undef $dispatch;

            ok( 1, 'sent mail via MIMELite' );
        }
    }
);

subtest(
    'Email::MailSender output',
    sub {
    SKIP:
        {
            skip 'Cannot do MailSender tests', 1
                unless $tests{MailSender} && $TestConfig{email_address};

            my $dispatch = Log::Dispatch->new;

            $dispatch->add(
                Log::Dispatch::Email::MailSender->new(
                    name      => 'Mail::Sender',
                    min_level => 'debug',
                    smtp      => 'localhost',
                    to        => $TestConfig{email_address},
                    subject   => 'Log::Dispatch test suite'
                )
            );

            $dispatch->log(
                level => 'emerg',
                message =>
                    "Mail::Sender - If you can read this then the test succeeded (PID $$)"
            );

            diag(
                "Sending email with Mail::Sender to $TestConfig{email_address}.\nIf you get it then the test succeeded (PID $$)\n"
            );
            undef $dispatch;

            ok( 1, 'sent email via MailSender' );
        }
    }
);

subtest(
    'Log::Dispatch::Output->accepted_levels',
    sub {
        my $l = Log::Dispatch::Screen->new(
            name      => 'foo',
            min_level => 'warning',
            max_level => 'alert',
            stderr    => 0
        );

        my @expected = qw(warning error critical alert);
        my @levels   = $l->accepted_levels;

        is_deeply(
            \@expected,
            \@levels,
            'accepted_levels matches what is expected'
        );
    }
);

subtest(
    'Log::Dispatch single callback',
    sub {
        my $reverse = sub { my %p = @_; return reverse $p{message}; };
        my $dispatch = Log::Dispatch->new( callbacks => $reverse );

        my $string;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'foo',
                string    => \$string,
                min_level => 'warning',
                max_level => 'alert',
            )
        );

        $dispatch->log( level => 'warning', message => 'esrever' );

        is(
            $string, 'reverse',
            'callback to reverse text'
        );
    }
);

subtest(
    'Log::Dispatch multiple callbacks',
    sub {
        my $reverse = sub { my %p = @_; return reverse $p{message}; };
        my $uc      = sub { my %p = @_; return uc $p{message}; };

        my $dispatch = Log::Dispatch->new( callbacks => [ $reverse, $uc ] );

        my $string;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'foo',
                string    => \$string,
                min_level => 'warning',
                max_level => 'alert',
            )
        );

        $dispatch->log( level => 'warning', message => 'esrever' );

        is(
            $string, 'REVERSE',
            'callback to reverse and uppercase text'
        );

        is_deeply(
            [ $dispatch->callbacks() ],
            [ $reverse, $uc ],
            '->callbacks() method returns all of the callback subs'
        );

        my $clone = $dispatch->clone();
        is_deeply(
            $clone,
            $dispatch,
            'clone is a shallow clone of the original object'
        );

        $clone->add(
            Log::Dispatch::Screen->new(
                name      => 'screen',
                min_level => 'debug',
            )
        );
        my @orig_outputs  = map { $_->name() } $dispatch->outputs();
        my @clone_outputs = map { $_->name() } $clone->outputs();
        isnt(
            scalar(@orig_outputs),
            scalar(@clone_outputs),
            'clone is not the same as original after adding an output'
        );

        $clone->add_callback( sub { return 'foo' } );
        my @orig_cb  = $dispatch->callbacks();
        my @clone_cb = $clone->callbacks();
        isnt(
            scalar(@orig_cb),
            scalar(@clone_cb),
            'clone is not the same as original after adding a callback'
        );
    }
);

subtest(
    'Log::Dispatch::Output single callback',
    sub {
        my $reverse = sub { my %p = @_; return reverse $p{message}; };

        my $dispatch = Log::Dispatch->new;

        my $string;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'foo',
                string    => \$string,
                min_level => 'warning',
                max_level => 'alert',
                callbacks => $reverse
            )
        );

        $dispatch->log( level => 'warning', message => 'esrever' );

        is(
            $string, 'reverse',
            'Log::Dispatch::Output callback to reverse text'
        );
    }
);

subtest(
    'Log::Dispatch::Output multiple callbacks',
    sub {
        my $reverse = sub { my %p = @_; return reverse $p{message}; };
        my $uc      = sub { my %p = @_; return uc $p{message}; };

        my $dispatch = Log::Dispatch->new;

        my $string;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'foo',
                string    => \$string,
                min_level => 'warning',
                max_level => 'alert',
                callbacks => [ $reverse, $uc ]
            )
        );

        $dispatch->log( level => 'warning', message => 'esrever' );

        is(
            $string, 'REVERSE',
            'Log::Dispatch::Output callbacks to reverse and uppercase text'
        );
    }
);

subtest(
    'level parameter to callbacks',
    sub {
        my $level = sub { my %p = @_; return uc $p{level}; };

        my $dispatch = Log::Dispatch->new( callbacks => $level );

        my $string;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'foo',
                string    => \$string,
                min_level => 'warning',
                max_level => 'alert',
                stderr    => 0
            )
        );

        $dispatch->log( level => 'warning', message => 'esrever' );

        is(
            $string, 'WARNING',
            'Log::Dispatch callback to uppercase the level parameter'
        );
    }
);

subtest(
    'level name methods',
    sub {
        my %levels = map { $_ => $_ }
            (qw( debug info notice warning error critical alert emergency ));
        @levels{qw( warn err crit emerg )}
            = (qw( warning error critical emergency ));

        foreach my $allowed_level (
            qw( debug info notice warning error critical alert emergency )) {
            my $dispatch = Log::Dispatch->new;

            my $string;
            $dispatch->add(
                Log::Dispatch::String->new(
                    name      => 'foo',
                    string    => \$string,
                    min_level => $allowed_level,
                    max_level => $allowed_level,
                )
            );

            foreach my $test_level (
                qw( debug info notice warn warning err
                error crit critical alert emerg emergency )
                ) {
                $string = q{};
                $dispatch->$test_level( $test_level, 'test' );

                if ( $levels{$test_level} eq $allowed_level ) {
                    my $expect = join $", $test_level, 'test';
                    is(
                        $string, $expect,
                        qq{Calling $test_level method should send message '$expect'}
                    );
                }
                else {
                    ok(
                        !length $string,
                        "Calling $test_level method should not log anything"
                    );
                }
            }
        }
    }
);

subtest(
    'argument variations to name method',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new(
            outputs => [
                [
                    'String',
                    name      => 'string',
                    string    => \$string,
                    min_level => 'debug',
                ],
            ],
        );

        $dispatch->debug( 'foo', 'bar' );
        is(
            $string,
            'foo bar',
            'passing multiple elements to ->debug stringifies them like an array'
        );

        $string = q{};
        $dispatch->debug( sub {'foo'} );
        is(
            $string,
            'foo',
            'passing single sub ref to ->debug calls the sub ref'
        );

    }
);

subtest(
    'Log::Dispatch->level_is_valid method',
    sub {
        foreach my $l (
            qw( debug info notice warning err error
            crit critical alert emerg emergency )
            ) {
            ok( Log::Dispatch->level_is_valid($l), "$l is valid level" );
        }

        foreach my $l (qw( debu inf foo bar )) {
            ok( !Log::Dispatch->level_is_valid($l), "$l is not valid level" );
        }

        #   Provide calling line if level missing
        my $string;
        my $dispatch = Log::Dispatch->new(
            outputs => [
                [
                    'String',
                    name      => 'string',
                    string    => \$string,
                    min_level => 'debug',
                ],
            ],
        );

        like(
            exception { $dispatch->log( msg => 'Message' ) },
            qr/Logging level was not provided at .* line \d+./,
            'Provide calling line if level not provided'
        );
    }
);

subtest(
    'Log::Dispatch->would_log method',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new(
            outputs => [
                [
                    'String',
                    name      => 'string',
                    string    => \$string,
                    min_level => 'debug',
                ],
            ],
        );

        is(
            $dispatch->would_log('debug'),
            1,
            'Would log works with level name'
        );

        is(
            $dispatch->would_log(0),
            1,
            'Would log works with level number'
        );
    }
);

subtest(
    'File output mode=write',
    sub {
        my $mode_log = File::Spec->catfile( $tempdir, 'mode.log' );

        my $f1 = Log::Dispatch::File->new(
            name      => 'file',
            min_level => 1,
            filename  => $mode_log,
            mode      => 'write',
        );
        $f1->log(
            level   => 'emerg',
            message => "test2\n"
        );

        undef $f1;

        open my $fh, '<', $mode_log
            or die "Cannot read $mode_log: $!";
        my $data = do { local $/ = undef; <$fh> };
        close $fh or die $!;

        like( $data, qr/^test2/, 'test write mode' );
    }
);

subtest(
    'Log::Dispatch->dispatch by name',
    sub {
        my $dispatch = Log::Dispatch->new;

        $dispatch->add(
            Log::Dispatch::Screen->new(
                name      => 'yomama',
                min_level => 'alert'
            )
        );

        ok(
            $dispatch->output('yomama'),
            'yomama output should exist'
        );

        ok(
            !$dispatch->output('nomama'),
            'nomama output should not exist'
        );
    }
);

subtest(
    'File output close_after_writer & permissions',
    sub {
        my $dispatch = Log::Dispatch->new;

        my $close_log = File::Spec->catfile( $tempdir, 'close.log' );

        ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
        $dispatch->add(
            Log::Dispatch::File->new(
                name              => 'close',
                min_level         => 'info',
                filename          => $close_log,
                permissions       => 0777,
                close_after_write => 1
            )
        );

        $dispatch->log( level => 'info', message => "info\n" );

        open my $fh, '<', $close_log
            or die "Can't read $close_log: $!";
        my @log = <$fh>;
        close $fh or die $!;

        is(
            $log[0], "info\n",
            q{First line in log file should be 'info\\n'}
        );

        my $mode = ( stat $close_log )[2]
            or die "Cannot stat $close_log: $!";

        my $mode_string = sprintf( '%04o', $mode & 07777 );

        if ( $^O =~ /win32/i ) {
            ok(
                $mode_string eq '0777' || $mode_string eq '0666',
                'Mode should be 0777 or 0666'
            );
        }
        elsif ( $^O =~ /cygwin|msys/i ) {
            ok(
                $mode_string eq '0777' || $mode_string eq '0644',
                'Mode should be 0777 or 0644'
            );
        }
        else {
            is(
                $mode_string,
                '0777',
                'Mode should be 0777'
            );
        }
    }
);

subtest(
    'File output chmod calls',
    sub {
        my $dispatch = Log::Dispatch->new;

        my $chmod_log = File::Spec->catfile( $tempdir, 'chmod.log' );

        open my $fh, '>', $chmod_log
            or die "Cannot write to $chmod_log: $!";
        close $fh or die $!;

        chmod 0777, $chmod_log
            or die "Cannot chmod 0777 $chmod_log: $!";

        my @chmod;
        ## no critic (TestingAndDebugging::ProhibitNoWarnings)
        no warnings 'once';
        local *CORE::GLOBAL::chmod = sub { @chmod = @_; warn @chmod };

        ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
        $dispatch->add(
            Log::Dispatch::File->new(
                name        => 'chmod',
                min_level   => 'info',
                filename    => $chmod_log,
                permissions => 0777,
            )
        );

        $dispatch->warning('test');

        ok(
            !scalar @chmod,
            'chmod() was not called when permissions already matched what was specified'
        );
    }
);

subtest(
    'File output binmode',
    sub {
    SKIP:
        {
            ## no critic (ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions)
            skip "Cannot test utf8 files with this version of Perl ($])", 1
                unless $] >= 5.008;

            my $dispatch = Log::Dispatch->new;

            my $utf8_log = File::Spec->catfile( $tempdir, 'utf8.log' );

            $dispatch->add(
                Log::Dispatch::File->new(
                    name      => 'utf8',
                    min_level => 'info',
                    filename  => $utf8_log,
                    binmode   => ':encoding(UTF-8)',
                )
            );

            my @warnings;

            {
                local $SIG{__WARN__} = sub { push @warnings, @_ };
                $dispatch->warning("\x{999A}");
            }

            ok(
                !scalar @warnings,
                'utf8 binmode was applied to file and no warnings were issued'
            );
        }
    }
);

subtest(
    'Log::Dispatch->would_log',
    sub {
        my $dispatch = Log::Dispatch->new;

        $dispatch->add(
            Log::Dispatch::Null->new(
                name      => 'null',
                min_level => 'warning',
            )
        );

        ok(
            !$dispatch->would_log('foo'),
            q{will not log 'foo'}
        );

        ok(
            !$dispatch->would_log('debug'),
            q{will not log 'debug'}
        );

        ok(
            !$dispatch->is_debug(),
            'is_debug returns false'
        );

        ok(
            $dispatch->is_warning(),
            'is_warning returns true'
        );

        ok(
            $dispatch->would_log('crit'),
            q{will log 'crit'}
        );

        ok(
            $dispatch->is_crit,
            q{will log 'crit'}
        );
    }
);

subtest(
    'messages as coderefs are only called as needed',
    sub {
        my $dispatch = Log::Dispatch->new;

        $dispatch->add(
            Log::Dispatch::Null->new(
                name      => 'null',
                min_level => 'info',
                max_level => 'critical',
            )
        );

        my $called = 0;
        my $message = sub { $called = 1 };

        $dispatch->log( level => 'debug', message => $message );
        ok(
            !$called,
            'subref is not called if the message would not be logged'
        );

        $called = 0;
        $dispatch->log( level => 'warning', message => $message );
        ok( $called, 'subref is called when message is logged' );

        $called = 0;
        $dispatch->log( level => 'emergency', message => $message );
        ok(
            !$called,
            'subref is not called when message would not be logged'
        );
    }
);

subtest(
    'passing coderef to ->log',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'handle',
                string    => \$string,
                min_level => 'debug',
            )
        );

        $dispatch->log(
            level   => 'debug',
            message => sub {'this is my message'},
        );

        is(
            $string, 'this is my message',
            'message returned by subref is logged'
        );
    }
);

subtest(
    'newline parameter to output',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'handle',
                string    => \$string,
                min_level => 'debug',
                newline   => 1,
            )
        );
        $dispatch->debug('hello');
        $dispatch->debug('goodbye');

        is( $string, "hello\ngoodbye\n", 'added newlines' );
    }
);

subtest(
    'log_and_die method',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'handle',
                string    => \$string,
                min_level => 'debug',
            )
        );

        my $e = exception {
            _log_and_die(
                $dispatch,
                level   => 'error',
                message => 'this is my message',
            );
        };

        ok( $e, 'died when calling log_and_die()' );
        like( $e, qr{this is my message}, 'error contains expected message' );
        like( $e, qr{basic\.t line 50\d\d}, 'error croaked' );

        is( $string, 'this is my message', 'message is logged' );

        undef $string;

        try {
            Croaker::croak($dispatch)
        }
        catch {
            $e = $_;
        };

        ok( $e, 'died when calling log_and_croak()' );
        like( $e, qr{croaking a message}, 'error contains expected message' );
        like(
            $e, qr{basic\.t line 100\d\d},
            'error croaked from perspective of caller'
        );

        is( $string, 'croaking a message', 'message is logged' );
    }
);

subtest(
    'adding and removing callbacks in output',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'handle',
                string    => \$string,
                min_level => 'debug',
            )
        );

        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'foo', 'first test w/o callback' );

        my $cb = sub { return 'bar' };
        $string = q{};
        $dispatch->add_callback($cb);
        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'bar', 'second call, callback overrides message' );

        $string = q{};
        $dispatch->remove_callback($cb);
        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'foo', 'third call, callback is removed' );
    }
);

subtest(
    'adding and removing callbacks in Log::Dispatch',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new(
            callbacks => sub { return 'baz' },
        );
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'handle',
                string    => \$string,
                min_level => 'debug',
            )
        );

        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'baz', 'first test gets orig callback result' );

        my $cb = sub { return 'bar' };
        $string = q{};
        $dispatch->add_callback($cb);
        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'bar', 'second call, callback overrides message' );

        $string = q{};
        $dispatch->remove_callback($cb);
        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'baz', 'third call, output callback is removed' );
    }
);

subtest(
    'callback in output can overwrite message',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new;
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'handle',
                string    => \$string,
                min_level => 'debug',
            )
        );

        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'foo', 'first test w/o callback' );

        $string = q{};
        $dispatch->add_callback( sub { return 'bar' } );
        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'bar', 'second call, callback overrides message' );
    }
);

subtest(
    'callback in Log::Dispatch can overwrite message',
    sub {
        my $string;
        my $dispatch = Log::Dispatch->new(
            callbacks => sub { return 'baz' },
        );
        $dispatch->add(
            Log::Dispatch::String->new(
                name      => 'handle',
                string    => \$string,
                min_level => 'debug',
            )
        );

        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'baz', 'first test gets orig callback result' );

        $string = q{};
        $dispatch->add_callback( sub { return 'bar' } );
        $dispatch->log( level => 'debug', message => 'foo' );
        is( $string, 'bar', 'second call, callback overrides message' );
    }
);

subtest(
    'default output name',
    sub {

        # Test defaults
        my $dispatch = Log::Dispatch::Null->new( min_level => 'debug' );
        like( $dispatch->name, qr/anon/, 'generated anon name' );
        is( $dispatch->max_level, 'emergency', 'max_level is emergency' );
    }
);

subtest(
    'callbacks get correct level',
    sub {
        my $level;
        my $record_level = sub {
            my %p = @_;
            $level = $p{level};
            return %p;
        };

        my $dispatch = Log::Dispatch->new(
            callbacks => $record_level,
            outputs   => [
                [
                    'Null',
                    name      => 'null',
                    min_level => 'debug',
                ],
            ],
        );

        $dispatch->warn('foo');
        is(
            $level,
            'warning',
            'level for call to ->warn is warning'
        );

        $dispatch->err('foo');
        is(
            $level,
            'error',
            'level for call to ->err is error'
        );

        $dispatch->crit('foo');
        is(
            $level,
            'critical',
            'level for call to ->crit is critical'
        );

        $dispatch->emerg('foo');
        is(
            $level,
            'emergency',
            'level for call to ->emerg is emergency'
        );
    }
);

subtest(
    'Code output',
    sub {
        my @calls;
        my $log = Log::Dispatch->new(
            outputs => [
                [
                    'Code',
                    min_level => 'error',
                    code      => sub { push @calls, {@_} },
                ],
            ]
        );

        $log->error('foo');
        $log->info('bar');
        $log->critical('baz');

        is_deeply(
            \@calls,
            [
                {
                    level   => 'error',
                    message => 'foo',
                }, {
                    level   => 'critical',
                    message => 'baz',
                },
            ],
            'code received the expected messages'
        );
    }
);

subtest(
    'passing level as name or integer',
    sub {
        my $dispatch = Log::Dispatch->new;
        my $log = File::Spec->catdir( $tempdir, 'emerg.log' );

        $dispatch->add(
            Log::Dispatch::File->new(
                name      => 'file1',
                min_level => 3,
                filename  => $log,
            )
        );

        $dispatch->log( level => 'info',  message => "info level 1\n" );
        $dispatch->log( level => 'emerg', message => "emerg level 1\n" );
        $dispatch->log( level => 'warn',  message => "warn level 1\n" );
        $dispatch->log( level => 3,       message => "bug 106495 1\n" );
        $dispatch->log( level => 4,       message => "bug 106495 2\n" );
        $dispatch->log( level => 1,       message => "bug 106495 3\n" );

        open my $fh, '<', $log or die $!;
        my @log = <$fh>;
        close $fh or die $!;

        is( $log[0], "emerg level 1\n", 'at level 3, emerg works' );
        is( $log[1], "warn level 1\n",  'at level 3, warn works' );
        is(
            $log[2], "bug 106495 1\n",
            'level as integer works with min_level 3 and level 3'
        );
        is(
            $log[3], "bug 106495 2\n",
            'level as integer works with min_level 3 and level 4'
        );
        is(
            $log[4], undef,
            'using integer level works with min_level 3 and level 1'
        );
    }
);

subtest(
    'more levels as integers',
    sub {
        my $dispatch = Log::Dispatch->new;
        my $log = File::Spec->catdir( $tempdir, 'emerg.log' );

        $dispatch->add(
            Log::Dispatch::File->new(
                name      => 'file1',
                min_level => 0,
                filename  => $log,
            )
        );

        $dispatch->log( level => 0, message => "bug 106495 0\n" );
        $dispatch->log( level => 1, message => "bug 106495 1\n" );
        $dispatch->log( level => 2, message => "bug 106495 2\n" );
        $dispatch->log( level => 3, message => "bug 106495 3\n" );
        $dispatch->log( level => 4, message => "bug 106495 4\n" );
        $dispatch->log( level => 5, message => "bug 106495 5\n" );
        $dispatch->log( level => 6, message => "bug 106495 6\n" );
        $dispatch->log( level => 7, message => "bug 106495 7\n" );

        open my $fh, '<', $log or die $!;
        my @log = <$fh>;
        close $fh or die $!;

        is( $log[0], "bug 106495 0\n", 'at level 0, int works' );
        is( $log[1], "bug 106495 1\n", 'at level 1, int works' );
        is( $log[2], "bug 106495 2\n", 'at level 2, int works' );
        is( $log[3], "bug 106495 3\n", 'at level 3, int works' );
        is( $log[4], "bug 106495 4\n", 'at level 4, int works' );
        is( $log[5], "bug 106495 5\n", 'at level 5, int works' );
        is( $log[6], "bug 106495 6\n", 'at level 6, int works' );
        is( $log[7], "bug 106495 7\n", 'at level 7, int works' );
    }
);

done_testing();

## no critic (Modules::ProhibitMultiplePackages)
{
    package Log::Dispatch::String;

    use strict;

    use Log::Dispatch::Output;

    use base qw( Log::Dispatch::Output );

    sub new {
        my $proto = shift;
        my $class = ref $proto || $proto;
        my %p     = @_;

        my $self = bless { string => $p{string} }, $class;

        $self->_basic_init(%p);

        return $self;
    }

    sub log_message {
        my $self = shift;
        my %p    = @_;

        ${ $self->{string} } .= $p{message};
    }
}

#line 5000
sub _log_and_die {
    shift->log_and_die(@_);
}

{
#line 10000
    package Croaker;

    sub croak {
        shift->log_and_croak(
            level   => 'error',
            message => 'croaking a message'
        );
    }
}
