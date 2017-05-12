package GraphViz::Data::Structure;

use strict;
use Carp;
use lib '..';

use GraphViz 2.01;
use Devel::Peek;
use Scalar::Util qw(refaddr reftype blessed);

our $Debug = 0;

sub _debug(@) {
  return unless $Debug;
  return unless @_;
  print STDERR @_;
  print "\n" unless $_[-1]=~/\n/;
}

our $VERSION = '0.19';

# The currently-supported color palettes.
our %palettes = (
                  Pastel => {Scalar=>'lightyellow',
                             Array =>'palevioletred',
                             Hash  =>'paleturquoise',
                             Glob  =>'lavender',
                             Font  =>'black'},
                  Bright => {Scalar=>'yellow',
                             Array =>'tomato',
                             Hash  =>'cyan',
                             Glob =>'purple',
                             Font =>'white'},
                  Deep   => {Scalar=>'gold',
                             Array =>'firebrick2',
                             Hash  =>'turquoise',
                             Glob  =>'mediumpurple1',
                             Font  =>'white'},
                  Plain  => {Scalar=>'white',
                             Array =>'white',
                             Hash  =>'white',
                             Glob  =>'white',
                             Font  =>'black'}
                );

=head1 NAME

GraphViz::Data::Structure - Visualise data structures

=head1 SYNOPSIS

  use GraphViz::Data::Structure;

  my $gvds = GraphViz:Data::Structure->new($data_structure);
  print $gvds->graph()->as_png;

=head1 DESCRIPTION

This module makes it easy to visualise data structures, even recursive
or circular ones. 

It is provided as an alternative to GraphViz::Data::Grapher. Differences:

=over 4

=item C<GraphViz::Data::Structure> handles structures of arbitrary depth and complexity, automatically following links using a standard graph traversal algorithm.

=item C<GraphViz::Data::Grapher> creates graphics of indiividual substructures (arrays, scalars, hashes) which keep the substructure type and data together; C<GraphViz::Data::Structure> does this by shape alone.

=item C<GraphViz::Data::Structure> encapsulates object info (if any) directly into the node  being used to represent the class.

=item C<GraphViz::Data::Grapher> colors its graphs; C<GraphViz::Data::Structure> doesn't by default.

=item C<GraphViz::Data:Structure> can parse out globs and CODE references (almost as well as the debugger does).

=back

=head1 REPRESENTING DATA STRUCTURES AS GRAPHS

C<Graphviz::Data::Structure> tries to draw data structure diagrams with a 
minimum of complexity and a maximum of elegance. To this end, the following
design choices were made:

=over 4

=item Strings, scalars, filehandles, and code references are represented as plain text.

=item Empty hashes and arrays are represented as Perl represents them in code: hashes as C<{}>, and arrays as C<[]>, except if they are blessed (see below).

=item Arrays are laid out as sets of boxes, in the order in which they were found in the existing data structure (left-to-right or top-to-bottom, depending on overall graph layout).

=item Hashes are laid out as pairs of sets of boxes, with the keys in alphabetically-sorted order top-to-bottom or left-to-right.

=item Blessed items have a box added to them in parallel, containing the name of the class and its type (scalar/array/hash).

=item Code references are decoded to determine their fully-qualified package name and are output as plaintext nodes.

=item Glob pointed to by references are disassembled and their individual parts dumped.

=back

=head1 ALGORITHM

The algorithm is a standard recursive depth-first treewalk; we determine how 
the current node should be added to the current graph, add it, and then call 
ourselves recursively to determine how all nodes below this one
should be visualized.Edges are added after the subnodes are added to the graph.

Items "within" the current subnode (array and hash elements which are
I<not> references) are rendered inside a cell in the aggregate corresponding to 
their position. References are represented by an edge linking the appropriate 
postion in the aggregate to the appropriate subnode.

This code does its data-structure unwrapping in a manner very similar to 
that used by C<dumpvar.pl>, the code used by the debugger to display data 
structures as text. The initial structure treewalk was written in isolation;
the C<dumpvar.pl> code was integrated only after it was recognized that there
was more to life than hashes, arrays, and scalars.The C<dumpvar.pl> code to
decode globs and code references was used almost as-is.

Code was added to attempt to spot references to array or hash elements, but
this code still does not work as desired. Array and hash I<element> references
still appear to be scalars to the current algorithm.

=head1 GLOBAL SETTINGS

=head2 C<GraphViz::Data::Structure::Debug> 

Set this to a true value to turn on some debugging messages output to STDERR.
Defaults to false, and should probably be left that way unless you're reworking
init().

  # Turn on GraphViz::Data::Structure debugging.
  $GraphViz::Data::Structure::Debug = 1;

=head1 CLASS METHODS

=head2 C<new()>

This is the constructor. It takes one mandatory argument, which is the
data structure to be visualised. A C<GraphViz:Data::Structure> object, the name
of the top node, and a list defining the 'to' port for this top node (if there 
is a 'to' port; if none, an empty list) are all returned.

  # Graph a data structure, creating a GraphViz object.
  # The new GraphViz:Data::Structure object, the name of 
  # the top node in the structure, and the "in" port are returned.
  my ($gvds, $top_name, @port) = 
   GraphViz::Data::Structure->new($structure);
  print $gvds->graph()->as_png("my.png");

If you  so desire, you can use the returned information to join
other graphs up to the top of the graph contained in this object by
callling C<graph()> to extract the C<GraphViz> object and calling other
C<GraphViz> primitives on that object. Most of the time you'll only care
about the C<GraphViz::Data::Structure> object and not the additional info.

=head3 Optional parameters

You can specify any, none, or all of the following optional keyword parameters:

=over 4

=item C<GraphViz>

You can specify your own C<GraphViz> object, in which the graph will be built.
C<GraphViz::Data::Structure> nodes all start with the string C<gvds>; if you
avoid using nodes with similar names, you should not have any nodename
collisions.

  # Create a graph of a data structure, using your own GraphViz object
  my ($gvds, $top_name, @port) = 
    GraphViz::Data::Structure->new($structure,
                                   GraphViz=>GraphViz->new());
  $gvds->graph()->as_png("my.png");

=item C<Depth>

If the C<Depth> parameter is supplied, C<GraphViz::Data::Structure> stops at
the designated level. If any references are found at this level, plaintext 
C<...> nodes are constructed for them. The default limit is B<no> limit.

  # Stop after reaching level 7.
  my ($gvds, $top_name, @port) = 
    GraphViz::Data::Structure->new($structure,
                                   Level=>7);
  $gvds->graph()->as_png("my.png");

