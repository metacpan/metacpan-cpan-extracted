package IPC::System::Options;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-06'; # DATE
our $DIST = 'IPC-System-Options'; # DIST
our $VERSION = '0.337'; # VERSION

use strict 'subs', 'vars';
use warnings;

use Proc::ChildError qw(explain_child_error);

my $log;
our %Global_Opts;

sub import {
    my $self = shift;

    my $caller = caller();
    my $i = 0;
    while ($i < @_) {
        # backtick is the older, deprecated name for readpipe
        if ($_[$i] =~ /\A(system|readpipe|backtick|run|start|import)\z/) {
            no strict 'refs';
            *{"$caller\::$_[$i]"} = \&{"$self\::" . $_[$i]};
        } elsif ($_[$i] =~ /\A-(.+)/) {
            die "$_[$i] requires an argument" unless $i < @_-1;
            $Global_Opts{$1} = $_[$i+1];
            $i++;
        } else {
            die "$_[$i] is not exported by ".__PACKAGE__;
        }
        $i++;
    }
}

sub _args2cmd {
    if (@_ == 1) {
        return $_[0];
    }
    if ($^O eq 'MSWin32') {
        require Win32::ShellQuote;
        return Win32::ShellQuote::quote_system_string(
            map { ref($_) eq 'SCALAR' ? $$_ : $_ } @_);
    } else {
        require String::ShellQuote;
        return join(
            " ",
            map { ref($_) eq 'SCALAR' ? $$_ : String::ShellQuote::shell_quote($_) } @_
        );
    }
}

