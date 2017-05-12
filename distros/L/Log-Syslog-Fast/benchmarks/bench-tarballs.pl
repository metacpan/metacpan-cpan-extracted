#!/usr/bin/env perl

# meta-benchmark that compares different versions and implementations of the module

use strict;
use warnings;

use Cwd 'abs_path';
use FindBin '$Bin';
use Getopt::Long;
use File::Temp 'tempdir';

GetOptions(
    'verbose!'  => \(my $verbose),
);

my $temp_dir = tempdir(CLEANUP => 1);

my @tarballs = map { abs_path $_ } @ARGV;

my @benchable;
for my $tarball (@tarballs) {
    (my $name = $tarball) =~ s,.*/,,;

    my $path = "$temp_dir/$name";

    mkdir $path;
    chdir $path;

    warn "Unpacking $tarball in $path\n";
    system "tar -zxf $tarball" and die "$tarball: failed to unpack";

    my $dh;
    opendir $dh, '.' or die "couldn't open dir: $!";
    my @contents = grep {$_ ne '.' && $_ ne '..'} readdir $dh;
    my $build_dir = shift @contents;
    die "unexpected file $build_dir in $path" unless -d $build_dir;
    $build_dir = abs_path $build_dir;
    chdir $build_dir or die "couldn't cd to $temp_dir: $!";

    unless (-e 'blib') {
        warn "Building $name\n";
        if (system "perl Makefile.PL && make") {
            warn "$tarball: error building\n";
            system "rm -rf $build_dir";
            next;
        }
    }

    push @benchable, [$name, $build_dir];
}

my %results;
for my $bench (@benchable) {
    my ($name, $build_dir) = @$bench;
    chdir $build_dir;

    my $script = "$Bin/bench-sizes.pl";

    my @classes = ('Log::Syslog::Fast');
    push @classes, 'Log::Syslog::Fast::PP' if -e 'blib/lib/Log/Syslog/Fast/PP.pm';

    for my $class (@classes) {
        print "Benchmarking $name/$class\n";
        chomp(my @results = qx{perl -Mblib $script --class $class 2>&1});
        $verbose && print "$_\n" for @results;
        for (@results) {
            if (m{(\d+)[^@]+@ ([0-9.]+)/s}) {
                $results{$class}{$name}{sprintf "%4d", $1} = 0+$2;
            }
        }
    }
}

use JSON;
print JSON->new->pretty->canonical->encode(\%results);

END { chdir '/'; }
