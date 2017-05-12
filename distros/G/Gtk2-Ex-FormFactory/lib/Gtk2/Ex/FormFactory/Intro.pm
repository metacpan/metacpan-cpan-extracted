1;
__END__

RFC Gtk2::Ex::FormFactory
-------------------------

=head1 NAME

Gtk2::Ex::FormFactory::Intro - Introduction into the FormFactory framework

=head1 DESCRIPTION

The Gtk2::Ex::FormFactory framework is for Perl Gtk2 developers who
(at least partially ;) agree with these statements:

=over 3

=item *

GUI programming is fun but often boring

=item *

A lot of tasks in GUI programming are similar and misleads
the lazy programmer to do too much Copy'n Paste

=item *

RAD tools like Glade are fine for small applications
but not if you want to have a consistent look and feel
in bigger and modular applications

=back

Gtk2::Ex::FormFactory tries to help you with these issues by

=over 3

=item *

Strictly separating GUI design, application logic
and data structures

=item *

Giving the developer a more declarative style of defining the
structure of your GUI

=item *

Giving the developer the possibility of definiting the design
of the GUI at a single spot in your program

=item *

Being lightweight and easy to learn.

=back

=head2 Enough buzzwords

Imagine you want to build a configuration dialog for your
application, which consists of a notebook, to distinguish several
topics, each containing a bunch of simpler widgets (in the
following example a single text entry). Also it should have
the usual Ok and Cancel buttons.

The straight approach often is to code all the stuff by hand
or "draw" all widgets using Glade. At any rate you need to
take care of:

=over 3

=item *

Consistent look and feel, e.g. labels should be bold and
properly aligned to the widgets; the widgets iteslf should
have some space around them, buttons should always be
aligned to the form above etc.

=item *

Initializing the widgets with the actual content of your
configuration data

=item *

Either connecting a lot of signals to track the changes the user
made. This would apply all changes straight to your internal
data structure, which may make implementing the Cancel button
difficult or impossible

=item *

Or grabbing all (changed) data from the widgets, when the
user hit the Ok button resp. simply close the window, when
the user hit the Cancel button

=back

That's a lot of stuff, which needs to be repeated for every
single dialog in your application. No fun anymore.

Gtk2::Ex::FormFactory will do the boring stuff for you.
That's how it works:

=head2 Register your objects to the Context

Create a Gtk2::Ex::FormFactory::Context object and register
all your objects, which should be presented/changed by the
GUI, here:
  
  my $context = Gtk2::Ex::FormFactory::Context->new;
  $context->add_object (
    name   => "config",
    object => $config_object
  );

$config_object has at least the following methods in
our example below:

  - get_data_dir()
  - get_selected_page()
  - set_data_dir()
  - set_selected_page()

The Context is a layer which encapsulates the methods of
accessing your object's attributes. Also the Context knows
about relationships between objects and/or their attributes,
so it's able to handle correspondent updates on the GUI side
automatically. We will discuss more details of
Gtk2::Ex::FormFactory::Context later in this document.

=head2 Define the structure of your GUI

Create Gtk2::Ex::FormFactory object and define the B<structure>
of your GUI. E.g, you want to have window which contains a
notebook, which consists of a few pages with a bunch of
text entries in them. This will look this way: [ very
compressed and evil nesting for this document - for bigger
dialogs you will break this into several pieces ]
  
  my $ff = Gtk2::Ex::FormFactory->new (
    context => $context,
    content => [
      Gtk2::Ex::FormFactory::Window->new(
	title   => "Preferences",
	content => [
	  Gtk2::Ex::FormFactory::Notebook->new (
            attr    => "config.selected_page",
	    content => [
	      Gtk2::Ex::FormFactory::VBox->new (
		title   => "Filesystem",
		content => [
		  Gtk2::Ex::FormFactory::Form->new (
		    content => [
		      Gtk2::Ex::FormFactory::Entry->new (
			attr   => "config.data_dir",
			label  => "Data Directory",
			tip    => "This directory takes all your files.",
			rules  => "writable-directory",
		      ),
		    ],
		  ),
		],
	      ),
            ],
	  );
	  Gtk2::Ex::FormFactory::DialogButtons->new
	],
      ),
    ],
  );
  
  $ff->open;	# actually build the GUI and open the window
  $ff->update;	# fill in the values from $config_object

So now you defined that you want to have a text entry,
which contains a valid writable directory name,
which should be inside a form on a notebook page. No details
about the exact layout yet, this is just the B<strucure>
of your dialog

=head2 But how is this rendered? 

For this task Gtk2::Ex::FormFactory
creates a Gtk2::Ex::FormFactory::Layout object which takes care of all
the rendering details. Gtk2::Ex::FormFactory has a default
implementation of this, but you can easily inherit from this module
to define your own layout (that's mainly for what all this is good
for!) and pass it to the FormFactory as the B<layouter>.

The Layout module mainly consists of two types of methods

=over 4

=item B<Methods for building a widget>

build_TYPE() methods for each FormFactory widget type
(Entry, SelectList, Popup, Foo etc.) you use in your dialog.
These have the Gtk2 code actually necessary to create
the corresponding Gtk2 widgets.

=item B<Methods for adding a widget to a container>

These are the so called add_WIDGET_to_CONTAINER() methods,
which specify how a
particular widget type is added to a particular container
type. E.g. they're responsible for consistent looking
labels beside widgets etc.
     
Because the details of adding a widget mainly depend
on the container the widget is added to, there are
generic methods for adding arbitrary widgets to a
container. If there is no specific method for a widget
type this generic method is called instead.

