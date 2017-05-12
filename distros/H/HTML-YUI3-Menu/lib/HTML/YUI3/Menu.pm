package HTML::YUI3::Menu;

use strict;
use warnings;

use Hash::FieldHash ':all';

use Text::Xslate 'mark_raw';

fieldhash my %horizontal    => 'horizontal';
fieldhash my %id            => 'id';
fieldhash my %js            => 'js';
fieldhash my %menu          => 'menu';
fieldhash my %menu_buttons  => 'menu_buttons';
fieldhash my %split_buttons => 'split_buttons';
fieldhash my %switch_js     => 'switch_js';
fieldhash my %template_path => 'template_path';
fieldhash my %tree          => 'tree';

our $VERSION = '1.01';

# -----------------------------------------------
# Note: This is a function, not a method.

sub build_js_names
{
	my($node, $opt) = @_;
	my($url)        = ${$node -> attribute}{url};

	if ($url)
	{
		my($s)            = $url;
		$s                =~ s|^/||;
		$s                =~ s|([a-z])([A-Z]+?)|$1_\l$2|g;
		$$opt{name}{$url} = lc $s;
	}

	# Keep processing.

	return 1;

} # End of build_js_names.

# -----------------------------------------------

sub build_switch_statement
{
	my($self, $templater) = @_;
	my($opt) =
	{
		callback => \&build_js_names,
		name     => {},
	};

	$self -> tree -> walk_down($opt);

	return
		mark_raw
		(
		 $templater -> render
		 (
		  'switch.statement.tx',
		  {
			  entry => [map{ {name => mark_raw($$opt{name}{$_}), url => mark_raw($_)} } sort keys %{$$opt{name} }],
		  }
		 )
		);

} # End of build_switch_statement.

# -----------------------------------------------

sub init
{
	my($self, $arg)      = @_;
	$$arg{horizontal}    ||= 0;
	$$arg{id}            ||= 'menu_1';
	$$arg{js}            = '';
	$$arg{menu}          = '';
	$$arg{menu_buttons}  ||= 0;
	$$arg{split_buttons} ||= 0;
	$$arg{switch_js}     ||= 0;
	$$arg{template_path} ||= '';
	$$arg{tree}          ||= '';

	if ($$arg{menu_buttons} && $$arg{split_buttons})
	{
		$$arg{menu_buttons} = 0;
	}

	return from_hash($self, $arg);

} # End of init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
    my($self)        = bless {}, $class;

	if (! $arg{tree} -> isa('Tree::DAG_Node') )
	{
		die __PACKAGE__ . '.new(): tree parameter must be of type Tree::DAG_Node';
	}

    return $self -> init(\%arg);

}	# End of new.

# -----------------------------------------------

