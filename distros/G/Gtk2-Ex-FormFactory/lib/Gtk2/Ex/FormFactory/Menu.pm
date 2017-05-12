package Gtk2::Ex::FormFactory::Menu;

use strict;

use base qw( Gtk2::Ex::FormFactory::Container );

sub get_type { "menu" }

sub get_menu_tree		{ shift->{menu_tree}			}
sub get_default_callback	{ shift->{default_callback}		}
sub get_user_data		{ shift->{user_data}			}
sub get_gtk_simple_menu		{ shift->{gtk_simple_menu}		}

sub set_menu_tree		{ shift->{menu_tree}		= $_[1]	}
sub set_default_callback	{ shift->{default_callback}	= $_[1]	}
sub set_user_data		{ shift->{user_data}		= $_[1]	}
sub set_gtk_simple_menu		{ shift->{gtk_simple_menu}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($menu_tree, $default_callback, $user_data) =
	@par{'menu_tree','default_callback','user_data'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_menu_tree($menu_tree);
	$self->set_default_callback($default_callback);
	$self->set_user_data($user_data);

	if ( $self->get_object eq '' ) {
		$self->set_object("__dummy");
	}

	return $self;
}

sub cleanup {
	my $self = shift;
	
	$self->SUPER::cleanup(@_);
	$self->set_gtk_simple_menu(undef);

	1;
}

sub build {
	my $self = shift;
	
	$self->SUPER::build(@_);

	$self->build_active_menu_items (
		$self->get_menu_tree, "",
	);
	
	1;
}

sub build_active_menu_items {
	my $self = shift;
	my ($menu_tree, $path) = @_;
	
	my $i = 0;
	my ($name, $def);
	while ( $i < @{$menu_tree} ) {
		$name = $menu_tree->[$i];
		$def  = $menu_tree->[$i+1];
		$name =~ s/_//g;

		if ( $def->{item_type} eq '<Branch>' ) {
			$self->build_active_menu_items (
				$def->{children},
				"$path/$name",
			);
		}

		if ( $def->{object} || $def->{active_cond} ) {
                        my $menu_item = Gtk2::Ex::FormFactory::MenuItem->new (
                            object          => $def->{object},
                            active_cond     => $def->{active_cond},
                            active_depends  => $def->{active_depends},
                        );
                        $menu_item->set_form_factory($self->get_form_factory);
                        $menu_item->set_gtk_widget(
                            $self->get_gtk_simple_menu
                                 ->get_widget("$path/$name")
                        );
                        push @{$self->get_content}, $menu_item;
		}

		$i += 2;
	}
	
	1;
}

package Gtk2::Ex::FormFactory::MenuItem;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type     { "menu_item" }
sub build_widget { 1 }

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Menu - A Menu in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Menu->new (
    menu_tree        => Hierarchical definition of the Menu,
    default_callback => Default callback for menu items,
    user_data        => User data for the default callback,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a Menu in a Gtk2::Ex::FormFactory framework and
pretty much wraps Gtk2::Ex::Simple::Menu. No application object attributes
are associated with a Menu as a whole.

But you may associate single Menu entries with an object. This way the
correspondent entries will set insensitive automatically if the
underlying object is undef and vice versa are activated once the object
is defined.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Menu

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after the associated FormFactory
was built.

=over 4

=item B<menu_tree> = ARRAYREF [mandatory]

This is a slightly extended menu tree definition in terms of
Gtk2::Ex::Simple::Menu. You may optionally associate each
entry with an application object by specifying its name with
the B<object> key in the item definition hash. This way the
item is active only if the correspondent object is defined.

As well you can control widget activity more detailed using the 
B<active_cond> and B<active_depends> keys as described in the
Gtk2::Ex::FormFactory::Widget manpage.

A short example. This is a File menu where the 'Save' and 'Close'
entries are sensitive only if a file was opened. We presume
that opening a file sets the 'worksheet' object, which is registered
with this name to the Context of the associated FormFactory.
Additionally the 'Manage rows' entry is active only if more than
three rows are selected:


  $menu_tree = [
    _File => {
      item_type => <Branch>',
      children  => [
        _Open  => {
	  callback => \&open_worksheet,
	              # sets the 'worksheet' object
	},
	_Save => {
	  callback => \&save_worksheet,
	  object   => 'worksheet',
	},
	_Close => {
	  callback => \&close_worksheet,
	  object   => 'worksheet',
	},
        "_Manage rows" => {
          callback       => \&manage_rows,
          object         => 'worksheet',
          active_cond    => sub { $worksheet->get_selected_rows_cnt > 3 },
          active_depends => "worksheet.rows",
      ],
    },
  ];

=item B<default_callback> = CODEREF [optional]

The default callback of this menu. Refer to Gtk2::Ex::Simple::Menu
for details.

=item B<user_data> = SCALAR [optional]

User data of the default callback of this menu. Refer to
Gtk2::Ex::Simple::Menu for details.

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

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