This can be useful if you have a very large data structure, but showing just
the upper levels is sufficient for your purposes.

=item C<Fuzz>

If your data structure has large pieces of text in it, you will probably
want to limit the size of the text displayed to keep C<GraphViz> from
creating huge unwieldy nodes. C<Fuzz> allows you to specify the maximum
length of any text to be inserted into blocks; the default value is
B<40> characters.

  # Trim any text to 20 characters or less.
  my ($gvds, $top_name, @port) = 
    GraphViz::Data::Structure->new($structure,
                                   Fuzz=>20);
  $gvds->graph()->as_png("my.png");

Be aware: large values for C<Fuzz> will result in long character strings being
passed to C<dot>, which will eventually segfault if the strings are long
enough.

=item C<Orientation>

You can choose to have your records laid out so that arrays and hashes are
either laid out horizontally, with class labels at the top, or vertically, with
class labels on the left. Default is C<horizontal>.

  # Stack items vertically.
  my ($gvds, $top_name, @port) = 
    GraphViz::Data::Structure->new($structure,
                                   Orientation=>'vertical');
  $gvds->graph()->as_png("my.png");

You cannot mix horizontal and vertical layouts in the same graph.

=item C<Colors>

You can choose how you want the different kinds of nodes colored by passing a
reference to a hash of type-to-color mappings as the value of the C<Colors>
parameter, or by choosing the name of any of the predefined palettes.

If you're making up your own set of colors, you can use any of the colors 
listed in the C<dot> manual. The names of the types are C<Scalar>, C<Array>,
C<Hash>, C<Glob>, and C<Font>. At present, C<GraphViz::Data::Structure> 
doesn't allow you to color the plain-text items (strings, scalar values, 
coderefs).

The predefined palettes are:

=over 4

=item Colors=>'Pastel' - this is a pale, rather subtle set of colors.

   Colors=>{Scalar=>'lightyellow',    Array=>'palevioletred', 
            Hash  =>'paleturquoise',  Glob =>'lavender',
            Font  =>'black');

=item Colors=>'Bright' - this is a brightly-colored set.

   Colors=>{Scalar=>'yellow',   Array=>'tomato', 
            Hash  =>'cyan',     Glob =>'purple',
            Font  =>'white);

=item Colors=>'Deep' - this is a darker set.

   Colors=>{Scalar=>'gold',      Array=>'firebrick4', 
            Hash  =>'turquoise4', Glob =>'MediumPurple4',
            Font  =>'white');

=item Colors=>'Plain' - this is the same as no coloring at all, and is the default behaviour.

   Colors=>{Scalar=>'white',     Array=>'white',
            Hash  =>'white',     Glob =>'white',
            Font  =>'black');

=back


  # Graph a structure, with the "bright" palette:
  my $gvds = GraphViz::Data::Structure->new($structure,Colors=>Bright);

  # Graph a structure, creating your own palette:
  my $gvds = Graphviz::Data::Structure->new($structure,
                                            Colors=>{Scalar=>'VioletRed1',
                                                     Array =>'SeaGreen1',
                                                     Hash  =>'tan1',
                                                     Glob  =>'goldenrod1',
                                                     Font  =>'white'
                                                    }
                                            );

It should be noted that the optional palettes are simply a demonstration set
of colors; someone with a better eye for graphic design will, I hope, submit
better ones. The "rainbow" effect caused using the alternate palettes on a
data structure with a lot ofdifferent node types in it is rather jarring - 
sort of like an explosion in a Jello factory.

=item Other parameters

C<GraphViz> supports a number of other parameters at the graph level; any 
parameters that C<GraphViz::Data::Structure> doesn't understand itself will 
be passed on to C<GraphViz>.

  # Add a title and change the default font:
  my ($gvds, $top_name, @port) = 
    GraphViz::Data::Structure->new($structure,
                                   graph=>{label=>'My graph',
                                           fontname=>'Helvetica'}
                                  );

=back 

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $data_structure = shift;
  my %params = @_;

  # GraphViz::Data::Structure object. Internal use only.
  # Do not write code that depends on any fields within this object!
  # They are subject to change without notice in future releases.
  my $self = {};
  bless $self, $class;

  # Parameters we understand.
  $self->{Fuzz}        = $params{Fuzz}        || 40;
  $self->{Depth}       = $params{Depth}       || undef;
  $self->{Label}       = $params{Label}       || 'left';
  $self->{Orientation} = $params{Orientation} || "horizontal";

  # Handle Colors. This will be either a color set name, or a reference
  # to a hash which defines the colors.
  # Begin by defaulting the palette.
  $self->{Colors} = $palettes{Plain};
  if (defined $params{Colors}) {
    # Color parameter set was specified. Override the defaults with whatever
    # was specified. Note that specifying everything is the same as defining
    # a completely new palette.
    if (ref $params{Colors}) {
      foreach my $item (sort keys %{$params{Colors}}) {
        $self->{Colors}->{$item} = $params{Colors}->{$item};
      }
    }
    else {
      # Color set name was provided. Choose from the supported
      # palettes; if not there, generate a monochrome palette with black text.
      $self->{Colors} = defined $palettes{$params{Colors}}
                          ? $palettes{$params{Colors}}
                          : {Scalar=>$params{Colors},
                             Hash  =>$params{Colors},
                             Array =>$params{Colors},
                             Glob  =>$params{Colors},
                             Font  =>'black'
                            };
     }
  }

  # Carry over the remaining parameters to GraphViz, if possible.
  # If we've got an old GraphViz object, it's too late.
  local $_;
  map {delete $params{$_}} qw(Fuzz Depth Label Orientation Colors);
  my @gvparams = %params;
  push @gvparams, ($self->{Orientation} eq 'vertical' ? ('rankdir'=>1) : ());
  $self->{Graph}       = $params{GraphViz}    || (GraphViz->new(@gvparams));

  # Initialize the node and address caches.
  $self->{NodeCache} = {};
  $self->{Addresses} = {};

  # Counters for name generation.
  $self->{Atoms}   = 0;
  $self->{Scalars} = 0;
  $self->{Arrays}  = 0;
  $self->{Dummies} = 0;
  $self->{Subs}    = 0;
  $self->{Undefs}  = 0;
  $self->{Globs}   = 0;

  # Recursive descent, depth-first search.
  my ($top, @port) = $self->init($data_structure, 0);

  # Done. Return GraphViz::Data::Structure object, or list as appropriate.
  wantarray() ? ($self, $top, @port) : $self;
}

