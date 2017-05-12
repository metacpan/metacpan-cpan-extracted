#!/usr/bin/perl -w

# (C) by Tels 2006.
# Generate dependency graph for a Perl package from it's name

use strict;
use YAML ();
use Graph::Easy;
use Module::CoreList;
use File::Spec;

my $module = shift;

# turn "Foo::Bar" into "Foo-Bar"
$module =~ s/::/-/g;

die ("Need module name") unless $module;

# create the output dirs, unless they exist
for my $dir (qw/tmp out/)
  {
  mkdir $dir unless -d $dir;
  }

# for all these we need to do the check, recursively
my @TODO = $module;
my %DONE;

my $graph = Graph::Easy->new();

while (@TODO)
  {
  my $m = shift @TODO;
  # turn "Foo::Bar" into "Foo-Bar"
  $m =~ s/::/-/g;

  print "At $m, still todo: ", scalar @TODO, "\n";

  # don't do module twice
  next if exists $DONE{$m};
  $DONE{$m} = undef;

  my $file = "tmp/$m-META.yml";

  my $node = $graph->add_node($m);		# need at least once :)

  my $m_org = $m;
  # get the file unless it exists;
  if (!-f $file)
    {
    my $rc = `perl scripts/get_meta.pl '$m'` unless -f $file;

    die ("Didn't get proper result from get_meta") unless
      $rc =~ /author '([^']*)'.*module '([^']+)'/;
    print "  $m is part of $2 from author $1.\n";
    $m = $2;
    $DONE{$m} = undef;
    }

  if ($m ne $m_org)
    {
    $node->set_attribute('label', "$m_org\\n ($m)");
    }

  $file = "tmp/$m-META.yml";
  die ("Error: Couldn't find $file: $!") unless -f $file;

  my $yaml = YAML::LoadFile($file);
  my $prereq = $yaml->{requires};

  # make a hash out of the current todo module names
  my %todo =map { $_ => undef } @TODO;

  print "  Found ", scalar keys %$prereq, " prerequisites.";
  print " Checking them..." if scalar keys %$prereq > 0;
  print "\n";

  for my $req (sort keys %$prereq)
    {
    next if $req eq 'perl';			# Duh!

    # turn "Foo::Bar" into "Foo-Bar"
    my $p = $req; $p =~ s/::/-/g;

    my $d = 'Todo'; $d = 'Done' if $DONE{$p};

    print "   $d: Prereq: $p\n";
    my ($A, $B, $E) = $graph->add_edge($node, $p);

    $E->set_attribute('start', 'front,0');

    $todo{$p} = undef unless $DONE{$p};		# mark as todo
    }

  # enter all the keys in the list
  @TODO = sort keys %todo;
  }

$graph->set_attribute('node.core','fill','#e0ffe0');
$graph->set_attribute('node','fill','#ffe0e0');
$graph->set_attribute('flow', 'down');

# color the nodes depending on whether they are in a Perl release or not
for my $node ($graph->nodes())
  {
  my $name = $node->name();
  $name =~ s/-/::/g; my $release = Module::CoreList->first_release($name);
  if (defined $release)
    {
    $node->set_attribute('class', 'core');
    }
  }

my $dir = File::Spec->catdir('out', $module);
mkdir $dir unless -d $dir;

push @ARGV, 'png' if @ARGV == 0;

for my $f (@ARGV) { _generate($f); }

# generate the .txt as last, because in Graph::Easy 0.39
# doing it before as_graphviz() will make as_graphviz() fail:

my $out = File::Spec->catfile( 'out', $module, 'graph.txt');
print "Writing dependency graph to $out...\n";
open FILE, ">$out" or die ("Cannot write to $out: $!");
print FILE $graph->as_txt();
close FILE;

print "All done, Have fun.\n";

sub _generate
  {
  my $output = shift || 'png';

  my $f = File::Spec->catfile('out', $module, "$module.$output");
  print "Generating '$f'...\n";
  if ($output eq 'png')
    {
    my $dot = '/usr/local/bin/dot'; $dot = 'dot' unless -e $dot;

    my $o = "| $dot -Tpng -o '$f'";

    open FILE, $o or die ("Cannot open pipe to '$o': $!");
    print FILE $graph->as_graphviz();
    close FILE;
    }
  else
    {
    open FILE, ">$f" or die ("Cannot write to '$f': $!");
    my $method = 'as_' . $output . '_file';

    print FILE $graph->$method();
    close FILE;
    }
  }


