#############################################################################
# Generate a graph from package dependencies (usage profile via use/require)
#
# (c) by Tels 2004-2006.
#############################################################################

package Graph::Usage;

use Graph::Easy 0.40;

use strict;
# XXX TODO: remove the global var @files
use vars qw/$VERSION @ISA @EXPORT_OK @files/;

$VERSION = '0.12';
@ISA = qw/Exporter/;
@EXPORT_OK = qw/LINK_USE LINK_REQUIRE/;

use File::Spec;
use File::Find;
use Exporter;

# types of links
sub LINK_USE ()		{ 0 };
sub LINK_REQUIRE ()	{ 1 };

#############################################################################

sub new
  {
  my $class = shift;

  my $self = bless {}, $class;

  my $args = $_[0];
  $args = { @_ } if ref($args) ne 'HASH';

  $self->_init($args);
  }

sub _init
  {
  my ($self, $args) = @_;

  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
  $self;
  }  

# mapping format to method (all) and file extension (except for graphviz)
my $ext = {
  html => 'html',
  graphviz => 'graphviz',
  svg => 'svg',
  dot => 'dot',
  ascii => 'txt',
  };

sub color_mapping
  {
  # my ($self) = @_;

  # mapping usage count to color name
  {
    0  => '#ffffff',
    1  => '#d0ffd0',
    2  => '#a0ffa0',
    3  => '#80ff80',
    4  => '#80ff50',
    5  => '#a0ff50',
    6  => '#ffff80',
    7  => '#ffff50',
    8  => '#ffa050',
    9  => '#ff5050',
    10 => '#d05050',
    11 => '#d02020',
  };
  }

#############################################################################

sub _inc
  {
  # generate and return list of paths from @INC (excluding doubles)
  my $self = shift;

  my $opt = $self->{opt};

  my $no_doubles = 1; $no_doubles = 0 if $opt->{recurse};

  my @inc;
  my $current = quotemeta(File::Spec->curdir());
  PATH_LOOP:
  for my $i (sort { length $a <=> length $b } @INC)
    {
    # not "." and "lib"
    next if $i =~ /^($current|lib)\z/;

    if ($no_doubles)
      {
      # go throught the already accumulated path and if one of
      # them matches the start of the current, we can ignore it
      # because it is a sub-directory
      for my $p (@inc)
        {
        my $pr = quotemeta($p);
        next PATH_LOOP if $i =~ /^$pr/;
        }
      }
    push @inc, $i;
    }
  @inc;
  }

sub find_file
  {
  # Take a package name and a list of include directories and find
  # the file. Returns the path if the file exists, otherwise undef.
  my ($self, $package, @inc) = @_;

  # A::B, do'h etc
  $package =~ s/::/'/g; my @parts = split /'/, $package; $parts[-1] .= '.pm';

  for my $i (@inc)
    {
    my $file = File::Spec->catfile ($i, @parts);
    return $file if -f $file;
    }
  undef;
  }

sub generate_graph
  {
  # fill @files and return a Graph::Easy object
  my ($self) = shift;

  my $opt = $self->{opt};

  my $graph = Graph::Easy->new();
  $self->{graph} = $graph;

  $graph->set_attribute('edge', 'color', 'grey');
  $graph->set_attribute('graph','flow', $opt->{flow});

  $self->hook_after_graph_generation();

  my @inc = split /\s*,\s*/, $opt->{inc};
  @inc = $self->_inc() unless $opt->{inc};

  $self->output ("\n  Including:\n    ", join ("\n    ", @inc), "\n");

  if ($opt->{recurse})
    {
    my $done = {}; my $todo = {};
    # put all packages todo into $todo
    for my $p (split /\s*,\s*/, $opt->{recurse})
      {
      $todo->{$p} = undef;
      }

    # as long as we have something to do
    while (scalar keys %$todo > 0)
      {
      my ($package,$undef) = each %$todo;

      # mark package as done
      delete $todo->{$package};
      $done->{$package} = undef;

      my $file = $self->find_file ($package, @inc);

      next unless defined $file;

      # parse file and get list of "used" packages
      my @dst = $self->parse_file ($file);

      for my $p (@dst)
        {
        if (!exists $done->{$p} && !exists $todo->{$p})
          {
          $self->output ("    Also todo: $p\n") if $opt->{verbose} > 1;
          }
        # put into todo if not already done
        $todo->{$p} = undef unless exists $done->{$p};
        }
      }
    }
  else
    {
    find ( { wanted => \&_wanted, follow => 1 }, @inc );

    $self->output ("\n  Found " . scalar @files . " .pm files. Parsing them...\n");

    for my $file (@files)
      {
      # open the file and parse it
      $self->parse_file ($file);
      }
    }

  $self->hook_before_colorize();
  $self->colorize() if $opt->{color};
  $self->hook_after_colorize();

  $graph;
  }

