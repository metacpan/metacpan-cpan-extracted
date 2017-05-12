package Decl;

use warnings;
use strict;
use base qw(Decl::EventContext Decl::Node);
use Filter::Util::Call;
#use Parse::Indented;
#use Parse::RecDescent::Simple;
use Decl::Parser;
use Decl::Util;
use Decl::DefaultParsers;
use Decl::StandardFilters;
use Decl::NodalValuator;
use File::Spec;
use Data::Dumper;
use Scalar::Util qw(blessed);
use Carp;

=head1 NAME

Decl - Provides a declarative framework for Perl

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

$SIG{__WARN__} = sub {
   return if $_[0] =~ /Deep recursion.*Parser/;  # TODO: Jezus, Maria es minden szentek.
   #require Carp; Carp::cluck
   warn $_[0];
};


=head1 SYNOPSIS

This module is a framework for writing Perl code in a declarative manner.  What that means right now is that instead of seeing a script as a
series of actions to be carried out, you can view the script as a set of objects to be instantiated, then invoked.  The syntax for building
these objects is intended to be concise and flexible, mostly staying out of your way.  Perl code is used to declare actions to be taken once
the structure is built, as well as any actions to be taken interactively as the script runs.

The original motivation for designing this framework was to provide a more rational way of defining a L<Wx> user interface.  As it is, the
data structures making up a Wx GUI are built with painstakingly detailed (and boring) imperative code.  There are XML-based GUI specification
frameworks, but I wanted to write my own that wasn't XML-based because I hate typing XML even more than I hate writing setup code.

Back when I did a lot of GUI work, I'd usually write some pseudocode to describe parts of the UI, then translate it into code by hand.
So this year, while noodling around about some tools I'd find useful in my translation business, I thought, well,
why not just write a class to interpret that pseudocode description directly?

Once I started getting into that in earnest, I realized that the Wx-specific functionality could be spun out into an application-specific
(in my new parlance, a "semantic") domain, leaving a core set of functionality that was a general declarative framework.  I then realized that
the same framework could easily be used to work with domains other than Wx GUIs, such as building PDFs, building Flash applications, doing
things with Word documents... All kinds of things.  All of those things are currently in pieces on the workbench - except for the Word
module, which is ready, if not for prime time, then at least for deep cable midnight airing.

Here's a GUI example using something like the Wx domain. This is a pretty simple example, but it gives you a taste of what I'm talking about.
Since Decl runs as a source filter, the example below is a working Perl script that replaces roughly 80 lines of the Wx
example code it was adapted from.  And yes, it runs in my test suite right now.

   use Wx::Declarative;
   
   dialog (xsize=250, ysize=110) "Wx::Declarative dialog sample"
      field celsius (size=100, x=20, y=20) "0"
      button celsius (x=130, y=20) "Celsius" { $^fahrenheit = ($^celsius / 100.0) * 180 + 32; }
      field fahrenheit (size=100, x=20, y=50) "32"
      button fahrenheit (x=130, y=50) "Fahrenheit" { $^celsius = (($^fahrenheit - 32) / 180.0) * 100; }

The main things to look at are as follows: first, yes - syntactically significant indentation.  I know it's suspiciously Pythonic, I know all
the arguments citing the danger of getting things to line up, and I don't care; this is the way I have always written my pseudocode, and
odds are you're no different and you know it.  If it makes you feel better, the indentation detection algorithm is pretty flexible, and Perl
code within curly braces is exempt from indentation significance.  (Not that this example has any multiline code, but you see what I mean.)

Second, fields are declared here and their content is exposed as magic variables in the code snippets.  You will immediately see that code
embedded in a declarative structure goes through a modification pass before being C<eval>'d into a sub.  So there is a possibility that I
have screwed that modification pass up.  I don't have an answer for this right now; the point is quick and easy, not perfection (yet).
Caveat emptor.  It's still a neat feature.

There is a standard parser and standard data structure available for tags to use if it suits your purpose - but there's no mandate to use them,
and the parser tools are open for use.  They're still a little raw, but pretty powerful.

