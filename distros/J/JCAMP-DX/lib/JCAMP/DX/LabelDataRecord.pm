#------------------------------------------------------------------------------
#$Author: andrius $
#$Date: 2021-02-10 13:44:25 +0200 (Tr, 10 vas. 2021) $
#$Revision: 94 $
#$URL: svn+ssh://www.crystallography.net/home/coder/svn-repositories/JCAMP-DX/tags/v0.03/lib/JCAMP/DX/LabelDataRecord.pm $
#------------------------------------------------------------------------------
#*
#  Label Data Record object
#**

package JCAMP::DX::LabelDataRecord;

use strict;
use warnings;

# ABSTRACT: Label Data Record object
our $VERSION = '0.03'; # VERSION

use JCAMP::DX::ASDF qw(decode);

our $max_line_length = 80;
our @records_with_variable_lists = qw(
    PEAKTABLE
    XYDATA
    XYPOINTS
);

sub new
{
    my( $class, $label, $value ) = @_;

    if( defined $value ) {
        $value =~ s/^\s+//;
        $value =~ s/\s+$//;
    }

    my $self = {
        label => $label,
        value => $value,
    };

    $self = bless $self, $class;
    return $self if !defined $value;

    # Converting records with variable lists
    if( grep { $_ eq $self->canonical_label }
             @records_with_variable_lists ) {
        parse_AFFN_or_ASDF( $self );
    }

    return $self;
}

sub canonicalise_label
{
    my( $label ) = @_;
    $label = uc $label;
    $label =~ s/[\s\-\/\\_]//g;
    return $label;
}

sub label
{
    return $_[0]->{label};
}

sub canonical_label
{
    return canonicalise_label( $_[0]->label );
}

sub value
{
    return $_[0]->{value};
}

sub length
{
    my( $self ) = @_;
    if( $self->{variables} ) {
        return scalar @{$self->{$self->{variables}[0]}};
    } else {
        return 1;
    }
}

sub parse_AFFN_or_ASDF
{
    my( $ldr ) = @_;

    # Process the variable list:
    $ldr->{value} =~ s/^\s*(\S+)\s*\n//s;
    my $variable_list = $1;

    return if !$variable_list; # Not an ASDF LDR actually

    my @lines = split /\n/, $ldr->value;
    if( $variable_list =~ /^\((.)\+\+\((.)\.\.\2\)\)$/ ) {
        # (X++(Y..Y)) form
        delete $ldr->{value};
        my @variables = ( $1, $2 );
        $ldr->{variables} = \@variables;

        my @checkpoints =
            map { s/^\s*([+-]?\d*\.?\d+([+-]?E\d*)?)//; $1 } @lines;
        my @lines =
            map { s/^\s+//; s/\s+$//; [ decode( $_ ) ] } @lines;
        my $diff;
        for my $i (0..$#checkpoints) {
            if( $i < $#checkpoints ) {
                $diff = ($checkpoints[$i+1] - $checkpoints[$i]) / @{$lines[$i]};
            }
            push @{$ldr->{$variables[0]}},
                 map { $checkpoints[$i] + $_ * $diff } 0..$#{$lines[$i]};
            push @{$ldr->{$variables[1]}}, @{$lines[$i]};
        }
    } elsif( $variable_list =~ /^\(([a-z0-9]+)\.\.\1\)$/i ) {
        # (XY..XY) and (XYZ..XYZ) form
        delete $ldr->{value};
        my @variables = split '', $1;
        $ldr->{variables} = \@variables;

        my @pairs = map { split /[;\s]+/, $_ } @lines;
        for my $pair (@pairs) {
            my @var = split /,/, $pair;
            for my $i (0..$#var) {
                push @{$ldr->{$variables[$i]}}, $var[$i];
            }
        }
    } else {
        die "cannot process variable list of form '$variable_list'";
    }
}

sub to_string
{
    my( $ldr ) = @_;
    my $output = '##' . $ldr->label . '=';
    my $value;
    if( $ldr->{variables} ) {
        $value = '(' . join( '', @{$ldr->{variables}} ) . '..' .
                       join( '', @{$ldr->{variables}} ) . ")\n";
        my $line = '';
        for my $i (0..($ldr->length-1)) {
            my $point = join( ',', map { $ldr->{$_}[$i] }
                                       @{$ldr->{variables}} ) . ' ';
            if( CORE::length( $line . $point ) < $max_line_length ) {
                $line .= $point;
            } else {
                $value .= "$line\n";
                $line = $point;
            }
        }
        $value .= $line . "\n" if $line;
    } else {
        $value = $ldr->{value} . "\n";
    }
    $output .= $value;
    return $output;
}

1;
