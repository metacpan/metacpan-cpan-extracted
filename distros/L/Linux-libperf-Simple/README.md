# Linux::libperf::Simple

This module is a simple wrapper around Linux `libperf`.

It is intended for use in measuring in-process execution time for
precise benchmarking, whether it will actually be useful for that
remains to be seen.

You will need to install the package (Redhat-ish) or build from source
(Debian-ish at this time).  `libperf` is supplied as part of the
Linux source tree, it is *not* `theonewolf/libperf` from Github.

To build from source extract the linux sources, the more recent the
better:

```
cd tools/lib/perf
make prefix=/where/to/install install
```

When configuring `Linux-libperf-Simple`, ensure `libperf.pc` from the `libperf` build is in the `PKG_CONFIG_PATH` environment variable, eg.:

```
PKG_CONFIG_PATH=~/local/libperf/lib64/pkgconfig/ perl Makefile.PL
```

To actually use this module you will either need to be root, or
`kernel.perf_event_paranoid` may need to be set to a lower value than
the default, look this up before using it.

If you have a one-liner you want to test:

```
$ perl -Mblib -MLinux::libperf::Simple=report -e 'report(sub { for (1.. 100_000_000) { } })'
branch-misses: 5,236
branches: 2,133,471,368
bus-cycles: 15,710,865
cache-misses: 3,377
cache-references: 29,733
context-switches: 3
cpu-migrations: 1
cycles: 2,373,174,556
instructions: 10,194,546,708
page-faults: 0
task-clock: 916,441,424
```

Otherwise you can create an object and start and stop stats
collection, and finally fetch the results:

```
use Linux::libperf::Simple;
my $perf = Linux::libperf::Simple->new;
$perf->enable;
# code to benchmark here
...
$perf->disable;
my $results = $perf->results;
use Data::Dumper;
print Dumper($results);
```

# Troubleshooting

Unfortunately `libperf`'s reporting isn't very good, if libperf fails
to initialize try using `strace` to see details on which system call
actually failed, eg you might try:

```
strace -o trace.txt perl -MLinux::libperf::Simple=run -e 'run(sub {})'
```
and look over `trace.txt` to see why it failed.