A declarative object can report its own source code, and that source code can compile into an equivalent declarative object.  This means that dynamically
constructed objects or applications can be written out as executable code, and code has introspective capability while in the loaded state.  C<Decl>
also has a macro system that allows the construction of code during the build phase; a macro always dumps as its source, not the result of the expansion, so
you can capture dynamic behavior that runs dynamically every time.

=head1 TUTORIAL

For more information about how to use C<Decl>, you'll probably want to see the tutorial in L<Decl::Semantics>
instead of this file; the rest of this presentation is devoted to the internal workings of C<Decl>.
(Old literate programming habits, I guess.)
Honestly, you can probably just stop here, because if you're not reading the source along with the POD it probably won't make any sense anyway.
Go read the tutorial.  Not that I've finished it.

=head1 SETTING UP THE CLASS STRUCTURE

=head2 import, yes_i_am_declarative, import_one

The C<import> function is called when the package is imported.  It's used for the filter support; don't call it.

If semantic classes are supplied in the C<use> command, we're going to instantiate and scan them here.  They'll be used to decorate the
parse tree appropriately.

=cut

our %build_handlers = ();
our %build_flags = ();
our @semantic_classes = ();

sub yes_i_am_declarative { 1 }  # This is probably a childish way of doing this.
our $initial_load;
sub import
{
   my($type, @arguments) = @_;
   
   if (not defined $initial_load) {
      $initial_load = 1;
   
      if (!@arguments || $arguments[0] ne '-nofilter') {
         filter_add(bless { start => 1 });
      } else {
         shift @arguments if @arguments;
      }
      push @arguments, "Decl::Semantics" unless grep { $_ eq "Decl::Semantics" } @arguments;
   }

   use lib "./lib"; # This allows us to test semantic modules without disturbing their production variants that are installed.
   foreach my $import_module (@arguments) {
      import_one($import_module);
   }
}
sub import_one {
   my ($import_module) = @_;

   #print "importing $import_module\n";
   unless (grep { defined $_ and $import_module eq $_ } @semantic_classes) { # Only try to import each semantic class once.
      eval "use $import_module;";
      if ($@) {
         warn $@;
      } else {
         push @semantic_classes, $import_module;
         eval 'foreach (' . $import_module . '->decl_include()) { import_one $_ }';
      }
   }
}

=head2 class_builders(), find_tagdef($parent, $tag), build_handler ($parent, $tag), register_builder ($node)

Given a tag name, C<class_build_handler> returns a hashref of information about how the tag expects to be treated:

* The class its objects should be blessed into, as a coderef to generate the object ('Decl::Node' is the default)
* Its line parser, by name ('default-line' is the default)
* Its body parser, by name ('default-body' is the default)
* A second-level hashref of hashrefs providing overriding semantics for descendants of this tag.

If you also provide a hashref, it is assigned to the tag name.

The C<app_build_handler> does the same thing, but specific to the given application - this allows dynamic tag definition.

Finally, C<build_handler> is a read-only lookup for a tag in the context of its ancestry that climbs the tree to find the contextual
semantics for the tag.

=cut

our $class_builders;  # Note: this is initalized below, after the default parsers are set up.

sub class_builders { $class_builders; }

sub find_tagdef {
   my ($self, $parent, $tag) = @_;
   
   my $apptag = $self->{build_handlers} ? $self->{build_handlers}->nodes($tag) : undef;
   my $classtag = $class_builders->nodes($tag);
   
   my $apptagd = defined $apptag ? $apptag->nodes($parent->{domain}) : undef;
   my $classtagd = defined $classtag ? $classtag->nodes($parent->{domain}) : undef;

   my $tagdef = $apptagd || $classtagd;
   
   $tagdef = $apptag->nodes if not defined $tagdef and defined $apptag;
   $tagdef = $classtag->nodes if not defined $tagdef and defined $classtag;  #TODO: man, this really doesn't seem right.
 
   return $tagdef;
}

