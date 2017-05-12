package GraphViz::Regex;

use strict;
use warnings;
use Carp;
use Config;
use lib '../..';
use lib '..';
use GraphViz;
use IPC::Run qw(run);

# See perldebguts

our $VERSION = '2.24';

my $DEBUG = 0;    # whether debugging statements are shown

=head1 NAME

GraphViz::Regex - Visualise a regular expression

=head1 SYNOPSIS

  use GraphViz::Regex;

  my $regex = '(([abcd0-9])|(foo))';

  my $graph = GraphViz::Regex->new($regex);
  print $graph->as_png;

=head1 DESCRIPTION

This module attempts to visualise a Perl regular
expression. Understanding regular expressions is tricky at the best of
times, and regexess almost always evolve in ways unforseen at the
start. This module aims to visualise a regex as a graph in order to
make the structure clear and aid in understanding the regex.

The graph visualises how the Perl regular expression engine attempts
to match the regex. Simple text matches or character classes are
represented by.box-shaped nodes. Alternations are represented by a
diamond-shaped node which points to the alternations. Repetitions are
represented by self-edges with a label of the repetition type (the
nodes being repeated are pointed to be a full edge, a dotted edge
points to what to match after the repetition). Matched patterns (such
as $1, $2, etc.) are represented by a 'START $1' .. 'END $1' node
pair.

This uses the GraphViz module to draw the graph.

=head1 METHODS

=head2 new

This is the constructor. It takes one mandatory argument, which is a
string of the regular expression to be visualised. A GraphViz object
is returned.

  my $graph = GraphViz::Regex->new($regex);

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $regex = shift;

    return _init($regex);
}

=head2 as_*

The regex can be visualised in a number of different graphical
formats. Methods include as_ps, as_hpgl, as_pcl, as_mif, as_pic,
as_gd, as_gd2, as_gif, as_jpeg, as_png, as_wbmp, as_ismap, as_imap,
as_vrml, as_vtx, as_mp, as_fig, as_svg. See the GraphViz documentation
for more information. The two most common methods are:

  # Print out a PNG-format file
  print $g->as_png;

  # Print out a PostScript-format file
  print $g->as_ps;

=cut

