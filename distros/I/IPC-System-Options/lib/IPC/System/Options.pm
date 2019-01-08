package IPC::System::Options;

our $DATE = '2019-01-07'; # DATE
our $VERSION = '0.331'; # VERSION

use strict;
use warnings;

use Proc::ChildError qw(explain_child_error);
use String::ShellQuote;

my $log;
our %Global_Opts;

sub import {
    my $self = shift;

    my $caller = caller();
    my $i = 0;
    while ($i < @_) {
        # backtick is the older, deprecated name for readpipe
        if ($_[$i] =~ /\A(system|readpipe|backtick|run|import)\z/) {
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

sub _quote {
    if (@_ == 1) {
        return $_[0];
    }

    if ($^O eq 'MSWin32') {
        require Win32::ShellQuote;
        return Win32::ShellQuote::quote_system_string(
            map { ref($_) eq 'SCALAR' ? $$_ : $_ } @_);
    } else {
        return join(
            " ",
            map { ref($_) eq 'SCALAR' ? $$_ : shell_quote($_) } @_
        );
    }
}

sub _system_or_readpipe_or_run {
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
                        chdir|dies?|dry_run|env|lang|log||max_log_output|shell|
                        stdin # XXX: only for run()
                    )\z/x;
    }

    my $opt_die = $opts->{die} || $opts->{dies};

    my $exit_code;
    my $os_error = "";
    my $extra_error;

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
            $exit_code = -1;
            $os_error = $!;
            $extra_error = "Can't getcwd";
            goto CHECK_RESULT;
        }
        unless (chdir $opts->{chdir}) {
            $log->error("Can't chdir to '$opts->{chdir}': $!") if $log;
            $exit_code = -1;
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
                warn "[DRY RUN] system(".join(", ", @args).")\n";
            }
            if ($opts->{dry_run}) {
                $exit_code = 0;
                $res = "";
                goto CHECK_RESULT;
            }
        }

        my $doit = sub {
            if ($opts->{shell}) {
                # force the use of shell
                $res = system _quote(@args);
            } elsif (defined $opts->{shell}) {
                # forbid shell
                $res = system {$args[0]} @args;
            } else {
                # might or might not use shell (if @args == 1)
                $res = system @args;
            }
            $exit_code = $?;
            $os_error = $!;
        };
        $code_capture->($doit);

    } elsif ($which eq 'readpipe') {

        $wa = wantarray;
        my $cmd = _quote(@args);

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
                $routine->("%sreadpipe(%s), env=%s", $label, $cmd, \%set_env);
            } else {
                warn "[DRY RUN] readpipe($cmd)\n";
            }
            if ($opts->{dry_run}) {
                $exit_code = 0;
                $res = "";
                goto CHECK_RESULT;
            }
        }

        my $doit = sub {
            if ($wa) {
                $res = [`$cmd`];
            } else {
                $res = `$cmd`;
            }
            $exit_code = $?;
            $os_error = $!;
        };
        $code_capture->($doit);

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
                unless $exit_code;
        }

    } else {

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
                warn "[DRY RUN] run(".join(", ", @args).")\n";
            }
            if ($opts->{dry_run}) {
                $exit_code = 0;
                $res = "";
                goto CHECK_RESULT;
            }
        }

        require IPC::Run;
        $res = IPC::Run::run(
            \@args,
            defined($opts->{stdin}) ? \$opts->{stdin} : \*STDIN,
            sub {
                if ($opts->{capture_stdout}) {
                    ${$opts->{capture_stdout}} .= $_[0];
                } else {
                    print $_[0];
                }
            }, # out
            sub {
                if ($opts->{capture_stderr}) {
                    ${$opts->{capture_stderr}} .= $_[0];
                } else {
                    print STDERR $_[0];
                }
            }, # err
        );
        $exit_code = $?;
        $os_error = $!;

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
            $exit_code ||= -1;
            $os_error = $!;
            $extra_error = "Can't chdir back";
            goto CHECK_RESULT;
        }
    }

  CHECK_RESULT:
    if ($exit_code) {
        if ($opts->{log} || $opt_die) {
            my $msg = sprintf(
                "%s(%s) failed: %s (%s)%s%s%s",
                $which,
                join(" ", @args),
                defined $extra_error ? "" : $exit_code,
                defined $extra_error ? "$extra_error: $os_error" : explain_child_error($exit_code, $os_error),
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

    $? = $exit_code;

    return $wa && $which ne 'run' ? @$res : $res;
}

sub system {
    _system_or_readpipe_or_run('system', @_);
}

# backtick is the older, deprecated name for readpipe
sub backtick {
    _system_or_readpipe_or_run('readpipe', @_);
}

sub readpipe {
    _system_or_readpipe_or_run('readpipe', @_);
}

sub run {
    _system_or_readpipe_or_run('run', @_);
}

1;
# ABSTRACT: Perl's system() and readpipe/qx replacement, with options

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::System::Options - Perl's system() and readpipe/qx replacement, with options

=head1 VERSION

This document describes version 0.331 of IPC::System::Options (from Perl distribution IPC-System-Options), released on 2019-01-07.

=head1 SYNOPSIS

 use IPC::System::Options qw(system readpipe run);

 # use exactly like system()
 system(...);

 # use exactly like readpipe() (a.k.a. qx a.k.a. `` a.k.a. the backtick operator)
 my $res = readpipe(...);
 $res = `...`;

 # but these functions accept an optional hash first argument to specify options
 system({...}, ...);
 readpipe({...}, ...);

 # run without shell, even though there is only one argument
 system({shell=>0}, "ls");
 system({shell=>0}, "ls -lR"); # will fail, as there is no 'ls -lR' binary

 # force shell, even though there are multiple arguments (arguments will be
 # quoted for you, including proper quoting on Win32).
 system({shell=>1}, "ls", "-laR");

 # note that to prevent the quoting mechanism from quoting some special
 # characters (like ">") you can use scalar references, e.g.:
 system({shell=>1}, "ls", "-laR", \">", "/root/ls-laR");

 # set LC_ALL/LANGUAGE/LANG environment variable
 $res = readpipe({lang=>"de_DE.UTF-8"}, "df");

 # log using Log::Any, die on failure
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
log using L<Log::Any> at the C<trace> level.

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

=item * stdin => scalar

Supply standard input.

=item * chdir => str

See option documentation in C<system()>.

=item * dry_run => bool

See option documentation in C<system()>.

=back

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

This software is copyright (c) 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
