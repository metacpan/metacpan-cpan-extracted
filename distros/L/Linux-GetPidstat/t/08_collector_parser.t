use strict;
use warnings;
use Test::More 0.98;
use Data::Section::Simple qw(get_data_section);
use Capture::Tiny qw/capture/;

use Linux::GetPidstat::Collector::Parser;

my $output = get_data_section('pidstat.output');
my @lines = split '\n', $output;

{
    my @parts = @lines[0..3];

    my $parsed = parse_pidstat_output(\@parts);
    is_deeply $parsed, {
        'cpu'                => '2.78',
        'cswch_per_sec'      => '6.48',
        'disk_read_per_sec'  => '0.00',
        'disk_write_per_sec' => '-1000.00',
        'memory_percent'     => '34.62',
        'memory_rss'         => '10876916000.00',
        'nvcswch_per_sec'    => '2.78',
        'stk_ref'            => '28000.00',
        'stk_size'           => '116000.00',
    } or diag explain $parsed;
}

{
    my $parsed = parse_pidstat_output(\@lines);
    is_deeply $parsed, {
        'cpu'                => '21.20',
        'cswch_per_sec'      => '19.87',
        'disk_read_per_sec'  => '0.00',
        'disk_write_per_sec' => '-250.00',
        'memory_percent'     => '34.63',
        'memory_rss'         => '10881534000.00',
        'nvcswch_per_sec'    => '30.45',
        'stk_ref'            => '25500.00',
        'stk_size'           => '128500.00'
    } or diag explain $parsed;
}

{
    # data is missing
    my @parts = @lines[0..2];

    my ($stdout, $stderr, $parsed) = capture {
        parse_pidstat_output(\@parts);
    };
    ok !$parsed or diag explain $parsed;
    like $stderr, qr/Empty metric: name=/ or diag $stderr;
}

done_testing;

__DATA__
@@ pidstat.output
Linux 3.13.0-83-generic (ip-10-0-1-51)  04/02/2016      _x86_64_        (4 CPU)

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594082   500     23081    2.78    0.00    0.00    2.78     1      0.00      0.00 11071276 10876916  34.62     116      28      0.00      -1.00      0.00      6.48      2.78  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594082   500     23081   23.00    0.00    0.00   23.00     3     41.00      0.00 11071588 10876916  34.62     136      18      0.00      0.00      0.00     63.00     55.00  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594083   500     23081   25.00    0.00    0.00   25.00     0   2276.00      0.00 11081496 10886152  34.65     126      28      0.00      0.00      0.00      9.00     23.00  perl

#      Time   UID       PID    %usr %system  %guest    %CPU   CPU  minflt/s  majflt/s     VSZ    RSS   %MEM StkSize  StkRef   kB_rd/s   kB_wr/s kB_ccwr/s   cswch/s nvcswch/s  Command
 1459594084   500     23081   34.00    0.00    0.00   34.00     0     50.00      0.00 11081496 10886152  34.65     136      28      0.00      0.00      0.00      1.00     41.00  perl