=head2 C<add()>

C<add()>, called as a class method, simply calls C<new()>, supporting all of
the C<new()> parameters as usual.

  # Create a graph (replicates the new() call). Parameters default.
  my ($gvds, $top_name, @ports) = 
    GraphViz::Data::Structure->add($structure);

=head1 INSTANCE METHODS

=head2 C<graph()>

C<graph()> returns a C<GraphViz> object, loaded with the nodes and edges 
corresponding to any data structure passed in via C<new()> and/or C<add()>.
You can make any of the standard C<GraphViz> calls to this object.

Methods include C<as_ps>, C<as_hpgl>, C<as_pcl>, C<as_mif>, C<as_pic>,
C<as_gd>, C<as_gd2>, C<as_gif>, C<as_jpeg>, C<as_png>, C<as_wbmp>, 
C<as_ismap>, C<as_imap>, C<as_vrml>, C<as_vtx>, C<as_mp>, C<as_fig>, 
C<as_svg>. See the C<GraphViz> documentation for more information. The 
most common methods are:

  # Print out a PNG-format file
  print $gvds->graph->as_png();

  # Print out a PostScript-format file
  print $gvds->graph->as_ps();

  # Print out a dot file, in "canonical" form:
  print $gvds->graph->as_canon();
=cut

sub graph {
  my $self = shift;
  $self->{Graph};
}

=head2 C<was_null>

C<was_null()> checks to ensure that your data structure didn't generate
a graph that was too complex for C<dot> to handle. Directly self-referential 
structures (e.g., C<@a = (1,\@a,3)>) seem to be the only offenders in this 
area; if your structure isn't directly self-referential -- by far the most
likely situation -- you won't need to use C<was_null()> at all.

C<was_null> forces a C<dot> run to get the "canonical" form of the graph
back, which can be computationally expensive; avoid it if possible.

=cut

sub was_null {
  my $self = shift;
  return $self->graph->as_canon() eq "";
}

=head2 C<add()>

C<add()>, called as an instance method, simply adds new nodes and edges
(corresponding to a new data structure) to an existing
C<GraphViz::Data::Structure> object.

You can specify the C<Fuzz>, C<Label>, and
C<Depth>  arguments, just as you would for C<new()>. You cannot specify 
C<GraphViz>, C<Orientation>, or any of the C<GraphViz> parameters that 
are used to create a C<GraphViz> object;
C<add()> uses the pre-existing C<GraphViz> object
in the C<GraphViz::Data::Structure> object to add new nodes.

  # Create a graph (replicates the new() call).
  my ($gvds, $top_name, @ports) = 
    GraphViz::Data::Structure->add($structure);

  # Add a second structure; nodes will be merged as necessary.
  my ($gvds, $top_name, @ports) =  $gvds->add($structure);

=cut

sub add {
  my $self_or_class = shift;
  # If the first item in the parameter list is a reference to a
  # GraphViz::Data::Structure object, we are being called as an
  # instance method.
  if (ref $self_or_class and 
      ref $self_or_class eq "GraphViz::Data::Structure") {
    my $self = $self_or_class;
    my ($data_structure,%params) = @_;
  
    $self->{Fuzz}        = $params{Fuzz}        || 40;
    $self->{Depth}       = $params{Depth}       || undef;
    $self->{Label}       = $params{Label}       || 'left';

    # Add the new nodes to the graph. Recursive descent, depth-first search.
    my ($top, @port) = $self->init($data_structure, 0);

    # Done. Return GraphViz::Data::Structure object, top node, and port.
    wantarray ? ($self, $top, @port) : $self;
  }

  # Called as a class method. Just call new().
  else {
      GraphViz::Data::Structure->new(@_);
  }
}

=head2 Alternate palettes

You can define your own palettes (or redefine the standard ones) by assigning
them to the C<%GraphViz::Data::Structure::palettes> hash.

  # Create and use a new AllPink palette:
  $GraphViz::Data::Structure::palettes{AllPink} = 
   {Scalar=>'pink', Hash=>'pink', Array=>'pink', Glob=>'pink', Font=>'black'};
  my $gvds = GraphViz::Data::Structure->new($pink_struct,Colors=>AllPink);

  # Do it the easy way:
  my $gvds = GraphViz::Data::Structure->new($pink_struct,Colors=>'pink');

=begin internals

=head1 INTERNAL METHODS

=over 4

The following methods are I<internal> methods and should not be counted 
upon; if the internal algorithm changes, these routines will undoubtedly also
change. Do not base any code on the peculiarities of these methods!
They are documented here only for ease in further extension of the program.

=back 

=head2 C<init($root,$rank)>

C<init()> (currently) does a depth-first search of the data 
structure. As it reaches each node, it creates an appropriate C<GraphViz> 
node for it, caches the item (so it will not be processed again, and so other
links to this node will point to it), and then calls itself
recursively to process all the nodes below it.

The call returns a node name and a "to" port specification suitable for
passing on to a C<GraphViz-\>add_edge()> call. 

Initial rank should be zero; recursive calls increment the rank. When the
rank exceeds the C<Depth> parameter, the recursion halts and dummy "..."
nodes are returned.

=end internals

=cut 

