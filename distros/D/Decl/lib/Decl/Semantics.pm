package Decl::Semantics;

use warnings;
use strict;

use Data::Dumper;
use File::Spec;
#use Decl;  This use is actually done via eval down below, but preserved here for documentation.

=head1 NAME

Decl::Semantics - provides the framework for a set of semantic classes in a declarative framework.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Everything in C<Decl> is declared using tags, and some of those tags are standard with the distribution.
A set of tags is called a "semantic domain", and the standard set is called the "core semantics".  The core semantics
contain a I<lot> of stuff you might not consider core, like database functionality, but the basic rule is that if I
use something a lot, and I want specific support for it in the core code, it kind of needs to be in the core semantics.

This particular module (C<Decl::Semantics>) is a kind of template for other semantic domains, but it really
doesn't do a lot except define how standard domains scan for their own tag definitions.  Other semantic domains define
useful utility code that can be used by tags and code working with them, but since the core domain is the language itself,
there's nothing additional it needs to do.

So this is where I'm putting the tutorial, because to be absolutely honest, I can't get .pod files to link right on CPAN.
Once you start reading, you'll see that this is clearly a work in progress.  If you have questions or suggestions, drop
me a line at the email at the end of this file.

=head1 HOW TO USE DECL

=head2 How to call a Decl program

Before we get down to brass tacks of what a Decl program looks like, you'll probably want to know how to set one up
in the first place.  As usual with Perl, there's more than one right way to do it.

The simplest is to invoke Decl as a source filter in a normal Perl program:

   use Decl;
   
   value count "0"
   sub increment {
      $^count ++;
   }
   do {
      increment();
      print "$^count\n";
   }

(Ignore the blatant weirdness in that code for the moment; this is just a taste.)