sub _system_or_readpipe_or_run_or_start {
    my $which = shift;
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    for (keys %Global_Opts) {
        $opts->{$_} = $Global_Opts{$_} if !defined($opts->{$_});
    }
    my @args = @_;

    # check known options
    for (keys %$opts) {
        die "Unknown option '$_'"
            unless /\A(
                        capture_stdout|capture_stderr|capture_merged|
                        tee_stdout|tee_stderr|tee_merged|
                        chdir|dies?|dry_run|env|lang|log|max_log_output|shell|
                        exit_code_success_criteria|
                        stdin # XXX: only for run()
                    )\z/x;
    }

    my $opt_die = $opts->{die} || $opts->{dies};

    my $child_error;
    my $os_error = "";
    my $exit_code_is_success;
    my $extra_error;

    my $code_exit_code_is_success = sub {
        my $exit_code = shift;
        if (defined $opts->{exit_code_success_criteria}) {
            if    (ref $opts->{exit_code_success_criteria} eq ''      ) { return $exit_code == $opts->{exit_code_success_criteria} }
            elsif (ref $opts->{exit_code_success_criteria} eq 'ARRAY' ) { return (grep { $exit_code==$_ } @{ $opts->{exit_code_success_criteria} }) ? 1:0 }
            elsif (ref $opts->{exit_code_success_criteria} eq 'Regexp') { return $exit_code =~ $opts->{exit_code_success_criteria} }
            elsif (ref $opts->{exit_code_success_criteria} eq 'CODE'  ) { return $opts->{exit_code_success_criteria}->($exit_code) }
            else { die "exit_code_success_criteria must be a number, array of numbers, Regexp, or coderef" }
        } else {
            return $exit_code == 0;
        }
    };

    if ($opts->{log}) {
        require Log::ger;
        Log::ger->import;
    }

    my $cwd;
    if ($opts->{chdir}) {
        require Cwd;
        $cwd = Cwd::getcwd();
        if (!defined $cwd) { # checking $! is always true here, why?
            $log->error("Can't getcwd: $!") if $log;
            $child_error = -1;
            $exit_code_is_success = 0;
            $os_error = $!;
            $extra_error = "Can't getcwd";
            goto CHECK_RESULT;
        }
        unless (chdir $opts->{chdir}) {
            $log->error("Can't chdir to '$opts->{chdir}': $!") if $log;
            $child_error = -1;
            $exit_code_is_success = 0;
            $os_error = $!;
            $extra_error = "Can't chdir";
            goto CHECK_RESULT;
        }
    }

    # set ENV
    my %save_env;
    my %set_env;
    if ($opts->{lang}) {
        $set_env{LC_ALL}   = $opts->{lang};
        $set_env{LANGUAGE} = $opts->{lang};
        $set_env{LANG}     = $opts->{lang};
    }
    if ($opts->{env}) {
        $set_env{$_} = $opts->{env}{$_} for keys %{ $opts->{env} };
    }
    if (%set_env) {
        for (keys %set_env) {
            $save_env{$_} = $ENV{$_};
            $ENV{$_} = $set_env{$_};
        }
    }

    my $wa;
    my $res;

    my $capture_stdout_was_false;
    my $emulate_backtick;
    my $tmp_capture_stdout;

    my $code_capture = sub {
        my $doit = shift;

        if ($opts->{capture_stdout} && $opts->{capture_stderr}) {
            require Capture::Tiny;
            (${ $opts->{capture_stdout} }, ${ $opts->{capture_stderr} }) =
                &Capture::Tiny::capture($doit);
        } elsif ($opts->{capture_merged}) {
            require Capture::Tiny;
            ${ $opts->{capture_merged} } =
                &Capture::Tiny::capture_merged($doit);
        } elsif ($opts->{capture_stdout}) {
            require Capture::Tiny;
            ${ $opts->{capture_stdout} } =
                &Capture::Tiny::capture_stdout($doit);
        } elsif ($opts->{capture_stderr}) {
            require Capture::Tiny;
            ${ $opts->{capture_stderr} } =
                &Capture::Tiny::capture_stderr($doit);

        } elsif ($opts->{tee_stdout} && $opts->{tee_stderr}) {
            require Capture::Tiny;
            (${ $opts->{tee_stdout} }, ${ $opts->{tee_stderr} }) =
                &Capture::Tiny::tee($doit);
        } elsif ($opts->{tee_merged}) {
            require Capture::Tiny;
            ${ $opts->{tee_merged} } =
                &Capture::Tiny::tee_merged($doit);
        } elsif ($opts->{tee_stdout}) {
            require Capture::Tiny;
            ${ $opts->{tee_stdout} } =
                &Capture::Tiny::tee_stdout($doit);
        } elsif ($opts->{tee_stderr}) {
            require Capture::Tiny;
            ${ $opts->{tee_stderr} } =
                &Capture::Tiny::tee_stderr($doit);
        } else {
            $doit->();
        }
    };

    if ($which eq 'system') {

        if ($opts->{log} || $opts->{dry_run}) {
            if ($opts->{log}) {
                no strict 'refs';
                my $routine;
                my $label = "";
                if ($opts->{dry_run}) {
                    $label = "[DRY RUN] ";
                    $routine = "log_info";
                } else {
                    $routine = "log_trace";
                }
                $routine->("%ssystem(%s), env=%s", $label, \@args, \%set_env);
            } else {
                warn "[DRY RUN] system("._args2cmd(@args).")\n";
            }
            if ($opts->{dry_run}) {
                $child_error = 0;
                $exit_code_is_success = 1;
                $res = "";
                goto CHECK_RESULT;
            }
        }

        my $doit = sub {
            if ($opts->{shell}) {
                # force the use of shell
                $res = system _args2cmd(@args);
            } elsif (defined $opts->{shell}) {
                # forbid shell
                $res = system {$args[0]} @args;
            } else {
                # might or might not use shell (if @args == 1)
                $res = system @args;
            }
            $child_error = $?;
            $exit_code_is_success = $code_exit_code_is_success->($? < 0 ? $? : $? >> 8);
            $os_error = $!;
        };
        $code_capture->($doit);

    } elsif ($which eq 'readpipe') {

        $wa = wantarray;

        if ($opts->{log} || $opts->{dry_run}) {
            if ($opts->{log}) {
                no strict 'refs';
                my $routine;
                my $label = "";
                if ($opts->{dry_run}) {
                    $label = "[DRY RUN] ";
                    $routine = "log_info";
                } else {
                    $routine = "log_trace";
                }
                $routine->("%sreadpipe(%s), env=%s", $label, _args2cmd(@args), \%set_env);
            } else {
                warn "[DRY RUN] readpipe("._args2cmd(@args).")\n";
            }
            if ($opts->{dry_run}) {
                $child_error = 0;
                $exit_code_is_success = 1;
               $res = "";
                goto CHECK_RESULT;
            }
        }

        # we want to avoid the shell, so we don't use the builtin backtick.
        # instead, we emulate backtick by system + capturing the output
        if (defined $opts->{shell} && !$opts->{shell}) {
            $emulate_backtick++;
            die "Currently cannot backtick() with options shell=0 and capture_merged|tee_*"
                if $opts->{capture_merged} || $opts->{tee_stdout} || $opts->{tee_stderr} || $opts->{tee_merged};
            if (!$opts->{capture_stdout}) {
                $capture_stdout_was_false++;
                $opts->{capture_stdout} = \$tmp_capture_stdout;
            }
        }

        my $doit = sub {
            if ($emulate_backtick) {
                # we don't want shell so we have to emulate backtick with system
                # + capture the output ourselves
                system {$args[0]} @args;
            } else {
                my $cmd = _args2cmd(@args);
                #warn "cmd for backtick: " . $cmd;
                # use backtick, which uses the shell
                if ($wa) {
                    $res = [`$cmd`];
                } else {
                    $res = `$cmd`;
                }
            }
            $child_error = $? < 0 ? $? : $? >> 8;
            $exit_code_is_success = $code_exit_code_is_success->($? < 0 ? $? : $? >> 8);
            $os_error = $!;
        };
        $code_capture->($doit);

        if ($emulate_backtick) {
            $res = $capture_stdout_was_false ? $tmp_capture_stdout :
                ${ $opts->{capture_stdout} };
            $res = [split /^/m, $res] if $wa;
            $opts->{capture_stdout} = undef if $capture_stdout_was_false;
        }

        # log output
        if ($opts->{log}) {
            my $res_show;
            if (defined $opts->{max_log_output}) {
                $res_show = '';
                if ($wa) {
                    for (@$res) {
                        if (length($res_show) + length($_) >=
                                $opts->{max_log_output}) {
                            $res_show .= substr(
                                $_,0,$opts->{max_log_output}-length($res_show));
                            last;
                        } else {
                            $res_show .= $_;
                        }
                    }
                } else {
                    if (length($res) > $opts->{max_log_output}) {
                        $res_show = substr($res, 0, $opts->{max_log_output});
                    }
                }
            }
            log_trace("result of readpipe(): %s (%d bytes)",
                      defined($res_show) ? $res_show : $res,
                      defined($res_show) ?
                          $opts->{max_log_output} : length($res))
                if $exit_code_is_success;
        }

    } elsif ($which eq 'run' || $which eq 'start') {

        if ($opts->{log} || $opts->{dry_run}) {
            if ($opts->{log}) {
                no strict 'refs';
                my $routine;
                my $label = "";
                if ($opts->{dry_run}) {
                    $label = "[DRY RUN] ";
                    $routine = "log_info";
                } else {
                    $routine = "log_trace";
                }
                $routine->("%srun(%s), env=%s", $label,
                           join(", ", @args), \%set_env);
            } else {
                warn "[DRY RUN] $which(".join(", ", @args).")\n";
            }
            if ($opts->{dry_run}) {
                $child_error = 0;
                $exit_code_is_success = 1;
                $res = "";
                goto CHECK_RESULT;
            }
        }

        require IPC::Run;
        my $func = $which eq 'run' ? "IPC::Run::run" : "IPC::Run::start";
        $res = &{$func}(
            \@args,
            defined($opts->{stdin}) ? \$opts->{stdin} : \*STDIN,
            sub {
                if ($opts->{capture_stdout}) {
                    if (ref $opts->{capture_stdout} eq 'CODE') {
                        $opts->{capture_stdout}->($_[0]);
                    } else {
                        ${$opts->{capture_stdout}} .= $_[0];
                    }
                } else {
                    print $_[0];
                }
            }, # out
            sub {
                if ($opts->{capture_stderr}) {
                    if (ref $opts->{capture_sderr} eq 'CODE') {
                        $opts->{capture_sderr}->($_[0]);
                    } else {
                        ${$opts->{capture_stderr}} .= $_[0];
                    }
                } else {
                    print STDERR $_[0];
                }
            }, # err
        );
        if ($which eq 'run') {
            $child_error = $?;
            $exit_code_is_success = $code_exit_code_is_success->($? < 0 ? $? : $? >> 8);
            $os_error = $!;
        } else {
            $child_error = 0;
            $exit_code_is_success = 1;
            $os_error = "";
        }

    } # which

    # restore ENV
    if (%save_env) {
        for (keys %save_env) {
            if (defined $save_env{$_}) {
                $ENV{$_} = $save_env{$_};
            } else {
                undef $ENV{$_};
            }
        }
    }

    # restore previous working directory
    if ($cwd) {
        unless (chdir $cwd) {
            $log->error("Can't chdir back to '$cwd': $!") if $log;
            $child_error ||= -1;
            $os_error = $!;
            $extra_error = "Can't chdir back";
            goto CHECK_RESULT;
        }
    }

  CHECK_RESULT:
    unless ($exit_code_is_success) {
        if ($opts->{log} || $opt_die) {
            my $msg = sprintf(
                "%s(%s) failed: %s (%s)%s%s%s",
                $which,
                join(" ", @args),
                defined $extra_error ? "" : $child_error,
                defined $extra_error ? "$extra_error: $os_error" : explain_child_error($child_error, $os_error),
                (ref($opts->{capture_stdout}) ?
                     ", captured stdout: <<" .
                     (defined ${$opts->{capture_stdout}} ? ${$opts->{capture_stdout}} : ''). ">>" : ""),
                (ref($opts->{capture_stderr}) ?
                     ", captured stderr: <<" .
                     (defined ${$opts->{capture_stderr}} ? ${$opts->{capture_stderr}} : ''). ">>" : ""),
                (ref($opts->{capture_merged}) ?
                     ", captured merged: <<" .
                     (defined ${$opts->{capture_merged}} ? ${$opts->{capture_merged}} : ''). ">>" : ""),
            );
            log_error($msg) if $opts->{log};
            die $msg if $opt_die;
        }
    }

    if ($which ne 'start') {
        $? = $child_error;
    }

    return $wa && $which ne 'run' && $which ne 'start' ? @$res : $res;
}

