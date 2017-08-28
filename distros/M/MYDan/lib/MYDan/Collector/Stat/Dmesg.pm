package MYDan::Collector::Stat::Dmesg;

use strict;
use warnings;
use Carp;
use POSIX;

use Data::Dumper;
use MYDan::Collector::Util;

my %REGEX = 
(
    'I/O error' => 'I/O',
    'SCSI error' => 'SCSI',
    'SCSI bus speed downshifted' => 'SCSI',
    'Fatal drive error' => 'DRIVE',
    'CHECK CONDITION sense key' => 'sense',
    '.*error.*returned' => 'returned',
    'mpt2.*log_info.*originator.*code.*sub_code' => 'mpt2',
    'task abort' => 'taskabort',
    'sd.*timing out command' => 'timing',
    'Hardware Error(?!]: Machine check events logged)' => 'Hardware',
    'pblaze_pcie_interrupt' => 'flash',
);

sub co
{
    my ( $this, @stat ) = shift;

    my $grep = join '|', keys %REGEX;

    my @data = MYDan::Collector::Util::qx ( "dmesg |grep -iE -m 10 \"$grep\"" );

    my %data = map{ $_ => 0 }values %REGEX;
    push @stat, [ 'DMESG', 'all', sort keys %data ];


    for my $data ( @data )
    {
        map { if( $data =~ /$_/ ) { $data{$REGEX{$_}} ++; next; } }keys %REGEX;
    }
    
    map{ $data{all} += $_ }values %data;
    $data{DMESG} = 'error';

    push @stat, [ map{ $data{$_} }@{$stat[0]} ];

    return \@stat;
}

1;
