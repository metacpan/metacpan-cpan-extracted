#!/usr/bin/perl

use strict;
use warnings;

use MARC::Detrans;
use MARC::Batch;
use Getopt::Long;
use Pod::Usage;

=head1 NAME

convert.pl - a sample MARC::Detrans driver

=head1 SYNOPSIS
    
    convert.pl --config=options.xml --in=marc.dat --out=new.dat

=head1 DESCRIPTION

This is a sample script that illustrates how to use MARC::Detrans
for detransliterating MARC records. It was customized mainly for its
first user (Queens Borough Public Library) so you may want to change
stuff in here. Most of what you'll find is code to enable logging,
MARC::Detrans takes care of the actual detransliteration in a few lines 
of code.

=head1 OPTIONS

=over 4

=item * --config

The location of the XML config file.

=item * --in

The location of the MARC input file.

=item * --out

The location to write out the new records. If unspecified log messages
will be sent to STDOUT.

=item * --log

Optional parameter to log messages to a file rather than the screen.

=back

=cut

## gather options or output documentation
my ( $config, $in, $out, $log ); 
GetOptions(
    'config=s'      => \$config,
    'in=s'          => \$in,
    'out=s'         => \$out,
    'log=s'         => \$log,
);
pod2usage( {verbose=>2} ) if ! ($config and $in and $out);

## create our detransliteration engine
my $detrans = MARC::Detrans->new( config => $config );

## open up some MARC records
my $batch = MARC::Batch->new( 'USMARC', $in );
open( OUT, ">$out" );

## redirect to log if necessary
if ( $log ) { open( LOG, ">$log" ); }
else { *LOG = *STDOUT; }

## setup some counters
my $recordCount = 0;
my $writtenCount = 0;
my $errorCount = 0;
my $translationSkip = 0;
my $parallelSkip = 0;

RECORD: while ( my $record = $batch->next() ) {
    $recordCount++;

    ## here's the magic :)
    my $new = $detrans->convert( $record );

    ## print out any errors 
    ERROR: foreach my $error ( $detrans->errors() ) {
        $errorCount++;

        ## instead of outputting distinct errors about skipped
        ## fields due to translation and parallel title just 
        ## keep a running count
        if ( $error =~ /skipped because of translation/ ) {
            $translationSkip++;
            next ERROR;
        }
        if ( $error =~ /skipped parallel title/ ) {
            $parallelSkip++;
            next ERROR;
        }

        ## use the 001 for log messages if we can
        ## otherwise use the message count
        my $f001 = $record->field('001');
        if ( $f001 ) { print LOG $f001->data(), ": $error\n"; }
        else { print "record $recordCount: $error\n"; }
    }

    ## output the new record if one was returned 
    if ( $new ) { 
        ## add a 940 note indicating we touched this record
        $new->insert_fields_ordered( 
            MARC::Field->new( '940', '', '', a => 
                'Edited by MARC::Detrans at '.localtime())
        );
        print OUT $new->as_usmarc();
        $writtenCount++;
    }
}

## output summary stats

print LOG "\n\nJOB STATISTICS\n\n";
printf LOG "%-23s%15d\n", 'Records Processed', $recordCount;
printf LOG "%-23s%15d\n", 'Records Written', $writtenCount;
printf LOG "%-23s%15d\n", '880 Fields Added', $detrans->stats880sAdded();
printf LOG "%-23s%15d\n", 'Errors', $errorCount;
printf LOG "%-23s%15d\n", 'Skipped Parallel Title', $parallelSkip;
printf LOG "%-23s%15d\n", 'Skipped Translation', $translationSkip;

## statsDetransliterated() returns a hash of statistics
## for which field/subfield combinations were transliterated
## we will just output them in sorted order
my %transCounts = $detrans->statsDetransliterated();
my @sorted = sort { $a cmp $b } keys(%transCounts);
print LOG "\nFields/Subfields Transliterated: \n";
foreach ( @sorted ) {
    printf LOG "%10s%10d\n", $_, $transCounts{ $_ };
}

## statsCopied retuns a similar has of statistics
## for which field/subfield combinations were copied
## we will just output them in sorted order
my %copyCounts = $detrans->statsCopied();
@sorted = sort { $a cmp $b } keys(%copyCounts);
print LOG "\nFields/Subfields Copied: \n";
foreach ( @sorted ) {
    printf LOG "%10s%10d\n", $_, $copyCounts{ $_ };
}

print LOG "\n\n";

