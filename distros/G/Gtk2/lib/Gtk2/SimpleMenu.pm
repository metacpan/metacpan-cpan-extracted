#
# $Id$
#

package Gtk2::SimpleMenu;

use strict;
use warnings;
use Carp;
use Gtk2;

our @ISA = 'Gtk2::ItemFactory';

our $VERSION = 0.50;

sub new
{
	my $class = shift;
	my %opts = ( @_ );
	
	# create an accel group to pass to the item factory call, it's later
	# stored so that our owner can add the accel group to something
	my $accel_group = Gtk2::AccelGroup->new;
	
	# create the item factory providing a accel_group.
	my $self = Gtk2::ItemFactory->new('Gtk2::MenuBar', '<main>', $accel_group);

	# put the options into the simple item object
	foreach (keys %opts)
	{
		$self->{$_} = $opts{$_};
	}
	
	bless($self, $class);
	
	# convert our menu_tree into a set of entries for itemfactory
	$self->parse;
	# create the entries 
	foreach (@{$self->{entries}})
	{
		$self->create_item ($_, $_->[6] || $self->{user_data});
	}
	# store the widget so our owner can easily get to it
	$self->{widget} = $self->get_widget('<main>');
	# cache the accel_group so the user can add it to something,
	# the window, if they so choose
	$self->{accel_group} = $accel_group;

	delete $self->{entries} unless( $self->{keep_entries} );
	delete $self->{menu_tree} unless( $self->{keep_menu_tree} );

	return $self;
}


sub parse
{
	my $self = shift;

	our @entries = ();
	our @groups = ();
	our $default_callback = $self->{default_callback};

	# called below (for 'root' branch) and the recusively for each branch
	sub parse_level
	{
		my $path = shift;
		my $label = shift;
		my $itms = shift;
	
		# we need a type to test to prevent warnings,
		# just use one that will fall through to defaul
		$itms->{item_type} = ''
			unless( exists($itms->{item_type}) );

		if( $itms->{item_type} eq 'root' )
		{
			# special type for first call, doesn't add entry
			my $i = 0;
			for($i = 0; $i < scalar(@{$itms->{children}}); $i += 2)
			{
				parse_level ('/',
					$itms->{children}[$i],
					$itms->{children}[$i+1]);
			}
		}
		elsif( $itms->{item_type} =~ /Branch/ )
		{
			# add the branch item
			push @entries, [ $path.$label,
					 undef,
					 undef,
					 undef,
					 $itms->{item_type}, ];
			# remove mnemonics from path
			$label =~ s/_//g;
			# then for each of its children parse that level
			my $i = 0;
			for( $i = 0; $i < scalar(@{$itms->{children}}); $i += 2)
			{
				parse_level ($path.$label.'/',
					$itms->{children}[$i],
					$itms->{children}[$i+1]);
			}
		}
		elsif( $itms->{item_type} =~ /Radio/ )
		{
			# cache the groupid
			my $grp = $itms->{groupid};

			# add this radio item to the existing group, if one,
			# otherwise use item_type
			push @entries, [ $path.$label,
					 $itms->{accelerator},
					 (exists($itms->{callback}) ? 
						 $itms->{callback} : 
						 $default_callback ),
					 $itms->{callback_action},
					 (exists($groups[$grp]) ? 
						 $groups[$grp] :
						 $itms->{item_type}), 
					 $itms->{extra_data},
					 $itms->{callback_data} ];

			# create the group identifier (path)
			# so that next button in this group will
			# be added to existing group
			unless( exists($groups[$grp]) )
			{
				$groups[$grp] = $path.$label;
				$groups[$grp] =~ s/_//g;
			}
		}
		else
		{
			# everything else just gets created with its values
			push @entries, [ $path.$label,
					 $itms->{accelerator},
					 (exists($itms->{callback}) ? 
						 $itms->{callback} : 
						 $default_callback ),
					 $itms->{callback_action},
					 $itms->{item_type},
					 $itms->{extra_data}, 
					 $itms->{callback_data} ];
		}
	}

	# fake up a root branch with the menu_tree as it's children
	parse_level (undef, undef, { 
			item_type => 'root', 
			children => $self->{menu_tree} });

	# store the itemfactory entries array
	$self->{entries} = \@entries;
}

1;
__END__
# documentation is a good thing.

=head1 NAME