sub system {
    _system_or_readpipe_or_run_or_start('system', @_);
}

# backtick is the older, deprecated name for readpipe
sub backtick {
    _system_or_readpipe_or_run_or_start('readpipe', @_);
}

sub readpipe {
    _system_or_readpipe_or_run_or_start('readpipe', @_);
}

sub run {
    _system_or_readpipe_or_run_or_start('run', @_);
}

sub start {
    _system_or_readpipe_or_run_or_start('start', @_);
}

1;
# ABSTRACT: Perl's system() and readpipe/qx replacement, with options

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::System::Options - Perl's system() and readpipe/qx replacement, with options

=head1 VERSION

This document describes version 0.337 of IPC::System::Options (from Perl distribution IPC-System-Options), released on 2020-06-06.

=head1 SYNOPSIS

 use IPC::System::Options qw(system readpipe run start);

 # use exactly like system()
 system(...);

 # use exactly like readpipe() (a.k.a. qx a.k.a. `` a.k.a. the backtick
 # operator). if you import readpipe, you'll override the backtick operator with
 # this module's version (along with your chosen settings).
 my $res = readpipe(...);
 $res = `...`;

 # but these functions accept an optional hash first argument to specify options
 system({...}, ...);
 $res = readpipe({...}, ...);

 # run without shell, even though there is only one argument
 system({shell=>0}, "ls");
 system({shell=>0}, "ls -lR");          # will fail, as there is no 'ls -lR' binary
 $res = readpipe({shell=>0}, "ls -lR"); # ditto

 # force shell, even though there are multiple arguments (arguments will be
 # quoted and joined together for you, including proper quoting on Win32).
 system({shell=>1}, "perl", "-e", "print 123"); # will print 123
 $res = readpipe({shell=>1}, "perl", "-e", "print 123");

 # note that to prevent the quoting mechanism from quoting some special
 # characters (like ">") you can use scalar references, e.g.:
 system({shell=>1}, "ls", "-laR",  ">", "/root/ls-laR"); # fails, because the arguments are quoted so the command becomes: ls '-laR' '>' '/root/ls-laR'
 system({shell=>1}, "ls", "-laR", \">", "/root/ls-laR"); # works

 # set LC_ALL/LANGUAGE/LANG environment variable
 $res = readpipe({lang=>"de_DE.UTF-8"}, "df");

 # log using Log::ger, die on failure
 system({log=>1, die=>1}, "blah", ...);

 # chdir first before running program (and chdir back afterwards)
 system({chdir => "/tmp", die => 1}, "some-program");

