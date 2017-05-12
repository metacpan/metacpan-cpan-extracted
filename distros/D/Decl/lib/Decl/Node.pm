package hashtie;
use warnings;
use strict;
#require Tie::Hash;
#our @ISA = qw(Tie::ExtraHash);  - Apparently only standard in perl >= 5.10.  I'm copying it here to remove that dependency, because
#                                  let's face it, it's eleven lines of code.
#                                  Nota bene: CPAN Testers freaking rock!

sub new {
    my $pkg = shift;
    $pkg->TIEHASH(@_);
}
sub TIEHASH  { my $p = shift; bless [{}, @_], $p }
#sub STORE    { $_[0][0]{$_[1]} = $_[2] }
#sub FETCH    { $_[0][0]{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0][0]}; each %{$_[0][0]} }
sub NEXTKEY  { each %{$_[0][0]} }
sub EXISTS   { exists $_[0][0]->{$_[1]} }
sub DELETE   { delete $_[0][0]->{$_[1]} }
sub CLEAR    { %{$_[0][0]} = () }
sub SCALAR   { scalar %{$_[0][0]} }

# My versions of STORE and FETCH.
sub STORE {
   my ($this, $key, $value) = @_;
   if ($this->[1]{$key}) { return &{$this->[1]{$key}}(undef, $this->[0], $key, $value); }
   return $this->[2]->setvalue($key, $value) if defined $this->[2];
   $this->[0]{$key} = $value;
}

sub just_store {
   my ($this, $key, $value) = @_;
   $this->[0]{$key} = $value;
}

sub FETCH {
   my ($this, $key, $value) = @_;
   if ($this->[1]{$key}) { return &{$this->[1]{$key}}(undef, $this->[0], $key); }
   return $this->[2]->get_value($key) if defined $this->[2];
   $this->[0]{$key};
}

sub just_get {
   my ($this, $key, $value) = @_;
   $this->[0]{$key};
}

package Decl::Node;

use warnings;
use strict;

use Iterator::Simple qw(:all);
use Text::ParseWords;
use Decl::Semantics::Code;
use Decl::Util;
use Data::Dumper;
use Carp;

=head1 NAME

Decl::Node - implements a node in a declarative structure.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';


=head1 SYNOPSIS

Each node in a C<Decl> structure is represented by one of these objects.  Specific semantics modules subclass these nodes for each of their
components.

=head2 defines(), tags_defined()

Called by C<Decl> during import, to find out what xmlapi tags this plugin claims to implement.  This is a class method, and by default
we've got nothing.

The C<wantsbody> function governs how C<iterator> works.

=cut
sub defines { (); }
sub tags_defined {
   my $self = shift;
   my $tag = Decl->new_data('handle');
   foreach ($self->defines()) {
      $tag->load($_);
   }
   return $tag;
}

=head2 overloaded ""

The node class returns tag(class) when expressed as a string.

=cut

use Scalar::Util qw(refaddr);
use overload ('""' => sub { $_[0]->tag . '(' . ref($_[0]) . ':' . refaddr($_[0]) . ')' },
              '==' => sub { refaddr($_[0]) eq refaddr($_[1]) },
              'eq' => sub { refaddr($_[0]) eq refaddr($_[1]) },
              '!=' => sub { refaddr($_[0]) ne refaddr($_[1]) });

=head2 refaddr_or_undef

This is a cheap trick we're going to use for inserting children after other children.

=cut

sub refaddr_or_undef {
   my $r = refaddr ($_[0]);
   $r = $_[0] if not defined $r;
   $r;
}

=head2 new()

The constructor for a node takes either one or an arrayref containing two texts.  If one, it is the entire line-and-body of a node;
if the arrayref, the line and the body are already separated.  If they're delivered together, they're split before proceeding.

The line and body are retained, although they may be further parsed later.  If the body is parsed, its text is discarded and is reconstructed if it's
needed for self-description.  (This can be suppressed if a non-standard parser is used that has no self-description facility.)

The node's I<tag> is the first word in the line.  The tag determines everything pertaining to this entire section of the
application, including how its contents are parsed.

=cut

sub new {
   my $class = shift;
   #print STDERR "Adding $class\n";
   my $self = bless {
      state       => 'unparsed', # Fresh.
      payload     => undef,      # Not built.
      sub         => sub {},     # Null action.
      callable    => 0,          # Default is not callable.
      owncode     => 0,          # Default doesn't have own callable code.
      macroresult => 0,          # Default is explicit text.
      flag        => '',         # Indicates special handling of content.
      name        => '',
      namelist    => [],
      parameters  => {},
      parmlist    => [],
      options     => {},
      optionlist  => [],
      label       => '',
      parser      => undef,
      code        => undef,
      finalcode   => undef,
      errors      => [],
      elements    => [],
      parent      => undef,
      comment     => '',
      bracket     => 0,
      replaced    => 0,
      group       => 0,
      parsemode   => '',         # Default is to use class nodes.  Other valid values: text, vanilla.
      is_reference=> 0,
   }, $class;

   my %values = ();
   my %handlers = ();
   $self->{hashtie} = tie %values, 'hashtie', \%handlers, $self;
   $self->{v} = \%values;
   $self->{h} = \%handlers;
   $self->{e} = {};
   
   # Now prepare the body as needed.
   my ($line, $body);
   $body = shift;
   #print STDERR "new: body is " . Dumper ($body);
   $body = '' unless defined $body;
   if (ref $body eq 'ARRAY') {
      #print STDERR "new: body is arrayref\n";
      {
         my @bodyrest;
         ($line, @bodyrest) = @$body;
         #print STDERR "new: first line is $line\n";
         $body = \@bodyrest;
      }
   } else {
      ($line, $body) = split /\n/, $body, 2;
   }
   
   $line = 'node' unless defined $line;
   my ($fulltag, $rest) = split /\s+/, $line, 2;
   my ($tag, $flag) = splittag ($fulltag);
   $self->{tag} = $tag;
   $self->{flag} = $flag;
   $self->{line} = $rest;
   $self->{line} = '' if not defined $self->{line};
   $self->{body} = $body;

   return $self;
}

