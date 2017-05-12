#
# Graph::Reader::HTK - perl module for reading an HTK lattice into a Graph
#
package Graph::Reader::HTK;
$Graph::Reader::HTK::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

use parent 'Graph::Reader';
use Carp;

my %node_attributes =
(
  'WORD' => [ 'WORD', 'label' ],
  'W'    => [ 'WORD', 'label' ],
  'time' => [ 'time' ],
  't'    => [ 'time' ],
  'var'  => [ 'var' ],
  'v'    => [ 'var' ],
  'L'    => [ 'L' ],
);

my %edge_attributes =
(
  'WORD'     => [ 'WORD', 'label' ],
  'W'        => [ 'WORD', 'label' ],
  'START'    => [ 'START' ],
  'S'        => [ 'START' ],
  'END'      => [ 'END' ],
  'E'        => [ 'END' ],
  'var'      => [ 'var' ],
  'v'        => [ 'var' ],
  'div'      => [ 'div' ],
  'd'        => [ 'div' ],
  'acoustic' => [ 'acoustic' ],
  'a'        => [ 'acoustic' ],
  'ngram'    => [ 'ngram' ],
  'n'        => [ 'ngram' ],
  'language' => [ 'language', 'weight' ],
  'l'        => [ 'language', 'weight' ],
);

#=======================================================================
#
# _read_graph
#
# The private method which implements the actual reading of the file.
#
#=======================================================================
sub _read_graph
{
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;

    my $nvertices;
    my $nedges;
    my $v;
    my $from;
    my $to;
    my $weight;
    my ($an, $av);
    my $node_num;
    my $link;


    while (<$FILE>)
    {
        chop;

        #---------------------------------------------------------------
        # ignore version line
        #---------------------------------------------------------------
        if (/^\s*(V|VERSION)\s*=\s*(\S+)/)
        {
            $graph->set_graph_attribute('HTK_VERSION', $2);
            next;
        }

        if (/^\s*(base|lmname|lmscale|wdpenalty)\s*=\s*(\S+)/)
        {
            # print STDERR "Setting graph attribute $1 to $2\n";
            $graph->set_graph_attribute($1, ''.$2);
        }

        #---------------------------------------------------------------
        # line which says how many nodes & links we have
        #---------------------------------------------------------------
        if (/N\s*=\s*(\d+)\s*L\s*=\s*(\d+)/)
        {
            # $NUM_NODES = $1;
            # $NUM_LINKS = $2;
            next;
        }

        #---------------------------------------------------------------
        # node definition
        #---------------------------------------------------------------
        if (/^I\s*=\s*(\d+)/mg)
        {
            #---------------------------------------------------------------
            # strip off the fields from the rest of the line
            # and set appropriate attributes
            #---------------------------------------------------------------
            $node_num = "n$1";
            $graph->add_vertex($node_num);
            # print STDERR "Node $node_num:\n";
            while (/\s*(\S+)\s*=\s*(\S+)/mg)
            {
                $an = $1;
                $av = $2;
                if (exists $node_attributes{$an})
                {
                    foreach my $a (@{ $node_attributes{$an} })
                    {
                        # print STDERR "   attr $a = $av\n";
                        $graph->set_vertex_attribute($node_num, $a, $av);
                    }
                }
                else
                {
                    carp "unknown node field \"$an\" - ignoring\n";
                }
            }
            next;
        }
        elsif (/I\s*=\s*/)
        {
            carp "unexpected format for node line \"$_\" - ignoring\n";
            next;
        }

        #---------------------------------------------------------------
        # edge definition
        #---------------------------------------------------------------
        if (/^J\s*=\s*(\d+)/mg)
        {
            my %attr;

            $link = $1;
            # print STDERR "Edge $link:\n";
            while (/\s*(\S+)\s*=\s*(\S+)/mg)
            {
                $an = $1;
                $av = $2;
                # print STDERR "   field $an = $av\n";
                if (exists $edge_attributes{$an})
                {
                    foreach my $a (@{ $edge_attributes{$an} })
                    {
                        $attr{$a} = $av;
                    }
                }
                else
                {
                    carp "unknown link field \"$an\" - ignoring\n";
                }
            }

            if (exists $attr{START} && exists $attr{END})
            {
                $from = 'n'.$attr{START};
                $to   = 'n'.$attr{END};
                delete $attr{START};
                delete $attr{END};
            }
            else
            {
                carp "link on line $. doesn't have START and END - ignoring\n";
                next;
            }
            $graph->add_edge($from, $to);
            foreach $a (keys %attr)
            {
                # print STDERR "     attr $a = ", $attr{$a}, "\n";
                $graph->set_edge_attribute($from, $to, $a, $attr{$a});
            }
        }
        elsif (/^J/)
        {
            carp "unexpected format for link line \"$_\" - ignoring\n";
            next;
        }
    }

    return 1;
}

1;

__END__

=head1 NAME

Graph::Reader::HTK - read an HTK lattice in as an instance of Graph

=head1 SYNOPSIS

  use Graph::Reader::HTK;

  $reader = Graph::Reader::HTK->new;
  $graph = $reader->read_graph('mylattice.lat');

=head1 DESCRIPTION

This module can be used to read a directed graph in the
L<HTK|http://htk.eng.cam.ac.uk> lattice
format. It returns an instance of the L<Graph> class.

=head1 SEE ALSO

=over 4

=item L<Graph>

Jarkko Hietaniemi's Graph class and others, used for representing
and manipulating directed graphs. Available from CPAN.
Also described / used in the chapter on directed graph algorithms
in the B<Algorithms in Perl> book from O'Reilly.

=item L<Graph::Reader>

The base-class for this module, which defines the public methods,
and describes the ideas behind Graph reader and writer modules.

=item L<Graph::Writer::HTK>

A class which will write a perl Graph out as an HTK lattice.

=item L<HTK|http://htk.eng.cam.ac.uk>

The Hidden Markov Model Toolkit.

=back

=head1 REPOSITORY

L<https://github.com/neilb/Graph-ReadWrite>

=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2000-2012, Neil Bowers. All rights reserved.
Copyright (c) 2000, Canon Research Centre Europe. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

