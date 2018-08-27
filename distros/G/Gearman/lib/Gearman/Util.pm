package Gearman::Util;
use version ();
$Gearman::Util::VERSION = version->declare("2.004.015");

use strict;
use warnings;

# for sake of _read_sock
no warnings "recursion";

# man errno
# Resource temporarily unavailable
# (may be the same value as EWOULDBLOCK) (POSIX.1)
use IO::Select;
use POSIX qw(:errno_h);
use Scalar::Util qw();
use Time::HiRes qw();

=head1 NAME

Gearman::Util - Utility functions for gearman distributed job system

=head1 METHODS

=cut

sub DEBUG () {0}

# I: to jobserver
# O: out of job server
# W: worker
# C: client of job server
# J: jobserver
our %cmd = (
    1  => ['I',  "can_do"],           # from W:  [FUNC]
    2  => ['I',  "cant_do"],          # from W:  [FUNC]
    3  => ['I',  "reset_abilities"],  # from W:  ---
    4  => ['I',  "pre_sleep"],        # from W: ---
    6  => ['O',  "noop"],             # J->W  ---
    7  => ['I',  "submit_job"],       # C->J  FUNC[0]UNIQ[0]ARGS
    8  => ['O',  "job_created"],      # J->C HANDLE
    9  => ['I',  "grab_job"],         # W->J --
    10 => ['O',  "no_job"],           # J->W --
    11 => ['O',  "job_assign"],       # J->W HANDLE[0]FUNC[0]ARG
    12 => ['IO', "work_status"],      # W->J/C: HANDLE[0]NUMERATOR[0]DENOMINATOR
    13 => ['IO', "work_complete"],    # W->J/C: HANDLE[0]RES
    14 => ['IO', "work_fail"],        # W->J/C: HANDLE
    15 => ['I',  "get_status"],       # C->J: HANDLE
    16 => ['I',  "echo_req"],         # ?->J TEXT
    17 => ['O',  "echo_res"],         # J->? TEXT
    18 => ['I',  "submit_job_bg"],    # C->J     " "   "  " "
    19 => ['O',  "error"],            # J->? ERRCODE[0]ERR_TEXT
    20 => ['O', "status_res"],    # C->J: HANDLE[0]KNOWN[0]RUNNING[0]NUM[0]DENOM
    21 => ['I', "submit_job_high"],    # C->J  FUNC[0]UNIQ[0]ARGS
    22 => ['I', "set_client_id"],      # W->J: [RANDOM_STRING_NO_WHITESPACE]
    23 => ['I', "can_do_timeout"],     # from W: FUNC[0]TIMEOUT

    # for worker to declare to the jobserver that this worker is only connected
    # to one jobserver, so no polls/grabs will take place, and server is free
    # to push "job_assign" packets back down.
    24 => ['I',  "all_yours"],             # W->J ---
    25 => ['IO', "work_exception"],        # W->J/C: HANDLE[0]EXCEPTION
    26 => ['I',  "option_req"],            # C->J: [OPT]
    27 => ['O',  "option_res"],            # J->C: [OPT]
    28 => ['IO', "work_data"],             # W->J/C: HANDLE[0]RES
    29 => ['IO', "work_warning"],          # W->J/C: HANDLE[0]RES
    32 => ['I',  "submit_job_high_bg"],    # C->J  FUNC[0]UNIQ[0]ARGS
    33 => ['I',  "submit_job_low"],        # C->J  FUNC[0]UNIQ[0]ARGS
    34 => ['I',  "submit_job_low_bg"],     # C->J  FUNC[0]UNIQ[0]ARGS
);

our %num;                                  # name -> num
while (my ($num, $ary) = each %cmd) {
    die if $num{ $ary->[1] };
    $num{ $ary->[1] } = $num;
}

=head2 cmd_name($num)

B<return> cmd

=cut

sub cmd_name {
    my $num = shift;
    my $c   = $cmd{$num};
    return $c ? $c->[1] : undef;
}

=head2 pack_req_command($key, $arg)

B<return> request string

=cut

sub pack_req_command {
    return _pack_command("REQ", @_);
}

=head2 pack_res_command($cmd, $arg)

B<return> response string

=cut

sub pack_res_command {
    return _pack_command("RES", @_);
}

=head2 read_res_packet($sock, $err_ref, $timeout)

B<return> undef on closed socket or malformed packet

=cut

