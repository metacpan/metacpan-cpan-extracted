package IPC::Exe;

use 5.008_008;

use warnings;
use strict;

BEGIN {
    require Exporter;
    *import = \&Exporter::import;

    our $VERSION   = "2.002001";
    our @EXPORT_OK = qw(exe bg);
}

use Carp qw(carp croak);
use Data::Dumper qw(Dumper);
use File::Spec ();
use Scalar::Util qw(tainted);
use Symbol qw(gensym);
use Time::HiRes qw(usleep);

++$Carp::Internal{$_} for __PACKAGE__;

use constant NON_UNIX => ($^O =~ /^(?:MSWin32|os2)$/);
use constant OPEN_RDWR_RX => qr/^\s*(\d*)\s*(\+?[<>].*)/;

# default environment variables to check for taint
our @TAINT_ENV = qw(PATH PATHEXT IFS CDPATH ENV BASH_ENV PERL5SHELL);

our $is_forked = 0;

# if set, fallback to forked child/parent process to ensure execution
our $bg_fallback = 0;

my $DEVNULL = File::Spec->devnull();

sub _reftype { Scalar::Util::reftype($_[0]) || "" }
sub _is_fh { eval { defined(fileno($_[0])) } }

sub _stringify_args {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq  = 1;
    local $Data::Dumper::Terse  = 1;
    return join(", " => map { Dumper($_) } @_);
}

# exit thread/process
sub _quit {
    my $status = shift || 0;
    $^E = 0;
    $! = $status == -1 ? 255 : $status;
    $? = $! << 8;
    threads->exit($status) if threads->can("exit");
    exit($status);
}