sub render
{
	my($self, $node, $opt) = @_;
	my(@daughter) = $node -> daughters;
	my($entry)    = '';

	if ($#daughter >= 0)
	{
		# Process submenu.

		my(@entry);
		my(@grand_daughters);
		my($id);

		for my $child (@daughter)
		{
			@grand_daughters = $child -> daughters;

			if ($#grand_daughters < 0)
			{
				$$opt{depth}++;
				push @entry, $self -> render($child, $opt);
				$$opt{depth}--;
			}
			else
			{
				$$opt{depth}++;

				if ($$opt{split_buttons})
				{
					$id = sprintf('split_buttons_%i', ++$$opt{split_buttons_count});

					push @entry, $$opt{templater} -> render
						(
						 'split.buttons.tx',
						 {
							 id     => $id,
							 items  => mark_raw($self -> render($child, $opt) ),
							 text   => $child -> name,
							 toggle => $id,
							 url    => ${$child -> attribute}{url},
						 }
						);
				}
				else
				{
					$id = sprintf('submenu_%i', ++$$opt{submenu_count});

					push @entry, $$opt{templater} -> render
						(
						 'submenu.tx',
						 {
							 id    => $id,
							 items => mark_raw($self -> render($child, $opt) ),
							 label => $child -> name,
						 }
						);
				}

				$$opt{depth}--;
			}
		}

		$entry = join('', @entry);
	}
	else
	{
		# Process item.

		$entry = $$opt{templater} -> render
			(
			 'item.tx',
			 {
				 entry => [{text => $node -> name, url => ${$node -> attribute}{url} }],
			 }
			);
	}

	return $entry;

} # End of render.

# -----------------------------------------------

sub run
{
	my($self) = @_;
	my($opt)  =
	{
		depth               => 0,
		split_buttons       => $self -> split_buttons,
		split_buttons_count => 0,
		submenu_count       => 0,
		templater           => Text::Xslate -> new
			(
			 input_layer => '',
			 path        => $self -> template_path,
			),
	};

	$self -> menu
		(
		 $$opt{templater} -> render
		 (
		  'menu.tx',
		  {
			  entries      => mark_raw($self -> render($self -> tree, $opt) ),
			  horizontal   => $self -> horizontal ? ' yui3-menu-horizontal' : '',
			  id           => $self -> id,
			  menu_buttons => $self -> menu_buttons ? ' yui3-menubuttonnav' : $self -> split_buttons ? ' yui3-splitbuttonnav' : '',
		  }
		 )
		);

	$self -> js
		(
		 $$opt{templater} -> render
		 (
		  'yui.js.tx',
		  {
			  id               => $self -> id,
			  switch_statement => $self -> switch_js ? $self -> build_switch_statement($$opt{templater}) : '',
		  }
		 )
		);

} # End of run.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<HTML::YUI3::Menu> - Convert a Tree::DAG_Node object into the HTML and JS for a YUI3 menu

=head1 Synopsis

Get a tree of type L<Tree::DAG_Node> from somewhere, and convert it into HTML.

This program is shipped as scripts/generate.html.pl.

All programs in scripts/ are described below, under L</Testing this module>.

	#!/usr/bin/env perl
	
	use strict;
	use warnings;
	
	use DBI;
	
	use HTML::YUI3::Menu;
	use HTML::YUI3::Menu::Util::Config;
	
	use Tree::DAG_Node::Persist;
	
	# --------------------------
	
	my($dbh)    = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
	my($driver) = Tree::DAG_Node::Persist -> new
	(
	 context    => 'HTML::YUI3::Menu',
	 dbh        => $dbh,
	 table_name => 'items',
	);
	
	my($tree)   = $driver -> read(['url']);
	my($config) = HTML::YUI3::Menu::Util::Config -> new -> config;
	my($yui)    = HTML::YUI3::Menu -> new
		(
		 horizontal    => 1,
		 menu_buttons  => 0,
		 split_buttons => 0,
		 switch_js     => 1,
		 template_path => $$config{template_path},
		 tree          => $tree,
		);
	
	$yui -> run;

	my($menu) = $yui -> menu;
	my($js)   = $yui -> js;

=head1 Description

L<HTML::YUI3::Menu> converts a tree of type L<Tree::DAG_Node> into the HTML and JS for a YUI3 menu.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installing the module

=head2 The Module Itself

Install L<HTML::YUI3::Menu> as you would for any C<Perl> module:

Run:

	cpanm HTML::YUI3::Menu

or run:

	sudo cpan HTML::YUI3::Menu

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head2 The Configuration File

All that remains is to tell L<HTML::YUI3::Menu> your values for some options.

For that, see config/.hthtml.yui3.menu.conf.

If you are using Build.PL, running Build (without parameters) will run scripts/copy.config.pl,
as explained next.

If you are using Makefile.PL, running make (without parameters) will also run scripts/copy.config.pl.

Either way, before editing the config file, ensure you run scripts/copy.config.pl. It will copy
the config file using L<File::HomeDir>, to a directory where the run-time code in
L<HTML::YUI3::Menu> will look for it.

	shell>cd HTML-YUI3-Menu-1.00
	shell>perl scripts/copy.config.pl

Under Debian, this directory will be $HOME/.perl/HTML-YUI3-Menu/. When you
run copy.config.pl, it will report where it has copied the config file to.

Check the docs for L<File::HomeDir> to see what your operating system returns for a
call to my_dist_config().

The point of this is that after the module is installed, the config file will be
easily accessible and editable without needing permission to write to the directory
structure in which modules are stored.

That's why L<File::HomeDir> and L<Path::Class> are pre-requisites for this module.

All modules which ship with their own config file are advised to use the same mechanism
for storing such files.

=head1 Constructor and Initialization

C<new()> is called as C<< my($builder) = HTML::YUI3::Menu -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<HTML::YUI3::Menu>.

Key-value pairs in accepted in the parameter list (see corresponding methods for details):

=over 4

=item o horizontal => $Boolean

=item o menu_buttons => $Boolean

=item o split_buttons => $Boolean

=item o switch_js => $Boolean

=item o template_path => $path

=item o tree => $tree

=back

=head1 Methods

=head2 horizontal($Boolean)

Set the option to make menus vertical (0) or horizontal (1).

Note: At the moment, you I<must always> set this to 1.

The default is 0.

This option is mandatory.

=head2 js()

Returns the Javascript generated by the call to run().

The return value does I<not> include a <script ...> ... </script> container.

This JS should be output just before the </body> tag.

=head2 menu()

Returns the HTML generated by the call to run().

The HTML will probably be output just after the <body> tag.

=head2 menu_buttons($Boolean)

Set the option to make menu items text (0) or buttons (1).

The default is 0.

Note: See split_buttons() for what happens when you try to set both
menu_buttons(1) and split_buttons(1).

See the L</FAQ> for details.

=head2 run()

Generate the HTML and JS.

=head2 split_buttons($Boolean)

Set the option to make menu buttons normal (0) or split (1).

The default is 0.

See the L</FAQ> for details.

In the constructor, if you specify both menu_buttons => 1 and split_buttons => 1,
menu_buttons is forced to be 0, so you get split buttons.

However, if you call these methods after creating the object, and wish to set split_buttons
to 1, you must also explicitly set menu_buttons to 0, otherwise the output will be not as
expected.

=head2 switch_js($Boolean)

Skip (0) or add (1) the contents of switch.statement.tx into the generated Javascript.

The default is 0.

Using 0 means you want a request to be sent to the url (if any) of each menu item
when the user clicks that item.

Using 1 means you want the url to be disabled. In this case, the urls are used to generate
a set of Javascript function names, and when the user clicks on a menu item, the corresponding
function is executed. That could, for instance, set up an Ajax request to the server.

You must write the code for these Javascript functions, and include them (preferably) in the
<head> part of the web page.

See the L</FAQ> for details.

=head2 template_path($path)

Set the path to the Text::Xslate templates.

These templates are shipped in htdocs/assets/templates/html/yui3/menu/.

See L</Testing this module> for instructions on installing them, and the L</FAQ> for
a discussion on the template_path option in the config file.

The default is ''.

It is mandatory to use new(template_path => $a_path) or template_path($a_path) before calling run().

=head2 tree($tree)

Set the L<Tree::DAG_Node> object holding the menu.

This option is mandatory.

=head1 Testing this module

	# 1: Prepare to use Postgres, or whatever.
	DBI_DSN=dbi:Pg:dbname=menus
	export DBI_DSN
	DBI_USER=me
	export DBI_USER
	DBI_PASS=seekret
	export DBI_PASS

	# 2 Somehow create a new, empty database called 'menus'.

	# 3: Install:
	cpanm Tree::DAG_Node::Persist

	# 4: Create a suitable table 'items' in the 'menus' database,
	# giving it an extra column called 'url'.
	# create.table.pl also ships with Tree::DAG_Node::Persist V 1.03.
	scripts/create.table.pl -e "url:varchar(255)" -t items

	# 5: Generate a menu and store it in the database,
	# using Tree::DAG_Node and Tree::DAG_Node::Persist.
	scripts/generate.menu.pl

	# 6: If desired, plot the menu.
	# Install graphviz: http://www.graphviz.org/.
	# Install the Perl interface.
	# $DR represents your web server's doc root.
	cpanm GraphViz
	scripts/plot.menu.pl > $DR/menu.svg

	# 7: Install this module.
	cpanm HTML::YUI3::Menu

	# 8: Copy the config file to ~/.perl/HTML-YUI3-Menu.
	# You'll need to download the distro to do this.
	scripts/copy.config.pl

	# 9: Edit ~/.perl/HTML-YUI3-Menu/.hthtml.yui3.menu.config as desired.

	# 10: Install YUI3's yui-min.js to the directory under your web server's
	# doc root, as you've specified in the config file.
	# Download from http://developer.yahoo.com/yui/3/.
	cp yui-min.js $DR/assets/js/yui3

	# 11: Copy the templates shipped with this module to a directory under
	# your doc root, also as you've specified in the config file.
	cp -r htdocs/assets/* $DR/assets

	# 11: Generate the HTML.
	perl scripts/generate.html.pl > $DR/menu.html

	# 12: Experiment with options.
	# Edit scripts/generate.html.pl to set either menu_buttons => 1
	# or split_buttons => 1.
	perl scripts/generate.html.pl > $DR/menu.html

=head1 FAQ

=over 4

=item o What is YUI?

A Javascript library. YUI stands for the Yahoo User Interface. See L<http://developer.yahoo.com/yui/3/>.

=item o How do I create the tree?

Use L<Tree::DAG_Node> and give each node in the tree, i.e. each menu item, a name and, optionally, a url.

The name is set by $node -> name($name) and the url is set by ${$node -> attribute}{url}.

If you wish, save the menu to a database using L<Tree::DAG_Node::Persist>.

See scripts/generate.menu.pl.

=item o What is a split button?

With YUI3, menu items can be of 3 types:

A menu item which is text is just the text.

A menu item which is a button has a down arrow and a vertical bar on the right side (of the text), separating it from the next button.

A menu item which is a split button has a vertical bar on its right, a down arrow, and another vertical bar.

The down arrows indicate submenus.

=item o Are urls mandatory?

No. Any menu item will be ok without a url.

=item o Can menu buttons have their own urls?

Yes, but they don't have to have them.

For menu items which don't have submenus, the item is useless if it does not have a url.

But see the next question.

=item o What are name and url?

The node name appears as the text in the menu.

The url is used in a href, so that when the user clicks that menu item, the web client sends a request to that url.

At least, that's true for text items and split button items.

There is complexity in the behaviour of menu buttons 'v' split buttons.

With menu buttons, the url is not used, since the href must point to the submenu. That's part of the design of YUI3.

Split buttons can have their own url, and for both menu buttons and split buttons, each submenu item can have its own url.

=item o What is switch_js?

If you wish to stop the user's click on a menu item actually doing a submit to the url, you can set switch_js => 1,
and this module makes various changes to the generated HTML, as described above.

See the next 2 questions.

=item o How are urls converted into Javascript function names?

Some examples: '/Build' becomes build(), and '/UpdateVersionNumber' becomes update_version_number().

=item o What is switch.statement.tx?

This module will fabricate a switch statement, using switch.statement.tx, and insert the Javascript into
yui.js.tx, for output just before the </body> tag.

The generated switch statement will look like:

	menu.on("click", function(e)
	{
		e.preventDefault();
		switch (e.target.getAttribute('href') )
		{
		case "/Build":
			build();
			break;
		// Etc, down to...
		case "/UpdateVersionNumber":
			update_version_number();
			break;
		default:
			break;
		}
	});

So, clicking on a menu item calls the Javascript funtion, which you write and put in the <head> of the web page.

=item o What goes into the config file?

A sample config file is shipped as config/.hthtml.yui3.menu.conf.

=item o In the config file, why is template_path so long?

My doc root is L<Debian|http://www.debian.org/>'s RAM disk, /dev/shm/, and within that a directory html/.

Under that directory, all my modules use /assets/templates/..., where the ... comes from
the name of the module.

So, L<HTML::YUI3::Menu> will become html/yui3/menu/. Hence the template path is:
/dev/shm/html/assets/templates/html/yui3/menu/.

For other modules, beside templates/ there would be css/ or js/, depending on what ships with
each module.

=item o Why is the default for horizontal 0 when every program has to set it to 1?

Because when that code is working, all defaults will be 0, which is much less confusing.

=item o Is there any sample code?

Yes, see L</Testing this module>.

=item o What is scripts/copy.config.pl?

After this module is installed, you will probably need to edit the config file.

But before editing it, use copy.config.pl to copy it from config/ to ~/.perl/HTML-YUI3-Menu/.

Check the docs for L<File::HomeDir> to see what your operating system returns for a
call to my_dist_config().

The point of this is that after the module is installed, the config file will be
easily accessible and editable without needing permission to write to the directory
structure in which modules are stored.

That's why L<File::HomeDir> and L<Path::Class> are pre-requisites for this module.

All modules which ship with their own config file are advised to use the same mechanism
for storing such files.

=back

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-YUI3-Menu>.

=head1 Author

L<HTML::YUI3::Menu> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