sub init {
  my($self, $root, $rank, $linkthru) = @_;
  local $_;

  my @rank = (rank=>$rank);

  # If we've exceeded the depth limit, just return a plaintext "..." node.
  if (defined $self->{Depth} and $rank > $self->{Depth}) {
    _debug("Dummy node\n");
    my $node_type = sprintf("DUMMY(%08X)",0+$self->{Dummies}++);
    my $node_label = $node_type; 
    my $name = "gvds_dummy" . $self->{Dummies}++;

    $self->{Graph}->add_node($name,
                             label=>"...",
                             @rank,
                             shape=>"plaintext");
    $self->{NodeCache}->{$node_label} = [$name];  
      return ($name,());   # no to-port for plaintext
  }

  # Find the address of the incoming item. If it's already a reference,
  # stringifying it will get the address.If not, make a reference to it.
  # Special case for regexps: they have a ref of 'Regexp', but if stringified
  # they return the regexp. Get a reference to them too.
  my $ref = (ref($root) eq 'Regexp' or !ref($root)) ? \$root : $root;

  # If this item is already in the addresses cache, we've visualized it
  # already. Find the node and port information and just return that.
  my $hookup_info = $self->{Addresses}->{refaddr($ref)};
  return @$hookup_info if defined $hookup_info;

  # Figure out what the node is. Just ref() won't do, as it doesn't tell you
  # what the referent is if it's an object.
  foreach my $node_type (reftype($root)) {
    my $node_label = ref $root;
    my @to_port = ();
    
    _debug("Label: $node_label\n");

    # Just a scalar, not a scalar ref. Generate a plaintext node.
    # Yes, this one *should* be node_label, not node_type.
    $node_label =~ /^$/ and do {
      _debug("Atomic node\n");
      my $hookup_info = undef;
      $hookup_info = $self->{Addresses}->{$root} if defined $root;
      return @$hookup_info if defined $hookup_info;

      my $name = "gvds_atom" . $self->{Atoms}++;
      $self->{Graph}->add_node($name,
                               label=>$self->_dot_escape($root),
                               @rank,
                               shape=>"plaintext");
      $self->{NodeCache}->{$name} = [$name, ()];
      $self->{Addresses}->{$root} = [$name, ()] if defined $root;
      return ($name,());   # no to-port for plaintext
    };

    # Regexp. Generate a node for this containing the regexp text and return. 
    # Regexps are always leaf nodes. Again, this should be node_label.
    $node_label =~ /^Regexp$/ and do {
      $node_type = "$root";
      my($flagson, undef, $flagsoff, $regexp) = 
        ($node_type =~ /^\(\?(.*?)(-(.*?))*?:(.*)\)$/);
      print "Regex $node_type parsed as: $regexp (+$flagson, -$flagsoff)\n" if $Debug;
      my $name = "gvds_atom" . $self->{Atoms}++;
      $self->{Graph}-> add_node($name,
                                label=>$self->_dot_escape("qr/$regexp/$flagson"),
                                @rank,
                                shape=>"plaintext");
      $self->{NodeCache}->{name}            = [$name, ()];
      $self->{Addresses}->{refaddr(\$root)} = [$name, ()];
      return ($name,());   # no to-port for plaintext
    };

    # Scalar reference.
    $node_type =~ /SCALAR|REF/ and do {
      _debug("Scalar node\n");
      my $name = "gvds_scalar" . $self->{Scalars}++;
      # If linkthrough is on, just skip this node and go down a level directly.
      # Do not increment the rank since we've skipped a level. This is needed
      # because hashes seem to generate an extra scalar node internally when
      # references are stored in aggregate elementis; linkthru elimnates this 
      # from the graph. The result is not 100% accurate, but it is more 
      # readable.
      return $self->init($$root, $rank) if defined $linkthru;

      # Add the node for the scalar itself.
      $self->{Graph}->add_node($name,
                               label=>$self->_scalar_port($root),
                               'shape' => 'record',
                               'color' => $self->{Colors}->{Scalar},
                               'style' => 'filled',
                               'fontcolor' => $self->{Colors}->{Font},
                               @rank);
      @to_port = blessed($root) ? ('to_port' => 0) : ();
      my @from_port = blessed($root) ? ('from_port' => 1) : ();
      $self->{NodeCache}->{$node_type}     = [$name, @to_port];
      $self->{Addresses}->{refaddr($root)} = [$name, @to_port];
 
      # Visualize nodes under this one. If the item pointed to is an element of
      # an aggregate (hash or array), visualize the whole aggregate and then
      # add the edge appropriately. If it's not, just visualize what's
      # underneath and add an edge to it.
      #
      # Sadly, this code does not yet work properly. Everything looks like a
      # scalar. Maybe later.
      my $subnode = $$root;
      my $subnode_name;
      my @next_to_port = blessed($subnode) ? ('to_port' => 0) : ();
      ($subnode_name,@next_to_port) = $self->init($subnode, $rank+1);
      $self->{Graph}-> add_edge($name=>$subnode_name,
                                @from_port,
                                @next_to_port);
      return ($name, @to_port);
    };

    # Array reference. Generate a lst of ports as long as this array is, and
    # create the nodes under it, linking them to the proper ports.
    $node_type =~ /ARRAY/ and do {
      _debug("Array node\n");
      my $name = "gvds_array" . $self->{Arrays}++;

      # Add node for the array itself.
      if (@$root == 0 && !blessed($root)) {
        # Empty unblessed array.
        $self->{Graph}->add_node($name, 
                                 label=>$self->_array_ports($root),
                                 @rank,
                                 shape=> 'plaintext');
      }
      else {
        # Blessed and/or non-empty.
        $self->{Graph}->add_node($name, 
                                 label=>$self->_array_ports($root),
                                 @rank,
                                 shape=> 'record',
                                 'color' => $self->{Colors}->{Array},
                                 'style' => 'filled',
                                 'fontcolor' => $self->{Colors}->{Font},
                                 );
      }
      my @to_port = blessed($root) ? ('to_port' => 0) : ();
      $self->{NodeCache}->{$node_type}     = [$name, @to_port];
      $self->{Addresses}->{refaddr($root)} = [$name, @to_port];

      # For each entry in the array that's a reference, crawl down
      # and link the subtree back in to the current port. Non-reference
      # items have already been trapped in the array_ports routine.
      # In addition, record the address of each element in the array
      # for catching references to individual elements.
      #
      # Recording works, but the lookup to spot references to elements 
      # currently does not.
      my $port = 1;
      my @next_to;
      foreach my $subnode (0..$#{$root}) {
         $self->{Addresses}->{refaddr(\($root->[$subnode]))} = 
           [$name, ('to_port' => $port)];
         if (ref $root->[$subnode]) {
           my ($subnode_name,@next_to) = 
             $self->init($root->[$subnode], $rank+1, "link through");
           $self->{Graph}-> add_edge($name=> $subnode_name,
                                     'from_port'=>"$port", 
                                     @next_to);
         }
         $port++;    # always go to next port, even if no edge added
      }
      return ($name, @to_port);
    };

    # Hash reference. Add a node for it; the label creates a record with a
    # port to connect in to (port 0), and ports to connect out from for all
    # entries  that contain references. Generate the nodes below (if any) and
    # hook them back in.
    $node_type =~ /HASH/ and do {
      _debug("Hash node\n");
      my $name = "gvds_hash" . $self->{Hashes}++;
      if (scalar keys %$root == 0 && !blessed($root)) {
        # Empty hash.
        $self->{Graph}->add_node($name, 
                                 label=>$self->_hash_ports($node_type, $root), 
                                 @rank,
                                 shape=>'plaintext'
                                 );
      }
      else {
        # Non-empty and/or blessed hash.
        $self->{Graph}->add_node($name, 
                                 label=>$self->_hash_ports($node_type, $root), 
                                 @rank,
                                 shape=>'record',
                                 'color' => $self->{Colors}->{Hash},
                                 'style' => 'filled',
                                 'fontcolor' => $self->{Colors}->{Font},
                                 );
      }
      my @to_port = blessed($root) ? ('to_port' => 0) : ();
      $self->{NodeCache}->{$node_type}     = [$name, @to_port];
      $self->{Addresses}->{refaddr($root)} = [$name, @to_port];

      my $port = 2;

      foreach my $subnode (sort keys %$root) {
        # Same logic as above: if the value is scalar, we don't want to
        # crawl down, because object_ports will have caught it. Otherwise,
        # crawl down, generate the nodes below, and link them back in.
        # We go by twos because the keys have the odd ports and the values
        # the even ones; we want links to come from the values.
        if (ref $root->{$subnode}) {
          $self->{Addresses}->{refaddr(\($root->{$subnode}))} = 
            [$name, ('to_port' => $port)];
          my ($subnode_name,@to_port) = $self->init($root->{$subnode},
                                              $rank+1,"link through");
          $self->{Graph}->add_edge($name=>$subnode_name,
                                   'from_port' => "$port", @to_port);
        }
        $port += 2;  # always go to next port, even if no edge added
      }
      return ($name, @to_port);
    };

    # Code reference. We call a modified version of dumpvar.pl, then insert
    # a plaintext node containing the package and name.
    $node_type =~ /CODE/ and do {
      _debug("Code node\n");
      my $name = "gvds_sub" . $self->{Subs}++;
      my $label = _dumpsub(0,$root);
      $self->{Graph}->add_node($name,
                               label=>$self->_code_label($root, $label),
                               @rank,
                               shape=>"plaintext");
      $self->{NodeCache}->{$name}          = [$name, ()];  
      $self->{Addresses}->{refaddr($root)} = [$name, ()];
      return ($name,());   # no to-port for plaintext
    };

    # Glob reference. We parse the glob, creating a fake hash object for the
    # glob, and then recurse on it just like you would normally for a hash.
    $node_label =~ /GLOB/ and do {
      my $name = "gvds_glob" . $self->{Globs}++;
      my ($fake_glob, $label) = _dumpglob($root);
      if (ref $fake_glob) {
        bless $fake_glob, $label;
        $self->{Graph}-> add_node($name,
				  label=> $self->_glob_ports($label,$fake_glob),
				  @rank,
                                  'color' => $self->{Colors}->{Glob},
                                  'style' => 'filled',
                                  'fontcolor' => $self->{Colors}->{Font},
				  shape=> "record"
                                  );
	my @to_port = ('to_port' => 0);  # the fake hash is always blessed
	$self->{NodeCache}->{$name}               = [$name, @to_port];	
        $self->{Addresses}->{refaddr($fake_glob)} = [$name, @to_port];

	# Now take the "glob" apart.
	my $port = 2;
	foreach my $subnode (sort keys %$fake_glob) {
	  # Same logic as above: if the value is scalar, we don't want to
	  # crawl down, because _hash_ports will have caught it. Otherwise,
	  # crawl down, generate the nodes below, and link them back in.
	  # We go by twos because the keys have the odd ports and the values
	  # the even ones; we want links to come from the values.
	  if (ref $fake_glob->{$subnode}) {
            $self->{Addresses}->{refaddr(\($fake_glob->{$subnode}))} = 
              [$name, ('to_port' => $port)];
	    my ($subnode_name,@to_port) = $self->init($fake_glob->{$subnode},
                                                      $rank+1, "link through");
	    $self->{Graph}->add_edge($name=>$subnode_name,
                                     'from_port' => "$port", @to_port);
	  }
          $port += 2;  # always go to next port, even if no edge added
        }
        # Done. Return the fake glob to the next level up.
        return ($name,@to_port);
      }
      # Otherwise, it was an empty glob. Just print the string for it.
      else {
        $self->{Graph}->add_node($name,
                                 label=>$self->_code_label($root, $label),
                                 @rank,
                                 shape=>"plaintext");
        $self->{NodeCache}->{$name}          = [$name, ()];
        $self->{Addresses}->{refaddr($root)} = [$name, ()];
        return ($name, ());   # no to-port for plaintext
      }
    };
  }
}