Set default options for all calls (prefix each option with dash):

 use IPC::System::Options 'system', 'readpipe', -log=>1, -die=>1;

C<run()> is like C<system()> but uses L<IPC::Run>'s C<run()> instead of
C<system()>:

 run('ls');

 # also accepts an optional hash first argument. some additional options that
 # run() accepts: stdin.
 run({capture_stdout => \$stdout, capture_stderr => \$stderr}, 'ls', '-l');

C<start()> is like C<run()> but uses L<IPC::Run>'s C<start()> instead of
C<run()> to run program in the background. The result is a handle (see
L<IPC::Run> for more details) which you can then call C<finish()>, etc on.

 my $h = start('ls', '-l');
 ...
 $h->finish;

=head1 DESCRIPTION

=for Pod::Coverage ^(backtick)$

=head1 FUNCTIONS

=head2 system([ \%opts ], @args)

Just like perl's C<system()> except that it accepts an optional hash first
argument to specify options. Currently known options:

=over

=item * shell => bool

Can be set to 0 to always avoid invoking the shell. The default is to use the
shell under certain conditions, like perl's C<system()>. But unlike perl's
C<system()>, you can force shell usage even though you pass multiple arguments
(in which case, the arguments will be quoted for you, including proper quoting
on Win32).

=item * lang => str