=head2 splittag - class method

This splits the flag off a tag (e.g. template. => template + .)

=cut

sub splittag { $_[0] =~ /^(.*?)([\?\!\*\.\+:]*)$/; }

=head2 tag(), flag(), is($tag), name(), names(), line(), hasbody(), body(), elements(), truenodes(), payload()

Accessor functions.

=cut

sub tag       { $_[0]->{tag} }
sub flag      { $_[1] ? (index ($_[0]->{flag}, $_[1]) >= 0) : $_[0]->{flag} }
sub is        {
   my ($self, $is) = @_;
   foreach (split /\|/, $is) {
      return 1 if $self->{tag} eq $_;
   }
   return 0;
}
sub name      { $_[0]->{name} }
sub names     { @{$_[0]->{namelist}} }
sub line      { $_[0]->{line} }
sub hasbody   { defined $_[0]->{body} ? ($_[0]->{body} ? 1 : 0) : 0 }
sub body      { $_[0]->{body} }
sub elements  { @{$_[0]->{elements}} }
sub truenodes { grep { ref $_ && (defined $_[1] ? $_->is($_[1]) : 1) } @{$_[0]->{elements}} }
sub payload   { $_[0]->{payload} }

=head2 nodes($flavor)

The I<true> nodes (C<truenodes()> of a parent are the actual structural children that aren't comments.  This function returns
the I<functional> nodes - by using a grouping structure, the results of macros, selects, and inserts can appear to be rooted
in the parent at precisely the place their progenitor is located.

If C<$flavor> is specified, C<nodes()> returns only those children with tags equal to C<$flavor>; otherwise, all functional
children are returned.

=cut

sub nodes {
   my ($self, $flavor) = @_;
   my @return = ();
   
   foreach my $n ($self->truenodes) {
      if ($n->{group}) {
         push @return, $n->nodes($flavor);
      } elsif (defined $flavor ? $n->is($flavor) : 1) {
         push @return, $n;
      }
   }
   return wantarray ? @return : (@return ? $return[0] : undef);
}

=head2 content_nodes($flavor)

The I<content> nodes of a parent are the functional nodes returned by C<nodes> minus any that have the flag ':'.  This permits nodes to be split
into "meta" specifications and child specifications for a given parent. An example might be providing a "style:" parameter for a text structure, or
a "path:" parameter for a directory.

=cut

sub content_nodes {
   my ($self, $flavor) = @_;
   my @return = ();
   
   foreach my $n ($self->truenodes) {
      if ($n->{group} and not $n->flag(':')) {
         push @return, $n->content_nodes($flavor);
      } elsif ((defined $flavor ? $n->is($flavor) : 1) and not $n->flag(':')) {
         push @return, $n;
      }
   }
   return wantarray ? @return : (@return ? $return[0] : undef);
}


=head2 parent(), ancestry()

A list of all the tags of nodes above this one, culminating in this one's tag, returned as an arrayref.

=cut

sub parent { $_[0]->{parent} }
sub ancestry {
   my ($self) = @_;
   my $parent = $self->parent();
   (defined $parent and $parent != $self->root()) ? [@{$parent->ancestry()}, $self->tag()] : [$self->tag()];
}

=head2 parameter($p), option($o), parmlist(), optionlist(), parameter_n(), option_n(), label(), parser(), code(), gencode(), errors(), bracket(), comment()

More accessor functions.

=cut

sub parameter   { $_[0]->{parameters}->{$_[1]} || $_[2] || '' }
sub option      { $_[0]->{options}->{$_[1]} || $_[2] || '' }
sub option_n    { ($_[0]->optionlist)[$_[1]-1] }
sub parameter_n { ($_[0]->parmlist)[$_[1]-1] }
sub parmlist    { @{$_[0]->{parmlist}} }
sub optionlist  { @{$_[0]->{optionlist}} }
sub label       { $_[0]->{label} }
sub parser      { $_[0]->{parser} }
sub code        { $_[0]->{code} }
sub gencode     { $_[0]->{gencode} }
sub bracket     { $_[0]->{bracket} }
sub comment     { $_[0]->{comment} }

sub errors  { @{$_[0]->{errors}} }

=head2 plist(@parameters)

Given a list of parameters, returns a hash (not a hashref) of their values, first looking in the parameters, then looking for children
of the same name and returning their labels if necessary.  This allows us to specify a parameter for a given object either like this:

   object (parm1=value1, parm2 = value2)
   
or like this:

   object
      parm1 "value1"
      parm2 "value2"
      
It just depends on what you find more readable at the time.  For this to work during payload build, though, the children have to be built
first, which isn't the default - so you have to call $self->build_children before using this in the payload build.

This is really useful if you're wrapping a module that uses a hash to initialize its object.  Like, say, L<LWP::UserAgent>.

=cut

sub plist {
   my $self = shift;
   my %p;
   foreach my $p (@_) {
      if ($self->parameter($p)) {
         $p{$p} = $self->parameter($p);
      } elsif (my $pnode = $self->find($p)) {
         $p{$p} = $pnode->label;
      }
   }

   %p;
}

=head2 parm_css (parameter), set_css_values (hashref, parameter_string), prepare_css_value (hashref, name), get_css_value (hashref, name)

CSS is characterized by a sort of "parameter tree", where many parameters can be seen as nested in a hierarchy.  Take fonts, for example.
A font has a size, a name, a bolded flag, and so on.  To specify a font, then, we end up with things like font-name, font-size, font-bold, etc.
In CSS, we can also group those things together and get something like font="name: Times; size: 20", and that is equivalent to
font-name="Times", font-size="20".  See?

This function does the same thing with the parameters of a node.  If you give it a name "font" it will find /font-*/ as well, and munge
the values into the "font" value.  It returns a hashref containing the entire hierarchy of these things, and it will also interpret any
string-type parameters in the higher levels, e.g. font="size: 20; name: Times" will go into {size=>20, name=>'Times'}.  Honestly, I love
this way of handling parameters in CSS.

If you give a name "font-size" it will also find any font="size: 20" specification and retrieve the appropriate value.

It I<won't> decompose multiple hierarchical levels starting from a string (e.g. something like font="size: {type: 3}" will not be parsed for
font-size-type, because you'd need curly brackets or something anyway, and this ain't JSON, it's just simple CSS-like parameter addressing.

=cut

sub parm_css {
   my ($self, $parameter) = @_;
   my $return = {};
   my $top = $parameter;
   $top =~ s/[.\-\/].*$//;
   hh_set ($return, $top, $self->parameter ($top)) if $self->parameter($top);
   foreach ($self->parmlist()) {
      if ($_ =~ /^$top[.\-\/]/) {
         hh_set ($return, $_, $self->parameter ($_));
      }
   }
   return hh_get ($return, $parameter);
}


=head2 flags({flag=>numeric value, ...}), oflags({flag=>numeric value, ...})

A quick utility to produce an OR'd flag set from a list of parameter words.  Pass it a hashref containing numeric values for a set of words, and
you'll get back the OR'd sum of the flags found in the parameters.  The C<flags> function does this for the parameters (round parens) and the C<oflags>
function does the same for the options [square brackets].

=cut

sub flags {
   my ($self, $f) = @_;
      
   my $r = 0;
   
   while (my ($k, $v) = each %$f) {
      $r |= $v if $self->parameter ($k);
   }
   return $r;
}
sub oflags {
   my ($self, $f) = @_;
   
   my $r = 0;
   
   for (my ($k, $v) = each %$f) {
      $r |= $v if $self->option ($k);
   }
   return $r;
}

=head2 list_parameter ($name)

Sometimes, instead of having e.g. position-x and position-y parameters, it's easier to have something like p=40 20 or dim=20x20.  We can use
the C<list_parameter> function to obtain a list of any numbers separated by non-number characters. (Note that due to the line parser using
commas to separate the parameters themselves, the separator can't be a comma.  Unless you want to write a different line parser, in which
case, go you!)

So the separator characters can be: !@#$%^&*|:;~x and space.

=cut

sub list_parameter { split /[!@\#\$%\^\&\*\|:;~xX ]/, parameter(@_); }

=head1 BUILDING STRUCTURE

=head2 load ($string, $after)

The C<load> method loads declarative specification text into a node by calling the parser appropriate to the node.  Multiple loads can be carried out,
and will simply add to text already there.

The return value is the list of objects added to the target, if any.

=cut

sub load {
   my ($self, $string, $after) = @_;
   
   my @added;
   
   if (ref $string) {
      #print STDERR "load: Adding from arrayref!\n" . Dumper($string);
      if (ref $string ne 'ARRAY') {  # In case we're loading already-created nodes.
         $string->{parent} = $self;
         $self->{elements} = [$self->elements, $string];
         push @added, $string;
      } else {
         my $root = $self->root;
         $string = [$string] unless ref $$string[0];
         foreach my $addition (@$string) {
            #print STDERR "addition is $addition\n";
            #print STDERR "line is " . ref($addition) ? $$addition[0] : $addition;
            my $tag = ref($addition) ? $$addition[0] : $addition;
            $tag =~ s/ .*//;
            #print STDERR ", tag is $tag\n";
         
            # Make and add the tag by hand (for a text body, this is done by the parser in the 'else' block below).
            my $newtag = $root->makenode($self, $tag, $addition);
            $newtag->{parent} = $self;
            $self->{elements} = [$self->elements, $newtag];
         
            push @added, $newtag;
         }
      }
   } else {
      # Taken from the Perl recipes:
      my ($white, $leader);  # common whitespace and common leading string
      if ($string =~ /^\s*(?:([^\w\s]+)(\s*).*\n)(?:\s*\1\2?.*\n)+$/) {
          ($white, $leader) = ($2, quotemeta($1));
      } else {
          ($white, $leader) = ($string =~ /^(\s+)/, '');
      }
      $leader = '' unless $leader;
      $white = '' unless $white;
      $white =~ s/^\n*//;
      $string =~ s/^\s*?$leader(?:$white)?//gm if $leader or $white;
      my $root = $self->root();
      @added = $root->parse ($self, $string);
   }
   
   if ($after) {
      # Rearrange $self->{elements} if we were given an 'after' node that appears in 'elements'.
      my @newels = ();
      my $found_after = 0;
      foreach my $e (@{$self->{elements}}) {
         if (refaddr_or_undef($e) eq refaddr_or_undef($after)) {
            $found_after = 1;
            push @newels, $e;
            foreach my $a (@added) {
               push @newels, $a;
            }
         } else {
            last if grep {refaddr_or_undef($_) eq refaddr_or_undef($e)} @added;
            push @newels, $e;
         }
      }
      $self->{elements} = \@newels if $found_after;
   }
   
   foreach (@added) {
      $_->build if $_->can('build');
   }
   #print Dumper($self->sketch);
   return wantarray ? @added : (@added ? $added[0] : undef);
}

=head2 macroinsert ($spec, $after)

This function adds structure to a given node at runtime that won't show up in the node's C<describe> results.  It is used by the macro system (hence
the name) but can be used by other runtime structure modifiers that act more or less like macros.  The idea is that this structure is meaningful at runtime
but is semantically already accounted for in the existing definition, and should I<always> be generated only at runtime.

=cut

sub macroinsert {
   my ($self, $string, $after) = @_;
   my @objects = $self->load($string, $after);
   foreach (@objects) {
      $_->{macroresult} = 1;
   }
   @objects;   
}

=head2 replace_node ($old_node, $new_node)

There are times when dynamically changing semantics force us to reevaluate an existing node during the build phase.  We use C<replace>
to replace the existing node with the newly interpeted variant.  It works by actual pointer.  If the C<old_name> isn't found, nothing will
happen.

=cut

sub replace_node {
   my ($self, $old, $new) = @_;
   $old->{replaced} = $new; # Make sure ongoing builds build the right node.
   foreach (@{$self->{elements}}) {
      next unless ref $_;
      $_ = $new if $_ == $old;
   }
}

=head2 Setting parts of a node: set_name($name), set_label($label), set_parmlist (@list), set_parameter($key, $value), set_optionlist (@list), set_option($key, $value)

These are handy for building a node from scratch.

=cut

sub set_name {
   my $self = shift;
   $self->{name} = $_[0];
   $self->{namelist} = [@_];  # Make a copy!
}
sub set_label {
   my $self = shift;
   $self->{label} = $_[0];
}
sub set_parmlist {
   my $self = shift;
   $self->{parmlist} = [@_];
}
sub set_parameter {
   my ($self, $key, $value) = @_;
   $self->{parameters}->{$key} = $value;
}
sub set_optionlist {
   my $self = shift;
   $self->{optionlist} = [@_];
}
sub set_option {
   my ($self, $key, $value) = @_;
   $self->{options}->{$key} = $value;
}

=head2 The build process: build(), preprocess(), preprocess_line(), decode_line(), parse_body(), build_payload(), build_children(), add_to_parent(), post_build()

The C<build> function parses the body of the tag, then builds the payload it defines, then calls build on each child if appropriate, then adds itself
to its parent.  It provides the hooks C<preprocess> (checks for macro nature and expresses if so), C<parse_body> (asks the application to call the appropriate
parser for the tag), C<build_payload> (does nothing by default), C<build_children> (calls C<build> on each element), and C<add_to_parent> 
(does nothing by default).

If this tag corresponds to a macro, then substitution takes place before parsing, in the preprocess step.

=cut

sub build {
   my $self = shift;
   return $self->{replaced}->build if $self->{replaced};
   
   if ($self->{state} ne 'built') {
      if ($self->root()->{macro_definitions}->{$self->tag}) { # This is required because in some cases, the macro definition may have been
                                                              # registered *after* the class was already assigned to the macro instance.
                                                              # E.g.:
                                                              #  define my_macro
                                                              #  ...
                                                              #  my_macro
                                                              # (On the same level with the same parent, my_macro has already been split out.)
         bless $self, 'Decl::Semantics::Macro';
      }
      $self->{force_text} = 0;
      $self->preprocess_line;
      $self->decode_line;
      $self->preprocess;
      $self->parse_body unless $self->{force_text};
      $self->build_payload;
      $self->build_children unless $self->{force_text};
      $self->add_to_parent;
      $self->post_build;

      $self->{state} = 'built';
   }
   return $self->payload;
}

sub preprocess_line {}

sub decode_line {   # Was called parse_line, but there was an unfortunate and brain-bending collision with Text::ParseWords.   Oy.
   my $self = shift;
   my $root = $self->root;
   $root->parse_line ($self);
}

sub preprocess {}

sub parse_body {
   my $self = shift;
   if ($self->tag =~ /^!/) {
      $self->{tag} =~ s/^!//;
   } else {
      my $root = $self->root;
      if (ref $self->body eq 'ARRAY') {
         # If we have an arrayref input, we don't need to parse it!  (2010-12-05)
         #print "parse_body: body is an arrayref\n";
         my $list = $self->{body};
         $self->{body} = '';
         foreach (@$list) {
            $self->load ($_);
         }
      } else {
         my @results = $root->parse ($self, $self->body) if $self->body and not $self->{bracket};
         $self->{body} = '' if @results;
      }
   }
}

sub build_payload {}

sub build_children {
   my $self = shift;
   
   foreach ($self->nodes) {
      $_->build if $_->can('build');
   }
}

sub add_to_parent {}

sub post_build {}

=head1 STRUCTURE ACCESS

=head2 find($locator), findbyname($locator)

Given a node, finds a descendant using a simple XPath-like language.  Once you build a recursive-descent parser facility into your language, this sort
of thing gets a whole lot easier.  The C<find> function looks by tag; the C<findbyname> treats the tag as a type and thus the name as the search
property.

Generation separators are '.', '/', or ':' depending on how you like it.  Offsets by number are in round brackets (), while finding children by name is
done with square brackets [].  Square brackets [name] find tags named "name".  Square brackets [name name2] find name lists (which nodes can have, yes),
and square brackets with an = or =~ can also search for nodes by other values.

You can also pass the results of a parse (the arrayref tree) in as the path; this allows you to build the parse tree using other tools instead of forcing
you to build a string (it also allows a single parse result to be used recursively without having to parse it again).

=cut

sub find {
   my ($self, $path) = @_;
   
   $path = $self->root->parse_using ($path, 'locator') unless ref $path;
   return $self if @$path == 0;

   my $first = shift @$path;
   foreach ($self->nodes) {
      return $_->find($path) if $_->match($first);
   }
   return undef;
}
sub findbyname {
   my ($self, $path) = @_;
   
   $path = $self->root->parse_using ($path, 'locator') unless ref $path;
   return $self if @$path == 0;

   my $first = shift @$path;
   foreach ($self->nodes) {
      return $_->findbyname($path) if $_->matchbyname($first);
   }
   return undef;
}

=head2 match($pathelement), matchbyname($pathelement)

Returns a true value if the node matches the path element specified; otherwise, returns a false value.

=cut

sub match {
   my ($self, $pathelement) = @_;
   return ($self->tag eq $pathelement) unless ref $pathelement;
   my ($tag, $name) = @$pathelement;
   return 1 if $self->tag eq $tag and $self->name eq $name;
   return 0;
}

sub matchbyname {
   my ($self, $pathelement) = @_;
   return ($self->name eq $pathelement) unless ref $pathelement;
   my ($name, $label) = @$pathelement;
   return 1 if $self->name eq $name and $self->label eq $label;
   return 0;
}

=head2 first($nodename)

Given a node, finds a descendant with the given tag anywhere in its descent.  Uses the same path notation as C<find>.

=cut

sub first {
   my ($self, $path) = @_;

   $path = $self->root->parse_using ($path, 'locator') unless ref $path;
   return $self if @$path == 0;

   my ($first, @rest) = @$path;
   foreach ($self->nodes) {
      if ($_->match($first)) {
         my $possible = $_->find(\@rest);
         return $possible if $possible;
      }
      my $child = $_->first($path);
      return $child if $child;
   }
   return undef;
}

=head2 search($nodename)

Given a node, finds all descendants with the given tag.

=cut

sub search {
   my ($self, $path) = @_;
   my @returns = ();
   foreach ($self->nodes) {
      push @returns, $_ if $_->tag eq $path;
      push @returns, $_->search($path);
   }
   @returns
}

=head2 search_data($type)

Given a node, finds all its descendents that match the given type in either name or tag.
If the type ends in a ':', will only return meta nodes.

=cut

sub search_data {
   my ($self, $type) = @_;
   my $flag = '';
   if ($type =~ /:$/) {   # TODO: just : flag?
      $type =~ s/:$//;
      $flag = ':';
   }
   my @returns = ();
   foreach ($self->nodes) {
      if ($_->is($type) || $_->name eq ($type)) {
         push @returns, $_ if not $flag or $_->flag($flag);
      }
      push @returns, $_->search_data($type . $flag);
   }
   @returns;
}

=head2 describe, myline, describe_content

The C<describe> function is used to get our code back out so we can reparse it later if we want to.  It includes the body and any children.
The C<myline> function just does that without the body and children (just the actual line).
The C<describe_content> function does just the body and children (without the actual line).

We could also use this to check the output of the parser, which notoriously just stops on a line if it encounters something it's not
expecting.

=cut

sub myline {
   my ($self) = @_;

   my $description = $self->tag . $self->flag;
   foreach (@{$self->{namelist}}) {
      $description .= " " . $_;
   }
   
   if ($self->parmlist) {
      $description .= " (" .
         join (', ', map {
            $self->parameter($_) eq 'yes' ?
               $_ :
               ($self->parameter($_) =~ / |"/ ?
                   $_ . '="' . escapequote ($self->parameter($_)) . '"' :
                   $_ . '=' . $self->parameter($_))
            } $self->parmlist) .
         ")";
   }

   if ($self->optionlist) {
      $description .= " [" .
         join (', ', map {
            $self->option($_) eq 'yes' ?
               $_ :
               ($self->option($_) =~ / |"/ ?
                   $_ . '="' . escapequote ($self->option($_)) . '"' :
                   $_ . '=' . $self->option($_))
            } $self->optionlist) .
         "]";
   }
   
   $description .= ' "' . $self->label . '"' if $self->label ne '';
   $description .= ' ' . $self->parser . ' <' if $self->parser;
   $description .= ' ' . $self->code if $self->code;
   $description .= ' ' . $self->bracket if $self->bracket;
   $description .= ' ' . $self->comment if $self->comment;
   
   $description;
}   
   
sub describe {
   my ($self, $macro_ok) = @_;
   
   $self->myline . "\n" . $self->describe_content ('   ', $macro_ok);
}
sub describe_content {
   my ($self, $prefix, $macro_ok) = @_;
   my $description = '';
   $prefix = '' unless defined $prefix;
   $macro_ok = 0 unless defined $macro_ok;
   
   if ($self->body) {
      foreach (split /\n/, $self->body) {
         $description .= "$prefix$_\n";
      }
      $description .= "}\n" if $self->bracket;
   } else {
      foreach ($self->elements) {
         if (not ref $_) {
            $description .= $_;
         } elsif ($_->{macroresult} and not $macro_ok) {
            next;
         } else {
            foreach (split /\n/, $_->describe($macro_ok)) {
               $description .= "$prefix$_\n";
            }
         }
      }
   }
   
   $description;
}

=head2 sketch (), sketch_c(), sketch_d()

Returns a thin structure reflecting the nodal structure of the node in question:

   ['tag',
     [['child1', []],
      ['child2', []]]]
      
Like that.  I'm building it for testing purposes, but it might be useful for something else, too.

The C<sketch_c> variant also includes the class of each node, and the C<sketch_d> variant runs the
whole thing through Dumper first.

=cut

sub sketch {
   my ($self) = @_;
   
   [$self->tag, [map { $_->sketch() } $self->nodes()]];
}
sub sketch_c {
   my ($self) = @_;
   
   [$self->tag, ref($self), [map { $_->sketch_c() } $self->nodes()]];
}
sub sketch_d { Dumper ($_[0]->sketch_c); }

=head2 mylocation()

This reports the node's own location in the code tree.

=cut

sub mylocation {
   my $self = shift;
   my $p = $self->parent->mylocation();
   my $l = $self->tag() . '[' . join(' ', $self->names()) . ']';
   return      '/' . $l if $p eq '/';
   return $p . '/' . $l;
}

=head2 go($item)

For callable nodes, this is one way to call them.  The default is to call the go methods of all the children of the node, in sequence.
The last result is returned as our result (this means that the overall tree may have a return value if you set things up right).

=cut

sub go {
   my $self = shift;
   my $callcontext = shift;

   $self = $self->deref;
   return unless defined $self; # TODO: warning
   return unless $self->{callable};
   return &{$self->{sub}}($callcontext, @_) if $self->{owncode} && $self->{sub};

   my $return;
   my $last_iffy;
   my $master_iffy = undef;
   foreach ($self->content_nodes) {
      next unless $_->{callable};
      next if $_->{callable} eq 'sub';
      next if $_->{event};
      if ($_->{callable} eq '?') {
         $last_iffy = $_;
         $master_iffy = $_ if $_->flag('!') and not defined $master_iffy;
      } else {
         $return = $_->go (@_);
         undef $last_iffy;
      }
   }
   return $master_iffy->go(@_) if defined $master_iffy;
   return $last_iffy->go(@_) if defined $last_iffy;
   $return;
}

=head2 closure(...)

For callable nodes, this is the other way to call them; it returns the closure created during initialization.  Note that the
default closure is really boring.

=cut

sub closure { $_[0]->{sub} }


=head2 iterate()

Returns an L<Iterator::Simple> iterator over the body of the node.  If the body is a text body, each call returns a line.  If the body is a bracketed
code body, it is executed to return an iterable object.  Yes, this is neat.

If we're a parser macro, we'll run our special parser over the body instead of the normal parser.

TODO: shouldn't this be recursive for structured nodes?

TODO: might want to do something clever with a code ref tag.  (I.e. if the tag is a reference but also has a code block, perhaps evaluate the code
block to figure out the reference or something.  This might be a plate of beans.)

=cut

sub iterate {
   my $self = shift;
   
   $self = $self->deref;
   return iter([]) unless defined $self;  # TODO: warning
   return iter([]) unless $self->code or $self->nodes or $self->body;
   if ($self->code or $self->bracket) {
      # This is code to be executed, that should return an iterable object.
      my $code;
      if ($self->code) { 
         $code = $self->code;
      } else {
         $code = $self->bracket . "\n";
         $code =~ s/^{//;
         $code .= $self->body;
      }
      my $sub = Decl::Semantics::Code::make_code ($self, $code);
      my $result = &$sub();
      if (ref $result) {
         return iter ($result);
      } else {
         my @lines = split /\n/, $result;
         return iter (\@lines);
      }
   } elsif ($self->nodes) {
      # Iterate over children.
      return ichain map { $_->iterate } $self->nodes;
   } else {
      # This is text to be iterated over.
      my @lines = split /\n/, $self->body;
      return iter (\@lines);
   }
}

=head2 text()

This returns a tokenstream on the node's body permitting a consumer to read a series of words interspersed with formatting commands.
The formatting commands are pretty loose - essentially, "blankline" is the only one.  Punctuation is treated as letters in words; that is, 
only whitespace is elided in the tokenization process.

If the node has been parsed, it probably doesn't have a body any more, so this will return a blank tokenstream.  On the other hand, if the node
is callable, it will be called, and the result will be used as input to the tokenstream - same rules as C<iterate> above.

=cut


=head2 express(), content()

The C<content> function returns the iterated content from iterate(), assembled into lines with as few newlines as possible.
The C<express> function is normally an alias for C<content>.

=cut

sub express {
   my $self = shift;
   $self->content(@_);
}
sub content {
   my ($self, $linebreak) = @_;
   $linebreak = "\n" unless $linebreak;
   
   my $i = $self->iterate;
   my $result = '';
   my $line;
   
   do {
      $line = $i->();
      return $result unless defined $line;
      
      chomp $line;
      $result .= "$line\n";
   } while (defined $line);
   
   return $result;
}
   
   #my $linestart = 1;     TODO: figure out why I thought this should be the default.  Sigh.
   #do {
   #   $line = $i->();
   #   if (defined $line) {
   #      if ($self->parameter('raw')) {
   #         $result .= $line . "\n";
   #      } else {
   #         $line =~ s/\s+$//;
   #         if ($line ne '') {
   #            $result .= ($linestart ? '' : ' ') . $line;
   #            $linestart = 0;
   #         } else {
   #            $result .= $linebreak;
   #            $linestart = 1;
   #         }
   #      }
   #   }
   #} while (defined $line);


our $ACCEPT_EVENTS = 0;

=head2 event_context

If the node is an event context (e.g. a window or frame or dialog), this should return the payload of the node.
Otherwise, it returns the event_context of the parent node.

=cut

sub event_context {
   return $_[0] if $ACCEPT_EVENTS;
   return $_[0]->parent()->event_context() if $_[0]->parent;
   $_[0]->root;
}

=head2 root

Returns the parent - all nodes do this.  The top node at C<Decl> returns itself.

=cut

sub root {$_[0]->parent->root}

=head2 error

Error handling is the part of programming I'm worst at.  But you just have to bite the bullet and address your weaknesses,
so here is an error marker function.  If there's a problem with a node specification, this marks it.  Later we'll do something
sensible with it.  TODO: something sensible.

=cut

sub error {
   my ($self, $error) = @_;
   $self->{errors} = [] unless $self->{errors};
   push @{$self->{errors}}, $error;
   #print STDERR "$error\n";  # TODO: bad long-term...
}

=head2 find_data

The C<find_data> function finds a data node starting at a given point in the tree.  Right now, it's just going to look for nodes
by name/tag, but more mature locators should follow eventually.

=cut

sub find_data {
   my ($self, $data) = @_;
   $data = 'data' unless defined $data;
   foreach ($self->nodes) { return ($_, $_->tag) if $_->name eq $data; }
   foreach ($self->nodes) { return ($_, $_->tag) if $_->is($data); }
   return $self->parent->find_data ($data) if $self->parent;
   return (undef, undef);
}

=head2 find_context (tag, name)

Here, we search for a node with a given name and tag in almost the same way as C<find_data> - first searching our siblings, then our parent's
siblings, and so on.  Used to look for macro definitions, databases, whatever.  If either the tag or the name is omitted, it won't be
used for comparison (thus the first tag of any name or the first named tag of any type will be returned).

Note I said "almost".  Any node that comes after the caller won't be considered context.  (Neither will the caller itself.)  Ditto the parent,
grandparent, etc.  What that means is that context has to appear in the source before the point where C<find_context> is called.

=cut

sub find_context {
   my ($self, $tag, $name) = @_;
   return unless ($self->parent);
   foreach ($self->parent->nodes) {
      last if $_ == $self;
      return ($_) if ((not defined $tag) || $_->is($tag)) and ((not defined $name) || $_->name eq $name);
   }
   $self->parent->find_context($tag, $name);
}


=head2 find_ref (tag, name)

The C<find_ref> function looks for tag-and-name combinations that don't have the "is_reference" flag set.  It returns the first it finds.
If either tag or name is C<undef>, it ignores that spec.

=cut

sub find_ref {
   my ($self, $tag, $name) = @_;
   foreach ($self->nodes) {
      next if $_->{is_reference} or $_->flag('?');
      return $_ if ((not defined $tag) || $_->is($tag)) and ((not defined $name) || $_->name eq $name);
   }
   $self->parent->find_ref ($tag, $name);
}

=head2 deref ()

The C<deref> function uses C<find_ref> to dereference a reference tag.  If the tag you give it isn't a reference, you'll just get that tag back.
If it's a dangling reference, you'll get C<undef>.

=cut

sub deref {
   my ($self) = @_;
   return $self unless $self->{is_reference} or $self->flag('?');
   return $self->parent->find_ref (undef, $self->name) if defined $self->name;
   return $self->parent->find_ref ($self->tag);
}

=head2 set(), get(), get_pair()

These provide a place for object constructors to stash useful information.  The C<get> function gets a parameter if the named user variable
hasn't been set.  It also allows the specification of a default value.

C<get_pair> gets a pair of named values as an arrayref, with a single arrayref default if neither is found.  The individual defaults are assumed
to be 0.

=cut

sub set {
   my ($self, $var, $value) = @_;
   $self->{user}->{$var} = $value;
}
sub get {
   my ($self, $var, $default) = @_;
   return $self->{user}->{$var} if defined $self->{user}->{$var};
   return $self->{parameters}->{$var} if defined $self->{parameters}->{$var};
   return $default if defined $default;
   ''
}
sub get_pair {
   my ($self, $x, $y, $default) = @_;
   
   if ($self->get($x) ne '' || $self->get($y) ne '') {
      return [($self->get($x, 0)), ($self->get($y, 0))];
   }
   return $default;
}

=head1 VALUES

The value system in a Decl node is getting pretty darned complex.  Essentially, though, each node has a value lookup hash that either has scalar values directly
or closures that can be used as proxies for values found in other nodes.  (For example, if a node is a macro instantiation, then mostly we're going to be referring
to values in the definition, not in the instance.  If a node hasn't explicitly defined a value but its parent has, then when we set that value we'll want to set it
in the parent, not in the child.  And so on.)

When we first want to use a given value in a node, we'll call "find_value".  That will return a closure that can be called to get or set the value.  If the value
can't be set, the closure will simply have no effect.  The closure will be stashed locally so that it need only be located once, and we're always assured of being
able to access the same storage location for a given name.

=head2 find_value($var), with helper function get_value_closure

To find a value:

1. Return any previously located closure.
2. If we're a macro instantiation, look at the macro definition.
3. See if there's a local definition for the value; return it if so.
4. See if we have any local constant definitions (our children, evaluated as values).
5. Check our event context.
6. If we're still not in luck, ask our parent to do the same.
7. Otherwise, return "undefined".  A set will then create a local variable if necessary.

The closure returned by get_value_closure has the same signature as the varhandlers used by the value tag.
So weird as it sounds, the key and value are in parameters 2 and 3.

=cut

sub get_value_closure {
   my ($self, $value) = @_;
   return $self->{h}->{$value} if exists $self->{h}->{$value};
   my $v = $self->{hashtie}->just_get($value);
   return $v if ref $v eq 'CODE';
   return sub {
      $self->{hashtie}->just_store($value, $_[3]) if defined $_[3];
      $self->{hashtie}->just_get($value);
   }
}

sub find_value {
   my ($self, $value) = @_;
   
   #print STDERR "find_value! $self\n";
   return $self->{h}->{$value} if exists $self->{h}->{$value};
   #print STDERR "0\n";
   return $self->get_value_closure($value) if exists $self->{v}->{$value};
   #print STDERR "1\n";
   
   my $target = $self;
   $target = $self->{instantiates} if $self->{instantiates}; # TODO: maybe.  Consider a "context" keyword or sigil or something.

   #print STDERR "target is actually $target\n";
   if (exists $target->{h}->{$value}) {
      #print STDERR "There is a target handler\n";
      $self->{h}->{$value} = $target->{h}->{$value};
      return $self->{v}->{$value};
   }
   if (exists $target->{v}->{$value}) {
      #print STDERR "local pointer " . $target->{v}->{$value} . " found\n";
      $self->{hashtie}->just_store($value, $target->get_value_closure($value));
      return $self->{hashtie}->just_get($value);
   }

   foreach my $child ($target->nodes) {
      if ($child->is($value) or $child->name eq $value) {
         if ($child->label) {
            #print STDERR "local child " . $child->describe . " found\n";
            $self->{hashtie}->just_store ($value, sub { $child->label });
            return $self->{hashtie}->just_get ($value);
         }
         if ($child->describe_content) {
            #print STDERR "local child " . $child->describe . " found\n";
            $self->{hashtie}->just_store ($value, sub { $child->describe_content });
            return $self->{hashtie}->just_get ($value);
         }
         last;
      }
   }

   unless ($target->event_context == $target) {
      #print STDERR "We have an event context\n";
      my $cx = $target->event_context;
      if (exists $cx->{h}->{$value}) {
         #print STDERR "There is a target handler in the cx\n";
         $self->{h}->{$value} = $cx->{h}->{$value};
         return $self->{h}->{$value};
      }
      #print STDERR "Looking in event context $cx\n";
      my $context_value = $cx->find_value($value);
      #print STDERR "3\n";
      if (defined $context_value) {
         #print STDERR "context value $context_value found\n";
         $self->{hashtie}->just_store ($value, $context_value);
         return $context_value;
      }
      #print STDERR "Was not defined in event context $cx\n";
   }

   #print STDERR "Looking in parent\n";
   return $self->parent->find_value($value) if $self->parent;
   #print STDERR "Returning undef\n";
   return undef;
}


=head2 value($var), setvalue($var, $value)

Accesses the global application value named.

=cut

sub value { $_[0]->{v}->{$_[1]} }
#sub setvalue { $_[0]->{v}->{$_[1]} = $_[2]; }
sub setvalue {
   my ($self, $value, $newvalue) = @_;
   return if $value =~ /^\*/;  # Set has no effect on *-values.
   my $var = $self->find_value($value);
   return $var->($self, $self->{v}, $value, $newvalue) if defined $var;
   $self->{hashtie}->just_store($value, $newvalue);
}

=head2 get_value($var)

Given the name of a value, we can find it in various places, which we look at in order:

- A set value in the node asked
- Rinse and repeat for the node's parent.

Names starting with an asterisk find parts of the node itself: *name, *label, *parameter <n>,
*option <n>, *content, and anything else I forgot and add later.  A double asterisk gets the same values
from the parent.  Triple asterisk, grandparent, etc.

=cut

sub get_value {
   my ($self, $value) = @_;
   
   if ($value =~ /^\*/) {
      $value =~ s/^\* *//;
      return $self->parent->get_value ($value) if $value =~ /^\*/;
      return $self->name                    if $value eq 'name';
      return $self->label                   if $value eq 'label';
      return $self->describe_content('', 0) if $value eq 'content';
      return undef;
   }
   
   my $var = $self->find_value($value);
   return if not defined $var;
   $var->($self, $self->{v}, $value);
}

=head2 express_value($valuespec)

A full value spec pipes a given value through a series of filters:

   <value>[|<filter>]*
   
A filter is simply a function that takes one parameter.  (This is an oversimplification: the filter can be given parameters that are space-delimited.)

If no lookup value is desired as a starting value, you can also just start the pipe with a filter/function call. marked with an exclamation mark:

  !<filter>[|<filter>]*
  
Clear?  Clear.

=cut

sub express_value {
   my ($self, $valspec) = @_;
   my @pieces = split /\|/, $valspec; # TODO: a real parser to permit pipe characters within strings.
   my $value = '';
   if ($pieces[0] =~ /^!/) {
      $pieces[0] =~ s/^! *//;
   } else {
      $value = $self->get_value(shift @pieces);
   }
   while (my $filter = shift @pieces) {
      $filter =~ s/^\s*//;
      $filter =~ s/\s*$//;
      my @words = parse_line ('\s+', 0, $filter);
      my $filter = shift @words;
      $value = $self->call_filter($filter, $value, @words);
   }
   $value;
}
   

=head2 register_varhandler ($event, $handler)

Registers a variable handler in the event context.  If there is a handler registered for a name, it will be called instead of the normal
hash read and write.  This means you can attach active content to a variable, then treat it just like any other variable in your code.

=cut

sub register_varhandler {
   my ($self, $key, $handler) = @_;
   $self->{h}->{$key} = $handler;
}


=head2 subs()

Returns all our direct children named 'sub', plus the same thing from our parent.  Our answers mask our parent's.

=cut

sub subs {
   my $self = shift;
   my $subs = $self->parent ? $self->parent()->subs() : {};
   foreach ($self->nodes()) {
      next unless $_->tag() eq 'sub';
      $_->build();
      $subs->{$_->name} = $_;
   }
   return $subs;
}

=head2 find_filter(filter), call_filter(filter, value)

Finds a filter by name from a given point in the tree and calls it with a set of parameters.

=cut

sub find_filter {
   my ($self, $filter) = @_;
   
   $self = $self->{instantiates} if $self->{instantiates}; # TODO: I think this is probably correct.
   foreach ($self->nodes()) {
      return $_ if $_->is("sub|filter") and $_->name eq $filter;
   }
   return $self->parent->find_filter($filter) if $self->parent;
   $filter = Decl->register_filter($filter);
   return $filter;
}

sub call_filter {
   my $self = shift;
   my $filter = shift;
   my $value = shift;
   
   $filter = $self->find_filter($filter);
   if (not defined $filter) {
      # TODO: warning
      return $value;
   }
   if (ref $filter eq 'CODE') {
      return &$filter ($value, @_);
   }
   $filter->go(undef, $value, @_);
}

#=head2 AUTOLOAD
#
#If a call is made against a node with a payload, the node will try to proxy the payload object's methods using AUTOLOAD.
#
#TODO: some kind of dot notation to permit this to work with inner nodes.
#
#=cut
#
#sub AUTOLOAD {
#    my ($self) = @_;
#    croak "No method $AUTOLOAD" unless $self->payload and ref($self->payload);
#    
#    my $name = our $AUTOLOAD;
#    $name =~ s/.*://;
#    return "No method $AUTOLOAD" unless $self->payload->can($name);
#    
#    *$AUTOLOAD = eval "sub { my \$self = shift; \$self->payload->$name (\@_) }";
#    goto &$AUTOLOAD;
#}


=head1 OUTPUT

=head2 write(), log(), output()

The C<write> function is supported for any node; by default it simply passes its arguments up to its parent.  The top of the tree will print everything
to STDOUT - by default.  At any point in the tree, though, a node may claim ownership of the output stream by having an option [output]; any C<write>
called below that node's parent will be written to that node's C<write>.  Obviously, this is a good way to use files.

The C<log> function is exactly the same, except the default is to write to STDERR and the option to use is [log].

There is another difference: a file used as [output] will by default start from scratch ('w'), while a file used as [log] will append its material ('a').
Either is opened during build, and closed when the program closes.

If it's not in [output] or [log] mode, however, each call to C<write> on a file is independent; the file is closed afterwards and no handle is kept around.
This can be overridden with a (keepopen) parameter or a (>>) parameter for appending.  (Any appending file will be opened for appending during build and
closed when the program closes.)

If a file is in keepopen mode, the buffers are flushed after each C<write>/C<log>.

The C<output> function defaults to C<write>.  For a macro definition, though, it is used to build the macro to be instantiated.

=cut

sub output {
   my $self = shift;
   $self->write(@_);
}

sub write {
   my $self = shift;
   $self->parent->write(@_);
}
sub log {
   my $self = shift;
   $self->parent->log(@_);
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Node
