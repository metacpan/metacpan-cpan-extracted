package File::FormatIdentification::RandomSampling;
# ABSTRACT: methods to identify content of device o media files using random sampling
our $VERSION = '0.005'; # VERSION:
# (c) 2020/2021 by Andreas Romeyke
# licensed via GPL v3.0 or later


use strict;
use warnings;
use feature qw(say);
use Moose;

has 'bytegram' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {[]},
);




sub init_bytegrams {
    my $self = shift;
    my $bytegram_ref = $self->{'bytegram'};
    $bytegram_ref->[0] = [(0) x 256]; # onegram
    $bytegram_ref->[1] = [(0) x 65536]; #bigram
    return 1;
}

sub BUILD {
    my $self = shift;
    $self->init_bytegrams();
    return 1;
}



sub update_bytegram {
    my $self = shift;
    my $buffer = shift;
    if (defined $buffer) {
        my $bytegram_ref = $self->{'bytegram'};
        my @bytes = unpack "C*", $buffer;
        my @words = unpack "S*", $buffer;
        #    my @bytes = map{ ord($_)} split //, $buffer;
        if (scalar @bytes > 0) {
            my @onegram = @{$bytegram_ref->[0]};
            my @bigram = @{$bytegram_ref->[1]};
            foreach my $byte (@bytes) {
                $onegram[$byte]++;
            }
            foreach my $word (@words) {
                $bigram[$word]++;
            }
            $bytegram_ref->[0] = \@onegram;
            $bytegram_ref->[1] = \@bigram;
        }
    }
    return 1;
}


sub calc_histogram { # use only the most significant first 8 entries
    my $self = shift;
    my $bytegram_ref = $self->{'bytegram'};
    my @bytes_sorted = sort {$bytegram_ref->[0]->[$b] <=> $bytegram_ref->[0]->[$a]} (0..255);
    my @words_sorted = sort {$bytegram_ref->[1]->[$b] <=> $bytegram_ref->[1]->[$a]} (0 .. 65535);
    # show only 8 most onegrame bytes
    my @bytes_truncated = @bytes_sorted[0..7];
    my @words_truncated = @words_sorted[0..7];
    my %histogram;
    foreach my $byte (@bytes_truncated) {
        push @{$histogram{onegram}}, $byte; #$bytegram_ref->[0]->[$byte];
    }
    foreach my $word (@words_truncated) {
        push @{$histogram{bigram}}, $word; #$bytegram_ref->[1]->[$word];
    }
    return \%histogram;
}


sub is_uniform {
    my $self = shift;
    #say "is_uniform?";
    my $bytegram_ref = $self->{'bytegram'};
    my $sum = 0;
    my $n = 0;
    my @unigram = @{$bytegram_ref->[0]};
    foreach my $byte (0 .. 255) {
        if ($unigram[$byte] > 0) {
            $n +=  $unigram[$byte];
            $sum += ($unigram[$byte] * $byte);
        }
    }
    if ($n == 0) { return;}
    my $expected = (256)/2;
    my $mean = ($sum/$n);
    #say "expected=$expected, sum=$sum, mean=$mean";
    return (abs($expected - $mean) < 4);
}


sub is_empty {
    my $self = shift;
    #say "is_empty?";
    my $bytegram_ref = $self->{'bytegram'};
    my $sum = 0;
    my $n = 0;
    my @unigram = @{$bytegram_ref->[0]};
    foreach my $byte (0 .. 255) {
        if ($unigram[$byte] > 0) {
            $n   += $unigram[$byte];
            $sum += ($unigram[$byte] * $byte);
        }
    }
    if ($n == 0) { return;}
    my $expected = 0;
    my $mean = ($sum/$n);
    # say "expected=$expected, mean=$mean";
    my $criteria = abs($expected - $mean) < 4;
    return ( $criteria);
}