sub _wanted
  {
  # called by find() for each file in path_to_source
  return unless -f $_ && $_ =~ /\.pm\z/;

  push @files, $File::Find::name;
  }

sub _match_package_name
  {
  qr/[a-z][\w:]+/i;
  }

sub parse_file
  {
  # parse a file for "package A; use B;" and then add "A => B" into $graph
  my ($self, $file) = @_;
 
  my $graph = $self->{graph};
  my $opt = $self->{opt};

  $self->output ("  At $file\n") if $opt->{verbose} > 0;

  my $FILE;
  open $FILE, $file or (warn ("Cannot open '$file': $!") && return);
  my ($line,$src,$name);
  my $qq = $self->_match_package_name();
  my $in_pod = 0;
  my @rc;				# for returning found packages
  my $ver;
  while (defined ($line = <$FILE>))
    {
    last if $line =~ /^__(END|DATA)__/;

    # Pod::HTML starts it's POD with "=head" so cover this case, too
    $in_pod = 1 if $line =~ /^=(pod|head|over)/;
    $in_pod = 0 if $line =~ /^=cut/;
    next if $in_pod;

    # extract VERSION
    if ($line =~ /^\s*(our\s*)?\$VERSION\s*=\s*["']?(.*?)['"]?\s*;/)
      {
      my $v = $2;
      $ver = $v unless $v =~ /(Revision|do|eval|sprintf|")/;	# doesn't look like a plain VERSION
      $ver = $1 if $v =~ /Revision: ([\d\.]+)/;		# extract VERSION
      $ver = '' if $ver =~ /VERSION/;			# failed to extract
      }

    if ($line =~ /^\s*package\s+($qq)\s*;/)
      {
      # skip "package main" and the example from CPANPLUS::Internals::Constants::Report:
      next if $1 eq 'main' || $1 eq 'Your::Module::Here';

      # should we skip this package?
      my $n = $1; next if $n =~ $opt->{skip};

      if (defined $src)
        {
        # we are about to switch packages, so set version if nec.
        $self->set_package_version($ver);
        }
      $name = $n;
      $src = $self->add_package($name);
      $ver = '';
      }

    # The "^require" should catch require statements inthe outermost scope
    # while not catching ones inside subroutines. Thats hacky, but better
    # than to ignore them completely.
    if ($line =~ /^(require|\s*use)\s+($qq)\s*(qw|[\(;'"])?/ && defined $src)
      {
      my $type = $1 || '';
      my $pck = $2;
      next if $pck =~ /v\d/;		# skip "v5..."

      # skip example from CPANPLUS::Internals::Constants::Report:
      next if $pck eq 'Your::Module::Here';

      # should we skip this package?
      next if $pck =~ $opt->{skip};

      push @rc, $pck;					# for returning it	
      my $dst = $self->add_package($pck);

      $self->output("  $src->{name} => $dst->{name}\n") if $opt->{verbose} > 2;

      $self->add_link ($src, $dst, $type eq 'use' ? LINK_USE : LINK_REQUIRE );
      }
    }

  $self->set_package_version($src, $ver) if $src;

  close $FILE;

  @rc;
  }

sub colorize
  {
  my ($self) = @_;
  
  my $graph = $self->{graph};
  my $opt = $self->{opt};

  my @nodes = $graph->nodes();

  my $color_table = $self->color_mapping();

  foreach my $node (@nodes)
    {
    my $cnt = 0;
    if ($opt->{color} == 1)
      {
      $cnt = scalar $node->successors();
      }
    else
      {
      $cnt = scalar $node->predecessors();
      }

    my $color = $color_table->{$cnt} || '#d00000';
    $node->set_attribute ('fill', $color);
    $node->set_attribute ('title', "$cnt");
    }
  }

sub output_file
  {
  # generate the output file
  my ($self) = @_;

  my $graph = $self->{graph};
  my $opt = $self->{opt};

  my $file = $opt->{output_file};
  
  my $e = $ext->{$opt->{format}};
  $e = $opt->{extension} if $e eq 'graphviz';
  $e =~ s/^\.//;		# ".dot" to "dot

  $file .= '.' . $e unless $file =~ /\.$e/;

  my $method = 'as_' . $opt->{format} . '_file';

  $self->output ("\n  Format: $opt->{format}\n");
  $self->output ("  Output to: '$file'\n");

  if ($method eq 'as_graphviz_file')
    {
    $file = "|$opt->{generator} -T$e -o '$file'";
    }
  elsif ($method eq 'as_dot_file')
    {
    $method = 'as_graphviz_file';
    $file = '>' . $file;
    }
  else
    {
    $file = '>' . $file;
    }
  
  $self->output ("  Method: $method\n");
  $self->output ("  Generator: $opt->{generator}\n") if $opt->{format} eq 'graphviz';

  my $starttime = time();
  $graph->timeout(720);		# 10 minutes
  my $rc = $graph->$method();

  if ($opt->{debug})
    {
    $starttime = time() - $starttime;
    $self->output (sprintf ("  Debug: Took %0.2f seconds to generate output.\n", $starttime));
    }

  $starttime = time();
  my $FILE;
  open $FILE, $file or die ("Cannot open '$file': $!");
  if ($method ne 'as_dot_file')
    {
    binmode $FILE, ':utf8' or die ("binmode $FILE, ':utf8' failed: $!");
    }
  print $FILE $rc;
  close $FILE;

  if ($opt->{debug})
    {
    $starttime = time() - $starttime;
    $self->output ( sprintf ("  Debug: Took %0.2f seconds to write to \"$file\".\n", $starttime) );
    $self->output ($rc);
    }

  }

sub output
  {
  my ($self) = shift;

  print @_;
  }

sub statistic
  {
  my ($self) = @_;

  my $graph = $self->{graph};

  $self->output ("Resulting graph has " .
    scalar $graph->nodes() . " nodes and " .
    scalar $graph->edges() . " edges.\n");
  }

sub add_package
  {
  my ($self, $package_name, $version) = @_;

  my $graph = $self->{graph};
  my $opt = $self->{opt};

  my $src = $graph->add_node($package_name);
  $src->set_attribute('fill', '#ffffff');		# for no color and dot output
  $src->set_attribute('border', 'bold') if $opt->{dotted};

  $self->set_package_version($src, $version) if $version;

  $src;
  }

sub add_link
  {
  my ($self, $src, $dst, $link) = @_;

  my $graph = $self->{graph};
  my $opt = $self->{opt};

  # convert Graph::Easy::Node to name
  $src = $src->{name} if ref($src);
  $dst = $dst->{name} if ref($dst);

  # make sure to add each edge only once (double processing or something)
  my $edge = $graph->edge($src, $dst);
  return $edge if $edge;

  $edge = $graph->add_edge($src, $dst);

  # default is black
  my $color = ''; $color = '#c0c0c0' if $link == LINK_REQUIRE;
  $edge->set_attribute('color', $color) if $opt->{color} && $color;
  $edge->set_attribute('style', 'dotted') if $opt->{dotted} && $color;

  $edge;
  }

sub set_package_version
  {
  my ($self, $src, $ver) = @_;

  my $opt = $self->{opt};
  return unless $opt->{versions} && $ver;

  my $graph = $self->{graph};

  $src = $graph->node($src) unless ref $src;

  my $name = $src->name();

  $src->set_attribute('label', "$name\\nv$ver");
  }

#############################################################################
# hooks that are called through the process of generating the graph. Can be
# overridden in a subclass.

sub hook_after_graph_generation
  {
  }

sub hook_before_colorize
  {
  }
 
sub hook_after_colorize
  {
  }
 
1;

__END__

=pod

=head1 NAME

Graph::Usage - graph usage patterns from Perl packages

=head1 SYNOPSIS

	./gen_graph --inc=lib/ --format=graphviz --output=usage_graph
	./gen_graph --nocolor --inc=lib --format=ascii
	./gen_graph --recurse=Graph::Easy
	./gen_graph --recurse=Graph::Easy --format=graphviz --ext=svg
	./gen_graph --recurse=var --format=graphviz --ext=jpg
	./gen_graph --recurse=Math::BigInt --skip='^[a-z]+\z'
	./gen_graph --use=Graph::Usage::MySubClass --recurse=Math::BigInt

Options:

	--color=X		0: uncolored output
				1: default, colorize nodes on how much packages they use
				2: colorize nodes on how much packages use them
	--nocolor		Sets color to 0 (like --color=0, no color at all)

	--inc=path[,path2,..]	Path to source tree or a single file
				if not specified, @INC from Perl will be used
	--recurse=p[,p2,..]	recursively track all packages from package "p"
	--skip=regexp		Skip packages that match the given regexp. Example:
				  -skip='^[a-z]+\z'		skip all pragmas
				  -skip='^Math::BigInt\z'	skip only Math::BigInt
				  -skip='^Math'			skip all Math packages

	--output		Base-name of the output file, default "usage".
	--format		The output format, default "graphviz", valid are:
				  ascii (via Graph::Easy)
				  html (via Graph::Easy)
				  svg (via Graph:Easy)
				  dot (via Graph:Easy)
				  graphviz (see --generator below)
	--generator		Feed the graphviz output to this program, default "dot".
				It must be installed and in your path.
	--extension		Extension of the output file. For "graphviz" it will
				change the format of the output to produce the appr.
				file type.  For all other formats it will merely set
				the filename extension. It defaults to:
				  Format	Extension
				  ascii		txt
				  html		html
				  svg		svg
				  dot		dot
				  graphviz	png
	--flow			The output flows into this direction. Default "south".
				Possible are:
				  north
				  west
				  east
				  south
	--versions		include package version number in graph nodes.

	--debug			print some timing and statistics info.

	--use=Package		Use this package instead of Graph::Usage to do
				the work behind the scenes. See SUBCLASSING.

Help and version:

	--help			print this help and exit
	--version		print version and exit


=head1 DESCRIPTION

This script traces the usage of Perl packages by other Perl packages from
C<use> and C<require> statements and plots the result as a graph.

Due to the nature of the parsing it might miss a few connections, or even
generate wrong positives. However, the goal is to provide a map of what
packages your module/package I<really> uses. This can be quite different
from what the dependency-tree in Makefile.PL states.

X<graph>
X<require>
X<perl>
X<package>

=head1 EXPORTS

Exports nothing by default, but can export:

	LINK_USE
	LINK_REQUIRE

=head1 SUBCLASSING

You can subclass this module to fine-tune the graphing process.

Here is an overview of the general code flow:

	new()
	generate_graph()
		create Graph::Easy object
		call hook_after_graph_generation()
		process files, calling:
			parse_file()
			add_package()
			add_link
		call hook_before_colorize()
		optional: call colorize()
		call hook_after_colorize()
	statistic()
	output_file()

=head1 METHODS

=head2 new()

=head2 output()

=head2 generate_graph()

=head2 parse_file()

=head2 statistic()

=head2 colorize()

=head2 color_mapping()

=head2 add_link()

	$brain->add_link('Foo::Bar', 'Foo::Baz', LINK_USE);
	$brain->add_link('Foo::Bar', 'Foo::Baz', LINK_REQUIRE);

=head2 add_package()

=head2 find_file()
  
	my $path = $self->find_file($package, @inc);

Take a package name and a list of include directories and try to find
the file there. Returns the path if the file exists, otherwise undef.

=head2 output_file()

	$self->output_file();

Generate the output file containing the graph.

=head2 hook_after_graph_generation()

=head2 hook_before_colorize()

=head2 hook_after_colorize()

=head2 set_package_version()

=head1 TODO

=head2 Output formats

Formats rendered via Graph::Easy (HTML, ASCII and SVG) have a few limitations
and only work good for small to medium sized graphs.

The output format C<graphviz> is rendered via C<dot> or other programs and can
have arbitrary large graphs.

However, for entire source trees like the complete Perl source, the output becomes
unlegible and cramped even when using C<dot>.

I hope I can improve this in time.

=head1 SEE ALSO

C<Graph::Easy> and C<http://bloodgate.com/perl/graph/usage>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL version 2.
See the LICENSE file for information.

X<license>
X<gpl>

=head1 AUTHOR

(c) 2005-2006 by Tels bloodgate.com.

X<author>
X<tels>

=cut

