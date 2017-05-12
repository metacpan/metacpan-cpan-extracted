#!/usr/bin/perl

=head1 NAME

xref.pl - graphing subroutine cross-reference reports for Perl modules

=cut

=head1 SYNOPSIS

To graph the subroutine cross-reference of 'Functional.pm':

  % perl -MO=Xref,-r Functional.pm > examples/Functional.xref
  % ./xref_aux.pl Functional.xref > Functional.png
  % gqview Functional.png
  # (or your favourite image viewer)

=head1 DESCRIPTION

xref.pl uses the information gleamed by the B::Xref module to draw a
pretty graph showing how subroutines in a module call each other.

For example, the "GraphViz.png" image shows that:

=over 4

=item * _as_debug can call _attributes

=item * both _parse_dot and _as_generic can call run

=back

Unfortunately, it is quite hard to understand this without looking at
the picture, hence this program and the GraphViz module ;-)

A couple of options are available by changing variables in the
program. It is expected that these become command-line options for the
next version.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2000, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

use strict;
use lib '../lib';
use GraphViz;
use IO::File;

my $multiple_edges = 0;
my $show_lines = 0;

$multiple_edges = 1 if $show_lines;

my $fh = IO::File->new(shift || 'Functional.xref') || die "$!";

my $g = GraphViz->new();

my %edges;

while (defined(my $line = <$fh>)) {
  chomp $line;
  my($file, $subroutine, $line, $package, $proto, $name, $type) = split /\s+/, $line;
  next if $file =~ /^\//;
  next unless $proto =~ /&/;
  next if $subroutine eq '(definitions)';

#  warn "$file $subroutine $package $proto $name $type\n";

#warn "$subroutine -> $package $name\n";

  my $subcluster = $subroutine;
  $subcluster =~ s|::.*?$||;
  $subroutine =~ s|^.*::||;

  my $namecluster = $package;

#warn "# $subroutine ($subcluster) -> $name ($namecluster)\n";

  my $subnode = $g->add_node($subroutine, cluster => $subcluster);
  my $namenode = $g->add_node($name, cluster => $namecluster);

  next if !$multiple_edges && $edges{$subnode}->{$namenode}++;

  my $edge = { from =>  $subnode,
	         to => $namenode,
	     };

  if ($show_lines) {
    $g->add_edge($subnode => $namenode, label => $line);
  } else {
    $g->add_edge($subnode => $namenode);
  }
}

print $g->as_png;
#print $g->_as_debug;
#print $g->as_text;