sub _init {
    my $regex = shift;

    my $compiled;
    my $foo;

    my $perl = $Config{perlpath};
    warn "perlpath: $perl\n" if $DEBUG;

    my $option = qq|use re "debug";qr/$regex/;|;
    run [$perl], \$option, \$foo, \$compiled;

    warn "[$compiled]\n" if $DEBUG;

    #  die "Crap" unless $compiled;

    my $g = GraphViz->new( rankdir => 'LR' );

    my %states;
    my %following;
    my $last_id;

    foreach my $line ( split /\n/, $compiled ) {
        next unless my ( $id, $state ) = $line =~ /(\d+):\s+(.+)$/;
        $states{$id}         = $state;
        $following{$last_id} = $id if $last_id;
        $last_id             = $id;
    }

    my %done;
    my @todo = (1);

    warn "last id: $last_id\n" if $DEBUG;

    if ( not defined $last_id ) {
        $g->add_node("Error compiling regex");
        return $g;
    }

    while (@todo) {
        my $id = pop @todo;
        next unless $id;
        next if $done{$id}++;
        my $state     = $states{$id};
        my $following = $following{$id};
        my ($next) = $state =~ /\((\d+)\)$/;

        #    warn "todo: " . join(", ", @todo) . "\n" if $DEBUG;

        push @todo, $following;
        push @todo, $next if $next;

        my $match;

        warn "$id:\t$state\n" if $DEBUG;
        if ( ($match) = $state =~ /^EXACTF?L? <(.+)>/ ) {
            warn "\t$match $next\n" if $DEBUG;
            $g->add_node( $id, label => $match, shape => 'box' );
            $g->add_edge( $id => $next ) if $next != 0;
            $done{$following}++ unless $next;
        } elsif ( ($match) = $state =~ /^ANYOF\[(.+)\]/ ) {
            warn "\tany $match $next\n" if $DEBUG;
            $g->add_node( $id, label => '[' . $match . ']', shape => 'box' );
            $g->add_edge( $id => $next ) if $next != 0;
            $done{$following}++ unless $next;
        } elsif ( ($match) = $state =~ /^OPEN(\d+)/ ) {
            warn "\tOPEN $match $next\n" if $DEBUG;
            $g->add_node( $id, label => 'START \$' . $match );
            $g->add_edge( $id => $following );
        } elsif ( ($match) = $state =~ /^CLOSE(\d+)/ ) {
            warn "\tCLOSE $match $next\n" if $DEBUG;
            $g->add_node( $id, label => 'END \$' . $match );
            $g->add_edge( $id => $next );
        } elsif ( $state =~ /^END/ ) {
            warn "\tEND\n" if $DEBUG;
            $g->add_node( $id, label => 'END' );
        } elsif ( $state =~ /^BRANCH/ ) {
            my $branch = $next;
            warn "\tbranch $branch / " . ($following) . "\n" if $DEBUG;
            my @children;
            push @children, $following;
            while ( $states{$branch} =~ /^BRANCH|TAIL/ ) {
                warn "\tdoing branch $branch\n" if $DEBUG;
                $done{$branch}++;
                push @children, $following{$branch};
                ($branch) = $states{$branch} =~ /(\d+)/;
            }
            $g->add_node( $id, label => '', shape => 'diamond' );
            foreach my $child (@children) {
                push @todo, $child;
                $g->add_edge( $id => $child );
            }
        } elsif ( my ($repetition) = $state =~ /^(PLUS|STAR)/ ) {
            warn "\t$repetition $next\n" if $DEBUG;
            my $label = '?';
            if ( $repetition eq 'PLUS' ) {
                $label = '+';
            } elsif ( $repetition eq 'STAR' ) {
                $label = '*';
            }
            $g->add_node( $id, label => 'REPEAT' );
            $g->add_edge( $id => $id,   label => $label );
            $g->add_edge( $id => $following );
            $g->add_edge( $id => $next, style => 'dashed' );
        } elsif ( my ( $type, $min, $max )
            = $state =~ /^CURLY([NMX]?)\[?\d*\]? \{(\d+),(\d+)\}/ )
        {
            warn "\tCURLY$type $min $max $next\n" if $DEBUG;
            $g->add_node( $id, label => 'REPEAT' );
            $g->add_edge(
                $id   => $id,
                label => '{' . $min . ", " . $max . '}'
            );
            $g->add_edge( $id => $following );
            $g->add_edge( $id => $next, style => 'dashed' );
        } elsif ( $state =~ /^BOL/ ) {
            warn "\tBOL $next\n" if $DEBUG;
            $g->add_node( $id, label => '^' );
            $g->add_edge( $id => $next );
        } elsif ( $state =~ /^EOL/ ) {
            warn "\tEOL $next\n" if $DEBUG;
            $g->add_node( $id, label => "\$" );
            $g->add_edge( $id => $next );
        } elsif ( $state =~ /^NOTHING/ ) {
            warn "\tNOTHING $next\n" if $DEBUG;
            $g->add_node( $id, label => 'Match empty string' );
            $g->add_edge( $id => $next );
        } elsif ( $state =~ /^MINMOD/ ) {
            warn "\tMINMOD $next\n" if $DEBUG;
            $g->add_node( $id, label => 'Next operator\nnon-greedy' );
            $g->add_edge( $id => $next );
        } elsif ( $state =~ /^SUCCEED/ ) {
            warn "\tSUCCEED $next\n" if $DEBUG;
            $g->add_node( $id, label => 'SUCCEED' );
            $done{$following}++;
        } elsif ( $state =~ /^UNLESSM/ ) {
            warn "\tUNLESSM $next\n" if $DEBUG;
            $g->add_node( $id, label => 'UNLESS' );
            $g->add_edge( $id => $following );
            $g->add_edge( $id => $next, style => 'dashed' );
        } elsif ( $state =~ /^IFMATCH/ ) {
            warn "\tIFMATCH $next\n" if $DEBUG;
            $g->add_node( $id, label => 'IFMATCH' );
            $g->add_edge( $id => $following );
            $g->add_edge( $id => $next, style => 'dashed' );
        } elsif ( $state =~ /^IFTHEN/ ) {
            warn "\tIFTHEN $next\n" if $DEBUG;
            $g->add_node( $id, label => 'IFTHEN' );
            $g->add_edge( $id => $following );
            $g->add_edge( $id => $next, style => 'dashed' );
        } elsif ( $state =~ /^([A-Z_0-9]+)/ ) {
            my ($state) = ( $1, $2 );
            warn "\t? $state $next\n" if $DEBUG;
            $g->add_node( $id, label => $state );
            $g->add_edge( $id => $next ) if $next != 0;
        } else {
            $g->add_node( $id, label => $state );
        }
    }

    return $g;
}

=head1 BUGS

Note that this module relies on debugging information provided by
Perl, and is known to fail on at least two versions of Perl: 5.005_03
and 5.7.1. Sorry about that - please use a more recent version of Perl
if you want to use this module.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2000-1, Leon Brocard

This module is free software; you can redistribute it or modify it under the Perl License,
a copy of which is available at L<http://dev.perl.org/licenses/>.

=cut

1;
