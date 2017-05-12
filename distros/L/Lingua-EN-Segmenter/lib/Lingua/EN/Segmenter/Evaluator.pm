package Lingua::EN::Segmenter::Evaluator;

=head1 NAME

Lingua::EN::Segmenter::Evaluator - Evaluate a segmenting method

=head1 SYNOPSIS
 
    my $tiling_segmenter = Lingua::EN::Segmenter::TextTiling->new();

    foreach (@ARGV) {
        my $input = read_file($_);

        print "\nFile name: $_\n";

        printf "Results from TextTiling algorithm:
      Strict scoring:       %2d%% recall, %2d%% precision
      Relaxed scoring:      %2d%% recall, %2d%% precision
      V. relaxed scoring:   %2d%% recall, %2d%% precision
    ", calc_stats(evaluate_segmenter($tiling_segmenter,20,$input));
    }

=head1 DESCRIPTION

See synopsis.

Also check out segmenter.pl in the eg directory.

=head1 BUGS

This module only works correctly when the segmenter has a MIN_SEGMENT_SIZE >= 2.

=head1 AUTHORS

David James <splice@cpan.org>

=head1 SEE ALSO

L<Lingua::EN::Segmenter::TextTiling>, L<Lingua::EN::Segmenter::Evaluator>,
L<http://www.cs.toronto.edu/~james>

=cut


$VERSION = 0.10;
@EXPORT_OK = qw(evaluate_segmenter calc_stats);
use strict;
use base 'Class::Exporter';
use Math::HashSum qw(hashsum);

# Create a new Evaluator object
sub new {
    my $self = shift;
    bless { 
        @_
    }, $self
}


# Evaluate the segmenter on a particular input
sub evaluate_segmenter {
    my ($self, $segmenter, $input, $num_segments) = @_;
    
    $self->{taken} = {}; 
       
    my $num_paragraphs = @{$segmenter->{splitter}->paragraph_breaks($input)};

    my $break = $self->{break} = $segmenter->{splitter}->segment_breaks($input);
    $num_segments ||= scalar keys %{$break};
    my $assigned = $self->{assigned} = $segmenter->segment($num_segments, $input);
    
    my @description = map { {
        para=>$_,
        true=>exists $break->{$_},
        label=>$assigned->{$_},
        strict=>exists $break->{$_} && exists $assigned->{$_},
        relaxed=>$self->relaxed_weight($_),
        very_relaxed=>$self->very_relaxed_weight($_),
    } } (0..$num_paragraphs-1);
        
    return @description;
}

# Get the weight of a particular index based on a relaxed scheme
# NOTE: Assumes that MIN_SEGMENT_SIZE >= 2
sub relaxed_weight {
    my ($self, $i) = @_;
    my $assigned = $self->{assigned}{$i};
    my $break = $self->{break}{$i};
    if ($assigned and $break) {
        $self->take(1,"break",$i);
        $self->take(1,"assigned",$i);
        return 1;
    }
    if (defined $assigned) {
        if ($assigned =~ /L/ and $self->take(1,"break",$i-1) or
            $assigned =~ /R/ and $self->take(1,"break",$i+1)) {
            return 0.8;
        } elsif ($self->take(1,"break",$i-1) or $self->take(1,"break",$i+1)) {
            return 0.4;
        }
    } elsif (exists $self->{break}{$i}) {
        if ($self->take(1,"assigned",$i-1,"R") or 
            $self->take(1,"assigned",$i+1,"L")) {            
            return 0.8;
        } elsif ($self->take(1,"assigned",$i-1) or 
            $self->take(1,"assigned",$i+1)) {
            
            return 0.4;
        }
    }
    return 0;
}

# Get the weight of a particular index based on a very relaxed scheme
# NOTE: Assumes that MIN_SEGMENT_SIZE >= 2
sub very_relaxed_weight {
    my ($self, $i) = @_;
    my $assigned = $self->{assigned}{$i};
    my $break = $self->{break}{$i};
    
    if ($assigned or $break) {
        foreach (-2..2) {
            $assigned ||= $self->take(2,"assigned",$i+$_);
            $break ||= $self->take(2,"break",$i+$_);
        }
    }
    return ($assigned and $break);
}

# Mark a particular index as used if it's not already used 
sub take {
    my ($self,$count,$which,$i,$req) = @_;
    if (!$self->{taken}{$count}{$which}{$i} and $self->{$which}{$i}) {
        if (!$req or $self->{$which}{$i} =~ /$req/) {
            $self->{taken}{$count}{$which}{$i}++;
            return 1;
            
        }
    }
    return;
}

# Calculate precision and recall for strict, relaxed, very_relaxed
sub calc_stats {    
    my $self = shift;
    my %sum = hashsum map { %$_ } @_;

    # Ensure "R" and "L" count as categories
    $sum{label} = grep { $_->{label} } @_;

    # Ensure relaxed counts don't double-count
    $sum{relaxed} -= ($sum{relaxed} - $sum{strict})/2;
    $sum{very_relaxed} -= ($sum{very_relaxed} - $sum{strict})/2;
    
    # Sanity checks
    if ($sum{true} == 0) {
        die "No segment_breaks found. Please label the true segments in the original text so that we can evaluate the performance of the Segmenting algorithm";
    } elsif ($sum{label} == 0) {
        die "No segments labelled by Segmenting algorithm";
    }

    # Return results 
    return map { 100*$sum{$_}/$sum{true}, 100*$sum{$_} / $sum{label} } 
        qw(strict relaxed very_relaxed);
}

1;