sub build_handler {
   my ($self, $parent, $tag) = @_;

   if (defined $parent->{parsemode} and $parent->{parsemode} eq 'vanilla') {
      return (defined $parent->{vanilla_class} ? $parent->{vanilla_class} : 'Decl::Node', undef, 'vanilla');
   }
   
   my $flag;
   ($tag, $flag) = Decl::Node::splittag ($tag);
   
   my $tagdef = $self->find_tagdef($parent, $tag);
   return ($tagdef->label, $tagdef->tag, $tagdef->parameter('body'), $tagdef->parameter('line'), $tagdef->parameter('vanilla')) if defined $tagdef;

   my $vanilla_class = 'Decl::Node';

   return ($vanilla_class, undef, 'vanilla') unless blessed($parent);
   my $ancestry = $parent->ancestry();
   foreach (@$ancestry) {
      my $t = $self->find_tagdef($parent, $_);
      if (defined $t and $t->parameter('vanilla')) {
         $vanilla_class = $t->parameter('vanilla');
         last;
      }
   }
   return ($vanilla_class, undef, 'vanilla', undef, $vanilla_class);
}

sub register_builder {
   my ($self, $class, $domain, $tags) = @_;
   my $bh_list = ref($self) ? $self->{build_handlers} : $class_builders;
   foreach my $tag_to_add ($tags->nodes()) {
      my $tag = $bh_list->first($tag_to_add->tag) || $bh_list->load($tag_to_add->tag);
      my $domain_tag = $tag->nodes($domain);
      if (not defined $domain_tag) {
         $domain_tag = $tag->load($domain);
      }
      my $within = $tags->nodes('within');
      if ($within) {
         my $target_within = $domain_tag->load($within->myline());
         $domain_tag = $target_within;
      }
      $domain_tag->set_label($class);
      $domain_tag->{parmlist} = \@{$tag_to_add->{parmlist}};      # TODO: maybe a real Node copier at some point?  This is hardly going to be the first transformation
      $domain_tag->{parameters} = \%{$tag_to_add->{parameters}};  #       where this is going to be needed...
      foreach ($tag_to_add->nodes()) {
         next if $_->is('within');
         $domain_tag->load ($_->describe());
      }
   }
   #print STDERR $self->{build_handlers}->describe() if ref($self);
}

=head2 makenode($ancestry, $code)

Finds the right build handler for the tag in question, then builds the right class of node with the code given.

=cut

sub makenode {
   my ($self, $parent, $tag, $body) = @_;

   my ($build_class, $domain, $parsemode, $linemode, $vanilla_class) = $self->build_handler($parent, $tag);
   my $newnode = $build_class->new($body);
   if ($vanilla_class) {
      $newnode->{parsemode} = 'vanilla';
      $newnode->{vanilla_class} = $vanilla_class;
   } else {
      $newnode->{parsemode} = $parsemode;
   }
   if ($newnode->flag('.')) {
      $newnode->{parsemode} = 'text';
   } elsif ($newnode->flag('*')) {
      $newnode->{parsemode} = 'vanilla';
   } elsif ($newnode->flag('+')) {
      $newnode->{parsemode} = '';
   }
   $newnode->{domain} = $domain;
   $newnode;
}

=head2 remakenode($node)

If it turns out that things have changed semantically since we split a node out, and the node hasn't been built yet
(this is specifically to support the "use" tag), then we can signal that the node should be remade, and we'll build
and substitute a new node based on the new semantic environment and using the information available to us in the
initially created node.

=cut

sub remakenode {
   my ($self, $node) = @_;
   
   my $bh = $self->build_handler($self->parent, $self->tag);  #$node->ancestry);
   my $replacement = $bh->{node}->([$node->tag . $node->flag . " " . $node->line, $node->body]);
   $replacement->{parent} = $node->parent;
   return $replacement;
}


=head1 FILTERING SOURCE CODE

By default, C<Decl> runs as a filter.  That means it intercepts code coming in and can change it before Perl starts parsing.  Needless to say,
filters act very cautiously, because the only thing that can parse Perl correctly is Perl (and sometimes even Perl has doubts).  So this filter basically just
wraps the entire input source in a call to C<new>, which is then parsed and called after the filter returns.

=head2 filter