Temporarily set locale-related environment variables: C<LC_ALL> (this is the
highest precedence, even higher than the other C<LC_*> variables including
C<LC_MESSAGES>), C<LANGUAGE> (this is used in Linux, with precedence higher than
C<LANG> but lower than C<LC_*>), and C<LANG>.

Of course you can set the environment variables manually (or use the C<env>
option), this option is just for convenience.

=item * env => hashref

Temporarily set environment variables.

=item * log => bool

If set to true, then will log invocation as well as return/result value. Will
log using L<Log::ger> at the C<trace> level.

=item * die => bool

If set to true, will die on failure.

=item * capture_stdout => scalarref

Capture stdout using L<Capture::Tiny>.

Cannot be used together with C<tee_*> or C<capture_merged>.

=item * capture_stderr => scalarref

Capture stderr using L<Capture::Tiny>.

Cannot be used together with C<tee_*> or C<capture_merged>.

=item * capture_merged => scalarref

Capture stdout and stderr in a single variable using L<Capture::Tiny>'s
C<capture_merged>.

Cannot be used together with C<tee_*>, C<capture_stdout>, or C<capture_stderr>.

=item * tee_stdout => scalarref

Tee stdout using L<Capture::Tiny>.

Cannot be used together with C<capture_*> or C<tee_merged>.

=item * tee_stderr => scalarref

Capture stderr using L<Capture::Tiny>.

Cannot be used together with C<capture_*> or C<tee_merged>.

=item * tee_merged => scalarref

Capture stdout and stderr in a single variable using L<Capture::Tiny>'s
C<capture_merged>.

Cannot be used together with C<capture_*>, C<tee_stdout>, or C<tee_stderr>.

=item * chdir => str

