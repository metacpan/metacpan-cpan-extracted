#!/usr/bin/perl -w

use strict;

use lib '../lib';
use Getopt::Long;
use Pod::Usage;
use GraphViz;
use XML::XPath;

sub process {
  my $xp = shift;

  my $graph = GraphViz->new();

  my %provides;
  my %requires;
  my @packages;

  my $nodeset = $xp->find("/channel/subchannel/package");
  foreach my $context ($nodeset->get_nodelist) {
    my $name = $xp->find('./name', $context);
    $name = "$name"; # don't want no fancy XPath object
    push @packages, $name;
    foreach my $provides (map { $_->getData} $context->find('./provides/dep/@name')->get_nodelist) {
      $provides{$provides} = "$name";
    }
    foreach my $requires (map { $_->getData} $context->find('./requires/dep/@name')->get_nodelist) {
      push @{$requires{$requires}}, "$name";
    }
  }

  my %deps;

  foreach my $name (@packages) {
    #  print "$name:\n";
    $graph->add_node($name);
    foreach my $requires (@{$requires{$name}}) {
      $graph->add_edge($provides{$requires} => $name);
      #    print "  $requires ($provides{$requires})\n";
    }
  }

  return $graph;
}

our $VERSION='0.01';

my %opts = (
    help     => 0,
    man      => 0,
    verbose  => 0,
);

GetOptions(\%opts, qw(
    help
    man
    verbose
)) || pod2usage(2);

pod2usage(1) if     $opts{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opts{man};

my $xp = XML::XPath->new(filename => 'ximian-gnome-redhat-70-i386-packageinfo.xml');

my $graph = process($xp);

print $graph->as_png;

__END__

=head1 NAME

redcarpet.pl - graph Ximian RedCarpet dependencies

=head1 SYNOPSIS

ppmgraph.pl > redcarpet.png

=head1 DESCRIPTION

This program takes a Ximian Red Carpet package info list (such as for
Ximian Gnome - you must first download and install Ximian Red Carpet
from http://www.ximian.com/apps/redcarpet.php3 and fetch a
*-packageinfo.xml file from /var/cache/redcarpet/) which is in XML
format, and uses it to determine dependencies between packages. It
then hands over those dependencies to GraphViz. The resulting graph is
output in PNG format on STDOUT.

=head1 OPTIONS

This section describes the supported command line options. Minimum
matching is supported.

=over 4

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<--verbose>

Print information messages as we go along.

=back

=head1 BUGS

Some. Possibly. I haven't fully tested it. Also, a performance
problem. The package XML file is over a meg, and performance suffers. At
the moment, this is of no concern, but I might switch over to PerlSAX
later. I'm using XPath at the moment since I'm familiar with it.

=head1 AUTHOR

Leon Brocard E<lt>acme@astray.comE<gt>, based on a framework by 
Marcel GrE<uuml>nauer E<lt>marcel@codewerk.comE<gt>

=head1 COPYRIGHT

Copyright 2000 Leon Brocard. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

GraphViz(3pm)

=cut