The C<filter> function is called by the source code filtering process.  You probably don't want to call it.  But if you've ever wondered
how difficult it is to write a source code filter, read it.  Hint: I<it really isn't difficult>.

=cut

sub filter
{
   my $self = shift;
   my $status;

   if (($status = filter_read()) > 0) {
      if ($$self{start}) {
         $$self{start} = 0;
         $_ = "my \$root = " . __PACKAGE__ . "->new();\n\$root->load(<<'DeclarativeEOF');\n$_";
      }
   } elsif (!$$self{start}) { # Called on EOF if we ever saw any code.
      $_ = "\nDeclarativeEOF\n\n\$root->start();\n\n";
      $$self{start} = 1;    # Otherwise we'll repeat the EOF forever.
      $status = 1;
   }

   $status;
}


=head1 PARSERS

The parsing process in C<Decl> is recursive.  The basic form is a tagged line followed by indented text, followed by another tagged line
with indented text, and so on.  Alternatively, the indented part can be surrounded by brackets.

   tag [rest of line]
      indented text
      indented text
      indented text
   tag [rest of line] {
      bracketed text
      bracketed text
   }
   
By default, each tag parses its indented text in the same way, and it's turtles all the way down.  Bracketed text, however, is normally I<not> parsed as 
declarative (or "nodal") structure, but is left untouched for special handling, typically being parsed by Perl and wrapped as a closure.

To force content to be handled as text instead of nodal structure, put a period on the end of the tag.  Some tags are defined with this as the default;
for these you can force normal nodal structure with a '!', or data-only nodal structure with a '*'.

However, all this is merely the default.  Any tag may also specify a different parser for its own indented text, or may carry out some transformation on the
text before invoking the parser.  It's up to the tag.  The C<data> tag, for instance, treats each indented line as a row in a table.

Once the body is handled, the "rest of line" is also parsed into data useful for the node.  Again, there is a default parser, which takes a line of the
following form:

   tag name (parameter, parameter=value) [option, option=value] "label or other string text" parser < { bracketed text }
   
Any element of that line may be omitted, except for the tag.

=head2 init_parsers()

Sets up the registry and builds our default line and body parsers.

=cut

sub init_parsers {
   my ($self) = @_;
   $self->{parsers} = {};
   
   #$self->{parsers}->{"default-line"} = $self->init_default_line_parser();
   #$self->{parsers}->{"default-body"} = $self->init_default_body_parser();
   #$self->{parsers}->{"locator"} = $self->init_locator_parser();
}

our %default_parsers = ();
$default_parsers{'default-line'} = Decl::DefaultParsers::init_default_line_parser(undef);
$default_parsers{'default-body'} = Decl::DefaultParsers::init_default_body_parser(undef);
$default_parsers{'locator'}      = Decl::DefaultParsers::init_locator_parser(undef);


$class_builders = Decl->new_data_with_label('*cbh');  # Have to initialize this after the default parsers are defined...

=head2 parser($name)

Retrieves a parser from the registry.

=cut

sub parser {
   my ($self, $parsername) = @_;
   my $possible = $self->{parsers}->{$parsername};
   return $possible if $possible;
   $default_parsers{$parsername};
}

=head2 parse_line ($node)

Given a node, finds the line parser for it, and runs it on the node's line.

=cut

sub parse_line {
   my ($self, $node, $line) = @_;
   
   my ($class, $domain, $bodyp, $linep) = $self->build_handler($node->parent, $node->tag);
   return if defined $linep and $linep eq 'none';
   my $p = $self->parser($linep || 'default-line');
   $p->execute($node, $line);    # TODO: error handler for incorrect parser specification.
}

=head2 parse($node, $body)

Given a node and body text for it, finds the body parser appropriate to the node's tag and runs it on the node and the body text specified.

=cut

sub parse {
   my ($self, $node, $body) = @_;
   
   return if $node->{parsemode} eq 'text';
   
   my ($class, $domain, $bodyp, $linep) = $self->build_handler($node->parent, $node->tag);
   $bodyp = 'default-body' if $bodyp eq 'text' and $node->{parsemode} eq 'vanilla';
   $bodyp = 'default-body' if $bodyp eq 'vanilla';
   my $p = $self->parser($bodyp || 'default-body');
   $p->execute($self, $node, $body);
}

