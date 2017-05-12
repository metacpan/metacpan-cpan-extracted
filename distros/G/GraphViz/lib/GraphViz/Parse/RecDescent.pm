package GraphViz::Parse::RecDescent;

use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use lib '../..';
use lib '..';
use GraphViz;
use Parse::RecDescent;

our $VERSION = '2.24';

=head1 NAME

GraphViz::Parse::RecDescent - Visualise grammars

=head1 SYNOPSIS

  use GraphViz::Parse::RecDescent;

  # Either pass in the grammar
  my $graph = GraphViz::Parse::RecDescent->new($grammar);
  print $g->as_png;

  # or a Parse::RecDescent parser object
  my $graph = GraphViz::Parse::RecDescent->new($parser);
  print $g->as_ps;

=head1 DESCRIPTION

This module makes it easy to visualise Parse::RecDescent grammars.
Writing Parse::RecDescent grammars is tricky at the best of times, and
grammars almost always evolve in ways unforseen at the start. This
module aims to visualise a grammar as a graph in order to make the
structure clear and aid in understanding the grammar.

Rules are represented as nodes, which have their name on the left of
the node and their productions on the right of the node. The subrules
present in the productions are represented by edges to the subrule
nodes.

Thus, every node (rule) should be connected to the graph - otherwise a
rule is not part of the grammar.

This uses the GraphViz module to draw the graph. Thanks to Damian
Conway for the idea.

Note that the Parse::RecDescent module should be installed.

=head1 METHODS

=head2 new

This is the constructor. It takes one mandatory argument, which can
either be the grammar text or a Parse::RecDescent parser object of the
grammar to be visualised. A GraphViz object is returned.

  # Either pass in the grammar
  my $graph = GraphViz::Parse::RecDescent->new($grammar);

  # or a Parse::RecDescent parser object
  my $graph = GraphViz::Parse::RecDescent->new($parser);

=cut

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $parser = shift;

    if ( ref($parser) ne 'Parse::RecDescent' ) {

        # We got a grammar instead, so we construct our own parser
        $parser = Parse::RecDescent->new($parser)
            or carp("Bad grammar");
    }

    return _init($parser);
}

=head2 as_*

The grammar can be visualised in a number of different graphical
formats. Methods include as_ps, as_hpgl, as_pcl, as_mif, as_pic,
as_gd, as_gd2, as_gif, as_jpeg, as_png, as_wbmp, as_ismap, as_imap,
as_vrml, as_vtx, as_mp, as_fig, as_svg. See the GraphViz documentation
for more information. The two most common methods are:

  # Print out a PNG-format file
  print $g->as_png;

  # Print out a PostScript-format file
  print $g->as_ps;

=cut

# Given a parser object, we look inside its internals and build up a
# graph of the rules, productions, and items. This is a tad scary and
# hopefully Parse::FastDescent will make this all much easier.
sub _init {
    my $parser = shift;

    # Our wonderful graph object
    my $graph = GraphViz->new();

    # A grammar consists of rules
    my %rules = %{ $parser->{rules} };

    foreach my $rule ( keys %rules ) {

        #    print "$rule:\n";
        my $rule_label;

        # Rules consist of productions
        my @productions = @{ $rules{$rule}->{prods} };

        foreach my $production (@productions) {

            my $production_text;

            # Productions consist of items
            my @items = @{ $production->{items} };

            foreach my $item (@items) {
                my $text;
                my $type = ref $item;
                $type =~ s/^Parse::RecDescent:://;

                # We ignore Action rules
                next if $type eq 'Action';

                # We could probably use a switch here ;-)
                if ( $type eq 'Subrule' ) {
                    $text = $item->{subrule};
                    $text .= $item->{argcode} if defined( $item->{argcode} );
                } elsif ( $type =~ /^(Literal|Token|InterpLit)$/ ) {

                    # These are all literals
                    $text = $item->{description};
                } elsif ( $type eq 'Error' ) {

                    # We make sure error messages are shown
                    if ( $item->{msg} ) {
                        $text = '<error:' . $item->{msg} . '>';
                    } else {
                        $text = '<error>';
                    }
                } elsif ( $type eq 'Repetition' ) {

                    # We make sure we show the repetition specifier
                    $text = $item->{subrule} . '(' . $item->{repspec} . ')';
                } elsif ( $type eq 'Operator' ) {
                    $text = $item->{expected};
                } elsif ( $type =~ /^(Directive|UncondReject)$/ ) {
                    $text = $item->{name};
                } else {

                    # It's something we don't know about, so complain!
                    warn
                        "GraphViz::Parse::RecDescent: unknown type $type found!\n";
                    $text = "?$type?";
                }

                $production_text .= $text . " ";
            }

            #      print "    $production_text\n";
            $rule_label .= $production_text . "\\n";
        }

        # Add the node for the current rule
        $graph->add_node( $rule, label => [ $rule, $rule_label ] );

        # Make links to the rules called
        foreach my $called ( @{ $rules{$rule}->{calls} } ) {
            $graph->add_edge( $rule => $called );
        }
    }

    return $graph;
}

=head1 BUGS

Translating the grammar to a graph is accomplished by peeking inside
the internals of a parser object, which is a tad scary. A new version
of Parse::RecDescent with different internals may break this module.

At the moment, almost all Parse::RecDescent directives are
supported. If you find one that has been missed - let me know!

Unfortunately, alternations (such as the following) do not produce
very pretty graphs, due to the fact that they are implicit (unamed)
rules and are implemented by new long-named subrules.

  character: 'the' ( good | bad | ugly ) /dude/

Hopefully Parse::FastDescent will make this all much easier.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001, Leon Brocard

This module is free software; you can redistribute it or modify it under the Perl License,
a copy of which is available at L<http://dev.perl.org/licenses/>.

=cut

1;
