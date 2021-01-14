#!/usr/bin/perl
# (c) 2020 by Andreas Romeyke
# licensed via GPL v3.0 or later
# call ./cfi_lear_model.pl CSV-file
# outputs perl code for a model of File::FormatIdentification::RandomSampling::Model
# PODNAME: cfi_learn_model.pl
use strict;
use warnings FATAL => 'all';
use feature qw(say);
use AI::DecisionTree;
my $dtree = AI::DecisionTree->new( noise_mode => 'pick_best', verbose => 1, max_depth => 8);
my $training_file = shift @ARGV;
open (my $fh, "<", $training_file);
my $header_line = <$fh>;
#chomp $header_line;
#my @header = split(/,/, $header_line);
my @header = qw(onegram1 onegram2 onegram3 onegram4 onegram5 onegram6 onegram7 onegram8 bigram1 bigram2 bigram3 bigram4 bigram5 bigram6 bigram7 bigram8 mimetype);
foreach my $line (<$fh>) {
    chomp $line;
    if ($line =~ m/^onegram/) { next;}
    my @values = split(/, */, $line);
    $dtree->add_instance(
        attributes => {
            $header[0] => $values[0],
            $header[1] => $values[1],
            $header[2] => $values[2],
            $header[3] => $values[3],
            $header[4] => $values[4],
            $header[5] => $values[5],
            $header[6] => $values[6],
            $header[7] => $values[7],
            $header[8] => $values[8],
            $header[9] => $values[9],
            $header[10] => $values[10],
            $header[11] => $values[11],
            $header[12] => $values[12],
            $header[13] => $values[13],
            $header[14] => $values[14],
            $header[15] => $values[15],
        },
        result     => $values[16],
        name       => $header[16],
    );
    #p($dtree);

}
$dtree->train();
#use Data::Printer;
#my $ruletree = $dtree->rule_tree();
#p($ruletree);
#p( $dtree);
my @rule_statements = $dtree->rule_statements();
say <<'HEADER';
package File::FormatIdentification::RandomSampling::Model;
# ABSTRACT: methods to identify files using random sampling
# VERSION:
# (c) 2020 by Andreas Romeyke
# licensed via GPL v3.0 or later
use strict;
use warnings;
use feature qw(say);
use Moose;
use List::Util qw( any );

sub calc_mimetype {
    my $self = shift;
    my $histogram = shift;
    my @bigrams = @{$histogram->{bigram}};
    my @onegrams = @{$histogram->{onegram}};
HEADER


say join("\n", map {
    s/if ([^-]*)-> ('[^']*')/\tif ($1) { return $2 ; }/;
    s/bigram[0-9]*='([^']*)'/(any {\$_ == $1 } \@bigrams)/g;
    s/onegram[0-9]*='([^']*)'/(any {\$_ == $1 } \@onegrams)/g;
    $_;
} @rule_statements);

say <<'FOOTER';
    return 'unknown';
}

1;
FOOTER

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

cfi_learn_model.pl - methods to identify files using random sampling

=head1 VERSION

version 0.005

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andreas Romeyke.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
