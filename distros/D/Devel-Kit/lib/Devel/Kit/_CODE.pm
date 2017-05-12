package Devel::Kit::_CODE;

use strict;
use warnings;

require Devel::Symdump;
require Time::HiRes;
require Unix::PID::Tiny;

my $pid = Unix::PID::Tiny->new();

my $countops_lazy = 0;

sub _cd {
    my ( $code, $dump_sym ) = @_;

    if ( !exists $INC{'Devel/CountOps.pm'} ) {
        require Devel::CountOps;
        $countops_lazy++;
    }

    if ( ref( $_[0] ) ne 'CODE' ) {
        return "Error: cd() requires a CODE ref\n";
    }
    else {
        local $| = 1;
        Devel::Kit::d("Begin cd($code)");
        my $sym_pre         = Devel::Symdump->rnew('main');
        my $pid_pre         = $pid->pid_info_hash($$);
        my $start_time      = [ Time::HiRes::gettimeofday() ];
        my $start_ops_count = ${^_OPCODES_RUN};
        eval { $code->() };
        my $stop_ops_count = ${^_OPCODES_RUN};
        my $err            = $@;                                # after $stop_ops_count so we don't count the opts in that, before anything else in case an eval way down deep makes $@ wonky
        my $stop_time      = [ Time::HiRes::gettimeofday() ];
        my $pid_pst        = $pid->pid_info_hash($$);
        my $sym_pst        = Devel::Symdump->rnew('main');
        Devel::Kit::o("\n");                                    # in case $code->() has no trailing newline
        Devel::Kit::d("End cd($code)");
        return "Error: “$code” failed:\n\t$err\n" if $err;

        my $res_hr = {};

        $res_hr->{'seconds'} = Time::HiRes::tv_interval( $start_time, $stop_time );
        if ( $res_hr->{'seconds'} =~ m/e/i ) {
            $res_hr->{'seconds'} = $stop_time->[0] - $start_time->[0];
            $res_hr->{'seconds'} .= '.';
            $res_hr->{'seconds'} .= sprintf(
                "%06d",
                sprintf( '%.6f', $stop_time->[1] ) - sprintf( '%.6f', $start_time->[1] )
            );
        }

        $res_hr->{'op_cnt'} = $stop_ops_count - $start_ops_count;
        if ($countops_lazy) {    # non-import Devel::CountOps needs done at BEGIN time to work correctly
            $res_hr->{'op_cnt'} .= ' (Add -mDevel::CountOps to command (or use Devel::CountOps (); to code) to get a more accurate count!)';
        }
        $res_hr->{'rss_inc_bytes'} = $pid_pst->{RSS} - $pid_pre->{RSS};

        $res_hr->{'sym_diff'} = $sym_pre->diff($sym_pst);

        $res_hr->{'sym_add'} = () = $res_hr->{'sym_diff'} =~ m/\+ /g;
        $res_hr->{'sym_rem'} = () = $res_hr->{'sym_diff'} =~ m/\- /g;

        my $dump = '';

        if ($dump_sym) {
            $dump = "        ---- Begin Raw Diff --\n$res_hr->{'sym_diff'}\n        ---- End Raw Diff --";
        }

        return <<"END_CODE";
$code info:
    Op Count: $res_hr->{'op_cnt'}
    Seconds : $res_hr->{'seconds'}
    RSS Grew: $res_hr->{'rss_inc_bytes'} bytes
    Symbols :
        Added  : $res_hr->{'sym_add'}
        Removed: $res_hr->{'sym_rem'}
$dump
END_CODE
    }
}

1;
