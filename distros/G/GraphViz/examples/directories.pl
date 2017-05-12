#!/usr/bin/perl -w
#
# This small example program walks the directory tree and draws a
# directory of the files and directories in the GraphViz distribution.
#
# It also shows the use of the GraphViz::No subclass.

use strict;
use lib '../lib';
use IO::Dir;
use GraphViz;
use GraphViz::Small;
use GraphViz::No;

my $directory = '../';

my $graph = GraphViz::No->new(directed => 0, layout => 'twopi');

walk($directory);

sub walk {
  my($dir, $parent) = @_;
#  warn "\nwalk $dir $parent\n";

  $graph->add_node($dir) unless defined $parent;

  my $d = IO::Dir->new($dir);
  foreach my $file ($d->read) {
    next if $file =~ /^\./;
    if (-f $dir . $file) {
      # It's a file!
#      warn "$file in $dir\n";
      $graph->add_node($dir . $file, label => $file);
      $graph->add_edge($dir => $dir . $file);
    } elsif (-d $dir . $file) {
      # It's a directory!
#      warn "$file in $dir is DIR\n";
      $graph->add_node($dir . $file . '/', label => $file . '/');
      $graph->add_edge($dir => $dir . $file . '/');
      walk($dir . $file . '/', $dir);
    }
  }
#  warn "\n";
}

#print $graph->_as_debug;
$graph->as_png("directories.png");
