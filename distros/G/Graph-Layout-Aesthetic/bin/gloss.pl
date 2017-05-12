#!/usr/bin/perl -w
use strict;

use Getopt::Long 2.11;
use Pod::Usage;

use Graph::Layout::Aesthetic;
use Graph::Layout::Aesthetic::Monitor::GnuPlot;

my $VERSION = "0.01";

Getopt::Long::Configure ("bundling_override");

my %weight;
GetOptions('help|?|h'	=> \my $help,
           man		=> \my $man,
           version	=> \my $version,
           "it=o"	=> \my $iterations,
           "bt=f"	=> \my $begin_temp,
           "et=f"	=> \my $end_temp,
           "m!"		=> \my $monitor,
           "mr=o"	=> \my $monitor_rate,
           "s!"		=> \my $sleep,
           "d=o"	=> \my $dimensions,
           "stress!"	=> \my $stress,
           "edges!"	=> \my $edges,
           "cin=s"	=> \my $coord_infile,
           "knr=f"	=> \$weight{NodeRepulsion},
           "kmel=f"	=> \$weight{MinEdgeLength},
           "kcp=f"	=> \$weight{Centripetal},
           "kner=f"	=> \$weight{NodeEdgeRepulsion},
           "kmei=f"	=> \$weight{MinEdgeIntersect},
           "kmei2=f"	=> \$weight{MinEdgeIntersect2},
           "kpl=f"	=> \$weight{ParentLeft},
           "kmlv=f"	=> \$weight{MinLevelVariance},
           ) || pod2usage(-message  => "(-help gives the list of options)",
                          -existval => 2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
if ($version) {
    print<<"EOF";
gloss.pl (Ton Utils) $VERSION
EOF
    exit 0;
}
$monitor = 1 if defined $monitor_rate && !defined $monitor;

sub read_coordinates {
    my $file = shift;
    open(my $fh, "<", $file) || die "Could not open $file: $!";
    local $_;
    my @coords;
    my $current = -1;
    while (<$fh>) {
        next unless /^\s*BEGIN_COORDINATES\s*$/i;
        while (<$fh>) {
            if (/^\s*END_COORDINATES\s*$/i) {
                shift @coords while @coords && !$coords[0];
                return \@coords;
            }
            if (s/^\s*(\d+)\s*:\s*//) {
                $current = $1;
            } else {
                $current++;
            }
            die "Already have coordinates for point $current" if
                $coords[$current];
            $coords[$current] = [split];
        }
        die "No END_COORDINATES in $file\n";
    }
    die "No BEGIN_COORDINATES in $file\n";
}

my @edges;
my $max = -1;
my $min = 9**9**9;
local $_;
while (<>) {
    s/#.*//;
    next unless /\S/;
    if (my ($from, $to) = /^\s*(\d+)\s+(\d+)\s*$/) {
        for ($from, $to) {
            $max = $_ if $_ > $max;
            $min = $_ if $_ < $min;
        }
        push @edges, [$from, $to];
    } elsif (my ($vertex, $attribute) = /\s*(\d+)\s+\(\s*(\d+)\s*\)\s*$/) {
        # We don't do anything with attributes (currently)
    } else {
        die "Cannot parse line $.: $_";
    }
}
die "No edges\n" unless @edges;

my $graph = Graph::Layout::Aesthetic::Topology->new_vertices($max-$min+1);
$graph->add_edge($_->[0]-$min, $_->[1]-$min) for @edges;
$graph->finish;

my $aglo = Graph::Layout::Aesthetic->new($graph, $dimensions);
my $n;
for (keys %weight) {
    my $weight = delete $weight{$_};
    $aglo->add_force($_, $weight), $n++ if $weight;
}
warn("No aesthetics specified, so you'll get random placement\n") unless $n;

$aglo->all_coordinates(read_coordinates($coord_infile)) if
    defined $coord_infile;

$monitor &&= Graph::Layout::Aesthetic::Monitor::GnuPlot->new();
my $start = time;
$aglo->gloss(begin_temperature	=> $begin_temp,
             end_temperature	=> $end_temp,
             iterations		=> $iterations,
             monitor_delay	=> $monitor_rate,
             monitor		=> $monitor,
             hold		=> defined $coord_infile);
# $aglo->normalize;
my $elapsed = time() - $start;

if ($edges) {
    print "BEGIN_STATE\n";
    for ($aglo->increasing_edges) {
        for (@$_) {
            printf "%f ", $_ for @$_;
            print "\n";
        }
        print "\n";
    }
    print "END_STATE\n";
    print "Elapsed time = $elapsed seconds\n";
} else {
    print "BEGIN_COORDINATES\n";
    for ($aglo->all_coordinates) {
        # print $min++, ": @$_\n";
        print "@$_\n";
    }
    print "END_COORDINATES\n";
}
print STDERR "Stress=", $aglo->stress, "\n" if $stress;
<STDIN> if $sleep;

__END__

=head1 NAME

gloss.pl - A commandline graph layout tool

=head1 SYNOPSIS

gloss.pl [options] [file ...]

=head1 DESCRIPTION

B<gloss.pl> is a tool which does graph layout using the aglo (Aesthetic Graph
Layout) method. The graph is read from the standard input or a file, layout is
performed according to the aesthetic combination specified on the command line,
and the resulting layout is printed on standard output.

There  is  a  facility  for monitoring the progress of the layout using
L<gnuplot|gnuplot(1)>.

This program tries to mimic the interface of the L<gloss|gloss(1)> program
that's part of the original aglo code.

=head1 OPTIONS

The floating point argument that all aesthetic options have is the weight
for that aesthetic

=over

=item B<-edges>

display edges instead of coordinates. This is the output format the
old gloss program gave.

=item B<-it integer>

Number of iterations, defaults to 1000

=item B<-bt float>

Beginning temperature, defaults to 100

=item B<-et float>

Ending temperature, defaults to 0.001

=item B<-m>

Turn monitor on

=item B<-mr integer>

Monitor update rate in seconds, default 2

=item B<-s>

Sleep until newline at end

=item B<-knr float>

Node repulsion aesthetic

=item B<-kmel float>

Minimize edge lengt aesthetic

=item B<-kcp float>

Centripetal (repulsion from centroid) aesthetic

=item B<-kner float>

Node/edge repulsion aesthetic

=item B<-kmei float>

Minimize edge intersection aesthetic

=item B<-kmei2 float>

Minimize edge intersections v2 aesthetic (stronger)

=item B<-kpl float>

Place parent to left of children aesthetic

=item B<-kmlv float>

Minimize intralevel variance aesthetic

=item B<-cin filename>

Reads a file in coordinate format (the default output format of this program)
and uses it as the initial coordinates of the nodes (the default is random
placement).

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 EXAMPLE

Input files for the examples are found in the ex/ directory in the 
L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> distribution.

  gloss.pl -s -mr 0 -knr 1 -kmel 1 ex/t04.in
  gloss.pl -s -mr 0 -knr 1 -kmel 1 -kner 1 -kmei2 6 ex/t12.in
  gloss.pl -s -mr 1 -knr 1 -kmel 1 -d 3 ex/ell.in

=head1 SEE ALSO

L<http://www.cs.ucla.edu/~stott/aglo/>,
L<Graph::Layout::Aesthetic>,
L<Graph::Layout::Aesthetic::Force>,
L<gnuplot(1)>,
L<gloss(1)>

=head1 AUTHOR

Ton Hospel, E<lt>Graph-Layout-Aesthetic@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
