#------------------------------------------------------------------------------
#$Author: andrius $
#$Date: 2018-11-21 13:22:13 +0200 (Tr, 21 lapkr. 2018) $
#$Revision: 33 $
#$URL: svn+ssh://www.crystallography.net/home/coder/svn-repositories/jcamp-dx/trunk/lib/JCAMP/DX.pm $
#------------------------------------------------------------------------------
#*
#  Parser for JCAMP-DX format.
#**

package JCAMP::DX;

use strict;
use warnings;

our $VERSION = '0.01';

use JCAMP::DX::ASDF qw(decode);

our @records_with_variable_lists = qw(
    PEAKTABLE
    XYDATA
    XYPOINTS
);

sub parse_jcamp_dx
{
    my( $filename, $options ) = @_;
    open( my $inp, $filename );

    my $title = <$inp>;
    $title =~ s/^\s*##title=//i;
    my $block = read_block( $inp, $options );
    $block->{title} = $title;

    close $inp;
    return $block;
}

sub read_block
{
    my( $inp, $options ) = @_;
    my $block = {};
    while( (my $line = <$inp>) !~ /^\s*##END=/ ) {
        $line =~ s/\$\$.*$//; # removing comments
        $line =~ s/\n$//;     # removing newlines
        next if $line =~ /^\s*$/;
        if( $line =~ s/^\s*##title=//i ) {
            my $inner_block = read_block( $inp, $options );
            $inner_block->{title} = $line;
            push @{$block->{blocks}}, $inner_block;
        } elsif( $line =~ /^\s*##([^=]+)=(.*)$/ ) {
            my( $label, $data_set ) = ( $1, $2 );
            $label = canonicalise_label( $label );
            push @{$block->{labels}}, $label;
            push @{$block->{data}{$label}}, $data_set;
        } elsif( $block->{labels} ) {
            my $last_label = $block->{labels}[-1];
            $block->{data}{$last_label}[0] .= "\n$line";
        }
    }

    # Converting records with variable lists
    for (@records_with_variable_lists) {
        next if !exists $block->{data}{$_};
        $block->{data}{$_} = parse_AFFN_or_ASDF( $_, $block->{data}{$_}[0] );
    }

    return $block;
}

sub parse_AFFN_or_ASDF
{
    my( $label, $record ) = @_;

    my $record_now = {};

    # Process variable list, if such exists:
    if( grep { $_ eq $label } @records_with_variable_lists ) {
        $record =~ s/^\s*(\S+)\s*\n//s;
        $record_now->{variable_list} = $1;
    }

    my @lines = split /\n/, $record;
    if( $record_now->{variable_list} &&
        $record_now->{variable_list} =~ /^\((.)\+\+\((.)\.\.\2\)\)$/ ) {
        # (X++(Y..Y)) form
        my @variables = ( $1, $2 );

        my @checkpoints =
            map { s/^\s*([+-]?\d*\.?\d+([+-]?E\d*)?)//; $1 } @lines;
        my @lines =
            map { s/^\s+//; s/\s+$//; [ decode( $_ ) ] } @lines;
        my $diff;
        for my $i (0..$#checkpoints) {
            if( $i < $#checkpoints ) {
                $diff = ($checkpoints[$i+1] - $checkpoints[$i]) / @{$lines[$i]};
            }
            push @{$record_now->{$variables[0]}},
                 map { $checkpoints[$i] + $_ * $diff } 0..$#{$lines[$i]};
            push @{$record_now->{$variables[1]}}, @{$lines[$i]};
        }
    }

    return $record_now;
}

sub canonicalise_label
{
    my( $label ) = @_;
    $label = uc $label;
    $label =~ s/[\s\-\/\\_]//g;
    return $label;
}

1;