Gtk2::SimpleMenu - A simple interface to Gtk2's ItemFactory for creating
application menus

=head1 SYNOPSIS

  use Gtk2 '-init';
  use Gtk2::SimpleMenu;

  my $menu_tree = [
  	_File => {
		item_type => '<Branch>',
		children => [
			_New => {
				callback => \&new_cb,
				callback_action => 0,
				accelerator => '<ctrl>N',
			},
			_Save => {
				callback_action => 1,
				callback_data => 'per entry cbdata',
				accelerator => '<ctrl>S',
			},
			_Exec => {
				item_type => '<StockItem>',
				callback_action => 2,
				extra_data => 'gtk-execute',
			},
			_Quit => {
				callback => sub { Gtk2->main_quit; },
				callback_action => 3,
				accelerator => '<ctrl>Q',
			},
		],
	},
	_Mode => {
		_First => {
			item_type => '<RadioItem>',
			callback => \&mode_callback,
			callback_action => 4,
			groupid => 1,
		},
		_Second => {
			item_type => '<RadioItem>',
			callback => \&mode_callback,
			callback_action => 5,
			groupid => 1,
		},
		_Third => {
			item_type => '<RadioItem>',
			callback => \&mode_callback,
			callback_action => 6,
			groupid => 1,
		},
	}
	_Help => {
		children => [
			_Tearoff => {
				item_type => '<Tearoff>',
			},
			_CheckItem => {
				item_type => '<CheckItem>',
				callback_action => 7,
			},
			Separator => {
				item_type => '<Separator>',
			},
			_Contents => {
				callback_action => 8, 
			},
			_About => {
				callback_action => 9, 
			},
		]
	}
  ];

  my $menu = Gtk2::SimpleMenu->new (
  		menu_tree => $menu_tree,
		default_callback => \&default_callback,
		user_data => 'user_data',
	);

  # an example of how to get to the menuitems.
  $menu->get_widget('/File/Save')->activate;
	
  $container->add ($menu->{widget});

=head1 ABSTRACT

SimpleMenu is an interface for creating application menubars in as simple a
manner as possible. Its main benefit is that the menu is specified as a tree,
which is the natural representation of such a menu.

=head1 DESCRIPTION

SimpleMenu aims to simplify the design and management of a complex application
menu bar by allowing the structure to be specified as a multi-rooted tree. Much
the same functionality is provided by Gtk2::ItemFactory, but the data provided
as input is a 1-D array and the hierarchy of the menu is controlled entirely by
the path components. This is not ideal when languages such as Perl provide for
simple nested data structures.

Another advantage of the SimpleMenu widget is that it simplifies the creation
and use of accelerators.

SimpleMenu is a child of Gtk2::ItemFactory, so that it may be treated as such.
Any method that can be called on a ItemFactory can be called on a SimpleMenu.

=head1 OBJECT HIERARCHY

 Glib::Object
 +--- Gtk2::Object
      +--- Gtk2::ItemFactory
           +--- Gtk2::SimpleMenu

=head1 FUNCTIONS

=over

=item $menu = Gtk2::SimpleMenu->new (menu_tree => $menu_tree, ...)

Creates a new Gtk2::SimpleMenu object with the specified tree. Optionally key
value paris providing a default_callback and user_data can be provided as well.
After creating the menu object all of the subsequent widgets will have been
created and are ready for use.

=back

=head1 MEMBER VARIABLES

=over

=item $menu->{widget}

The Gtk2::MenuBar root of the SimpleMenu. This is what should be added to the
widget which will contain the SimpleMenu.

  $container->add ($menu->{widget});

=item $menu->{accel_group}

The Gtk2::AccellGroup created by the menu tree. Normally accell_group would be
added to the main window of an application, but this is only necessary if
accelerators are being used in the menu tree's items. 

  $win->add_accel_group ($menu->{accel_group});

=back

=head1 SEE ALSO

Perl(1), Glib(3pm), Gtk2(3pm), examples/simple_menu.pl.

Note: Gtk2::SimpleMenu is deprecated in favor of Gtk2::Ex::Simple::Menu, part of the Gtk2-Perl-Ex project at L<http://gtk2-perl-ex.sf.net/> .

=head1 AUTHORS

 Ross McFarland <rwmcfa1 at neces dot com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by the Gtk2-Perl team.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.

=cut