If you need more control over the Perl, you can invoke Decl without the source filter.

   use Decl qw(-nofilter);
   
   $tree = Decl->new(<<EOF);
    ! value count "0"
    ! sub increment {
    !  ...
   EOF
   
   $tree->start();
   
The initial bangs aren't required, of course; they just make it easier to see where the declarative code is.

If you don't want to mess with significant indentation, you can do the whole thing with arrayrefs: (TODO: test this with coderefs)

   use Decl qw(-nofilter);
   
   $tree = Decl->new([['value count "0"'], [sub increment {...}]]);
   $tree->start();
   
If you're using one or more semantic domains, the same things apply (see L<Win32::Word::Declarative> for examples of invocation).

On Windows, you can define .dpl (say) as a declarative Perl extension, and then you don't even need to use Decl.
(I do that myself; eventually I should build it into the installation.)

=head2 The structure of a Decl program

Declarative Perl is built of nodes.  Each node consists of a first line and an optional body; the body is either bracketed, in which
case it's executable code (Perl), or not bracketed, in which case it must be indented and the node will decide what to do with it.  By
default, the body will itself consist of a series of nodes.

The first line consists of a tag, zero or more names, parameters in parentheses, options in square brackets, a label in quotes, and an
optional parser label to define what to do with the code block, if any, but right now the parser is ignored.  (Eventually I'll put in
L<Inline> and you'll be able to go crazy defining code in any language you like, which will actually be pretty darned cool.)

The code in a bracketed body has no significant indentation; it's just Perl (or whatever, eventually - meaning that if it's Python it
I<will> have significant indentation, but that sort of clouds the issue, so pretend you didn't just read it).

=head2 Order of execution

The overall execution of a Decl program has two phases, the build phase and the run phase.  During the build phase, tags are parsed
in a depth-first order and their active structure, if any, is built at the same time.  (For instance, a database connection is created
as soon as the database tag is parsed.)  Once everything is built, the run phase starts, consisting of the top-level node trying to
run each of its children in order (and each node its own children, again depth-first), with one caveat.  Some tags are declarative only,
and so do not run.  Some tags are code, and so always run.  And some tags are ambivalent.  It's the ambivalent ones that have the caveat:
if an ambivalent tag is the I<last tag> in its enclosing node (or the program as a whole), it will run; otherwise, it will consider itself
declarative and it won't run.

This is to permit a default behavior that makes sense if no explicit code is included, while still providing an easy way to override it.
The prime example is L<Win32::Word::Declarative> - if the Word document stands alone in its program, it will "run" by writing the file it
defines or by executing the actions defined within it.  But if there is code I<below> it, that code is considered to be the definitive action
of the program, so the Word file structure will simply be taken as descriptive.

Code that appears I<above> such a tag is assumed to be setup code that prepares whatever the native action of the ambivalent tag in question
will be, perhaps doing a calculation whose result will appear in the text of the Word file defined.

=head2 Embedding Perl

Every Decl program is, of course, a Perl program.  It's just more succinct.  But at nearly every point along
the way, it's possible to drop down into Perl and do things by hand if the Decl framework doesn't give you enough functionality.
And of course, any but the most trivial things will require this.

The thing to remember is that the 'do' tag always defines a callable action.  The 'sub' tag defines a subroutine for later use, just like you'd
think.  The 'on' tag defines an I<event>, which is essentially a simple command in the enclosing event context.  It's most commonly used for
user interface programming, so if you're doing, say, reporting, you might never even see an event.

=head2 The event context in embedded Perl

Every piece of Perl code in a Decl program runs in a "context" consisting of its parent object or some ancestor of the parent.
Tags know whether they're event contexts or not, and so if you ask a given tag for its context, it will respond either with a pointer
to itself, or to a pointer to its parent's event context.

The reason I started calling this an event context is because I was using it to model the parts of a Wx GUI program that handle events;
a button on a form has an event associated with it, but the event runs in the context of the form, so the form is the event context.
But once I had something like a context to hang things on, I ended up adding variables and functions to them as well.  So now they're
really more than just "event contexts", but the word "context" is too broad - so they're event contexts.

=head2 Syntactic sugar when embedding Perl

My main reason for writing Decl is to save typing and repetition.  The declarative structure itself replaces reams of setup code,
but there are lots of shorthand abbreviations I like to use in embedded Perl snippets as well.

=head2 Magic variables

An event context has a hashref that contains named values for the context.  However, you can also define getters and setters for those
values that do more than just get and set values.  I call these "magic variables".  The tastiest application of magic variables is to
bind named values to the text in input fields on a form.  Now you can get and set those values and Decl (actually Wx::Decl) will
automatically forward that to the input fields themselves.  This allows a I<lot> of succinctness:

   use Wx::Declarative;
   
   dialog (xsize=250, ysize=110) "Wx::Declarative dialog sample"
      field celsius (size=100, x=20, y=20) "0"
      button celsius (x=130, y=20) "Celsius" { $^fahrenheit = ($^celsius / 100.0) * 180 + 32; }
      field fahrenheit (size=100, x=20, y=50) "32"
      button fahrenheit (x=130, y=50) "Fahrenheit" { $^celsius = (($^fahrenheit - 32) / 180.0) * 100; }

Here, defining the fields "celsius" and "fahrenheit" automatically defines magic variables of the same names.  Magic variables have
syntactic sugar for access, so they're C<$^celsius> and C<$^fahrenheit> respectively.  This is one of my favorite examples because
(1) it works, (2) it's the reason I started down this path in the first place, and (3) it replaces about 80 lines of vanilla Perl setup
code.

=head2 Iterators

There is syntactic sugar available for iterators.  An iterator is defined by any text in the tree, by a 'data' tag, or by queries against
databases.

   TODO: Iterator examples

=head2 Databases

C<Decl> includes C<DBI> access for the simple reason that - while I love DBI like I love my own children - I hate
all the additional code needed to query a database.  I can never remember it, and that's my primary criterion for what is
a good candidate for declaratization.

The simplest way to query a database is just this:

   database (msaccess) "c:/translation/jobs2002.mdb"
   
   do {
      ^select due, words, customer, desc from [open jobs] {{
         print "-------------------\n";
         print "due:      $due\n";
         print "words:    $words\n";
         print "customer: $customer\n";
         print "desc:     $desc\n";
      }}
   }
   
Well, I lie.  The I<simplest> way to query a database is more like this:

   database (msaccess) "c:/translation/jobs2002.mdb"
   
   do {
      use Data::Dumper;
      ^select * from [open jobs] {{ print Dumper($row); }}
   }

The C<^select> construct is code-generation magic; note that it requires double brackets {{ }} to delineate its loop, just like other
iterators.  This is because it is actually a block with 'my' variables enclosing a loop; the closing }} terminates both the block and
the loop explicitly, while you should think of the opening {{ as containing all the 'my' variables.

If your select statement has a *, then the 'my' variables will be C<$dbh>, C<$sth>, and C<$row>, where C<$row> is a hashref with the
results of the current row.  If you explicitly name variables, then they will all be declared as 'my' variables, and C<$sth->bind_columns>
will be used to bind them to the current row results.  This is the fastest way to extract information from C<DBI>, so it's highly
recommended - but as you know, the point of C<Decl> is to be fast to I<write> and I<understand>; optimization will be left as
an exercise for the reader.

It's important to understand that the C<database> tag represents the database connection.  It's established during the build phase, and you
can reach it easily from Perl code like this:

   database (msaccess) "c:/translation/jobs2002.mdb"
   
   do {
      my $dbh = ^('database')->dbh;
      $dbh->table_info(...);
   }
   
Everything that L<DBI> exposes is thus available to you as well; you just don't have to set it all up.

Since the database connection is established at build time, you can also use it at build time with the 'select' tag to build structure that
depends on database input.  Here's an example with a Word document used as a report:

   use Win32::Word::Declarative;

   database (msaccess) "jobs2002.mdb"

   document "invoice_report.doc"
      para (align=center, size=16, bold) "Customers to invoice"
   
      table
         column (align=center)
         column (align=center)
         row (bold)
            cell "Customer"
         row (bold)
            cell "Amount"
         select customer, sum(value) as total from [jobs to invoice] group by customer order by total desc
            row
               cell "$customer"
               cell "\$$total"

Just try I<that> as succinctly with any vanilla imperative language!
You could do the same with a PDF, except that PDF doesn't support tables so conveniently, and I haven't yet written code to format them.
Not to mention that PDF::Declarative hasn't been published yet, but hey.  (TODO: revisit this paragraph when appropriate.)

=head2 Templates



=head1 WHAT DECL STILL DOESN'T DO WELL

Error handling, especially.  Generally, errors are still handled with croak or die, and in a GUI environment that's really not appropriate.
Some errors are just ignored, and that's not appropriate anywhere.
This alone makes Decl not quite ready for primetime.  I wouldn't mind tips and pointers if you're interested.

=head1 INTERNALS

If you're just wanting to use C<Decl>, you can probably stop reading now.

=head2 new(), tag()

A semantic class is just a collection of utilities for its plugins.  The core Semantics class doesn't really have anything at all - but as other
semantic classes will subclass this, your mileage will vary.  The one thing we know is that we'll want to keep track of the root.

The tag used to identify a semantic class will differ for each semantic class.  It's used to register the class in the root object.

=cut

sub new {
   my ($class, $root) = @_;

   bless { root => $root }, $class;
}
sub tag { 'core' }

=head2 node

The C<node> function creates a new node by handing things off to L<Decl>.  It's not too useful in the core semantics, but of
course it's inherited by the other semantic domains, where it can come in rather handy.

=cut

sub node {
   my $self = shift;
   require Decl;
   Decl->new(@_);
}

=head2 import, scan_plugins, file_root, our_flags

The C<import> function is called when the package is imported.  It checks for submodules (i.e. plugins) and calls their "defines" methods
to ask them what tag they claim to implement.  Then it gives that back to C<Decl>.  Most of the work is done in C<scan_plugins>,
because C<import> I<has> to execute in any subclass module so we can scan the right directory for plugins.

The C<scan_plugins>, C<file_root>, and C<our_flags> methods are all ways of managing subclasses that require independent existence.

=cut
sub import
{
   my($type, @arguments) = @_;
   foreach (@arguments) {
      $type->flags()->{$_} = 1;
   }
   
   my $caller = caller();   # Because caller() acts *weird* in list context!  Perl is so funky.
   if ($caller->can('yes_i_am_declarative')) {
      $type->scan_plugins ($caller, $type->file_root());
      push @Decl::semantic_classes, $type;
   } else {
      if (@arguments and $arguments[0] eq '-nofilter') {
         eval "use Decl qw(-nofilter $type);";
      } else {
         eval "use Decl qw($type);";
      }
   }
}
sub file_root { __FILE__ }
our $flags = {};
sub our_flags { $flags }
   
sub scan_plugins {
   my ($type, $caller, $file) = @_; 

   $caller = "Decl" unless $caller;
   eval "use Decl;";  # We do this to ensure C::D doesn't get called until it's really needed (instead of a regular use up top).
   my $directory = File::Spec->rel2abs($file);
   $directory =~ s/\.pm$//;
   opendir D, $directory or warn $!;
   foreach my $d (grep /\.pm$/, readdir D) {
      $d =~ s/\.pm$//;
      my $mod = $type . "::" . $d;
      $mod =~ /(.*)/;
      $mod = $1;
      eval "use $mod;";
      if ($@) {
         warn $@;
         # TODO: Also do something smarter...
         next;
      }
      my $tags;
      if ($mod->can('tags_defined')) {  # Just in case a non-node module sneaks in there somehow.
         $tags = $mod->tags_defined();
      }
      Decl->register_builder ($mod, tag(), $tags);
   }
}

=head2 start()

The C<start> function is called by the framework to start the application if this semantic class is the controlling class.  This won't happen
too often with the core semantics (except in the unit tests) but the default behavior here is to execute each callable child of the top-level
application in turn.

=cut

sub start {
   my ($self) = @_;
   my $return;
   
   foreach ($self->{root}->nodes) {
      next unless $_->{callable};
      next if $_->{event};
      $return = $_->go;
   }
   return $return;
}

=head2 do()

Each semantic module can accept events/commands issued to its name.  They are sent to the C<do> method here, already parsed.

=cut

sub do {
   my $self = shift;
   my $command = shift;
 
   # The core module doesn't implement anything.  
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

1; # End of Decl::Semantics