=head2 parse_using($string, $parser)

Given a string and the name of a parser, calls the parser on the string and returns the result.

=cut

sub parse_using {
   my ($self, $string, $parser) = @_;
   my $p = $self->parser($parser);
   return undef unless $p;
   return $p->execute($string);
}

=head1 TEMPLATE ENGINE

The macro system in Decl uses a template engine implemented in Decl::Template.  However, the plain vanilla "valuator" (the
function used by a given template engine instance to find values for fields with particular names/specs) is replaced in the
Decl node environment by a much more powerful valuator.  That valuator is implemented in Decl::NodalValuator.

We instantiate a template engine with a nodal valuator for use by the macro system here.

=cut

our $template_engine = Decl::NodalValuator::instantiate();

=head1 BUILDING AND MANAGING THE APPLICATION

You'd think this would be up at the top, but we had to do a lot of work just to be ready to instantiate a C<Decl> object.

=head2 new, new_data, new_data_with_label

The C<new> function is of course called to create a new C<Decl> object.  If you pass it some code, it will load that code
immediately.

The C<new_data> is used if you don't want anything to have any semantics or action.  It's used for some internal data structures.
"Describe" works the same way, not specifying the root tag.  This may not be what you want.

Finally C<new_data_with_label> allows you to provide a different *-tag for the data; this could be useful for debugging.  Or I might
get rid of it.  I don't know yet.  It's only used internally in this module anyway.

=cut

sub new {
   my $class = shift;
   my $self = $class->SUPER::new('*root');
   $self->{id_list} = {};
   $self->{next_id} = 1;
   $self->{root} = $self;
   
   $self->init_parsers;
   
   $self->{build_handlers} = Decl->new_data_with_label("*bh");
   
   $self->{semantics} = {};
   $self->{semtags} = {};
   $self->{controller} = '';
   
   foreach (@semantic_classes) { $self->initiate_semantic_class($_); }
   
   #print STDERR $class_builders->describe; die;

   $self->event_context_init;
   
   if (defined $_[0]) {
      $self->load($_[0]);
   }
   return $self;
}

sub new_data_with_label {
   my $class = shift;
   my $label = shift;
   my $self = $class->new_data(@_);
   $self->{tag} = $label;
   return $self;
}

sub new_data {
   my $class = shift;
   my $self = $class->SUPER::new('*data');
   $self->{id_list} = {};
   $self->{next_id} = 1;
   $self->{root} = $self;
   
   $self->{semantics} = {};
   $self->{semtags} = {};
   $self->{controller} = '';
   if (defined $_[0]) {
      $self->load($_[0]);
   }
   $self->{parsemode} = 'vanilla';
   return $self;
}

=head2 initiate_semantic_class

Does what it says on the tin.

=cut

sub initiate_semantic_class {
   my ($self, $class) = @_;
   return unless defined $class;
   return if defined $self->{semtags}->{$class};
   my $s = $class->new($self);
   $self->{semtags}->{$class} = $s->tag;
   $self->{controller} = $s->tag unless $self->{controller};
   $self->{semantics}->{$s->tag} = $s;
}

=head2 semantic_handler ($tag)

Returns the instance of a semantic module, such as 'core' or 'wx'.

=cut

sub semantic_handler { $_[0]->{semantics}->{$_[1]} }


=head2 start

This is called from outside to kick off the process defined in this application.  The way we handle this is just to ask the first semantic class to start
itself.  The idea there being that it's probably going to be Wx or something that provides the interface.  (It could also be a Web server or something.)

The core semantics just execute all the top-level items that are flagged callable.

=cut

sub start {
   my ($self, $tag) = @_;

   $self->{callable} = 1;
   $self->go();   
   #$tag = $self->{controller} unless $tag;
   #$self->{semantics}->{$tag}->start;
}


=head2 id($idstring)

Wx works with numeric IDs for events, and I presume the other event-based systems do, too.  I don't like numbers; they're hard to read and tell apart.
So C<Decl> registers event names for you, assigning application-wide unique numeric IDs you can use in your payload objects.

