package HTML::Seamstress;

use strict;
use warnings;

use Carp qw(confess);
use Cwd;
use Data::Dumper;
use File::Slurp;
use File::Spec;



use HTML::Element::Library;
use HTML::Element::Replacer;
use base qw/HTML::TreeBuilder HTML::Element/;


our $VERSION = '6.0' ;


sub bless_tree {

  my ($node, $class) = @_;


  if (ref $node) {
 #   warn "root node($class): ", $node->as_HTML;
    bless $node, $class ;

    foreach my $c ($node->content_list) {
      bless_tree($c, $class);
    }
  }
}



sub new_from_file { # or from a FH

  my ($class, $file) = @_;

  $class = ref $class ? ref $class : $class ;

  my $new = HTML::TreeBuilder->new_from_file($file);
  bless_tree($new, $class);
  #warn "CLASS: $class TREE:", $new;
#  warn "here is new: $new ", $new->as_HTML;
  $new;

}

sub new_file { # or from a FH

  my ($class, $file, %args) = @_;

  -e $file or die 'File $file does not exist';

  my $new = HTML::TreeBuilder->new;

  for my $k (keys %args) {
    next if $k =~ /guts/ ; # scales for more actions later
    $new->$k($args{$k});
  }

  -e $file or die "$file does not exist";
  $new->parse_file($file);
  bless_tree($new, $class);

  if ($args{guts}) {
    $new->guts;
  } else {
    $new;
  }

}

sub html {
  my ($class, $file, $extension) = @_;

  $extension ||= 'html';

  my $pm = File::Spec->rel2abs($file);
  $pm =~ s!pm$!$extension!;
  $pm;
}


sub eval_require {
  my $module = shift;

  return unless $module;

  eval "require $module";

  confess $@ if $@;
}

sub HTML::Element::xepand_replace {
    my $node = shift;
    
    my $seamstress_module = ($node->content_list)[0]  ;
    eval "require $seamstress_module";
    die $@ if $@;
    $node->replace_content($seamstress_module->new) ;

}


1;
__END__

=head1 NAME

HTML::Seamstress - HTML::Tree subclass for HTML templating via tree rewriting

=head1 SYNOPSIS



=head2 Text substitution via replace_content() API call.

In our first example, we want to perform simple text substitution on
the HTML template document. The HTML file html/hello_world.htm has
klass attributes which serve as compiler (kompiler?) hints to Seamstress:

 <html>
 <head>
   <title>Hello World</title>
 </head>
 <body>
 <h1>Hello World</h1>
   <p>Hello, my name is <span id="name">dummy_name</span>.
   <p>Today's date is <span id="date">dummy_date</span>.
 </body>
 </html>

=head3 Seamstress compiles HTML to C<html::hello_world>

 shell> seamc html/hello_world.htm
 Seamstress v2.91 generating html::hello_world from html/hello_world.htm

Now you simply use the "compiled" version of HTML with API calls to
HTML::TreeBuilder, HTML::Element, and HTML::Element::LIbrary

 use html::hello_world; 
 
 my $tree = html::hello_world->new; 
 $tree->look_down(id => name)->replace_content('terrence brannon');
 $tree->look_down(id => date)->replace_content('5/11/1969');
 print $tree->as_HTML;

=head2 If-then-else with the highlander API call

(But also see C<< $tree->passover() >> in L<HTML::Element::Library>).

 <span id="age_dialog">
    <span id="under10">
       Hello, does your mother know you're 
       using her AOL account?
    </span>
    <span id="under18">
       Sorry, you're not old enough to enter 
       (and too dumb to lie about your age)
    </span>
    <span id="welcome">
       Welcome
    </span>
 </span>


=head3 Compile and use the module:

 use html::age_dialog;

 my $tree = html::dialog->new;

 $tree->highlander
    (age_dialog =>
     [
      under10 => sub { $_[0] < 10} , 
      under18 => sub { $_[0] < 18} ,
      welcome => sub { 1 }
     ],
     $age
    );

  print $tree->as_HTML;

  # will only output one of the 3 dialogues based on which closure 
  # fires first	


The following libraries are always available for more complicated
manipulations:

=over 

=item * L<HTML::ElementTable>

=item * L<HTML::Element::Library>

=item * L<HTML::Element>

=item * L<HTML::Tree>

=back



=head1 PHILOSOPHY and MOTIVATION of HTML::Seamstress

