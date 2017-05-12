# ====================================================================
# Copyright (C) 1997,1998 Stephen Farrell <stephen@farrell.org>
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# ====================================================================
# File: TableLayout.pm
# Author: Stephen Farrell
# Created: August, 1997
# Locations: http://www.palefire.org/~sfarrell/TableLayout/
# CVS $Id: TableLayout.pm,v 1.16 1998/09/20 21:28:26 sfarrell Exp $
# ====================================================================
##
## Thanks for help and comments from: Jeff Stampes, Andreas Koenig, ...
##
##
## To do:
## o A thought is to have two versions of symbols to export, one
##   which is "short", but might be considered "rude" to the average
##   user's namespace.  This will need a special tag (:NS_HOG
##   perhaps). alternatively, all the symbols will be prefixed like
##   TL_window, TL_cell, etc.  whatever.

=head1 NAME

HTML::TableLayout - Layout Manager for cgi-based web applications

=head1 DESCRIPTION

This is a HTML-generating package for making graphical user interfaces
via a web browser using a "Layout Manager" paradigm such as in Tk/Tcl
or Java.  It includes a component heirarchy for making new "widgets".

=head1 EXPORT

=over 12

=item DEFAULT

C<parameters window table cell header text image link list pre>

=item FORM

C<form choice button hidden input_text password submit radio>

=back

=head1 SYNOPSIS

  use HTML::TableLayout;
	$w = window(undef,"Hello World");
	$w->insert(table()->insert("hello world"));
	# ...
	$w->print();

=head2 WARNING: DOCUMENTATION INCOMPLETE AND SOMETIMES WRONG.

This documentation is incomplete and occassionally wrong.  As always,
the source is the best reference (and, in fact, is relatively well
commented in this case).  This documentation will improve as the API
stabilizes.

On the other hand, some effort was made to bring it up-to-date with
release 1.1.4.

=head2 Weird OO Syntax

I thought that "new" was too noisy and took up too much space, so I
do not use it in the API.  When you call, for example,

	window($x,$y,$z),

you are really doing

	HTML::TableLayout::Window->new($x,$y,$z). 