=cut

sub id {
   my ($self, $str) = @_;
   
   if (not defined $str or not $str) {
      my $retval = $self->{next_id} ++;
      return $retval;
   }
   if (not defined $self->{id_list}->{$str}) {
      $self->{id_list}->{$str} = $self->{next_id} ++;
   }
   return $self->{id_list}->{$str};
}


=head2 root()

Returns $self; for nodes, returns the parent.  The upshot is that by calling C<root> we can get the root of the tree, fast.

=cut

sub root { $_[0] }

=head2 mylocation()

Special case: returns a slash.  (It's the root.)

=cut

sub mylocation { '/'; }

=head2 describe([$use])

Returns a reconstructed set of source code used to compile this present C<Decl> object.  If it was assembled
in parts, you still get the whole thing back.  Macro results are not included in this dump (they're presumed to be the result
of macros in the tree itself, so they should be regenerated the next time anyway).

If you specify a true value for $use, the dump will include a "use" statement at the start in order to make the result an
executable Perl script.
The dump is always in filter format (if you built it with -nofilter) and contains C<Decl>'s best guess of the
semantic modules used.  If you're using a "use lib" to affect your %INC, the result won't work right unless you modify it,
but if it's all standard modules, the dump result, after loading, should work the same as the original entry.

=cut

sub describe {
   my ($self, $macro_ok, $use) = @_;

   $macro_ok = 0 unless defined $macro_ok;
   
   my $description = '';
   $description = "use Decl qw(" . join (", ", @semantic_classes) . ");\n\n" if $use;
   
   foreach ($self->elements) {
      if (not ref $_) {
         $description .= $_;
      } elsif ($_->{macroresult} and not $macro_ok) {
         next;
      } else {
         $description .= $_->describe($macro_ok);
      }
   }
   
   return $description;
}

=head2 find_data

The C<find_data> function finds a top-level data node.

=cut

sub find_data {
   my ($self, $data) = @_;
   foreach ($self->nodes) { return ($_, $_->tag) if $_->name eq $data; }
   foreach ($self->nodes) { return ($_, $_->tag) if $_->is($data); }
   return (undef, undef);
}


=head2 write, log

Normal nodes send these to their parents if not otherwise set for the node; at the top level, unless otherwise set, we print to STDOUT or STDERR.

=cut

sub write {
   my $self = shift;
   print STDOUT @_;
}
sub log {
   my $self = shift;
   print STDERR @_;
}

=head1 FILTER REGISTRY

A C<filter> in Decl is just a function that takes one string and returns another.  (TODO: something iterator- and stream-aware, I suppose.)
It's used for text blocks.  A filter call can take additional parameters as well, but doesn't have to.

Filters are called using C<call_filter> on any given node; a search is made for the appropriate filter and it's invoked, if found.  If it's not found,
then a globally registered filter is called (this permits libraries to contain filters).  This filter registry is where that is managed.

=head2 register_filter ($name, $coderef, $origin)

During load, a module can register a filter with C<register_filter>.  (It can happen any other time, too, of course.)  To find a registered filter,
you can call register_filter without a code reference, and if there is such a filter registered under the name, it will be returned.

The C<$origin> parameter is something you can use for debugging.

  Decl->register_filter('myfilter', sub { ... }, 'where I defined this');

=cut

our %registered_filters = ();
our %registered_filter_origins = ();
sub register_filter {
   my ($class, $name, $coderef, $origin) = @_;
   if (defined $coderef) {
      $registered_filters{$name} = $coderef;
      $registered_filter_origins{$name} = $origin;
   }
   wantarray ? ($registered_filters{$name}, $registered_filter_origins{$name}) : $registered_filters{$name};
}
Decl::DefaultFilters->init_default_filters();

=head2 registered_filters()

Returns a sorted list of all global filter names.

=cut

sub registered_filters { sort keys %registered_filters }

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Decl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Decl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Decl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Decl>

=item * Search CPAN

L<http://search.cpan.org/dist/Decl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Decl