Welcome to push-style dynamic HTML generation!

When looking at HTML::Seamstress, we are looking at a uniquely
positioned 4th-generation HTML generator. Seamstress offers two sets
of advantages: those common to all 4th generation htmlgens and those
common to a subclass of L<HTML::Tree>.



I think a Perlmonks node:
L<http://perlmonks.org/?node_id=669956>
sums up the job of Seamstress quite well:

    Monks,

    I'm tired of writing meta code in templating languages.
    I'm really good at writing Perl, and good at writing HTML, 
    but I'm lousy at the templating languages (and I'm not too 
    fired up to learn more about them).


=head2 Reap 4th generation dynamic HTML generation benefits

What advantages does this fourth way of HTML manipulation offer? Let's
take a look:

=head3 Guarantee yourself well-formed HTML

Because lower-generation dynamic HTML generators treat HTML as a
string, there is no insurance against poorly formed HTML.

Take a look at these two Mason components, from
L<http://masonbook.com/book/chapter-5.mhtml#TOC-ANCHOR-5> :

=over 

=item * Example 5-3. /autohandler

  <html>
  % $m->call_next;
  </html>
  <%method .body_tag>
   <%args>
    $bgcolor => 'white'
    $textcolor => 'black'
   </%args>
   <body onLoad="prepare_images( )" bgcolor="<% $bgcolor %>" text="<% $textcolor %>">
  </%method>

=item * Example 5-4. /important_advice.mas

  <head><title>A Blue Page With Red Text</title></head>
  
  <& SELF:.body_tag, bgcolor=>'blue', textcolor=>'red' &>
   Never put anything bigger than your elbow into your ear.
  </body>

=back

There is nothing guaranteeing that open tags will match close tags or
that close tags will even exist. 
To make the correspondence between open and close tags even more troublesome,
they are in different files. And it is not easy for an HTML designer and/or
design tool to manipulate things once they have been shredded apart
like this. 


With the tree-based approach of Seamstress, the end tag will exist
and it will match the open tag. Well-formedness is job 1 in tree-based
HTML rewriting!




=head4 HTML will be properly escaped

=head3 Separate HTML development and its programmatic modification  

Software engineers refer to this as B<orthogonality>.
The contents of the document remain legal HTML/XML that can be be
developed using standard interactive design tools. The flow of control
of the code remains separate from the page. Technologies that mix
content and data in a single file result in code that is often
difficult to understand and has trouble taking full advantage of the
object oriented programming paradigm.  

=head3 Work at meta-level instead of object-level

The book "Godel, Escher, Bach: An Eternal Golden Braid" by  Douglas R
Hofstadter makes it clear what it means to operate at object-level as
opposed to meta-level. When you buy into earlier-generation HTML
generation systems you are working at object-level: you can only speak
and act I<as> the HTML with no ability to speak I<about> the HTML. 

Compare a bird's eye view of a city with standing on a city block and
you have the difference between the 4th generation of HTML development
versus all prior generations.


=head3 Reduced learning curve

If you have a strong hold on 
object-oriented Perl and a solid understand of the tree-based nature
of HTML, then all you need to do is read the manual pages showing how
Seamstress and related modules offer tree manipulation routines and
you are done.

Extension just requires writing new Perl methods - a snap for any
object oriented Perler.

=head3 Static validation and formatting

Mixing Perl and HTML (by any of the generation 1-3 approaches)
makes it impossible to use standard validation and formatting tools
for either Perl or HTML.


=head3 Two full-strength programming languages: HTML and Perl

Perl and HTML are solid technologies with years of effort behind
making them robust and flexible enough to meet real-world
technological demands.

=head3 Object-oriented reuse and extension of HTML

Class-based object-oriented programming makes use of inheritance and
other  techniques to achieve maximum code reuse. This typically
happens by a certain base/superclass method containing common actions
and a derived/subclass/mixin method containing extra actions.

A genuine tree-based approach (such as HTML::Seamstress) to HTML
generation is supportive of all methods of object-oriented reuse: 
because manipulator and manipulated are separate and manipulators are
written in oo Perl, we can compose manipulators as we please.

This is in contrast to inline simple object systems (as in Mason) and
also in contrast to the if-then approach of tt-esque systems.

=head4 Per-page stereotyped substitution

[ FYI: you can run the two Seamstress approaches. They are in 
F<$DISTRO/samples/perpage> ]

