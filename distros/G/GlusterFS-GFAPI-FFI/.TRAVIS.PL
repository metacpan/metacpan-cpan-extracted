#/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd         ();
use Symbol      qw/gensym/;
use IPC::Open3  qw/open3/;
use IO::Select;
use POSIX       qw/:sys_wait_h/;

use Test::Most;

sub run_cmd (@)
{
    my %args = @_;

    my $cmd     = $args{cmd};
    my @args    = defined($args{args}) ? @{$args{args}} : ();
    my $in      = $args{in};
    my $timeout = $args{timeout};
    my $quiet   = $args{quiet};
    my $cb_out  = $args{cb_out};
    my $cb_err  = $args{cb_err};
    my $nb      = $args{nb} // 4096;

    if (!defined($cmd))
    {
        warn '[ERR] Invalid parameter: cmd';
        return undef;
    }

    $timeout = 60    if (!defined($timeout) || $timeout !~ m/^\d+$/);
    $timeout = undef if ($timeout == 0);

    # generate symbol
    my ($cmd_in, $cmd_out, $cmd_err) = map gensym, 1..3;

    # Open Process
    my $pid   = open3($cmd_in, $cmd_out, $cmd_err, $cmd, @args);
    my $start = time;

    # For selecting.
    my $select_handle = IO::Select->new();

    if (defined($in))
    {
        print $cmd_in $in;

        #$select_handle->add($cmd_in);
        #
        #while (my @ready = $select_handle->can_write($timeout))
        #{
        #    foreach my $handle (@ready)
        #    {
        #        syswrite($handle, $in);
        #    }
        #}
        #
        #$select_handle->remove($cmd_in);
    }

    $select_handle->add($cmd_out);
    $select_handle->add($cmd_err);

    my $out = '';
    my $err = '';

    while (my @ready = $select_handle->can_read($timeout))
    {
        foreach my $handle (@ready)
        {
            my $buf = '';

            # Non-Buffered I/O
            if ($nb)
            {
                if (sysread($handle, $buf, $nb))
                {
                    if ($handle == $cmd_out)
                    {
                        if ($cb_out)
                        {
                            local $_ = $buf;
                            chomp($_);
                            $cb_out->();
                        }

                        $out .= $buf;
                    }
                    elsif ($handle == $cmd_err)
                    {
                        if ($cb_err)
                        {
                            local $_ = $buf;
                            chomp($_);
                            $cb_err->();
                        }

                        $err .= $buf;
                    }
                }
                else
                {
                    # EOF or Error
                    $select_handle->remove($handle);
                }
            }
            else
            {
                $buf = <$handle>;

                if ($buf)
                {
                    if ($handle == $cmd_out)
                    {
                        if ($cb_out)
                        {
                            local $_ = $buf;
                            chomp($_);
                            $cb_out->();
                        }

                        $out .= $buf;
                    }
                    elsif ($handle == $cmd_err)
                    {
                        if ($cb_err)
                        {
                            local $_ = $buf;
                            chomp($_);
                            $cb_err->();
                        }

                        $err .= $buf;
                    }
                }
                else
                {
                    # EOF or Error
                    $select_handle->remove($handle);
                }
            }
        }
    }

    close($cmd_in);
    close($cmd_out);
    close($cmd_err);

    my $is_timeout = 0;

    # check whether timeout or not.
    if ($select_handle->count)
    {
        kill('TERM', $pid);
        $is_timeout = 1;
    }

    my ($kid, $reap_count) = (0, 0);

    do {
        select(undef, undef, undef, 0.05);
        $kid = waitpid($pid, WNOHANG);
    } until ($kid > 0 || ++$reap_count >= 10);

    my $status = undef;

    if ($kid > 0)
    {
        $status = $?>>8;
    }

    chomp($out);
    chomp($err);

    if ($out =~ m/^open3:/)
    {
        warn "[ERR] Failed to execute with open3: $cmd";
        return undef;
    }

    return {
        cmd     => @args ? join(' ', $cmd, @args) : $cmd,
        pid     => $kid,
        status  => ($is_timeout) ? -1 : $status,
        out     => $out,
        err     => ($is_timeout) ? 'Timeout exceeded' : $err,
        runtime => time - $start,
    };
}

sub test_libgfapi
{
    $retval = run_cmd(
                    cmd    => 'make test TEST_VERBOSE=1',
                    cb_out => sub { print STDOUT "$_\n"; },
                    cb_err => sub { print STDERR "$_\n"; });

    if (!defined($retval) || $retval->{status})
    {
        die $retval->{status};
    }

    return 0;
}

our $ROOT = Cwd::abs_path(Cwd::cwd());

diag('libgfapi-perl');

test_libgfapi();

done_testing();