(but isn't it a whole lot nicer looking?)


=head1 User API

=over 12

=item C<parameters>

Constructor for default parameters.  This is used for setting up
application-wide defaults for parameters of various objects.  It takes
no arguments but has the following methods:

	$p->set($obj, %p);	# destructive
	$p->insert($obj, %p);	# non-destructive
	$p->delete(@tags);

Where the $obj is any instance of any component.

The hash %p is a hash of parameters.  In all but a few cases these
parameters are passed directly through as HTML parameters.  E.g., if I
write

$p->set(table(),width=>"100%",border=>undef,foo=>"bar"),

then all tables will look like

<TABLE width="100%" border foo="bar">

(plus other parameters you add later).  Note that it blindly passes
through what is presumably a meaningless HTML flag--"foo".


Now, you might find the first argument (an instance of the object)
passed in a little odd, to say the least.  Once you pass in any
instance of any object, it "recognizes" that kind of object in the
future.  This way, it works not only for built-in classes, but also
any that you choose to derive yourself.  (NOTE: this will change
w/1.2.x, but it will probably still work this way for backwards
compatibility)

One place that this is very useful is a trivial case.  Let's say that
I want to define a focused table--i.e., a table that I use
consistently to guide the users attention.  I can make a class like
such:

	package FocusedTable;
	@ISA=qw(HTML::TableLayout::ComponentTable);

	## EOF

and then I can add a setting:

	$p->set(FocusedTable->new(), %focustable_settings);

Now, whenever you use a FocusedTable, it will use these settings, even
though in reality it is the same as a table.

Hmm... you're thinking, but what if I derive a special Checkbox, but I
want it to get the parameters for a regular checkbox.  I've provided
for this as well.  In your constructor for this new checkbox (or an
init() method):

	package myCheckbox;
	@ISA=qw(HTML::TableLayout::FormComponent::Checkbox);

	sub new {
		my ($class, %params) = @_;
		my  = {};
		bless , $class;
		->tl_inheritParamsFrom(checkbox());
		return ;
	}

And the mechanism that sets the parameters will think it is really
just a Checkbox.

(It might be nice if instead of having to set this explicitely, the
mechanism (_obj2tag(), actually) could check based upon inheritance
and use the settings from the closest parent.  The thing is (a) I
don't know how to do this efficiently (b) I want to have this
tl_inheritParamsFrom() anyway so that one can force whichever behavior
she wants.)

NOTE: This is one of the things that will probably change/improve for
version 1.2.x...


=item C<window>

Constructor for a window.  The first argument is a parameters object,
while the third argument is the parameters specific to that window
instance. 

	window($parameters, $title, %params)


=item C<win_header>

Constructor for a window header.  The first argument is the number of
the header, as in:

	win_header(2,"some text")

will produce:

	<H2>some text</H2>

Similarly,

	win_header(undef,"some text")

will produce

	some text

but will place it up at the top of the window.

=item C<table>

Constructor for a table.  Other than a few special cases (such as
scripts and headers) everything is layed out via tables.  Tables can
be nested inside other tables.  It takes a hash of parameters as an
argument--these parameters will only be used for this table.  One
salient example would be "columns".  If you want to have a
15-columned table, you'd say:

	$t=table(columns=>15);

This parameter is passed directly out to the HTML, but this layout
manager also pays attention to it internally.

Tables have one external method:

	$t->insert($some_component);

This something can be pretty much anything derived from
HTML::TableLayout::Component.  It can also be a form--as a general
rule the table just does the right thing with whatever you stick in
it.  If it does not, it is a bug (please let me know!)

=item C<cell>

Constructor for a cell.  You will be using a lot of these--these
correspond to <TD></TD> in HTML.  (Rows are handled magically by this
layout manger).  Tables create default cells when you stick something
in them which is not a cell (or form).  If you want to put more than
one thing in a cell, or if you want to made a special cell (e.g., with
some non-default alignment), then you need to create a cell
explicitely.  You insert "stuff" into cells much like you do into
tables.  In fact, when you stick something into a table that the table
does not recognize, it just passes it along to a (new) cell.


=item C<cell_header>

Constructor for a cell header.  The first argument is the contents
(usually text), and the next arguments are a hash of parameters. You
can set the orientation of such with the "Orientation" pseudo-tag.
E.g., Orientation=>"left" will make the header appear to the left of
the cell.

=item C<text>

Constructor for text.  It looks like:

	$c->insert(text($text,%params));

The parameters are a bit special--if you put in stuff like bold=>undef
or size=>"+2", then it will do the following:

	<FONT size=+2><b>whatever</b></FONT>

Like everything else here, this is supposed to "just work" as you
expect it to, so I had to do some funky translations of HTML tags
since HTML is pretty screwed up with this stuff.

=item C<image>

Constructor for an image.  Use it like

	$c->insert(image($url,%params));

Where the url can be relative or absolute (straight HTML story).

=item C<link>

Constructor for a link.  Use it like

	$c->insert(link($url,$anchor,%params));

Note that $anchor might be something interesting, like an image, so:

	$c->insert(link("whatever.html",image("image.gif")));

should work like a charm.


=item C<list>

Constructor for a list.  A list sets up a list environment in
HTML. Unlike a lot of other components here, it takes two rigid
arguments, and not just parameters which get passed to HTML and maybe
noticed by the layout manager.

	$l=list($numbered, $delimited);
	$l->insert("first element");
	$l->insert(text("second element",bold=>undef));
	$l->insert(link($url,"third element"));



=item C<pre>

Sets up a preformatted environment in HTML.  Just give it some text;
it prints it out raw.

=item C<script>

Sets up an appropriate environment for a script.  Put the script in
the window if you want it to appear in the preamble; otherwise it will
appear whereever you call it in the table.

=head2

NOTE there are other classes... see the source for now to find these.

=head1 BUGS

See comments in code, particular TODO in TLCore.pm

=head1 AUTHOR

Stephen Farrell <stephen@farrell.org>--feel free to write email with
any questions.

=cut

package HTML::TableLayout;

$HTML::TableLayout::VERSION = 1.001008;

use HTML::TableLayout::Symbols;

use HTML::TableLayout::TLCore;

use HTML::TableLayout::Component;

use HTML::TableLayout::Form;

use Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
			parameters
			window
			win_header
			table
			cell
			cell_header
			script
	                text
	                image
			link
			list
			pre
			comment
			hrule
			container
			font
	   );
@EXPORT_OK=qw(
			form
			choice
			button
			checkbox
			textarea
			hidden
			faux
			input_text
			password
			submit
			radio
	      );

%EXPORT_TAGS=(FORM=>
	      [qw(
			form
			choice
			button
			checkbox
			textarea
			hidden
			faux
			input_text
			password
			submit
			radio
	       )]);