=back

=head2 Layout methods for our example

The Layout implementation needs the following methods,
to be able to generate a layout for our FormFactory defined above:

  build_window		 => creates a Gtk2::VBox in a Gtk2::Window    
  build_notebook	 => creates a Gtk2::Notebook		       
  build_form  		 => creates a Gtk2::Table (2 columns)         
  build_entry 		 => creates a Gtk2::Entry		       
  build_dialog_buttons   => creates a ButtonBox with Ok/Apply/Cancel  

  add_widget_to_form     => adds entry to table, label in 1st column  
  add_widget_to_notebook => adds form to notebook with tab title     	    
  add_widget_to_window	 => adds notebook and buttonbox to the window 

If you regularly code applications with Gtk2 you know, that none
of this tasks is rocket science. B<But> you have a lot of parameters
for each widget in question to take care of (simply think of the
border_width property which may lead to an ugly misaligned mess,
if you don't handle it really consistently)

Because you define this tasks at a B<single> point in your
program, it's really easy to create a consistently looking
application. Or to change the look quickly. E.g. you decide
to put a frame around all your forms? Just change B<one> method -
build_form() - and you're done!

=head2 Huh, a lot of new Widget classes to learn!

Not really. The FormFactory Widget classes are very simple and
mainly wrap correspondent Gtk2 widgets, so you don't need to
learn much more.

Using the builtin widgets is really easy. They all ship with
a manual page describing their specific attributes, which usualy
isn't much.

Also Gtk2::Ex::FormFactory has some nifty wrappers for really
inconvenient Gtk2 widgets, like Gtk2::Table. Take a look at
Gtk2::Ex::FormFactory::Table to learn how easy programming
complex table layouts can be. Or look at
Gtk2::Ex::FormFactory::Image which is a nice image widget
which resizes the image automatically in configurable ranges.

=head2 Building your own FormFactory widgets

If you need more widgets: implement them on your own.
Gtk2::Ex::FormFactory widget classes don't have much Gtk2 code
in them, they just define the properties, which represent this
particular form item and implement mainly the following methods:

=over 3

=item *

Define a short name for the type (e.g. "entry" for a Gtk2::Entry -
the Layout->add_X_to_Y() methods are derived from the short name)

=item *

Transfer the object's attribute value to the widget

=item *

Transfer the widget's value to the object's attribute

=item *

Connect the 'changed' signal for a synchronized dialog,
e.g. if you want to react immedately on user input

=back

What the widget and object "value" actually is (a scalar, hash,
array or complex structure) may be arbitrarly defined. How object
attributes are accessed, is defined in the Context module. Our
example uses the default set_foo(), get_foo() style accessors, but
there are more methods up to defining callbacks, which can do very
complex lookups.

=head2 Data consistency

Now we know that the FormFactory suite solve layout issues very
well. Another important feature is automatic data consistency
resp. keeping the GUI and your application data in sync.

Change an object attribute: the correspondent GUI widgets will
update automatically. The user entered data to a text entry:
the object attribute associated with this entry will automatically
get the new text.

Gtk2::Ex::FormFactory must know your application's objects very
well to do such a magic. That's what the Gtk2::Ex::FormFactory::Context
module is good for, mentioned shortly at the top of our example.

=head2 Abstraction from your application's objects

All your application objects are registered with a unique name
to the Context module. Each FormFactory has a reference to
this Context, so it know the objects which are registered.

When you register your object to the Context, you may specify
how attributes are accessed by setting prefixes for read/write
accessors.

You may even override methods inside the Context by specifying
correspondent closures, which are called instead of the original
method.

Also objects in terms of the Context module may be abstract things like
"The currently selected disc from the currently selected artist",
not only a simply hardwired object reference. This is done by
calling a closure returning the actual object instead of using
a hardwired object.

This way dependend widgets update automaticly, as soon as the
correspondent selection changes, e.g. updating a list of CD titles
when switching to another disc in an imaginary CD database program.

=head2 Widget consistency

Another challenge in a good GUI program is to make your widgets
consistent in terms of graying out widgets, which are not useful
in a particular state of your program.

Gtk2::Ex::FormFactory manages visibility and sensivity of your
widgets automatically for you once you registered the correspondent
dependencies at the Context. E.g. if there currently is no CD
album selected, the corresponding fields are greyed out automatically,
including the field labels.

=head2 Data validity

Gtk2::Ex::FormFactory specifies Gtk2::Ex::FormFactory::Rules,
which are checked against the values the user entered. These
conditions must apply, otherwise the old values are restored
automatically. A bunch of rules are shipped, but you can define
your own set by specifying a correspondent rule object or closures.

=head2 Extensibility

This framework was designed with extensibility in mind. You can

=over 3

=item *

Define your own FormFactory widgets, by simply using the base
class Gtk2::Ex::FormFactory::Widget resp.
Gtk2::Ex::FormFactory::Container. No matter how complex your
widget is as long as you provide correspondent object attribute
accessors, which transfer the widget's state to the object and
vice versa.

=item *

Define your own FormFactory Layout module, by deriving from the
default Layout implementation and passing a correspondent object
to the FormFactory constructor.

=item *

All items in your FormFactory have a name, which will be set by
default or to a value, you pass to the item's constructor.
This way your Layout implementation can even do very special
things for very special widgets, without the need of creating
an extra Widget module for this.

=item *

You can request any Gtk widget from a FormFactory widget by name
to do further manipulation, although you should consider doing
this inside your Layout implementation, to keep the "single point
of layout" rule.

=back

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
