use strict;
use warnings;
use Test::More 0.98;
use Data::Section::Simple qw(get_data_section);
use Capture::Tiny qw/capture/;

use Linux::GetPidstat::Collector::Parser;

{
    my $output = get_data_section('pidstat.output.one');
    my @lines = split '\n', $output;
    my $parsed = parse_pidstat_output(\@lines);
    is_deeply $parsed, {
        'cpu'                => '2.78',
        'cswch_per_sec'      => '6.48',
        'disk_read_per_sec'  => '0',
        'disk_write_per_sec' => '-1000',
        'memory_percent'     => '34.62',
        'memory_rss'         => '10876916000',
        'nvcswch_per_sec'    => '2.78',
        'stk_ref'            => '28000',
        'stk_size'           => '116000',
    } or diag explain $parsed;
}

{
    my $output = get_data_section('pidstat.output.multi');
    my @lines = split '\n', $output;
    my $parsed = parse_pidstat_output(\@lines);
    is_deeply $parsed, {
        'cpu'                => '21.2',
        'cswch_per_sec'      => '19.87',
        'disk_read_per_sec'  => '0',
        'disk_write_per_sec' => '-250',
        'memory_percent'     => '34.63',
        'memory_rss'         => '10881534000',
        'nvcswch_per_sec'    => '30.45',
        'stk_ref'            => '25500',
        'stk_size'           => '128500'
    } or diag explain $parsed;
}

{
    my $output = get_data_section('pidstat.output.include_child_process');
    my @lines = split '\n', $output;
    my $parsed = parse_pidstat_output(\@lines);
    is_deeply $parsed, {
        'cpu'                => '42.48',
        'cswch_per_sec'      => '33.54',
        'disk_read_per_sec'  => '500',
        'disk_write_per_sec' => '-500',
        'memory_percent'     => '42.15',
        'memory_rss'         => '13532901250',
        'nvcswch_per_sec'    => '44.04',
        'stk_ref'            => '39500',
        'stk_size'           => '190000'
    } or diag explain $parsed;
}

{
    # data is missing
    my $output = get_data_section('pidstat.output.one');
    my @lines = split '\n', $output;
    my @parts = @lines[0..2];

    my ($stdout, $stderr, $parsed) = capture {
        parse_pidstat_output(\@parts);
    };
    ok !$parsed or diag explain $parsed;
    like $stderr, qr/Empty metric: name=/ or diag $stderr;
}

done_testing;

__DATA__
@@ pidstat.output.one
Linux 3.13.0-83-generic (ip-10-0-1-51)  04/02/2016      _x86_64_        (4 CPU)

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594082   500     23081    2.78    0.00    0.00    2.78     1      0.00      0.00 11071276 10876916  34.62     116      28      0.00      -1.00      0.00      6.48      2.78  perl

@@ pidstat.output.multi
Linux 3.13.0-83-generic (ip-10-0-1-51)  04/02/2016      _x86_64_        (4 CPU)

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594082   500     23081    2.78    0.00    0.00    2.78     1      0.00      0.00 11071276 10876916  34.62     116      28      0.00      -1.00      0.00      6.48      2.78  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594082   500     23081   23.00    0.00    0.00   23.00     3     41.00      0.00 11071588 10876916  34.62     136      18      0.00      0.00      0.00     63.00     55.00  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594083   500     23081   25.00    0.00    0.00   25.00     0   2276.00      0.00 11081496 10886152  34.65     126      28      0.00      0.00      0.00      9.00     23.00  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594084   500     23081   34.00    0.00    0.00   34.00     0     50.00      0.00 11081496 10886152  34.65     136      28      0.00      0.00      0.00      1.00     41.00  perl

@@ pidstat.output.include_child_process
Linux 3.13.0-83-generic (ip-10-0-1-51)  04/02/2016      _x86_64_        (4 CPU)

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594082   500     23081    2.78    0.00    0.00    2.78     1      0.00      0.00 11071276 10876916  34.62     116      28      0.00      -1.00      0.00      6.48      2.78  perl
 1459594082   500     23082    5.22    0.00    0.00    5.22     2     13.00      0.00  2294571  2588472   7.33      52      12      0.00      -1.00      0.00      8.11      1.22  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594082   500     23081   23.00    0.00    0.00   23.00     3     41.00      0.00 11071588 10876916  34.62     136      18      0.00      0.00      0.00     63.00     55.00  perl
 1459594082   500     23082   12.00    0.00    0.00   12.00     1     22.00      0.00  2294571  2588472   7.33      59       9      1.00      0.00      0.00     33.12     29.12  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594083   500     23081   25.00    0.00    0.00   25.00     0   2276.00      0.00 11081496 10886152  34.65     126      28      0.00      0.00      0.00      9.00     23.00  perl
 1459594083   500     23082   55.23    0.00    0.00   55.23     2    256.00      0.00  2449581  2629242   7.59      82      24      0.00      0.00      0.00      8.45     13.00  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594084   500     23081   34.00    0.00    0.00   34.00     0     50.00      0.00 11081496 10886152  34.65     136      28      0.00      0.00      0.00      1.00     41.00  perl
 1459594084   500     23082   12.66    0.00    0.00   12.66     1    119.00      0.00  2449882  2799283   7.81      53      11      1.00      0.00      0.00      5.00     11.00  perl

