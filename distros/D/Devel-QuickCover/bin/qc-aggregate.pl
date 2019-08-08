#!/usr/bin/perl

# Aggregate a bunch of cover files into a Sereal "database".

use strict;
use warnings;
use Getopt::Long;

use Devel::QuickCover::Report;

my $QC_DATABASE   = 'qc.dat';
my $QC_PATH       = '/tmp';
my $QC_PREFIXES   = 'QC';      # Could be '(QC|CQ|XX)'
my $QC_EXTENSIONS = 'txt';     # Could be '(txt|dat|db)'

my $HELP_MSG =<<END;
qc-aggregate.pl - Aggregate Devel::QuickCover cover files

USE:

    qc-aggregate.pl

DESCRIPTION:

qc-aggregate.pl aggregates all Devel::QuickCover files $QC_PATH/${QC_PREFIXES}_\*.$QC_EXTENSIONS
into a Sereal database that can be converted into Devel::Cover output.
The data is written to $QC_DATABASE. If this file exists, the new data
is added to it.
END

exit main();

sub main {
    my %options = ();
    GetOptions(\%options, 'help|h');

    if (defined $options{help}) {
        print $HELP_MSG;
        return 0;
    }

    my $report = Devel::QuickCover::Report->new;

    $report->load($QC_DATABASE)
        if -f $QC_DATABASE;

    my @files = get_file_list($QC_PATH);
    for my $file (@files) {
        printf("Processing file %s... ", $file);
        $report->merge($file);
        unlink($file);
        printf("done\n");
    }

    if (!$report->changes) {
        printf("Data unchanged, not saving\n");
    } else {
        printf("After %d changes, saving data\n", $report->changes);
        $report->save($QC_DATABASE);
    }

    return 0;
}

sub get_file_list {
    my ($path) = @_;

    if (!opendir(DIR, $path)) {
        printf("Could not read directory [%s]\n", $path);
        return ();
    }

    my @list;
    while (my $file = readdir(DIR)) {
        # Ignore files beginning with a period
        next if ($file =~ m/^\./);

        # Ignore files that don't match QC_*.txt
        next if ($file !~ m/^($QC_PREFIXES)_.*\.($QC_EXTENSIONS)$/);

        push(@list, $path . '/' . $file);
    }
    closedir(DIR);
    return @list;
}