In the HTML::Mason book by O'Reilly:
L<http://masonbook.com/book/chapter-1.mhtml#TOC-ANCHOR-4>

we see a technique for doing simple text insertion which varies per
page:

 <html>
  <head><title>Welcome to Wally World!</title></head>
  <body bgcolor="#CCFFCC">
  <center><h1><% $m->base_comp->attr('head') %></h1></center>
  % $m->call_next;
  <center><a href="/">Home</a></center>
  </body></html>

 # homepage.html
 <%attr>
   head => "Wally World Home"
 </%attr>
  Here at Wally World you'll find all the finest accoutrements.

 # productpage.html
 <%attr>
   head => "Wally World Products"
 </%attr>
  
 <table> ... </table>

So, how would we do this using Seamstress' pure Perl approach to HTML
refinement? 

 
 <html>
  <head><title>Welcome to Wally World!</title></head>
  <body bgcolor="#CCFFCC">
  <center><h1 id=head>DUMMY_HEAD</h1></center>
  <span id=body>DUMMY_BODY</span>
  <center><a href="/">Home</a></center>
  </body></html>

 # homepage.pm
 package html::homepage;

 use base qw( HTML::Seamstress ) ;

 sub new {
  my ($class, $c) = @_;

  my $html_file = 'html/base.html';

  my $tree = __PACKAGE__->new_from_file($html_file);

  $tree;
 }

 sub process {
  my ($tree, $c, $stash) = @_;

  $tree->content_handler(head => 'Wally World Home');
  $tree->content_handler(body => 
   'Here at Wally World you'll find all the finest accoutrements.');
 }

 # productpage.pm
 package html::productpage;

 use base qw( HTML::Seamstress ) ;

 sub new {
  my ($class, $c) = @_;

  my $html_file = 'html/base.html';

  my $tree = __PACKAGE__->new_from_file($html_file);

  $tree;
 }

 sub process {
  my ($tree, $c, $stash) = @_;

  $tree->content_handler(head => 'Wally World Products);
  $tree->content_handler(body => html::productpage::body->new->guts)
 }

We have solved our problem. However, we can create even more re-use
because the both of these classes are very similar. They only vary in
2 things: the particular head and body they provide.
You can abstract this with whatever methodmaker you like. I tend to
prefer prototype-based oop 
over class-based, so with L<Class::Prototyped|Class::Prototyped>,
here's how we might do it:

 package html::abstract::common;

 use base qw(HTML::Seamstress Class::Prototyped);


 sub head { 'ABSTRACT BASE METHOD' }
 sub body { 'ABSTRACT BASE METHOD' }

 __PACKAGE__->reflect->addSlots(
  html_file => 'html/base.html',
 );

 sub new {
  my $self = shift;

  my $tree = $self->new_from_file($self->html_file);
 }

 sub process {   
  my ($tree, $c, $stash) = @_;
  $tree->content_handler(head => $tree->head);
  $tree->content_handler(body => $tree->body);
 }

 1;

and then have both of the above classes instantiate and 
specialize this common class accordingly.
     
[ Again: you can run the two Seamstress approaches. They are in 
F<$DISTRO/samples/perpage> ]



=head3 Parallel generation of a single page natural

A tree of HTML usually contains subtrees with no
inter-dependance. They therefore can be manipulated in parallel. If a
page contains 5 areas each of which takes C<N> time, then one could
realize an N-fold speedup.

=head2 Reap the benefits of using HTML::Tree

=head3 Pragmatic HTML instead of strict X(HT)ML

The real world is unfortunately more about getting HTML to work with
IE and maybe 1 or 2 other browsers. Strict XHTML may not be acceptable
under time and corporate pressures to get things to work with quirky
browsers. 

=head3 Rich API and User Contributions

L<HTML::Tree> has a nice large set of accessor/modifier functions. If
that is not enough, then take a gander at Matthew Sisk's
contributions: L<http://search.cpan.org/~msisk/> as well as
L<HTML::Element::Library>. 

=head1 Seamstress contains no voodoo elements whatsoever

If you know object-oriented Perl and know how to rewrite trees, then
everything that Seamstress offers will make sense: it's just various
boilerplates and scripts that allow your mainline code to be very
succinct: think of it as Class::DBI for HTML::Tree.


=over

=item * unifying HTML and the HTML processing via a Perl class

Seamstress contains two scripts, F<spkg.pl> and F<sbase.pl> which
together make it easy to access and modify an HTML file in very few
lines of startup code. If you have a file named 
F<html/hello_world.html>, Seamstress makes it easy for that to become
the Perl module C<html::hello_world> with a C<new()> method that 
loads and parses the HTML into an L<HTML::Tree|HTML::Tree>.

=item * a Catalyst View class with meat-skeleton processing

The meat-skeleton HTML production concept is discussed below. 
L<Catalyst::Seamstress::View|Catalyst::Seamstress::View> is all ready
to go for rendering simple or more complex pages.

=item * Loading in the HTML::Tree support classes

One a Perl class has been built for your HTML, it has
L<HTML::Element|HTML::Element> and 
L<HTML::Element::Library|HTML::Element::Library> as superclasses, ready
for you to use to rewrite the tree.

=back

=head2 Seamstress is here to help you use HTML::Tree, that's all.

=head2 Unify HTML and the processing of the HTML via a Perl class

Let's see why this is a good idea. In Mason, your Perl and HTML are
right there together in the same file. 
Same with Template. Now, since Seamstress
operates on the HTML without touching the HTML, the operations and
the HTML are not in the same file. So we create a Perl module to
glue the HTML file to the operations we plan to perform on it.

This module (auto-created by F<spkg.pl> and perhaps F<sbase.pl>)
has a constructor C<new()>, which grabs the HTML file and 
constructs an L<HTML::Element|HTML::Element> tree from it and
returns it to you.

It also contains a C<process()> subroutine which processes the 
HTML in some way: text substitutions, unrolling list elements,
building tables, and whatnot.

Finally, it contains a C<fixup()> subroutine. This subroutine is
designed to support the meat-skeleton paradigm, discussed above.
The C<process()> subroutine generated the C<$meat>. After <$meat>
has been placed in C<$skeleton>, there may be some page-specific
processing to the whole HTML page that you want to: pop in some
javascript, remove a copyright notice, whatever. That's what 
this routine is for.

Now that I've said all that, please understand that you are perfectly
free to call C<new()> and do what you want with the HTML tree. You
don't have to use C<process()> and C<fixup()>. But they are there and
are used by L<Catalyst::View::Seamstress> to make meat-skeleton
dynamic HTML development quick-and-easy (and non-greasy).

=head3 A Perl class created by spkg.pl

Here is our venerable little HTML file:

 metaperl@pool-71-109-151-76:/ernest/dev/catalyst-simpleapp/MyApp/root/html$ cat hello_world.html 
 <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
 <html>
  <head>
    <title>Hello World</title>
  </head>
  <body>
  <h1>Hello World</h1>
    <p>Hello, my name is <span id="name">dummy_name</span>.
    <p>Today's date is <span id="date">dummy_date</span>.
  </body>
 </html>


Now let's abstract this as a Perl class:

 metaperl@pool-71-109-151-76:/ernest/dev/catalyst-simpleapp/MyApp/root/html$ spkg.pl --base_pkg=MyApp::View::Seamstress --base_pkg_root=`pwd`/../../lib hello_world.html
 comp_root........ /ernest/dev/catalyst-simpleapp/MyApp/root/
 html_file_path... /ernest/dev/catalyst-simpleapp/MyApp/root/html/
 html_file........ hello_world.html
 html_file sans... hello_world
 hello_world.html compiled to package html::hello_world
 metaperl@pool-71-109-151-76:/ernest/dev/catalyst-simpleapp/MyApp/root/html$ 

Now lets see what html::hello_world looks like. Everything other than 
C<process()> was auto-generated:

 package html::hello_world;

 use strict;
 use warnings;

 use HTML::TreeBuilder;


 use base qw(MyApp::View::Seamstress); 

 our $tree;


 sub new {
  my $file = __PACKAGE__->comp_root() . 'html/hello_world.html' ;

  -e $file or die "$file does not exist. Therefore cannot load";

  $tree =HTML::TreeBuilder->new;
  $tree->parse_file($file);
  $tree->eof;
  
  bless $tree, __PACKAGE__;
 }

 sub process {
  my ($self, $c, $stash) = @_;

  $tree->look_down(id => $_)->replace_content($stash->{$_})
      for qw(name date);
 }

 sub fixup { $tree }

 1;



=head2 The meat-skeleton paradigm

This section is written to help understanding of
L<Catalyst::View::Seamstress> for people who want to use Seamstress as
the view for their L<Catalyst|Catalyst> apps.

HTML pages typically have meat and a skeleton. The meat varies from page
to page while the skeleton is fairly (though not completely) 
static. For example, the skeleton of a webpage is usually a header, a
footer, and a navbar. The meat is what shows up when you click on a
link on the page somewhere. While the meat will change with each
click, the skeleton is rather static.

The perfect example of 

Mason accomodates the meat-skeleton paradigm via
an C<autohandler> and C<< $m->call_next() >>. Template 
accomodates it via its C<WRAPPER> directive.

And Seamstress? Well, here's what you _can_ do:

=over

=item 1 generate the meat, C<$meat>

This is typically what you see in the C<body> part of an HTML page

=item 2 generate the skeleton, C<$skeleton>

This is typically the html, head, and maybe some body 

=item 3 put the meat in the skeleton

=back

So, nothing about this is forced. This is just how I typically do
things and that is why
L<Catalyst::View::Seamstress|Catalyst::View::Seamstress> has support
for this.

In all honesty, the meat-skeleton paradigm should be supported here
and called from C<Catalyst::View::Seamstress>. But the problem is, I
don't
want to create an abstract API here unless I have used the
meat-skeleton paradigm from one other framework besides Catalyst. Then
I will have a good idea of how to refactor it so any framework can
make good use of the paradigm.



	 


=head1 USAGE

The best example of usage is the F<Quickstart> directory in this
distribution. You can read L<HTML::Seamstress::Quickstart> and
actually run the code in that directory at the same time. After doing
so, the following sections are additional instruction.


=head2 Understand that HTML is a tree

The best representation of this fact is this slide right here:

L<http://xmlc.objectweb.org/doc/xmlcSlides/xmlcSlides.html#de>

If you understand this (and maybe the rest of the slides), then you
have a good grip on seeing HTML as a tree.

L<HTML::Tree::AboutTrees> does also teach this, but it takes a while
before he gets to what matters to us. It's a fun read nonetheless. 

Now that we've got this concept under our belts let's try some full examples.

=head2 Install and Setup Seamstress

The first thing to remember is that Seamstress is really just
convenience functions for L<HTML::Tree|HTML::Tree>. You can do
entirely without 
Seamstress. It's just that my daily real-world obligations have lead
to a set of library functions (HTML::Element::Library) and a
convenient way to locate "templates" (C<spkg.pl>) that work well on
top of L<HTML::Tree|HTML::Tree>

=over

=item * move spkg.pl and sbase.pl onto your execution C<$PATH>

C<sbase.pl> and C<spkg.pl> are used to simplify the process of 
parsing an HTML file into HTML::Treebuilder object. In other words
instead of having to do this in your Perl programs:

 use HTML::TreeBuilder;

 my $tree = HTML::TreeBuilder->new_from_file('/usr/htdocs/hello.html');

You can do this:

 use htdocs::hello;

 my $tree = htdocs::hello->new;

The lines of code is not much different, but abstracting away absolute
paths is important in production environments where the absolute path 
may come from who knows where via who knows how.

=item * run sbase.pl

sbase.pl will ask you 2 very simple questions. Just answer them. 
When it is finished, it will have installed a package named 
C<HTML::Seamstress::Base> on your C<@INC>. This module contains one
function, C<comp_root()> which points to a place you wouldn't
typically have on your C<@INC> but which you must have because your
HTML file and corresponding C<.pm> abstracting it are going to be
there. 

=item * run spkg.pl

In the default seutp, 
no options need be supplied to this script. They
are useful in cases where you have more than one document root or want
to inherit from more than one place.


 metaperl@pool-71-109-151-76:~/www$ spkg.pl moose.html
 comp_root........ /home/metaperl/
 html_file_path... /home/metaperl/www/
 html_file........ moose.html
 html_file sans... moose
 moose.html compiled to package www::moose

=item * load your abstracted HTML and manipulate it

Now, from Perl, to get the TreeBuilder object
representing this HTML file, we simply do this:

 use www::moose;
 
 my $tree = www::moose->new;
 # manipulate tree...
 $tree->as_HTML;

In a mod_perl setup, you would want to pre-load your HTML and
L<Class::Cache|Class::Cache> was designed for this very purpose. But
that's a topic for another time.

In a setup with HTML files in numerous places, I recommend setting up
multiple C<HTML::Seamstress::Base::here>,
C<HTML::Seamstress::Base::there> for each file root. To do this, you
will need to use the C<--base_pkg> and C<--base_pkg_root> options to
spkg.pl


=item * That's it!

Now you are ready to abstract away as many files as you want with the
same C<spkg.pl> call. Just supply it with a different HTML file to
create a different package. Then C<use> them, C<new> them and
manipulate them and C<< $tree->as_HTML >> them at will.

Now it's time to rock and roll!


=back


=head2 Text substitution == node mutation

In our first example, we want to perform simple text substitution on
the HTML template document:

 <html>
 <head>
   <title>Hello World</title>
 </head>
 <body>
 <h1>Hello World</h1>
   <p>Hello, my name is <span id="name">dummy_name</span>.
   <p>Today's date is <span id="date">dummy_date</span>.
 </body>
 </html>

First save this somewhere on your document root. Then compile it with
C<spkg.pl>. Now you simply use
the "compiled" version of HTML with API calls to 
HTML::TreeBuilder, HTML::Element, and HTML::Element::Library.

 use html::hello_world; 
 
 my $tree = html::hello_world->new; 
 $tree->look_down(id => name)->replace_content('terrence brannon');
 $tree->look_down(id => date)->replace_content('5/11/1969');
 print $tree->as_HTML;

C<replace_content()> is a convenience function in
L<HTML::Element::Library>. 



=head2 If-then-else == node(s) deletion

(But also see C<< $tree->passover() >> in L<HTML::Element::Library>).

 <span id="age_dialog">
    <span id="under10">
       Hello, does your mother know you're 
       using her AOL account?
    </span>
    <span id="under18">
       Sorry, you're not old enough to enter 
       (and too dumb to lie about your age)
    </span>
    <span id="welcome">
       Welcome
    </span>
 </span>


Again, compile and use the module:

 use html::age_dialog;

 my $tree = html::dialog->new;

 $tree->highlander
    (age_dialog =>
     [
      under10 => sub { $_[0] < 10} , 
      under18 => sub { $_[0] < 18} ,
      welcome => sub { 1 }
     ],
     $age
    );

  print $tree->as_HTML;

  # will only output one of the 3 dialogues based on which closure 
  # fires first	


And once again, 
the function we used is the highlander method, also a part
of L<HTML::Element::Library>.


The following libraries are always available for more complicated
manipulations:

=over 

=item * L<HTML::ElementSuper>

=item * L<HTML::ElementTable>

=item * L<HTML::Element::Library>

=item * L<HTML::Element>

=item * L<HTML::Tree>

=back



=head2 Looping == child/sibling proliferation

Table unrolling, pulldown creation, C<li> unrolling, and C<dl>
unrolling are 
all examples of a tree operation in which you take a child of a node
and clone it and then alter it in some way (replace the content, alter
some of its attributes), and then stick it under its parent.

Functions for use with the common HTML elements --- C<< <table> >>, 
C<< <ol> >>,
C<< <ul> >>, C<< <dl> >>, C<< <select> >> 
are documented in 
L<HTML::Element::Library> and are
prefaced with the words "Tree Building Methods".


=head2 What Seamstress offers

Beyond the "compilation" support documented above, Seamstress offers
nothing more than a simple structure-modifying method,
expand_replace(). And to be honest, it probably shouldn't offer
that. But once, when de-Mason-izing a site, it was easier to keep
little itty-bitty components all over and so I wrote this method to
facilitate the process.

Let's say you have this HTML:

     <div id="sidebar">

	<div class="sideBlock" id=mpi>mc::picBar::index</div>

	<div class="sideBlock" id=mnm>mc::navBox::makeLinks</div>

	<div class="sideBlock" id=mg>mc::gutenBox</div>

      </div>

In this case, the content of each sideBlock is the name of a Perl
Seamstress-style class. As you know, when the constructor for such a
class is called an 
HTML::Element, C<$E>, will be returned for it's parsed content.

In this case, we want the content of the div element to go from the
being the class name to being the HTML::Element that the class
constructs. So to inline all 3 tags you would do the following;

 $tree->look_down(id => $_)->expand_replace for qw(mpi mnm mg);



=head2 What Seamstress works with

=head3 Class::Cache

Useful in mod_perl environments and anywhere you want control over the
timing of object creation.

=head3 The family of HTML::Tree contributions

=over 4

=item * L<HTML::ElementTable>

=item * L<HTML::Element::Library>

=item * L<HTML::Element>

=item * L<HTML::Tree>

=back

=head1 METHODS

=head2 ->new_from_file()

This does the same thing as the TreeBuilder C<new_from_file()> method,
but it blesses the object into the invocant class. This makes the
invocant class derive from Seamstress which means it has
L<HTML::TreeBuilder|HTML::TreeBuilder>,
L<HTML::Element|HTML::Element> , and
L<HTML::Element::Library|HTML::Element::Library> at its disposal.

=head2 ->html()

This method takes C<__FILE__>, and optionally a desired C<$extension>
(defaults to 'html' if not given) and
changes the extension on C<__FILE__> from C<.pm> to C<$extension>.
This works well for common situations. 

=head1 A BRIEF HISTORY of Dynamic HTML Generation (Templating)

HTML::Seamstress provides "fourth generation" dynamic HTML generation
(templating). 

In the beginning we had...


=head2 First generation dynamic HTML production - server side includes

First generation dynamic HTML production used server-side
includes:

 <p>Today's date is   <!--#echo var="DATE_LOCAL" --> </p>

=head2 Second generation dynamic HTML production - HTML in Perl

The next phase of HTML generation saw
embedded HTML snippets in Perl code. For example:

 sub header {
   my $title = shift;
   print <<"EOHEADER";
   <head>
      <title>$title</title>
   </head>
   EOHEADER
 }

=head2 Third generation dynamic HTML production - Perl/minilanguage in HTML

The 3rd generation solutions embed
programming language constructs with HTML. The language constructs
are either a real language (as is with L<HTML::Mason>) or a
pseudo/mini-language (as is with L<PeTaL>, L<Template> or
L<HTML::Template>). Let's see some L<Template> code:

 <p>Hi there [% name %], are you enjoying your stay?</p>

=head2 Talkin' bout them generations...

Up to now, all approaches to this issue tamper with the
HTML in some form or fashion:

=over 

=item * Generation 1 adds SSI processing instructions

=item * Generation 2 rips the HTML apart and adds programming elements

=item * Generation 3 sprinkles programming constructs in the HTML

=back

=head2 Enter fourth generation dynamic HTML production - DOM style

The fourth generation of HTML production is distinguished by no need
for tampering with the HTML. There are a wealth of XML-based modules
which provide this approach (L<XML::Twig>, L<XML::LibXML>,
L<XML::TreeBuilder>, L<XML::DOM>). HTML::Seamstress is the one CPAN
module based around HTML and L<HTML::Tree> for this approach.

The fourth generation is also the way that a language like Javascript rewrites HTML.
By using Seamstress, you can always think about manipulating your HTML in the same way!



=head1 SEE ALSO

=head2 Object-oriented goodies

Seamstress is just glue for object-oriented tree processing in Perl (I can see my SEO rank climbing right now from that sentence!).
Anyway, here is your LOOM - (List of object-oriented modules):

=over 4

=item * L<HTML::ELement::Replacer|HTML::Element::Replacer>

=item * L<HTML::ELement::Library|HTML::Element::Library>

=back

=head2 Related Software

I created a node at Perlmonks which catalogues push-style templating systems
both in and outside of Perl:

L<http://perlmonks.org/?node_id=674225>

Here are two common ones:
L<http://xmlc.enhydra.org>
L<http://www.plope.com/software/meld3>




=over

=item * L<Template::Recall>

The author uses what he called "reverse callbacks" to create a style very
similar to Seamstress.

=item * L<Petal>

Based on Zope's TAL, this is a very nice and complete framework that is
the basis of MkDoc, a XML application server. It offers a
mini-language for XML rewriting, Seamstress does not. The philosophy
of the Seamstress is the orthogonal integration of Perl and HTML not a
mini-language and HTML.

=item * L<XML::LibXML>

By the XML guru Matt Sergeant, who is also the author of AxKit, another XML 
application server. This offers XPath for finding nodes

=item * L<XML::DOM>

If I wanted to ape XMLC entirely, I would have used TJ Mather's
L<XML::DOM>. Because XMLC is based around DOM API calls. However,
TreeBuilder is very handy and has a lot of nice libraries around it
such L<HTML::PrettyPrinter>. The biggest win of XML::DOM is it's easy
integration with L<XML::Generator>

From the docs, it looks like L<XML::GDOME> is the successor to this
module.


=back


=head2 Articles, Publications, Discussion


=head3 Push style templating systems

http://perlmonks.org/?node_id=674225

=head3 Form Validation in CGI::Application with Seamstress

L<http://perlmonks.org/?node_id=742427>

=head3 Easy table rendering in modern HTML::Seamstress

L<http://perlmonks.org/?node_id=768430>


=head3 HTML Templating as Tree Rewriting: Part I: "If Statements"

L<http://perlmonks.org/index.pl?node_id=302606>

=head3 HTATR II: HTML table generation via DWIM tree rewriting

L<http://perlmonks.org/index.pl?node_id=303188>

=head3 Survey of Surveys on HTML Templating systems

L<http://perlmonks.org/?node_id=433729>

A fierce head-to-head between PeTaL and Seamstress goes on for several
days in this thread!


=head3 The disadvantages of mini-languages

The disadvantages of mini-languages is discussed here:
L<http://perlmonks.org/?node_id=428053>

A striking example of the limitations of mini-languages is shown here:
L<http://perlmonks.org/?node_id=493477>

But the most cogent argument for using full-strength languages as
opposed to mixing them occurs in the L<Text::Template> docs:

 When people make a template module like this one, they almost always
 start by inventing a special syntax for substitutions. For example,
 they build it so that a string like %%VAR%% is replaced with the
 value of $VAR. Then they realize the need extra formatting, so they
 put in some special syntax for formatting. Then they need a loop, so
 they invent a loop syntax. Pretty soon they have a new little
 template language. 

 This approach has two problems: First, their little language is
 crippled. If you need to do something the author hasn't thought of,
 you lose. Second: Who wants to learn another language? You already
 know Perl, so why not use it? 

And for the Mason users whose retort is "we do use Perl!" the obvious
reply is: "granted, but in an embedded fashion with ad hoc,
inflexible object mechanisms, non-tree-based (hence syntactically
suspect) HTML manipulation, and no ability to statically validate the
Perl or HTML" 


=head3 Problems with JSP (JSP is similar to HTML::Mason)

L<http://www.servlets.com/soapbox/problems-jsp-reaction.html>

L<http://www-106.ibm.com/developerworks/library/w-friend.html?dwzone=web>

L<http://www.theserverside.com/resources/article.jsp?l=XMLCvsJSP>

=head3 Los Angeles Perl Mongers Talk on HTML::Seamstress

L<http://www.metaperl.org>

=head3 "Inside-out Templates in Perl"

L<http://www.webquills.net/web-development/perl/insideout-templates-in-perl.html>


=head1 SUPPORT and DEVELOPMENT



=head2 IRC

L<irc://irc.perl.org/#html-seamstress>

=head2 Mailing List

L<http://lists.sourceforge.net/lists/listinfo/seamstress-discuss>

=head2 Source repo

L<http://github.com/metaperl/html-seamstress/tree/master>

=head1 AUTHOR

Terrence Brannon, C<< tbone@cpan.org >>

=head2 ACKNOWLEDGEMENTS

I would like to thank 

=over

=item * Chris Winters for exposing me to XMLC

=item * Paul Lucas for writing C<HTML_Tree>

L<http://homepage.mac.com/pauljlucas/software/html_tree/>

HTML_Tree is a C++ HTML manipulator with a Perl interface. Upon using
his Perl interface, I began to notice limitations and extended his
Perl interface. The author was not interested in working with me or my
extensions, so I had to continue on a separate path.

=item * C<johnnywang> for his post about dynamic HTML generation 

L<http://perlmonks.org/?node_id=505080>.

=item * Matthew Sisk and John Porter for lively personal discussions

=item * Matthew Hodgson (Arathorn on #catalyst) 

for brainstorming with me on how to produce a Catalyst view 
for Seamstress

=item * Gary Ashton-Jones

for a patch to spkg.pl and being the first person to join
the C<seamstress-discuss> mailing list without any
solicitation from me C<:)>.

=item * Brock Wilcox

for ramming heads with me over possibly using CSS to specify tree 
rewrite actions:

sub fix_age : ID(age) {

   (shift)->replace_content(shift()) ;

}

Just an idea...

=item * Ian Tegebo

For noticing some doc bugs in the Quickstart guide.

=item * 

=back


=head1 COPYRIGHT AND LICENSE

Copyright RANGE(1999,NOW()) by Terrence Brannon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