Attempt to change to specified directory first and change back to the original
directory after the command has been run. This is a convenient option so you can
do this kind of task in a single call:

 {
     my $cwd = getcwd();
     chdir $dir or die;
     system(...);
     chdir $cwd or die;
 }

If the attempt to chdir before command execution fails, will die if C<die>
option is set to true. Otherwise, C<$!> (OS error) will be set to the C<chdir()>
error and to minimize surprise C<$?> (child exit code) will also be set to
non-zero value (-1) even though at this point no child process has been run.

If the attempt to chdir back (after command execution) fails, will die if C<die>
option is set to true. Otherwise, C<$!> will be set to the C<chdir()> error and
C<$?> will be set to -1 only if C<$?> is zero. So if the command fails, C<$?>
will contain the exit code of the command.

=item * dry_run => bool

If set to true, then will only display what would be executed to STDERR (or log
at C<warn> level, if C<log> option is true) instead of actually executing the
command.

Will set C<$?> (child exit code) to 0.

An example of how this option can be used:

 system({ dry_run => $ENV{DRY_RUN} }, ...);

This will allow you to run script in dry-run mode by setting environment
variable.

=item * exit_code_success_criteria => int|array[int]|Regexp|code

Specify which command exit codes are to be marked as success. For example, exit
code 1 for the B<diff> command does not signify an error; it just means that the
two input files are different. So in this case you can either specify one of:

 exit_code_success_criteria => [0,1]
 exit_code_success_criteria => qr/\A(0|1)\z/
 exit_code_success_criteria => sub { $_[0] == 0 || $_[0] == 1 }

By default, if this option is not specified, non-zero exit codes count as
failure.

Currently this only affects logging: when exit code is considered non-success, a
warning log is produced and C<readpipe()> does not log the result.

=back

=head2 readpipe([ \%opts ], @args)

Just like perl's C<readpipe()> (a.k.a. C<qx()> a.k.a. C<``> a.k.a. the backtick
operator) except that it accepts an optional hash first argument to specify
options. And it can accept multiple arguments (in which case, the arguments will
be quoted for you, including proper quoting on Win32).

Known options:

=over

=item * lang => str

See option documentation in C<system()>.

=item * env => hash

See option documentation in C<system()>.

=item * log => bool

See option documentation in C<system()>.

=item * die => bool

See option documentation in C<system()>.

=item * capture_stdout => scalarref

See option documentation in C<system()>.

=item * capture_stderr => scalarref

See option documentation in C<system()>.

=item * capture_merged => scalarref

See option documentation in C<system()>.

=item * tee_stdout => scalarref

See option documentation in C<system()>.

=item * tee_stderr => scalarref

See option documentation in C<system()>.

=item * tee_merged => scalarref

See option documentation in C<system()>.

=item * max_log_output => int

If set, will limit result length being logged. It's a good idea to set this
(e.g. to 1024) if you expect some command to return large output.

=item * chdir => str

See option documentation in C<system()>.

=item * dry_run => bool

See option documentation in C<system()>.

=item * exit_code_success_criteria => int|array[int]|Regexp|code

See option documentation in C<system()>.

=back

=head2 run([ \%opts ], @args)

Like C<system()>, but uses L<IPC::Run>'s C<run()>. Known options:

=over

=item * lang => str

See option documentation in C<system()>.

=item * env => hash

See option documentation in C<system()>.

=item * log => bool

See option documentation in C<system()>.

=item * die => bool

See option documentation in C<system()>.

=item * capture_stdout => scalarref|coderef

See option documentation in C<system()>.

=item * capture_stderr => scalarref|coderef

See option documentation in C<system()>.

=item * stdin => scalar

Supply standard input.

=item * chdir => str

See option documentation in C<system()>.

=item * dry_run => bool

See option documentation in C<system()>.

=item * exit_code_success_criteria => int|array[int]|Regexp|code

See option documentation in C<system()>.

=back

=head2 start([ \%opts ], @args)

Like C<run()>, but uses L<IPC::Run>'s C<start()>. For known options, see
C<run()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/IPC-System-Options>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-IPC-System-Options>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-System-Options>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