=head1 DOT INPUT - LAYOUT DETAILS

Port strings and C<shape=record> nodes are the key to visualizing the data 
structures in a readable way. The examples in the C<dot> documentation are 
some help, but a certain amount of experimentation was needed to determine 
exactly how the port strings needed to be set up so that the desired layout
was achieved.

Port strings do two things: they determine where edges come in and where they
go out, and they allow you to position items relative to one another inside a
node. This conflation of function makes creating port strings that Do What
You Want a little more difficult.

A little study of port strings seems to indicate that just alternating items
will cause them to be laid out horizontally, while putting them in braces and
alternating seems to yield a vertical layout:

   # Horizontal port string for 1 2 3:
   $ports = "1|2|3";
   # Vertical port string for 1 2 3:
    $ports = "{1}|{2}|{3}";

This works fine for very simple sets of boxes in a line (which, from studying
the examples, seems to be the principal thing that the original C<GraphViz>
implementors used). Anything more complicated (such as getting paired sets of
boxes to all line up smartly) takes a bit of extra work.

=head2 SCALARS

Scalars are represented either by plaintext nodes (for non-reference values)
or record nodes (for references); they don't need ports, because we'll be 
linking at most one edge out, and there's only one "thingy" to link to in a 
scalar. However, we do have to deal with blessed scalars as well, which need
to have both their class name and value in the node, but need to look
different than arrays.

If a scalar's value is a reference, we add a record-style node and link it to
the value. If the scalar is blessed, we put the class name and the scalar's
value both in the same node  by constructing a multi-line string with the 
class name on top, tagged appropriately, and the value on the bottom.

=cut