sub read_res_packet {
    warn " Entering read_res_packet" if DEBUG;
    my $sock       = shift;
    my $err_ref    = shift;
    my $timeout    = shift;
    my $time_start = Time::HiRes::time();
    unless (Scalar::Util::blessed($sock)) {
        # for the sake of Gearman::Client::Async
        # see https://github.com/p-alik/perl-Gearman/issues/37
        (ref($sock) eq "GLOB") || die "provided value is not a blessed object";
        ($$sock && $$sock eq '*Gearman::Worker::$sock')
            || die
            "provided value is not a GLOB of type Gearman::Worker::\$sock";
    } ## end unless (Scalar::Util::blessed...)

    my $err = sub {
        my $code = shift;
        Scalar::Util::blessed($sock) && $sock->close() if $sock->connected;
        $$err_ref = $code if ref $err_ref;
        return undef;
    };

    $sock->blocking(0);

    my $is = IO::Select->new($sock);

    my $readlen   = 12;
    my $offset    = 0;
    my $buf       = '';
    my $using_ssl = $sock->isa("IO::Socket::SSL");

    my ($magic, $type, $len);

    warn " Starting up event loop\n" if DEBUG;
    while (1) {
        if ($using_ssl && $sock->pending()) {
            warn "  We have @{[ $sock->pending() ]}  bytes...\n" if DEBUG;
        }
        else {
            my $time_remaining = undef;
            if (defined $timeout) {
                warn "  We have a timeout of $timeout\n" if DEBUG;
                $time_remaining = $time_start + $timeout - Time::HiRes::time();
                return $err->("timeout") if $time_remaining < 0;
            }

            $is->can_read($time_remaining) || next;
        } ## end else [ if ($using_ssl && $sock...)]
        warn "   Entering read loop\n" if DEBUG;

        my ($ok, $err_code) = _read_sock($sock, \$buf, \$readlen, \$offset);
        if (!defined($ok)) {
            next;
        }
        elsif ($ok == 0) {
            return $err->($err_code);
        }

        if (!defined $type) {
            next unless length($buf) >= 12;
            my $header = substr($buf, 0, 12, '');
            ($magic, $type, $len) = unpack("a4NN", $header);
            return $err->("malformed_magic: '$magic'") unless $magic eq "\0RES";
            my $starting = length($buf);
            $readlen = $len - $starting;
            $offset  = $starting;

            if ($readlen) {
                my ($ok, $err_code)
                    = _read_sock($sock, \$buf, \$readlen, \$offset);
                if (!defined($ok)) {
                    next;
                }
                elsif ($ok == 0) {
                    return $err->($err_code);
                }
            } ## end if ($readlen)
        } ## end if (!defined $type)

        $type = $cmd{$type};
        return $err->("bogus_command") unless $type;
        return $err->("bogus_command_type") unless index($type->[0], "O") != -1;

        warn " Fully formed res packet, returning; type=$type->[1] len=$len\n"
            if DEBUG;

        $sock->blocking(1);

        return {
            type    => $type->[1],
            len     => $len,
            blobref => \$buf,
        };
    } ## end while (1)
} ## end sub read_res_packet

sub _read_sock {
    my ($sock, $buf_ref, $readlen_ref, $offset_ref) = @_;
    local $!;
    my $rv = sysread($sock, $$buf_ref, $$readlen_ref, $$offset_ref);
    unless ($rv) {
        warn "   Read error: $!\n" if DEBUG;
        $! == EAGAIN && return;
    }

    return (0, "read_error") unless defined $rv;
    return (0, "eof")        unless $rv;

    unless ($rv >= $$readlen_ref) {
        warn
            "   Partial read of $rv bytes, at offset $$offset_ref, readlen was $$readlen_ref\n"
            if DEBUG;
        $$offset_ref += $rv;
        $$readlen_ref -= $rv;

        $sock->blocking(1);
        my $ret = _read_sock($sock, $buf_ref, $readlen_ref, $offset_ref);
        $sock->blocking(0);
        return $ret;
    } ## end unless ($rv >= $$readlen_ref)

    warn "   Finished reading\n" if DEBUG;
    return (1);
} ## end sub _read_sock

=head2 read_text_status($sock, $err_ref)

=cut

sub read_text_status {
    my $sock    = shift;
    my $err_ref = shift;

    my $err = sub {
        my $code = shift;
        $sock->close() if $sock->connected;
        $$err_ref = $code if ref $err_ref;
        return undef;
    };

    $sock->connected || return $err->("can't read from unconnected socket");
    my @lines;
    my $complete = 0;
    while (my $line = <$sock>) {
        chomp $line;
        return $err->($1) if $line =~ /^ERR (\w+) /;

        if ($line eq '.') {
            $complete++;
            last;
        }

        push @lines, $line;
    } ## end while (my $line = <$sock>)
    return $err->("eof") unless $complete;

    return @lines;
} ## end sub read_text_status

=head2 send_req($sock, $reqref)

=cut

sub send_req {
    my ($sock, $reqref) = @_;
    return 0 unless $sock;

    my $data = ${$reqref};
    (my $total_len) = (my $len) = length($data);
    my ($num_zero_writes, $offset) = (0, 0);
    local $SIG{PIPE} = "IGNORE";

    while ($len && ($num_zero_writes < 5)) {
        my $written = $sock->syswrite($data, $len, $offset);
        if (!defined $written) {
            warn "send_req: syswrite error: $!" if DEBUG;
            return 0;
        }
        elsif ($written > 0) {
            $len -= $written;
            $offset += $written;
        }
        else {
            $num_zero_writes++;
        }
    } ## end while ($len && ($num_zero_writes...))

    return ($total_len > 0 && $offset == $total_len);
} ## end sub send_req

=head2 wait_for_readability($fileno, $timeout)

given a file descriptor number and a timeout,

wait for that descriptor to become readable

B<return> 0 or 1 on if it did or not

=cut

sub wait_for_readability {
    my ($fileno, $timeout) = @_;
    return 0 unless $fileno && $timeout;

    my $rin = '';
    vec($rin, $fileno, 1) = 1;
    my $nfound = select($rin, undef, undef, $timeout);

    # nfound can be undef or 0, both failures, or 1, a success
    return $nfound ? 1 : 0;
} ## end sub wait_for_readability

#
# _pack_command($prefix, $key, $arg)
#
sub _pack_command {
    my ($prefix, $key, $arg) = @_;
    ($key && $num{$key}) || die sprintf("Bogus type arg of '%s'", $key || '');

    $arg ||= '';
    my $len = length($arg);
    return "\0$prefix" . pack("NN", $num{$key}, $len) . $arg;
} ## end sub _pack_command

1;