sub is_text {
    my $self = shift;
    #say "is_text?";
    my $bytegram_ref = $self->{'bytegram'};
    # many Bytes in range 32 .. 173
    my $printable = 0;
    my $non_printable = 0;
    my @unigram = @{$bytegram_ref->[0]};
    foreach my $byte (0 .. 255) {
        #say "bytegram[$byte] = ". $bytegram_ref->[0]->[$byte];
        if ($unigram[$byte] > 0) {
            if (($byte >= 32) && ($byte <= 173)) {
                $printable += ($unigram[$byte]);
            }
            else {
                $non_printable += ($unigram[$byte]);
            }
        }
    }
    my $ratio = $printable / ($printable + $non_printable + 1); # +1 to avoid division by zero
    #say "ratio text = $ratio (print=$printable, nonprint=$non_printable";
    return ($ratio > 0.9);
}


sub is_video { # quicktime
    my $self = shift;
    #say "is_video?";
    my $bytegram_ref = $self->{'bytegram'};
    # many Bytes with 0x6d, ratio > 1/256 per read Byte
    my $mp_indicator = 0;
    my $other = 0;
    my @unigram = @{$bytegram_ref->[0]};
    # MPEG-TS: Synchrobyte = 0x47 5times with distance of 188bytes
    # MP4/Quicktime: Atom 'mvhd'
    # General: 0x6d value
    foreach my $byte ( 0 .. 255) {
        if ($unigram[$byte] > 0) {
            if ($byte != 0x6d) {
                $other += $unigram[$byte];
            } else { # $byte = 0x6d
                $mp_indicator += $unigram[$byte];
            }
        }
    }
    my $ratio = $mp_indicator / ($mp_indicator + $other + 1); # +1 to avoid division by zero
    #say "ratio=$ratio ($mp_indicator / ".($mp_indicator + $other + 1).") 47=", chr(0x47);
    return ($ratio > 2/256);
}



sub calc_type {
    my $self = shift;
    my $buffer = shift;

    $self->init_bytegrams();
    $self->update_bytegram($buffer);

    if ($self->is_empty()) {
        return "empty";
    }
    elsif ($self->is_text()) {
        return "text";
    }
    elsif ($self->is_video()) {
        return "video/audio";
    }
    elsif ($self->is_uniform()) {
        return "random/encrypted/compressed";
    }
    return "undef";
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FormatIdentification::RandomSampling - methods to identify content of device o media files using random sampling

=head1 VERSION

version 0.005

=head1 SYNOPSIS

This module is suitable to get a good estimation about the content of media (or files). It uses random sampling of sectors to obtain heuristics about the content types.

To check the base type of a given binary string:

  my $ff = File::FormatIdentification::RandomSampling->new(); # basic instantiation
  my $type = $ff->calc_type($buffer); # calc type of given binary string

=head1 NAME

File::FormatIdentification::RandomSampling

=head1 TOOLS

The following tools are supplied with this module and are presented below:

=head2 F<crazy_fast_image_scan.pl>

This script scans devices or images very fast using random sampling and reports wht kind of content could be found.

For a detailed documentation use the included POD there.

=head2 F<cfi_create_training_data.pl>

This script scans a bunch of files and calcs most frequent one- and bigrams and stores them in a CSV file.

=head2 F<cfi_learn_model.pl>

This script uses the CSV file and prints a new model module in style of L<File::FormatIdentification::RandomSampling::Model> using L<AI::DecisionTree>.

=head1 SOURCE

The actual development version is available at L<https://art1pirat.spdns.org/art1/crazy-fast-image-scan>

=head1 METHODS

=head2 init_bytegrams

resets the internal bytegram state. Also called if object will be instantiated

=head2 update_bytegram

=over 1

=item C<$buffer> - updates the internal bytegram states using C<$buffer>

=back

=head2 calc_histogram

uses the most significant first 8 bytegram entries to from a histogram, returned as hash reference

=head2 is_uniform

returns true, if 1-byte bytegrams are uniform

=head2 is_empty

returns true, if 1-byte bytegrams indicating empty buffers

=head2 is_text

returns true, if 1-byte bytegrams are typical for texts

=head2 is_video

returns true, if 1-byte bytegrams are typical for MPEG/Quicktime Videos

=head2 calc_type

returns string indicating type of a given buffer

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andreas Romeyke.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
