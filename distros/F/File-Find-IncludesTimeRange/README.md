# File::Find::IncludesTimeRange

Takes a array of time stamped items(largely meant for use with files)
returns ones that include the specified time range.

Originally developed for use with Suricata conditional PCAPs and Daemonlogger.

```perl
use File::Find::IncludesTimeRange;
use Time::Piece;
use Data::Dumper;


my @files=(
    'daemonlogger.1677468390.pcap',
    'daemonlogger.1677468511.pcap',
    'daemonlogger.1677468632.pcap',
    'daemonlogger.1677468753.pcap',
    'daemonlogger.1677468874.pcap',
    'daemonlogger.1677468995.pcap',
    'daemonlogger.1677469116.pcap',
    'daemonlogger.1677469237.pcap',
    'daemonlogger.1677469358.pcap',
    'daemonlogger.1677469479.pcap',
    'daemonlogger.1677469600.pcap',
    'daemonlogger.1677469721.pcap',
    );

print Dumper(\@files);

my $start=Time::Piece->strptime('1677468511', '%s');
my $end=Time::Piece->strptime(  '1677468833', '%s');

my $found=File::Find::IncludesTimeRange->find(
                                              items=>\@files,
                                              start=>$start,
                                              end=>$end,
                                              regex=>'(?<timestamp>\d\d\d\d\d\d+)(\.pcap|(?<subsec>\.\d+)\.pcap)$',
                                              strptime=>'%s',
                                             );

print Dumper($found);
```

## File::Find::IncludesTimeRange->find

Searches through a list of items , finds the ones that appear to be timestamped.
It will then sort the found time stamps and return the ones that include the
specified time periods.

There following options are taken.

```orgmode
    - items :: A array ref of items to examine.

    - start :: A Time::Piece object set to the start time.

    - end :: A Time::Piece object set to the end time.

    - regex :: A regex to use for matching the files. Requires uses of the named
               group 'timestamp' for capturing the timestamp. If it includes micro
               seconds in it, since Time::Piece->strptime does not handle those,
               those can be captured via the group 'subsec'. They will then be
               appended to to the epoch time of any parsed timestamp for sorting
               purposes.
        - Default :: (?<timestamp>\d\d\d\d\d\d+)(\.pcap|(?<subsec>\.\d+)\.pcap)$

    - strptime :: The format for use with L<Time::Piece>->strptime.
        - Default :: %s
```