sub _scalar_port {
  my ($self, $scalar) = @_;
  my $out;
  if (defined (my $here = blessed($scalar))) {
     # Blessed scalar. Add name.
     $out = "{{<port0>$here\\n[Scalar object]}|{<port1>" .
              (ref $scalar ? "." : $self->_dot_escape($scalar)) ."}}";
  }
  else {
    # Not blessed.
    $out = "";
  }
  _debug("$out\n");
  $out;
}
=head2 ARRAYS

Arrays have to be handled four different ways:

=over 4

=item Unblessed, laid out vertically

=item Unblessed, laid out horizontally

=item Blessed, laid out vertically

=item Blessed, laid out horizontally

=back

Unblessed arrays should (ideally) simply be rows of boxes, with either values
or edges each box. We can set up port strings for this fairly easily:

   # Array assumed to contain (1,\$x,"s").
   $ports = "<port1>1|<port2>|<port3>s";

This gives a nice row of boxes, with all the cells lined up nicely in either
horizontal or vertical orientations.
We don't need extra fiddling with the port string to get them to look right.

Things become a bit mode complex for blessed arrays, though, because we
want to include the class name as well in the record. We want to make
sure that the class name itself isn't confused with any of the data
items, so it needs to be off in a box by itself, parallel to the boxes
defining the array. This means laying out a box the length of the whole
array above the boxes defining the array in a horizontal layout, and a box 
the height of the whole array to the left of the boxes defining the array in 
a vertical layout.

Fortunately (again), the same basic port string works in both orientations.

   # Object is an array blessed into class "Foo", containing (1,\$x,"s").
   # Horizontal:
   $ports = "{<port0>Foo|{{<port1>1}|{<port2>}|{<port2>s}}}";

Note that we use the alernating braced items to get the array to lay out at
90 degrees from the box containing the class name. This particular string
was arrived at after a fair amount of twiddling in C<dotty> and seems to be
the simplest port layout that works.

Empty arrays, if they're unblessed, are just shown as a "[]" plaintext node.
If they're blessed, we set up a record that looks sort of like a two-element
array, but contains the classname, notes that it's an array, and shows that
it's empty explicitly.

=cut

sub _array_ports {
  my ($self, $arrayref) = @_;
  local $_;
  my @ports = ();
  my $port = 1;
  my $label_needed = blessed($arrayref);

  # Deal with the empty cases first. If the array is completely empty
  # and is not blessed, we just want to show a plaintext "[]". If it's
  # blessed, we want to show a record which shows that it's a blessed
  # array, but empty.
  if (@$arrayref == 0) {
    if ($label_needed) {
      # Empty, but blessed.
      return "{<port0>$label_needed\\n[Array object]|{(empty)}}";
    }
    else {
      # Empty, and not blessed.
      return "[]";
    }
  }

  # Another exception: single-element arrays.
  if (@$arrayref == 1) {
    my $cleanvalue;
    my $v = $arrayref->[0];
    if (ref $v) {
      $cleanvalue = "<port1>.";
    }
    else {
      $cleanvalue = "<port1>" . $self->_dot_escape($v);
    }
    my $basic;
    if (!$label_needed) {
      $basic = "$cleanvalue";
    }
    else {
      $basic = "{<port0>$label_needed\\n[Array object]|$cleanvalue}";
    }
    return $basic;
  }

  my $case;
  # Case 2: unblessed array.
  $case = 2 if !$label_needed;

  # Case 4: blessed array. 
  $case = 4 if $label_needed;

  foreach (@$arrayref) {
    ref $_ ? (push @ports, "{<port$port>.}") 
           :  push @ports, "{<port$port>" . $self->_dot_escape($_) . "}";
    $port++;
  }

  local $_;
  my $array_ports;
  foreach ($case) {
    # Case 2: unblessed array, laid out horizontally.
    #   $hports = "<port1>1|<port2>|<port3>s";
    /2/ and do {
      $array_ports = join "|", @ports; 
    };

    # Case 4: blessed array, laid out horizontally. 
    #   $hports = "{<port0>Foo|{{<port1>1}|{<port2>}|{<port2>s}}}";
    /4/ and do {
      $array_ports = "{<port0>$label_needed\\n[Array object]|{" . (join "|", @ports) . "}}";
    }
  }
  _debug("$array_ports\n");
  $array_ports;
}

=head2 HASHES

Hashes are similar to arrays, with the twist that we need to have I<two
parallel> sets of boxes which correspond to the keys and values.
In addition, we have the same four cases we did for arrays:

=over 4

=item Unblessed, laid out vertically (key to right of value)

=item Unblessed, laid out horizontally (key above value)

=item Blessed, laid out vertically (key below value)

=item Blessed, laid out horizontally (key to right of value)

=back

Unblessed hashes should (ideally) simply be I<pairs> of rows of boxes - one 
for key, one for value - with  either values or edges in each "key" box.  
Setting up port strings for this is a bit more difficult.

   # Hash assumed to contain (A=>1,B=>\$x,C=>"s").
   # Horizontal:
   $hports = "{<port1>A|<port2>1}|{<port3>B|<port4>}|{<port5>C|<port6>s}";

   # Vertical:
   $vports = "{<port1>A|<port3>B|<port5>C}|{<port2>1|<port4>|<port6>s}";

Switching from horizontal to vertical requires us to separate the keys from
the values.

Adding a class name presents some problems. C<dot> is not absolutely
symmetric when it comes to parsing complex port strings; in some cases, it
carefully lines up all the edges of boxes internal to a record; other times
it doesn't. Rather than continue to try to kludge around this, it seemed
the better part of valor to simply accept what it would do prettily and
ignore the rest. In laying out blessed hashes (and following our self-imposed
standard), we can either have 

=over 4

=item a single box on the left containing the class name for 
hashes laid out vertically 

=item a single box the top containing the class name for hashes 
laid out horizontally

=back

