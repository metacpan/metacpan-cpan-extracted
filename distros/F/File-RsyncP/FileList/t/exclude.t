#!/bin/perl

use File::RsyncP;
use Data::Dumper;

my $f = File::RsyncP::FileList->new({
            protocol_version   => 28,
        });

my @Tests = (
    #
    # Test 1: basic excludes with wildcards
    #
    {
        excludes => [
            {exclude => "*.doc"},
            {exclude => "*.xls"},
        ],
        tests => [
            {file => "other/bar.doc",  result => -1},
            {file => "other/bar.xls",  result => -1},
            {file => "other/bar.doc2", result => 0},
            {file => "other/bar.xls2", result => 0},
        ],
        data => "050000002a2e646f63050000002a2e786c7300000000",
    },

    #
    # Test 2: basic excludes and includes with wildcards
    #
    {
        excludes => [
            {exclude => "*.doc"},
            {include => "*.doc2"},
            {exclude => "*.xls"},
            {include => "*.xls2"},
        ],
        tests => [
            {file => "other/bar.doc",  result => -1},
            {file => "other/bar.xls",  result => -1},
            {file => "other/bar.doc2", result => 1},
            {file => "other/bar.xls2", result => 1},
        ],
        data => "050000002a2e646f63080000002b202a2e646f6332050000002a2e786c73080000002b202a2e786c733200000000",
    },

    #
    # Test 2: top-level patterns
    #
    {
        excludes => [
            {exclude => "/*/*.doc"},
            {exclude => "/*/*/*.xls"},
            {include => "*.xls2"},
        ],
        tests => [
            {file => "other/bar.doc",  result => -1},
            {file => "other/bar.xls",  result => 0},
            {file => "other/bar.doc2", result => 0},
            {file => "other/bar.xls2", result => 1},
        ],
        data => "080000002f2a2f2a2e646f630a0000002f2a2f2a2f2a2e786c73080000002b202a2e786c733200000000",
    },
);
my $numTests = @Tests;
print "1..$numTests\n";

my $testNum = 1;
foreach my $t ( @Tests ) {
    my $ok = 1;

    #
    # Add excludes
    #
    $f->exclude_list_clear();
    foreach my $e ( @{$t->{excludes}} ) {
        if ( defined($e->{exclude}) ) {
            $f->exclude_add($e->{exclude}, 0);
        } elsif ( defined($e->{include}) ) {
            $f->exclude_add($e->{include}, 2);
        }
    }

    #
    # Check list
    #
    my $exc = $f->exclude_list_get();
    #print STDERR Dumper $exc;
    if ( @$exc != @{$t->{excludes}} ) {
        printf(STDERR "Exclude list count mismatch: %d vs %d\n",
            scalar(@$exc), scalar(@{$t->{excludes}}));
        $ok = 0;
    }
    foreach my $e ( @{$t->{excludes}} ) {
        if ( defined($e->{exclude}) ) {
            if ( $e->{exclude} ne $exc->[0]{pattern} ) {
                printf(STDERR "Exclude list pattern mismatch: %s vs %s\n",
                    $e->{exclude}, $exc->[0]{pattern});
                $ok = 0;
            }
            if ( $exc->[0]{flags} & (1 << 4) ) {
                printf(STDERR "Exclude %s has wrong flag %d\n",
                    $e->{exclude}, $exc->[0]{flags});
                $ok = 0;
            }
        }
        if ( defined($e->{include}) ) {
            if ( $e->{include} ne $exc->[0]{pattern} ) {
                printf(STDERR "Exclude list pattern mismatch: %s vs %s\n",
                    $e->{include}, $exc->[0]{pattern});
                $ok = 0;
            }
            if ( !($exc->[0]{flags} & (1 << 4)) ) {
                printf(STDERR "Exclude %s has wrong flag %d\n",
                    $e->{include}, $exc->[0]{flags});
                $ok = 0;
            }
        }
        shift(@$exc);
    }

    #
    # Check files
    #
    foreach my $file ( @{$t->{tests}} ) {
        if ( $f->exclude_check($file->{file}, 0) != $file->{result} ) {
            $ok = 0;
            printf(STDERR "Exclude check on %s returns %d vs %d\n",
                   $file->{file},
                   $f->exclude_check($file->{file}, 0), $file->{result});
        }
    }

    #
    # Check encoding
    #
    $f->exclude_list_send();
    my $data = $f->encodeData();
    if ( defined($t->{data}) && $t->{data} ne unpack("H*", $data) ) {
        print(STDERR "Botch encoded data: ", unpack("H*", $data),
                            " vs $t->{data}\n");
        $ok = 0;
    }

    #
    # Print result
    #
    if ( $ok ) {
        print("ok $testNum\n");
    } else {
        print("not ok $testNum\n");
    }
    $testNum++;
}