# escape LIST to be passed to exec() in a portable way
sub _escape_cmd_list {
    return NON_UNIX
      ? map {
            (my $x = $_)
              =~ s/(\\"|")/$1 eq '"' ? '\\"' : '\\\\\\"'/ge;

            $x =~ /[\[\](){}<>'"`~!@^&+=|;,\s]/
              ? qq("$x")
              : $x;
        } @_
      : @_;
}

sub _check_taint {
    my (@bad_args, @bad_env);

    my $i = -1;
    for my $v (@_)
    {
        ++$i;
        push(@bad_args, [ $v, $i ]) if tainted($v);
    }
    for my $v (@TAINT_ENV)
    {
        push(@bad_env, $v) if tainted($ENV{$v});
    }

    # die if environment / arguments are tainted
    if (@bad_args || @bad_env)
    {
        croak("IPC::Exe::exe() called with tainted vars:\n  ",
            join("\n  " => map { "\$ENV{$_}" } @bad_env), "\n  ",
            join("\n  " => map { "<$_->[0]> at index $_->[1]" } @bad_args), "\n",
        );
    }

    return;
}

sub _fh_slot {
    my ($slots, $n) = @_;
    $n += 0;

    my $FH_name = qw(STDIN STDOUT STDERR)[$n] || "FH[$n]";
    my $FH = ($n <= 2)
      ? (\*STDIN, \*STDOUT, \*STDERR)[$n]
      : ($slots->[$n] ||= gensym());

    return ($FH, $FH_name);
}

sub exe {
    _check_taint(@_) if $] >= 5.008 && ${^TAINT};

    return () if @_ == 0;

    # exe(sub { .. }) returns (sub { .. }) itself
    return $_[0] if @_ == 1 && _reftype($_[0]) eq "CODE";

    my $args = \@_;
    return sub { _exe(@_ ? [ @_ ] : undef, @{ $args }) };
}
sub _exe {
    # record error variables
    my @status = ($?, -+-$!, -+-$^E, $@);

    # ref to arguments passed to closure
    my $_args = shift;

    # merge options hash reference, if available
    my %opt = (
        pid        => undef,
        stdin      => 0,
        stdout     => 0,
        stderr     => 0,
        autoflush  => 1,
        binmode_io => undef,
    );
    my $opt_ref = $_[0];
    if (_reftype($opt_ref) eq "HASH")
    {
        @opt{keys %{ $opt_ref }} = values %{ $opt_ref };
        shift;
    }

    # propagate $opt{binmode_io} to set binmode down chain of executions
    local $IPC::Exe::_binmode_io = defined($opt{binmode_io})
      ? $opt{binmode_io}
      : $IPC::Exe::_binmode_io;

    # propagate $opt{stdin} down chain of executions
    local $IPC::Exe::_stdin = $IPC::Exe::_stdin || !(!$opt{stdin});

    # setup input filehandle to write to STDIN
    my ($FOR_STDIN, $TO_STDIN);
    if ($opt{stdin})
    {
        pipe($FOR_STDIN, $TO_STDIN)
          or carp("IPC::Exe::exe() cannot create pipe to STDIN", "\n  ", $!)
          and return ();

        # make filehandle hot
        select((select($TO_STDIN), $| = 1)[0]) if $opt{autoflush};
    }

    # setup output filehandle to read from STDERR
    my ($FROM_STDERR, $BY_STDERR);
    if ($opt{stderr})
    {
        pipe($FROM_STDERR, $BY_STDERR)
          or carp("IPC::Exe::exe() cannot create pipe from STDERR", "\n  ", $!)
          and return ();

        # make filehandle hot
        select((select($BY_STDERR), $| = 1)[0]) if $opt{autoflush};
    }

    # obtain CODE references, if available, for READER & PREEXEC subroutines
    my ($Preexec, $Reader);
    $Preexec = shift if _reftype($_[0])  eq "CODE";
    $Reader  =   pop if _reftype($_[-1]) eq "CODE";

    # obtain redirects
    my @redirs;
    unshift(@redirs, pop) while ref($_[-1]);
    if (@redirs)
    {
        my $old_preexec;
        $old_preexec = $Preexec if $Preexec;

        $Preexec = sub {
            my @FHops;
            @FHops = $old_preexec->(@_) if $old_preexec;
            return (@FHops, @redirs);
        };
    }

    # what is left is the command LIST
    my @cmd_list = @_;

    # ban undefined values in LIST
    if (grep { !defined($_) } @cmd_list)
    {
        carp("IPC::Exe::exe() cannot execute undef argument(s) below:", "\n  ",
          _stringify_args(@cmd_list), "\n");
        return ();
    }

    # as a precaution, do not continue if no PREEXEC or LIST found
    return () unless defined($Preexec) || @cmd_list;

    # duplicate stdin to be restored later
    my $ORIGSTDIN;
    NON_UNIX
      ? open($ORIGSTDIN, "<&=STDIN")
      : open($ORIGSTDIN, "<&STDIN")
      or carp("IPC::Exe::exe() cannot dup STDIN", "\n  ", $!)
      and return ();

    # safe pipe open to forked child connected to opened filehandle
    my $gotchild = _pipe_from_fork(my $EXE_READ, my $EXE_GO);
    my $defined_child = defined($gotchild);

    # check if fork was successful
    unless ($defined_child)
    {
        carp("IPC::Exe::exe() cannot fork child", "\n  ", $!);
        return ();
    }

    # parent reads stdout of child process
    if ($gotchild)
    {
        # unneeded stuff
        undef $_ for $Preexec, $_args, @redirs;
        close($FOR_STDIN) if $FOR_STDIN;
        close($BY_STDERR) if $BY_STDERR;

        # set binmode if required
        if (defined($IPC::Exe::_binmode_io)
           && index($IPC::Exe::_binmode_io, ":") == 0)
        {
            my $layer = $IPC::Exe::_binmode_io;

            if ($opt{stdin})
            {
                binmode($TO_STDIN, $layer) or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() cannot set binmode STDIN_WRITEHANDLE for layer "$layer"
EOT
            }

            binmode($EXE_READ, $layer) or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() cannot set binmode STDOUT_READHANDLE for layer "$layer"
EOT
        }

        my (@ret, @status_reader);

        if ($Reader)
        {
            # non-Unix: reset to default $IPC::Exe::_preexec_wait time
            local $IPC::Exe::_preexec_wait;

            # temporarily replace stdin
            $IPC::Exe::_stdin
              ? open(*STDIN, "<&=", $EXE_READ)
              : open(*STDIN, "<&",  $EXE_READ)
                  or croak("IPC::Exe::exe() cannot replace STDIN", "\n  ", $!);

            # create local package-scope $IPC::Exe::PIPE
            local our $PIPE = $EXE_READ;

            ($?, $!, $^E, my $err) = @status;

            my $failed = ! eval {
                $@ = $err;
                @ret = $Reader->($gotchild, @cmd_list);
                $err = $@;
                1;
            };

            @status_reader = ($?, -+-$!, -+-$^E, $failed ? $@ : $err);

            # restore stdin
            NON_UNIX
              ? open(*STDIN, "<&=", $ORIGSTDIN)
              : open(*STDIN, "<&",  $ORIGSTDIN)
              or croak("IPC::Exe::exe() cannot restore STDIN", "\n  ", $!);

            die $status_reader[3] if $failed;
        }
        elsif (!$opt{stdout})
        {
            # default &READER just prints stdin
            while (my $read = <$EXE_READ>)
            {
                print $read;
            }
        }

        # do not wait for interactive children
        my $reap = 0;
        unless ($IPC::Exe::_stdin || $opt{stdout} || $opt{stderr})
        {
            $reap = waitpid($gotchild, 0);
            $status[0] = $?;
        }

        #print STDERR "reap> $gotchild : $reap | $status[0]\n";

        # record status and close pipe for default &READER
        if (!$Reader && !$opt{stdout})
        {
            $ret[0] = $status[0];
            close($EXE_READ);
        }

        my $ret_pid = $gotchild;

        # reading from failed exec
        if ($status[0] == -1 || $status[0] == 255 << 8) # 255 (assumed as failed exec)
        {
            # must correctly reap before we decide to return undef PID
            # if using default &READER, additionally check if we reaped -1
            #   and return -1 since it looks like a failed exec

            $ret_pid = undef
              if (!$Reader && !$opt{stdout} # using default &READER
                && ($reap == $gotchild || $reap == -1 || $reap == 0)
                && ($ret[0] = -1)) # return -1
              || $reap == $gotchild;
        }

        # writing to failed exec
        if ($status[0] == -1 && $Reader && $reap == $gotchild && @ret)
        {
            # child PID is undef if exec failed
            $ret[0] = undef;
        }

        # assign scalar references if provided
        ${ $opt{pid} }    = $ret_pid     if _reftype($opt{pid})    eq "SCALAR";
        ${ $opt{stdin} }  = $TO_STDIN    if _reftype($opt{stdin})  eq "SCALAR";
        ${ $opt{stdout} } = $EXE_READ    if _reftype($opt{stdout}) eq "SCALAR";
        ${ $opt{stderr} } = $FROM_STDERR if _reftype($opt{stderr}) eq "SCALAR";

        # collect child PIDs & filehandle(s)
        unshift(@ret,
                            _reftype($opt{pid})    ne "SCALAR" ? $ret_pid     : (),
            $opt{stdin}  && _reftype($opt{stdin})  ne "SCALAR" ? $TO_STDIN    : (),
            $opt{stdout} && _reftype($opt{stdout}) ne "SCALAR" ? $EXE_READ    : (),
            $opt{stderr} && _reftype($opt{stderr}) ne "SCALAR" ? $FROM_STDERR : (),
        );

        # restore exit status
        ($?, $!, $^E, $@) = @status_reader ? @status_reader : @status;

        undef $Reader;

        return @ret[0 .. $#ret]; # return LIST instead of ARRAY
    }
    else # child performs exec()
    {
        # set package-scope $IPC::Exe::is_forked
        $is_forked = 1;

        # disassociate any ties with parent
        untie(*STDIN);
        untie(*STDOUT);
        untie(*STDERR);

        # unneeded stuff
        undef $Reader;
        close($TO_STDIN)    if $TO_STDIN;
        close($FROM_STDERR) if $FROM_STDERR;

        # change STDIN if input filehandle was required
        if ($FOR_STDIN)
        {
            open(*STDIN, "<&=", $FOR_STDIN)
              or croak("IPC::Exe::exe() cannot change STDIN", "\n  ", $!);
        }

        # collect STDERR if error filehandle was required
        if ($BY_STDERR)
        {
            open(*STDERR, ">&=", $BY_STDERR)
              or croak("IPC::Exe::exe() cannot collect STDERR", "\n  ", $!);
        }

        # set binmode if required
        if (defined($IPC::Exe::_binmode_io)
           && index($IPC::Exe::_binmode_io, ":") == 0)
        {
            my $layer = $IPC::Exe::_binmode_io;

            binmode(*STDIN, $layer) and binmode(*STDOUT, $layer)
              or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() cannot set binmode STDIN and STDOUT for layer "$layer"
EOT
        }

        # call PREEXEC subroutine if defined
        my @FHops;
        if ($Preexec)
        {
            local ($?, $!, $^E, $@) = @status;
            @FHops = $Preexec->($_args ? @{ $_args } : ());
            undef $_ for $Preexec, $_args, @redirs;
        }

        # manually flush STDERR and STDOUT
        select((select(*STDERR), $| = ($|++, print "")[0])[0]) if _is_fh(*STDERR);
        select((select(*STDOUT), $| = ($|++, print "")[0])[0]) if _is_fh(*STDOUT);

        # only exec() LIST if defined
        unless (@cmd_list)
        {
            # non-Unix: signal parent "process" to restore filehandles
            if (NON_UNIX && _is_fh($EXE_GO))
            {
                print $EXE_GO "exe_no_exec\n";
                close($EXE_GO);
            }

            _quit(0);
        }

        # perform redirections
        my @FHs;
        for (@FHops)
        {
            if (ref($_))
            {
                my $is_sysopen = 0;

                if (_reftype($_) =~ /REF|SCALAR/)
                {
                    $_ = ${ $_ };
                    ++$is_sysopen;
                }

                # open / sysopen
                if (_reftype($_) eq "ARRAY")
                {
                    my @args = @{ $_ };
                    my $FH_name;

                    if (!$is_sysopen && defined($args[0]))
                    {
                        my ($src, $op) = ($args[0] =~ OPEN_RDWR_RX);

                        if (defined($op))
                        {
                            $src = (index($op, "<") == -1) ? 1 : 0
                              if $src eq "";

                            (my $FH, $FH_name) = _fh_slot(\@FHs, $src);
                            shift @args;
                            unshift @args, ($FH, $op);
                        }
                    }

                    my $error_msg =
                      "IPC::Exe::exe() failed "
                      . ($is_sysopen ? "sysopen" : "open") . "( "
                      . ($FH_name ? "$FH_name, " : "")
                      . _stringify_args(
                          $FH_name ? () : $args[0],
                          @args[1 .. $#args],
                      ) . " )";

                    croak($error_msg, "\n  ", $! = 22)
                      if $is_sysopen
                        ? (@args < 3 || @args > 4)
                        : (@args == 0);

                    $is_sysopen
                      ? (@args == 4
                          ? sysopen($args[0], $args[1], $args[2], $args[3])
                          : sysopen($args[0], $args[1], $args[2])
                        )
                      : open(
                            $args[0],
                            @args >= 2 ? $args[1] : (),
                            @args >= 3 ? $args[2] : (),
                            @args[3 .. $#args],
                        )
                          or croak($error_msg, "\n  ", $!);

                    next;
                }
            }

            next unless defined($_);

            # set binmode
            if (/^\s*([012])\s*(:.*)$/)
            {
                my $FH_name = qw(STDIN STDOUT STDERR)[$1];
                my $layer = $2;
                $layer = ":raw" if $layer eq ":";

                binmode((*STDIN, *STDOUT, *STDERR)[$1], $layer)
                  or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() cannot set binmode $FH_name for layer "$layer"
EOT
                next;
            }

            # silence filehandles
            if (/^\s*(\d*)\s*>\s*(?:null|#)\s*$/)
            {
                my $src = ($1 eq "") ? 1 : $1;
                my ($FH, $FH_name) = _fh_slot(\@FHs, $src);

                open($FH, ">", $DEVNULL)
                  or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() cannot silence $FH_name (does $DEVNULL exist?)
EOT
                next;
            }

            # swap filehandles
            if (/^\s*(\d+)\s*><\s*(\d+)\s*$/)
            {
                my ($FH1, $FH_name1) = _fh_slot(\@FHs, $1);
                my ($FH2, $FH_name2) = _fh_slot(\@FHs, $2);

                my $SWAP;
                local $! = 9;
                _is_fh($FH1) && _is_fh($FH2)
                  && open($SWAP, ">&", $FH1)
                  && open($FH1, ">&", $FH2)
                  && open($FH2, ">&=", $SWAP)
                  or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() cannot swap $FH_name1 and $FH_name2
EOT
                next;
            }

            # redirect/close filehandles
            my ($src, $op, $tgt) =
              /^\s*(\d*)\s*(\+?(?:<|>>?)&=?)\s*(\d+|-)\s*$/;

            if (defined($op))
            {
                $src = (index($op, "<") == -1) ? 1 : 0
                  if $src eq "";

                my ($FH1, $FH_name1) = _fh_slot(\@FHs, $src);

                if ($tgt eq "-")
                {
                    close($FH1) or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() failed to close $FH_name1
EOT
                    next;
                }

                my ($FH2, $FH_name2) = _fh_slot(\@FHs, $tgt);

                local $! = 9;
                _is_fh($FH2) && open($FH1, $op, $FH2)
                  or croak(<<"EOT", "  ", $!);
IPC::Exe::exe() failed redirect $FH_name1 $op $FH_name2
EOT
                next;
            }

            if ($_ =~ OPEN_RDWR_RX)
            {
                $_ = [ $_ ];
                redo;
            }
        }

        # non-Unix: escape command so that it feels Unix-like
        my @cmd = _escape_cmd_list(@cmd_list);

        # non-Unix: signal parent "process" to restore filehandles
        my $restore_fh = (NON_UNIX && _is_fh($EXE_GO));

        no warnings qw(exec);
        # XXX: be quiet about "Attempt to free unreferenced scalar" for Win32
        no warnings qw(internal);

        # assume exit status 255 indicates failed exec
        ($restore_fh ? print $EXE_GO "exe_with_exec\n" : 1)
          and exec { $cmd[0] } @cmd
          or carp("IPC::Exe::exe() failed to exec the command below", " - ", $!, "\n  ",
               _stringify_args(@cmd), "\n")
          and _quit(-1);
    }
}

sub bg {
    return () if @_ == 0;

    my $args = \@_;
    return sub { _bg(@_ ? [ @_ ] : undef, @{ $args }) };
}
sub _bg {
    # record error variables
    my @status = ($?, -+-$!, -+-$^E, $@);
    local ($?, $!, $^E, $@);

    # ref to arguments passed to closure
    my $_args = shift;

    # merge options hash reference, if available
    my %opt = (
        wait => 2,
    );
    my $opt_ref = $_[0];
    if (_reftype($opt_ref) eq "HASH")
    {
        @opt{keys %{ $opt_ref }} = values %{ $opt_ref };
        shift;
    }

    # CODE reference for BACKGROUND subroutine
    my $Background;
    $Background = shift if _reftype($_[0]) eq "CODE";

    # do not continue if no BACKGROUND found
    return () unless defined($Background);

    # non-Unix: set longer $IPC::Exe::_preexec_wait time
    local $IPC::Exe::_preexec_wait = 2;
    if (defined($opt{wait}) && $opt{wait} >= 0)
    {
        $IPC::Exe::_preexec_wait = $opt{wait};
    }

    # dup(2) stdout
    my $ORIGSTDOUT;
    open($ORIGSTDOUT, ">&STDOUT")
      or carp("IPC::Exe::bg() cannot dup STDOUT", "\n  ", $!)
      and return ();

    # double fork -- immediately wait() for child,
    #       and init daemon will wait() for grandchild, once child exits

    # safe pipe open to forked child connected to opened filehandle
    my $gotchild = _pipe_from_fork(my $BG_READ, my $BG_GO1);
    my $defined_child = defined($gotchild);

    # check if fork was successful
    unless ($defined_child)
    {
        if ($bg_fallback)
        {
            carp("IPC::Exe::bg() cannot fork child, will try fork again", "\n  ", $!);
        }
        else
        {
            carp("IPC::Exe::bg() cannot fork child", "\n  ", $!) and return ();
        }
    }

    # parent reads stdout of child process
    if ($gotchild)
    {
        # background: parent reads output from child,
        #                and waits for child to exit
        my $grandpid = readline($BG_READ);
        waitpid($gotchild, 0);
        my $status = $?;
        close($BG_READ);
        return $status ? $gotchild : -+-$grandpid;
    }
    else
    {
        # background: perform second fork
        my $gotgrand = NON_UNIX
          ? _pipe_from_fork(my $DUMMY, my $BG_GO2)
          : fork();
        my $defined_grand = defined($gotgrand);

        # check if second fork was successful
        if ($defined_child)
        {
            $defined_grand or carp(<<"EOT", "  ", $!);
IPC::Exe::bg() cannot fork grandchild, using child instead
 -> parent must wait
EOT
        }
        else
        {
            if ($defined_grand)
            {
                $gotgrand and carp(<<"EOT", "  ", $!);
IPC::Exe::bg() managed to fork child, using child now
 -> parent must wait
EOT
            }
            else
            {
                carp(<<"EOT", "  ", $!);
IPC::Exe::bg() cannot fork child again, using parent instead
 -> parent does all the work
EOT
            }
        }

        # send grand/child's PID to parent process somehow
        my $childpid;
        if ($defined_grand && $gotgrand)
        {
            if ($defined_child)
            {
                # child writes grandchild's PID to parent process
                print { *STDOUT } "$gotgrand\n";
            }
            else
            {
                # parent returns child's PID later
                $childpid = $gotgrand;
            }
        }

        # child exits once grandchild is forked
        # grandchild calls BACKGROUND subroutine
        unless ($gotgrand)
        {
            # set package-scope $IPC::Exe::is_forked
            $is_forked = 1;

            # disassociate any ties with parent
            untie(*STDIN);
            untie(*STDOUT);
            untie(*STDERR);

            # restore stdout
            open(*STDOUT, ">&=", $ORIGSTDOUT)
              or croak("IPC::Exe::bg() cannot restore STDOUT", "\n  ", $!);

            # non-Unix: signal parent/child "process" to restore filehandles
            if (NON_UNIX)
            {
                if (_is_fh($BG_GO2))
                {
                    print $BG_GO2 "bg2\n";
                    close($BG_GO2);
                }

                if (_is_fh($BG_GO1))
                {
                    print $BG_GO1 "bg1\n";
                    close($BG_GO1);
                }
            }

            # BACKGROUND subroutine does not need to return
            ($?, $!, $^E, $@) = @status;
            $Background->($_args ? @{ $_args } : ());
            undef $_ for $Background, $_args;
        }
        elsif (!$defined_child)
        {
            # parent must wait to reap child
            waitpid($gotgrand, 0);
        }

        #  $gotchild  $gotgrand    exit
        #  ---------  ---------    ----
        #   childpid   grandpid    both child & grandchild
        #   childpid    undef      child
        #    undef     childpid    child
        #    undef      undef      none (parent executes BACKGROUND subroutine)
        _quit(0)  if  $defined_child &&  $defined_grand;
        _quit(10) if  $defined_child && !$defined_grand;
        _quit(10) if !$defined_child &&  $defined_grand && !$gotgrand;

        # falls back here if forks were unsuccessful
        return $childpid;
    }
}

# child writes while parent reads
# simulate open(FILEHANDLE, "-|");
# http://perldoc.perl.org/perlfork.html#CAVEATS-AND-LIMITATIONS
sub _pipe_from_fork ($$) {
    my $pid;

    # cannot fork on these platforms
    return undef if $^O =~ /^(?:VMS|dos|MacOS|riscos|amigaos|vmesa)$/;

    if (NON_UNIX)
    {
        # dup(2) stdin/stdout/stderr to be restored later
        my ($ORIGSTDIN, $ORIGSTDOUT, $ORIGSTDERR);

        open($ORIGSTDIN,  "<&STDIN")
          or carp("IPC::Exe cannot dup STDIN",  "\n  ", $!)
          and return undef;

        open($ORIGSTDOUT, ">&STDOUT")
          or carp("IPC::Exe cannot dup STDOUT", "\n  ", $!)
          and return undef;

        open($ORIGSTDERR, ">&STDERR")
          or carp("IPC::Exe cannot dup STDERR", "\n  ", $!)
          and return undef;

        # create pipe for READHANDLE and WRITEHANDLE
        pipe($_[0], my $WRITE) or return undef;

        # create pipe for READYHANDLE and GOHANDLE
        pipe(my $READY, $_[1]) or return undef;
        select((select($_[1]), $| = 1)[0]);

        # fork is emulated with threads on Win32
        if (defined($pid = fork()))
        {
            if ($pid)
            {
                close($WRITE);
                close($_[1]);

                # block until signalled to GO!
                #print STDERR "go> " . readline($READY);
                readline($READY);
                close($READY);

                # restore filehandles after slight delay to allow exec to happen
                my $wait = 0; # default
                $wait = $IPC::Exe::_preexec_wait
                    if defined($IPC::Exe::_preexec_wait);

                usleep($wait * 1e6);
                #print STDERR "wait> $wait\n";

                open(*STDIN,  "<&=", $ORIGSTDIN)
                  or croak("IPC::Exe cannot restore STDIN",  "\n  ", $!);

                open(*STDOUT, ">&=", $ORIGSTDOUT)
                  or croak("IPC::Exe cannot restore STDOUT", "\n  ", $!);

                open(*STDERR, ">&=", $ORIGSTDERR)
                  or croak("IPC::Exe cannot restore STDERR", "\n  ", $!);
            }
            else
            {
                close($_[0]);
                close($READY);

                # file descriptors are not "process"-persistent on Win32
                open(*STDOUT, ">&=", $WRITE)
                  or croak("IPC::Exe cannot establish IPC after fork", "\n  ", $!);
            }
        }
    }
    else
    {
        # need this form to allow close($_[0]) to set $? properly
        $pid = open($_[0], "-|");
    }

    return $pid;
}

'IPC::Exe';


__END__

=pod

=head1 NAME

IPC::Exe - Execute processes or Perl subroutines & string them via IPC. Think shell pipes.


=head1 SYNOPSIS

  use IPC::Exe qw(exe bg);

  my @pids = &{
         exe qw( ls  /tmp  a.txt ), \"2>#",
      bg exe qw( sort -r ),
         exe sub { print "[", shift, "] 2nd cmd: @_\n"; print "three> $_" while <STDIN> },
      bg exe 'sort',
         exe "cat", "-n",
         exe sub { print "six> $_" while <STDIN>; print "[", shift, "] 5th cmd: @_\n" },
  };

is like doing the following in a modern Unix shell:

  ls /tmp a.txt 2> /dev/null | { sort -r | [perlsub] | { sort | cat -n | [perlsub] } & } &

except that C<[perlsub]> is really a perl child process with access to main program variables in scope.


=head1 DESCRIPTION

This module was written to provide a secure and highly flexible way to execute external programs with an intuitive syntax. In addition, more info is returned with each string of executions, such as the list of PIDs and C<$?> of the last external pipe process (see L</RETURN VALUES>). Execution uses C<exec> command, and the shell is B<never> invoked.

The two exported subroutines perform all the heavy lifting of forking and executing processes. In particular, C<exe( )> implements the C<KID_TO_READ> version of

  http://perldoc.perl.org/perlipc.html#Safe-Pipe-Opens

while C<bg( )> implements the double-fork technique illustrated at

  http://perldoc.perl.org/perlfaq8.html#How-do-I-start-a-process-in-the-background?


=head1 EXAMPLES

Let's dive right away into some examples. To begin:

  my $exit = system( "myprog $arg1 $arg2" );

can be replaced with

  my $exit = &{ exe 'myprog', $arg1, $arg2 };

C<exe( )> returns a LIST of PIDs, the last item of which is C<$?> (of default C<&READER>). To get the actual exit value C<$exitval>, shift right by eight C<<< $? >> 8 >>>.

Extending the previous example,

  my $exit = system( "myprog $arg1 $arg2 $arg3 > out.txt" );

can be replaced with

  my $exit = &{ exe 'myprog', $arg1, $arg2, [ '>', 'out.txt' ] };

The previous two examples will wait for 'myprog' to finish executing before continuing the main program.

Extending the previous example again,

  # cannot obtain $exit of 'myprog' because it is in background
  system( "myprog $arg1 $arg2 $arg3 > out.txt &" );

can be replaced with

  # just add 'bg' before 'exe' in previous example
  my $bg_pid = &{ bg exe 'myprog', $arg1, $arg2, [ '>', 'out.txt' ] };

Now, 'myprog' will be put in background and the main program will continue without waiting.

To monitor the exit value of a background process:

  my $bg_pid = &{
      bg sub {
             # same as 2nd previous example
             my ($pid) = &{
                 exe 'myprog', $arg1, $arg2, [ '>', 'out.txt' ]
             };

             # check if exe() was successful
             defined($pid) or die("Failed to run process in background");

             # handle exit value here
             print STDERR "background exit value: " . ($? >> 8) . "\n";
         }
  } or die("Failed to send process to background");

Instead of using backquotes or C<qx( )>,

  # slurps entire STDOUT into memory
  my @stdout = `$program @ARGV`;

  # handle STDOUT here
  for my $line (@stdout)
  {
      print "read_in> $line";
  }

we can read the C<STDOUT> of one process with:

  my ($pid) = &{
      # execute $program with arguments
      exe $program, @ARGV,

      # handle STDOUT here
      sub {
          while (my $line = <STDIN>)
          {
              print "read_in> $line";
          }

          # set exit status of main program
          waitpid($_[0], 0);
      },
  };

  # check if exe() was successful
  defined($pid) or die("Failed to run process");

  # exit value of $program
  my $exitval = $? >> 8;

Perform tar copy of an entire directory:

  use Cwd qw(chdir);

  my @pids = &{
      exe sub { chdir $source_dir or die $! }, qw(/bin/tar  cf - .),
      exe sub { chdir $target_dir or die $! }, qw(/bin/tar xBf -),
  };

  # check if exe()'s were successful
  defined($pids[0]) && defined($pids[1])
    or die("Failed to run processes");

  # was un-tar successful?
  my $error = pop(@pids);

Here is an elaborate example to pipe C<STDOUT> of one process to the C<STDIN> of another, consecutively:

  my @pids = &{
      # redirect STDERR to STDOUT
      exe $program, @ARGV, \"2>&1",

      # 'perl' receives STDOUT of $program via STDIN
      exe sub {
              my ($pid) = &{
                  exe qw(perl -e), 'print "read_in> $_" while <STDIN>; exit 123',
              };

              # check if exe() was successful
              defined($pid) or die("Failed to run process");

              # handle exit value here
              print STDERR "in-between exit value: " . ($? >> 8) . "\n";

              # this is executed in child process
              # no need to return
          },

      # 'sort' receives STDOUT of 'perl'
      exe qw(sort -n),

      # [perlsub] receives STDOUT of 'sort'
      exe sub {
              # find out command of previous pipe process
              # if @_[1..$#_] is an empty list, previous process was a [perlsub]
              my ($child_pid, $prog, @args) = @_;

              # output: "last_pipe[12345]> sort -n"
              print STDERR "last_pipe[$child_pid]> $prog @args\n";

              # print sorted, 'perl' filtered, output of $program
              print while <STDIN>;

              # find out exit value of previous 'sort' pipe process
              waitpid($_[0], 0);
              warn("Bad exit for: @_\n") if $?;

              return $?;
          },
  };

  # check if exe()'s were successful
  defined($pids[0]) && defined($pids[1]) && defined($pids[2])
    or die("Failed to run processes");

  # obtain exit value of last process on pipeline
  my $exitval = pop(@pids) >> 8;

Shown below is an example of how to capture C<STDERR> and C<STDOUT> after sending some input to C<STDIN> of the child process:

  # reap child processes 'xargs' when done
  local $SIG{CHLD} = 'IGNORE';

  # like IPC::Open3; filehandles are returned on-the-fly
  my ($pid, $TO_STDIN, $FROM_STDOUT, $FROM_STDERR) = &{
      exe +{ stdin => 1, stdout => 1, stderr => 1 }, qw(xargs ls -ld),
  };

  # check if exe() was successful
  defined($pid) or die("Failed to run process");

  # ask 'xargs' to 'ls -ld' three files
  print $TO_STDIN "/bin\n";
  print $TO_STDIN "does_not_exist\n";
  print $TO_STDIN "/etc\n";

  # cause 'xargs' to flush its stdout
  close($TO_STDIN);

  # print captured outputs
  print "stderr> $_" while <$FROM_STDERR>;
  print "stdout> $_" while <$FROM_STDOUT>;

  # close filehandles
  close($FROM_STDOUT);
  close($FROM_STDERR);

Of course, more C<exe( )> calls may be chained together as needed:

  # reap child processes 'xargs' when done
  local $SIG{CHLD} = 'IGNORE';

  # like IPC::Open2; filehandles are returned on-the-fly
  my ($pid1, $TO_STDIN, $pid2, $FROM_STDOUT) = &{
      exe +{ stdin  => 1 }, sub { "2>&1" }, qw(perl -ne), 'print STDERR "360.0 / $_"',
      exe +{ stdout => 1 }, qw(bc -l),
  };

  # check if exe()'s were successful
  defined($pid1) && defined($pid2)
    or die("Failed to run processes");

  # ask 'bc -l' results of "360 divided by given inputs"
  print $TO_STDIN "$_\n" for 2 .. 8;

  # we redirect stderr of 'perl' to stdout
  #   which, in turn, is fed into stdin of 'bc'

  # print captured outputs
  print "360 / $_ = " . <$FROM_STDOUT> for 2 .. 8;

  # close filehandles
  close($TO_STDIN);
  close($FROM_STDOUT);

B<Important:> Some non-Unix platforms, such as Win32, require interactive processes (shown above) to know when to quit, and can neither rely on C<close($TO_STDIN)>, nor C<< kill(TERM => $pid); >>


=head1 SUBROUTINES

Both C<exe( )> and C<bg( )> are optionally exported. They each return CODE references that need to be called.

=head2 exe( )

  exe \%EXE_OPTIONS, &PREEXEC, LIST, @REDIRECTS, &READER

C<\%EXE_OPTIONS> is an optional hash reference to instruct C<exe( )> to return C<STDIN> / C<STDERR> / C<STDOUT> filehandle(s) of the executed B<child> process. See L</SETTING OPTIONS>.

C<LIST> is C<exec( )> in the child process after the parent is forked, where the child's stdout is redirected to C<&READER>'s stdin. It is optional if C<&PREEXEC> is provided.

C<&PREEXEC> is called right before C<exec( )> in the child process, so we may reopen filehandles or do some child-only operations beforehand. It is optional if C<LIST> is provided.

C<&PREEXEC> could return a LIST of C<@REDIRECTS> to perform common filehandle redirections and/or modify C<binmode> settings. The C<@REDIRECTS> may be optionally specified (as references) after C<LIST>. Returning these strings (or references to them) will do the following preset actions:

  "2>#"  or "2>null"   silence  stderr
   ">#"  or "1>null"   silence  stdout
  "2>&1"               redirect stderr to  stdout
  "1>&2" or ">&2"      redirect stdout to  stderr
  "2>&-"               close    stderr
  "1><2" or "2><1"     swap     stdout and stderr
                       (+) shell-way works too:
                           \"3>&1", \"1>&2", \"2>&3", \"3>&-"

  "0:crlf"             does binmode(STDIN,  ":crlf")
  "1:raw" or "1:"      does binmode(STDOUT, ":raw")
  "2:utf8"             does binmode(STDERR, ":utf8")

C<&PREEXEC> could also return array references in the mix to perform C<open> operations. If C<open> fails, C<IPC::Exe> will die. Minimal validation is done for the array items, so be careful. Examples:

  [ ">",  "/path/file" ]   does open(STDOUT, ">",  "/path/file")
  [ ">>", "/path/file" ]   does open(STDOUT, ">>", "/path/file")
  [ "2>", "/path/file" ]   does open(STDERR, ">",  "/path/file")
  [ *FH, "+>>", $file ]    does open(FH, "+>>", $file)

If references to array refs are returned by C<&PREEXEC>, then C<sysopen> will be used instead:

  \[ *FH, $file, O_RDWR ]           does sysopen(FH, $file, O_RDWR)
  \[ *FH, $file, O_WRONLY, 0644 ]   does sysopen(FH, $file, O_WRONLY, 0644)

It is important to note that the actions & return of C<&PREEXEC> matters, as it may be used to redirect filehandles before C<&PREEXEC> becomes the exec process. If C<@REDIRECTS> are provided along with C<&PREEXEC>, the filehandle operations returned by C<&PREEXEC> are done first prior to C<@REDIRECTS>, in return-order.

C<&PREEXEC> is called with arguments passed to the CODE reference returned by C<exe( )>.

C<&READER> is called with C<($child_pid, LIST)> as its arguments. C<LIST> corresponds to the positional arguments passed in-between C<&PREEXEC> and C<@REDIRECTS>.

If C<exe( )>'s are chained, C<&READER> calls itself as the next C<exe( )> in line, which in turn, calls the next C<&PREEXEC>, C<LIST>, etc.

C<&READER> is always called in the parent process.

C<&PREEXEC> is always called in the child process.

C<waitpid( $_[0], 0 )> in C<&READER> to set exit status C<$?> of previous process executing on the pipe. C<close( $IPC::Exe::PIPE )> can also be used to close the input filehandle and set C<$?> at the same time (for Unix platforms only).

If C<LIST> is not provided, C<&PREEXEC> will still be called.

If C<&PREEXEC> is not provided, C<LIST> will still exec.

If C<&READER> is not provided, it defaults to something like

  sub { print while <STDIN>; waitpid($_[0], 0); return $? } # $_[0] is the $child_pid

C<exe( &READER )> simply returns C<&READER>.

C<exe( )> with no arguments returns an empty list.

=head2 bg( )

  bg \%BG_OPTIONS, &BACKGROUND

C<\%BG_OPTIONS> is an optional hash reference to instruct C<bg( )> to wait a certain amount of time for PREEXEC to complete (for non-Unix platforms only). See L</SETTING OPTIONS>.

C<&BACKGROUND> is called after it is sent to the init process.

If C<&BACKGROUND> is not a CODE reference, return an empty list upon execution.

C<bg( )> with no arguments returns an empty list.

This experimental feature is not enabled by default:

=over

=item *

Upon failure of background to init process, C<bg( )> can fallback by calling C<&BACKGROUND> in parent or child process if C<$IPC::Exe::bg_fallback> is true. To enable fallback feature, set

  $IPC::Exe::bg_fallback = 1;

=back


=head1 SETTING OPTIONS

=head2 exe( )

C<\%EXE_OPTIONS> is a hash reference that can be provided as the first argument to C<exe( )> to control returned values. It may be used to return or assign C<STDIN> / C<STDERR> / C<STDOUT> filehandle(s) of the child process to emulate L<IPC::Open2> and L<IPC::Open3> behavior.

The default values are:

  %EXE_OPTIONS = (
      pid         => undef,
      stdin       => 0,
      stdout      => 0,
      stderr      => 0,
      autoflush   => 1,
      binmode_io  => undef,
  );

These are the effects of setting the following options:

=over

=item pid => \$pid

Set C<$pid> to the child process PID, given a SCALAR reference. The PID will not be returned as part of the return values of C<exe( )>.

=item stdin => 1  or  stdin => \$TO_STDIN

Return a B<WRITEHANDLE> to C<STDIN> of the child process. The filehandle will be set to autoflush on write if C<$EXE_OPTIONS{autoflush}> is true.

If given a SCALAR reference, set C<$TO_STDIN> to the B<WRITEHANDLE> described above. The WRITEHANDLE then will not be returned as part of the return values of C<exe( )>.

=item stdout => 1  or  stdout => \$FROM_STDOUT

Return a B<READHANDLE> from C<STDOUT> of the child process, so output to stdout may be captured. When this option is set and C<&READER> is not provided, the default C<&READER> subroutine will B<NOT> be called.

If given a SCALAR reference, set C<$FROM_STDOUT> to the B<READHANDLE> described above. The READHANDLE then will not be returned as part of the return values of C<exe( )>.

=item stderr => 1  or  stdout => \$FROM_STDERR

Return a B<READHANDLE> from C<STDERR> of the child process, so output to stderr may be captured.

If given a SCALAR reference, set C<$FROM_STDERR> to the B<READHANDLE> described above. The READHANDLE then will not be returned as part of the return values of C<exe( )>.

=item autoflush => 0

Disable autoflush on the B<WRITEHANDLE> to C<STDIN> of the child process. This option only has effect when C<$EXE_OPTIONS{stdin}> is true.

=item binmode_io => ":raw", ":crlf", ":bytes", ":encoding(utf8)", etc.

Set C<binmode> of C<STDIN> and C<STDOUT> of the child process for layer C<$EXE_OPTIONS{binmode_io}>. This is automatically done for subsequently chained C<exe( )>cutions. To stop this, set to an empty string C<""> or another layer to bring a different mode into effect.

=back

=head2 bg( )

B<NOTE:> This only applies to non-Unix platforms.

C<\%BG_OPTIONS> is a hash reference that can be provided as the first argument to C<bg( )> to set wait time (in seconds) before relinquishing control back to the parent thread. See L</CAVEAT> for reasons why this is necessary.

The default value is:

  %BG_OPTIONS = (
      wait => 2,  # Win32 option
  );


=head1 RETURN VALUES

By chaining C<exe( )> and C<bg( )> statements, calling the single returned CODE reference sets off the chain of executions. This B<returns> a LIST in which each element corresponds to each C<exe( )> or C<bg( )> call.

=head2 exe( )

=over

=item *

When C<exe( )> executes an external process, the PID for that process is returned, or an B<EMPTY LIST> if C<exe( )> failed in any operation prior to forking. If an EMPTY LIST is returned, the chain of execution stops there and the next C<&READER> is not called, guaranteeing the final return LIST to be truncated at that point. Failure after forking causes C<die( )> to be called.

=item *

When C<exe( )> executes a C<&READER> subroutine, the subroutine's return value is returned. If there is no explicit C<&READER>, the implicit default C<&READER> subroutine is called instead:

  sub { print while <STDIN>; waitpid($_[0], 0); return $? } # $_[0] is the $child_pid

It returns C<$?>, which is the status of the last pipe process close. This allows code to be written like:

  my $exit = &{ exe 'myprog', $myarg }; # $exit = ($myprog_pid, $myprog_exit_status);

=item *

When non-default C<\%EXE_OPTIONS> are specified, each C<exe( )> returns additional filehandles in the following LIST:

  (
      $PID,                # undef if exec failed
      $STDIN_WRITEHANDLE,  # only if $EXE_OPTIONS{stdin}  is true
      $STDOUT_READHANDLE,  # only if $EXE_OPTIONS{stdout} is true
      $STDERR_READHANDLE,  # only if $EXE_OPTIONS{stderr} is true
  )

The positional LIST form return allows code to be written like:

  my ($pid, $TO_STDIN, $FROM_STDOUT) = &{
      exe +{ stdin => 1, stdout => 1 }, '/usr/bin/bc'
  };

SCALAR references may be passed in C<\%EXE_OPTIONS> for their scalars to be assigned in-place, instead of returning them in the positional LIST:

  my ($pid, $FROM_STDOUT);
  my ($TO_STDIN) = &{
      exe +{ pid => \$pid, stdin => 1, stdout => \$FROM_STDOUT },
        '/usr/bin/bc'
  };

B<Note:> It is necessary to disambiguate C<\%EXE_OPTIONS> (also C<\%BG_OPTIONS>) as a hash reference by including a unary C<+> before the opening curly bracket:

  +{ stdin => 1, autoflush => 0 }
  +{ wait => 2.5 }

=back

=head2 bg( )

Calling the CODE reference returned by C<bg( )> B<returns> the PID of the background process, or an C<EMPTY LIST> if C<bg( )> failed in any operation prior to forking. Failure after forking causes C<die( )> to be called.


=head1 ERROR CHECKING

To determine if either C<exe( )> or C<bg( )> was successful until the point of forking, check whether the returned C<$PID> is defined.

See L</EXAMPLES> for examples on error checking.

B<WARNING:> This may get a slightly complicated for chained C<exe( )>'s when non-default C<\%EXE_OPTIONS> cause the positions of C<$PID> in the overall returned LIST to be non-uniform (caveat emptor). Remember, the chain of executions is doing a B<lot> for just a single CODE call, so due diligence is required for error checking.

A minimum count of items (PIDs and/or filehandles) can be expected in the returned LIST to determine whether forks were initiated for the entire C<exe( )> / C<bg( )> chain.

Failures after forking are responded with C<die( )>. To handle these errors, use C<eval>.


=head1 TAINT CHECKING

In taint mode, C<exe( )> will die if it is called with tainted arguments or environment variables. By default, the following environment variables are checked:

  PATH  PATHEXT  IFS  CDPATH  ENV  BASH_ENV  PERL5SHELL

We may add to this list with:

  BEGIN { push @IPC::Exe::TAINT_ENV, qw(PATH_LOCALE TERMINFO TERMPATH) }


=head1 SYNTAX

It is highly recommended to B<avoid> unnecessary parentheses ( )'s when using C<exe( )> and C<bg( )>.

C<IPC::Exe> relies on Perl's LIST parsing magic in order to provide the clean intuitive syntax.

As a guide, the following syntax should be used:

  my @pids = &{                                          # call CODE reference
      [ bg ] exe [ sub { ... }, ] $prog1, $arg1, @ARGV,  # end line with comma
             exe [ sub { ... }, ] $prog2, $arg2, $arg3,  # end line with comma
      [ bg ] exe sub { ... },                            # this bg() acts on last exe() only
             sub { ... },
  };

where brackets [ ]'s denote optional syntax.

Note that Perl sees

  my @pids = &{
      bg exe $prog1, $arg1, @ARGV,
      bg exe sub { "2>#" }, $prog2, $arg2, $arg3,
         exe sub { 123 },
         sub { 456 },
  };

as

  my @pids = &{
      bg( exe( $prog1, $arg1, @ARGV,
              bg( exe( sub { "2>#" }, $prog2, $arg2, $arg3,
                      exe( sub { 123 },
                           sub { 456 }
                      )
                  )
              )
          )
      );
  };


=head1 CAVEAT

=head2 END { } blocks

Code declared in END blocks will be called upon exit, whether it be after C<&PREEXEC> sub without a LIST command, from a C<die> failure, or even a failed C<exec> call.

The user should make provisions to handle this situation. This is desirable when END blocks must B<only> be called in the main process (or thread).

C<$IPC::Exe::is_forked> is set to true after the code forks in C<&PREEXEC> and C<&BACKGROUND>. It can be used to tell the main process/thread apart from child processes/threads:

  END {
      # only run in main process/thread
      return if $IPC::Exe::is_forked;

      ### REST OF THE CODE GOES HERE ###
      ...
  }

=head2 PLATFORMS

This module is targeted for Unix environments, using techniques described in perlipc and perlfaq8. Development is done on FreeBSD, Linux, and Win32 platforms. It may not work well on other non-Unix systems, let alone Win32.

=head2 MSWin32

Some care was taken to rely on Perl's Win32 threaded implementation of C<fork( )>. To get things to work almost like Unix, redirections of filehandles have to be performed in a certain order. More specifically: let's say STDOUT of a child I<process> (read: thread) needs to be redirected elsewhere (anywhere, it doesn't matter). It is important that the parent I<process> (read: thread) does not use STDOUT until B<after> the child is exec'ed. At the point after exec, the parent B<must> restore STDOUT to a previously dup'ed original and may then proceed along as usual. If this order is violated, deadlocks may occur, often manifesting as an apparent stall in execution when the parent tries to use STDOUT.

=head3 exe( )

Since C<fork( )> is emulated with threads, C<&PREEXEC> and C<&READER> really do begin their lives in the B<same> process, but in separate threads. This imposes limitations on how they can be used. One limitation is that, as separate threads, either one B<MUST NOT> block, or else the other thread will not be able to continue.

Writing to, or reading from a pipe will B<block> when the pipe buffer is full or empty, respectively.

Putting the facts together, it means that a pipe writer and reader should not function (as separate threads or otherwise) in the same process for fear that one may block and not let the other continue (a deadlock).

For example, this code below will B<block>:

  &{
      exe sub { print "a" x 9000, "\n" for 1 .. 3 }, # sub is &PREEXEC
          sub { @result = <STDIN> }                  # sub is &READER
  };

The execution stalls, and the program just hangs there. C<&PREEXEC> is writing out more data than the pipe buffer can fit. Once the buffer is full, C<print> will block to wait for the buffer to be emptied. However, C<&READER> is not able to continue and read off some data from the pipe buffer because it is in the same blocked process. If it were in a separate process (as in a real C<fork>), than a blocking C<&PREEXEC> cannot affect the C<&READER>.

The way to ensure C<exe( )> works smoothly on Win32 is to C<exec> processes on the pipeline chain. This code will work instead:

  &{
      exe qw(perl -e), 'print "a" x 9000, "\n" for 1 .. 3', # &PREEXEC exec'ed perl
          sub { @result = <STDIN> }                         # sub is &READER
  };

Now, C<&PREEXEC> is no longer running in the same process, and cannot affect C<&READER>. If the new C<perl> process blocks, C<&READER> in the original process can still continue to read the pipe.

Writing and reading small amounts of data (to not cause blocking) between C<&PREEXEC> and C<&READER> is possible, but not recommended.

=head3 bg( )

On Win32, C<bg( )> unfortunately has to substantially rely on timer code to wait for C<&PREEXEC> to complete in order to work properly with C<exe( )>. The example shown below illustrates that C<bg( )> has to wait at least until C<$program> is exec'ed. Hence, C<< $wait_time > $work_time >> must hold true and this requires I<a priori> knowledge of how long C<&PREEXEC> will take.

  &{
      bg +{ wait => $wait_time }, exe sub { sleep($work_time) }, $program
  };

This essentially renders C<bg &BACKGROUND> useless if C<&BACKGROUND> does not exec any programs (Win32).

In summary: (on Win32)

=over

=item *

Only use C<bg( )> to B<exec programs> into the background.

=item *

Keep C<&PREEXEC> as short-running as possible. Or make sure C<$BG_OPTIONS{wait}> time is longer.

=item *

No C<&PREEXEC> (or code running in parallel thread) == no problems.

=back

Some useful information:

  http://perldoc.perl.org/perlfork.html#CAVEATS-AND-LIMITATIONS
  http://www.nntp.perl.org/group/perl.perl5.porters/2003/11/msg85488.html
  http://www.nntp.perl.org/group/perl.perl5.porters/2003/08/msg80311.html
  http://www.perlmonks.org/?node_id=684859
  http://www.perlmonks.org/?node_id=225577
  http://www.perlmonks.org/?node_id=742363


=head1 DEPENDENCIES

Perl v5.8.8+ is required.

No non-core modules are required.


=head1 AUTHOR

Gerald Lai <glai at cpan dot org>


=cut