Anything else both significantly increases the complexity of the interface
("let's see, arrays should be horizontal, and hashes should be horizontal
with names on top, so I code ... uh ...") and, well, doesn't work very well.
So we stick with these two basic layouts and keep it pretty and simple.

   # Object is an hash blessed into class "Foo".
   # Hash assumed to contain (A=>1,B=>\$x,C=>"s").
   # Horizontal, name on top:
   $hports = 
   "{<port0>Foo|{{<port1>A|<port2>1}|{<port3>B|<port4>}|{<port5>C|<port6>s}}}";

   # Vertical, name on left:
   $vports = 
   "<port0>Foo|{<port1>A|<port3>B|<port5>C}|{<port2>1|<port4>|<port6>s}";

Note that we also have to change how we add the braces to the keys and values
when switching where the name is, in addition to separating or associating the 
keys and values as needed.

The good thing is that once this is all worked out, no one else has to care 
anymore.  It just works and looks nice.

=head2 GLOBS

Globs, from the layout point of view, look pretty much like blessed hashes.
The only exception for globs is if there's nothing in the glob, we want to 
display it just as a plaintext node.

=cut

=for internals

In the interest of coding as little as possible, we just reuse the hash code. 
We construct a tiny pair of wrapper methods which add the necessary information 
to the parameter list and then call the common module.

=cut

sub _hash_ports {
  my $self = shift;
  $self->_hash_or_glob_ports("Hash",@_);
}

sub _glob_ports {
  my $self = shift;
  $self->_hash_or_glob_ports("Glob",@_);
}

sub _hash_or_glob_ports {
  my ($self, $type, $label, $hash) = @_;
  local $_;
  my @ports = ();
  my $port;
  my $label_needed = blessed($hash);
  my $case;

  # Set up for later. Since both blessed hashes and globs are laid
  # out identically except for the text in the "what is this" box,
  # We'll just pull out the string that differentiates them and
  # set it appropriately right here. Leter on, the code can be
  # identical, with the decision already out of the way.
  my $description = {Hash=>"\\n[Hash object]", Glob=>""}->{$type};

  # Exception: empty hashes. If the hash is completely empty and is not
  # blessed, we just want to show a plaintext "{}". If it's blessed, we
  # want to show a record which shows that it's a blessed hash, but empty.
  # We use the description because that's the only thing that's different
  # by this point.
  if (scalar keys %$hash == 0) {
    if ($label_needed) {
      # Empty, but blessed.
      return "{<port0>$label_needed$description|{(empty)}}";
    }
    else {
      # Empty, and not blessed. Note that globs can't get here (they're
      # always blessed hashes), so we don't need any logic to differentiate.
      return "{}";
    }
  }

  # Another exception: single-element unblessed hash. Just needs to go back
  # as a pair of boxes.
  if (scalar keys %$hash == 1 and !$label_needed) {
    # (keys %$hash)[0] gets the only key there is.
    my $cleankey = "<port1>" . $self->_dot_escape((keys %$hash)[0]);
    my $cleanvalue;
    my $v = (values %$hash)[0];
    if (ref $v) {
      # Put in the dot so dot doesn't collapse the box.
      $cleanvalue = "<port2>.";
    }
    else {
      # There's a real value here.
      $cleanvalue = "<port2>" . $self->_dot_escape($v);
    }
    my $basic;
    $basic = "{$cleankey|$cleanvalue}";
    return $basic;
  }

  # Now for the other cases. These are:
  # Case 1: unblessed hash, laid out vertically.
  # {{<port1>A|<port3>B|<port5>C}|{<port2>1|<port4>|<port6>s}}
  $case = 1 if !$label_needed and $self->{Orientation} eq 'vertical';

  # Case 2: unblessed hash, laid out horizontally. 
  # {<port1>A|<port2>1}|{<port3>B|<port4>}|{<port5>C|<port6>s}
  $case = 2 if !$label_needed and $self->{Orientation} ne 'vertical';

  # Case 3: blessed hash (glob), laid out vertically, label on left.
  # {{<port0>Foo}|{<port1>A|<port3>B|<port5>C}|{<port2>1|<port4>|<port6>s}}
  $case = 3 if $label_needed  and $self->{Orientation} eq 'vertical';

  # Case 4: blessed hash (glob), laid out horizontally, label on top. 
  # {<port0>Foo|{{<port1>A|<port2>1}|{<port3>B|<port4>}|{<port5>C|<port6>s}}}
  $case = 4 if $label_needed  and $self->{Orientation} ne 'vertical';

  # Determine if we need associated or separated pairs. 
  my $associate = 1 if grep /$case/,(2,4);
  my $separate  = 1 if grep /$case/,(1,3);

  my @sets = ();
  my $port_string = "";

  # If the keys and values are separated, make one set of keys and one set
  # of values.
  if ($separate) {
    $port = 1;
    foreach my $k (sort keys %$hash) {
      my $v = $hash->{$k};
      $sets[0] .= "<port$port>" . $self->_dot_escape($k) . "|"; $port++;
      if (ref $v) {
        $sets[1] .= "<port$port>.|"; $port++;
      }
      else {
        $sets[1] .= "<port$port>" . $self->_dot_escape($v) . "|"; $port++;
      }
    }
    chop @sets;
  }

 # If they are associated, make a set for each key and value.
  elsif ($associate) {
    $port = 1;
    foreach my $k (sort keys %$hash) {
      my $v = $hash->{$k};
      my $cleankey = "<port$port>" . $self->_dot_escape($k); $port++;
      my $cleanvalue;
      if (ref $v) {
        $cleanvalue = "<port$port>."; $port++;
      }
      else {
        $cleanvalue = "<port$port>" . $self->_dot_escape($v); $port++;
      }
      push @sets, "$cleankey|$cleanvalue";
    }
  }
  else {
    die "Can't happen: neither separate nor associated";
  }

  # Now assemble the sets appropriately by case.
  if ($case == 1) {
    # Case 1: unblessed hash, laid out vertically.
    # {<port1>A|<port3>B|<port5>C}|{<port2>1|<port4>|<port6>s}
    $port_string = "{" . (join "|", (map {"{$_}"} @sets)) . "}";
  }

  if ($case == 2) {
    # Case 2: unblessed hash, laid out horizontally. 
    # {<port1>A|<port2>1}|{<port3>B|<port4>}|{<port5>C|<port6>s}
    $port_string = join "|", (map {"{$_}"} @sets);
  }

  if ($case == 3) {
    # Case 3: blessed hash (glob), laid out vertically, label on left.
    # {{<port0>Foo}|{<port1>A|<port3>B|<port5>C}|{<port2>1|<port4>|<port6>s}}
    $port_string = "{{<port0>$label_needed$description}|" . (join "|", (map {"{$_}"} @sets)) . "}";
  }

  if ($case == 4) {
    # Case 6: blessed hash (glob), laid out horizontally, label on top. 
    # {<port0>Foo|{{<port1>A|<port2>1}|{<port3>B|<port4>}|{<port5>C|<port6>s}}}
    $port_string = "{<port0>$label_needed$description|{" . (join "|", (map {"{$_}"} @sets))
                                            . "}}";
  }

  $port_string;
}

=head2 CODE references

C<CODE> references are the simplest. We just say that they're code, and add on
the class name if they're blessed. The mainline code's done all the nasty work
of actually figuring out the code ref's name, so we don't have to worry any
further.

=cut

sub _code_label {
  my ($self, $root, $label) = @_;
  my $out;
  if (defined (my $here = blessed($label))) {
     # Blessed scalar. Add name.
     $out = "$here\n[Code object]";
  }
  else {
    # Not blessed.
    $out = "$label";
  }
  _debug("$out\n");
  $out;
}

=head2 HANDING TEXT TO DOT

C<dot> is a C program and therefore can get extremely upset (as in segfault
upset) about text that is too long. In addition, it will become very testy
if the text contains characters which it considers significant in constructing
labels and the like. 

It is necessary to clean up and shorten any text that C<dot> will be expected
to put into a node. The C<_dot_escape> method is used to do this.

Note that the limit on strings is actually not very large; setting a really
big C<Fuzz> will probably make C<dot> segfault when it tries to draw your graph.

=cut

sub _dot_escape {
  my ($self, $string) = @_;
  my ($first,$rest) = ($string,"");
  return "undef" unless defined $string;

  if (length($string) > $self->{Fuzz}) {
    $string = substr($string,0,$self->{Fuzz}) . " ...";
    ($first,$rest) = split(/\n/,$string);
  }

  chomp $first;
  $first .= " ..." if $rest;

  # clean up characters significant to dot
  $first =~ s/([^?\-a-zA-Z0-9.=_(){}\/:* \n])/\\$1/g;
  _debug("$first\n");
  $first;
}

=begin internals

=head1 ESOTERICA

This section deals with Perl internals and will of course have to be rewritten
completely once we know what Perl6 is doing internally with code refs and globs.

It uses C<Devel::Peek> to muck around inside Perl and find the data we need.

=head2 CODEREFS

To decode code references, we just flat-out steal the code from C<dumpvar.pl>.
It has to be trimmed down some, because we don't have the debugger variables
that it depends on (slightly). Most particularly, we don't have line-number
information. C'est la vie.

We clean up the incoming sub reference, then look it up via C<Devel::Peek>.
Trimmed down to the barest essentials. C<Devel::Peek::CvGV> tracks back through
the active symbol tables and pads to find the glob that
contains this item. After that, we can address the glob as if it were a hash,
extracting the package and name from it.

=end internals 

=cut

sub _dumpsub {
  my ($off,$sub) = @_;
  my $ini = $sub;
  $sub = $1 if $sub =~ /^\{\*(.*)\}$/;
  my $subref = defined $1 ? \&$sub : \&$ini;
  $subref = \&$subref;                  # Hard reference...
  my $gv = Devel::Peek::CvGV($subref) or return "CODE()";
  '&' . *$gv{PACKAGE} . '::' . *$gv{NAME};
}

=begin internals

=head2 GLOBS

Globs are an interesting problem. Depending on how they're used, they may
appear to be globs, or they may not. The stringification used in C<init> will
tell us we have a glob if we got a reference to it, but it won't in the case
of a straight glob assignment to a scalar:

  $a = *STDOUT;
  # Appears just as a plaintext node "*main::STDOUT" in the output

  $a = \*STDOUT;
  # Appears to be a glob and is disassembled.

If a glob is detected, it's necessary to look at the components of the glob;
this may or may not lead to items down deeper, so it necessary to pull out
all the defined references in the glob and then recurse on those via C<init>.
Not in there yet: formats. However, since that wasn't in C<dumpvar.pl> either,
this isn't a terrible, awful, solve-it-now problem.

A glob should I<look> sort of like a blessed hash when it's output: there's
a name, which is the name of the glob (*main::Foo); there's a set of "keys"
corresponding to the items that are defined in the glob; and there are all
the things pointed to by the glob, which C<init> can already handle. Since
it also can already format a blessed hash (C<_hash_ports>), why not reuse
the code?

What we do is create an anonymous hash and plug all the pointers into it.
We then use C<Devel::Peek> again to get the glob's name, and bless the hash
into a class by that name, then return that and tell C<init> do dump that.
We stick this just-created node into the mode cache instead of the glob
itself, so any further references to this glob will just get this node again.

We do have to add a little bit of special-case code; the hash formatting code
has to look at the incoming class name and see if it looks like a glob name.
If it does, it formats the hash as a glob; if not, it goes ahead and calls it
a hash.

=end internals

=cut

sub _dumpglob {
  my ($glob) = @_;
  my ($key, $val) = ("{$$glob}", $$glob);
  my $returns = {};

  # We'll be doing all kinds of referencing of things that may not exist;
  # strict has to be off for this code to even *begin* to parse.
  no strict;
  local *entry  = $val;
  # Is there a scalar? 
  if (defined $entry) {
    $returns->{Scalar} = \$entry;
  }
  # An array?
  if (@entry) {
    $returns->{Array}  = \@entry;
  }
  # A hash?
  if (%entry && ($key !~ /::$/)) {
    $returns->{Hash} = \%entry;
  }
  # A filehandle?
  if (defined (my $fileno = fileno(*entry))) {
    $returns->{Filehandle} = \"FileHandle $$glob\n(fileno($fileno))";
  }
  # A sub ? 
  if (defined &entry) {
    $returns->{Sub} = \&entry;
  }
  (($returns ? $returns : "GLOB"),                        # The contents
   ('*' . *$val{PACKAGE} . '::' . *$val{NAME} or 'GLOB')  # The name
  ); 
}

=head1 BUGS

Cannot catch pointers to individual array or hash elements yet and display the
containing items, even though it tries.

=head1 BUGS EXPOSED IN DOT

Data structures which point directly to themselves will cause C<dot> to 
discard all input in some cases. There's currently no fix for this; you can
call the C<was_null()> method for now, which will tell you the graph was
null and let you decide what to do.

It isn't possible (in current releases of C<dot>) to code a record label which 
contains no text (e.g.: C<{E<lt>port1E<gt>}>); this generates a zero-width box. 
This has been worked around by placing a single period in places where nothing 
at all would have been preferable. The C<graphviz> developers have developed a
patch for C<dot> that corrects the problem, but it is not yet in a released 
version, though it is in CVS.

=head1 AUTHOR

Joe McMahon E<lt>F<mcmahon@ibiblio.org>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2002, Joe McMahon

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
