package Gtk2::Ex::ComboBox;

our $VERSION = '0.07';

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2::Ex::Simple::List;
use Gtk2::Ex::PopupWindow;
use Carp;
use Data::Dumper;

sub new {
	my ($class, $parent, $type) = @_;
	my $self  = {};
	bless ($self, $class);
	my $slist = Gtk2::Ex::Simple::List->new (
		'flag'		=> 'bool',
		''			=> 'text',
	);
	$self->{slist} = $slist;
	$self->{type} = $type;	
	my $popup = Gtk2::Ex::PopupWindow->new($parent);
	$self->{popup} = $popup;
	$self->{signals} = undef;
	my $frame = Gtk2::Frame->new;
	$type = 'with-buttons' unless $type;
	unless ($type eq 'with-buttons' or $type eq 'with-checkbox' or $type eq 'no-checkbox') {
		carp "Error: Expecting 'with-buttons' or 'with-checkbox'. Got $type\n";
		$type = 'with-buttons'; #default
	}
	if ($type eq 'with-buttons') {
		my $vbox = $self->_make_selectable;
		$frame->add($vbox);
	} elsif ($type eq 'with-checkbox') {
		my $vbox = $self->_make_checkable;
		$frame->add($vbox);
	} elsif ($type eq 'no-checkbox') {
		my $scrolledwindow = Gtk2::ScrolledWindow->new;
		$scrolledwindow->set_policy('automatic', 'automatic');
		$scrolledwindow->add($slist);
		$frame->add($scrolledwindow);
		$slist->get_selection->signal_connect ('changed' =>
			sub {
				my @sel = $slist->get_selected_indices;
				foreach my $line (@{$slist->{data}}) {
					$line->[0] = FALSE;
				}
				foreach my $x (@sel) {
					$slist->{data}->[$x]->[0] = TRUE;
				}
			}
		);
	}
	$popup->{window}->add($frame);
	$popup->{window}->set_default_size(200, 200);
	return $self;
}

sub signal_connect {
	my ($self, $signal, $callback) = @_;
	$self->{signals}->{$signal} = $callback;
	my $slist = $self->{slist};
	my $type = $self->{type};
	if ( $type eq 'with-buttons' or $type eq 'with-checkbox') {
		$slist->get_model()->signal_connect ('row-changed' =>
			sub {
				&{ $self->{signals}->{'changed'} };
			}
		);
	} elsif ( $type eq 'no-checkbox' ) {
		$slist->get_selection->signal_connect ('changed' =>
			sub {
				&{ $self->{signals}->{'changed'} };
			}
		);
	}
}

sub get_treeview {
	my ($self) = @_;
	return $self->{slist};
}

sub get_selected_values{
	my ($self) = @_;
	my $slist = $self->{slist};
	my @selectedvalues;
	my @unselectedvalues;
	foreach my $x (@{$slist->{data}}) {
		push @selectedvalues, $x->[1] if $x->[0];
		push @unselectedvalues, $x->[1] if !$x->[0];
	}
	return { 'selected-values' => \@selectedvalues, 'unselected-values' => \@unselectedvalues };
}

sub get_selected_indices{
	my ($self) = @_;
	my $slist = $self->{slist};
	my @selectedindices;
	my @unselectedindices;
	my $i = 0;
	foreach my $x (@{$slist->{data}}) {
		push @selectedindices, $i if $x->[0];
		push @unselectedindices, $i if !$x->[0];
		$i++;
	}
	return { 'selected-indices' => \@selectedindices, 'unselected-indices' => \@unselectedindices };
}

sub set_list_preselected {
	my ($self, $list) = @_;
	my $slist = $self->{slist};
	@{$slist->{data}} = @$list;
	if ($self->{type} eq 'no-checkbox') {
		$slist->set_headers_visible(FALSE);
		$slist->get_column(0)->set_visible(FALSE);
		$slist->get_selection->set_mode ('multiple');
		my $i = 0;
		foreach my $x (@$list) {		
			$slist->select($i) if $x->[0];
			$i++;
		}
	}
	return 0;
}

sub set_list {
	my ($self, $list) = @_;
	my @temp;
	foreach my $x (@$list) {
		push @temp, [0, $x];
	}
	$self->set_list_preselected(\@temp);
	return 0;
}

sub show {
	my ($self) = @_;
	$self->{popup}->show;
}

sub hide {
	my ($self) = @_;
	$self->{popup}->hide;
}

sub _make_selectable {
	my ($self) = @_;
	my $slist = $self->{slist};
	$slist->set_headers_visible(FALSE);
	my $label = Gtk2::Label->new('Select');
	my $allbutton = Gtk2::Button->new_from_stock('Select All');
	my $nonebutton = Gtk2::Button->new_from_stock('Select None');
	my $okbutton = Gtk2::Button->new_from_stock('gtk-ok');
	$allbutton->signal_connect ('button-release-event' => 
		sub {
			foreach my $line (@{$slist->{data}}) {
				$line->[0] = TRUE;
			}
		}
	);
	$nonebutton->signal_connect ('button-release-event' => 
		sub {
			foreach my $line (@{$slist->{data}}) {
				$line->[0] = FALSE;
			}
		}
	);
	$okbutton->signal_connect ('button-release-event' => 
		sub {
			$self->{popup}->hide;
		}
	);
	
	my $scrolledwindow = Gtk2::ScrolledWindow->new;
	$scrolledwindow->set_policy('automatic', 'automatic');
	$scrolledwindow->add($slist);
	my $hbox = Gtk2::HBox->new (TRUE, 0);
	$hbox->pack_start ($allbutton, FALSE, TRUE, 0);    
	$hbox->pack_start ($nonebutton, FALSE, TRUE, 0);    
	my $vbox = Gtk2::VBox->new (FALSE, 0);
	$vbox->pack_start ($hbox, FALSE, TRUE, 0);
	$vbox->pack_start ($scrolledwindow, TRUE, TRUE, 0);
	$vbox->pack_start ($okbutton, FALSE, TRUE, 0);
	return $vbox;
}

sub _make_checkable {
	my ($self) = @_;
	my $slist = $self->{slist};
	# Add a checkbutton to select all
	$slist->set_headers_clickable(TRUE);
	my $col = $slist->get_column(0);


	my $check = Gtk2::CheckButton->new;
	$col->set_widget($check);
	$check->set_active(TRUE);
	$check->show;  # very important, show_all doesn't get this widget!
	my $button = $col->get_widget; # not a button
	do {
		$button = $button->get_parent;
	} until ($button->isa ('Gtk2::Button'));
	
	$button->signal_connect (button_release_event => 
		sub {
			if ($check->get_active()) {
				$check->set_active(FALSE);
			} else {
				$check->set_active(TRUE);
			}
		}
	);
	$check->signal_connect (toggled => 
		sub {
			my $flag = 0;
			$flag = 1 if $check->get_active();
			foreach my $line (@{$slist->{data}}) {
				$line->[0] = $flag;
			}
		}
	);
	my $scrolledwindow = Gtk2::ScrolledWindow->new;
	$scrolledwindow->set_policy('automatic', 'automatic');
	$scrolledwindow->add($slist);
	return $scrolledwindow;
}

1;

__END__

=head1 NAME

Gtk2::Ex::ComboBox - A simple ComboBox with multiple selection capabilities.


=head1 DESCRIPTION

The Gtk2::ComboBox widget allows the user to select only one of the 
several drop down options. But if your application requires multiple selection
capability in the ComboBox, then try this widget instead.

This widget also serves as an example implementation using the Gtk2::Ex::PopupWindow
module.

=head1 SYNOPSIS

	use Glib qw(TRUE FALSE);
	use Gtk2 qw/-init/;
	use Gtk2::Ex::ComboBox;

	my $button = Gtk2::Button->new('click me');
	my $combobox = Gtk2::Ex::ComboBox->new($button);
	# Or you can call the constructor with two arguments
	# my $combobox = Gtk2::Ex::ComboBox->new($button, 'no-checkbox' );
	$combobox->set_list(['this', 'that', 'what']);
	$button->signal_connect('button-release-event' => sub { $combobox->show; } );

=head1 METHODS

=head2 new($parent, <$type>);

The C<$parent> refers to the widget to which the ComboBox is attached.

The C<$type> parameter is optional. It can be of one of the three types

	'with-buttons' (this is the default option if none specified)
	'with-checkbox' 
	'no-checkbox'
	

These three types control the way the user selects the multiple entries.
Please refer to the C<examples/combobox.pl> for a demonstration.

=head2 set_list([$list]);

The list of choices is entered using this method. Accepts an array (of strings)
as the argument.

	$combobox->set_list(['this', 'that', 'what']);

=head2 set_list_preselected([$list]);

The list of choices is entered using this method. Accepts an array of arrays
as the argument. Each element array should have a boolean and a string.
The boolean denotes whether this element should be marked as selected or not.

	$combobox->set_list([[0,'this'], [1,'that'], [1,'what']]);

In the example shown above, the elements C<'that'> and C<'what'> will be marked
as I<selected> in the dropdown list.

=head2 get_treeview;

Returns the treeview that serves as the model for the ComboBox. This widget
internally uses Gtk2::Ex::Simple::List and therefore the return object will
be of that class.

=head2 get_selected_values;

Returns a hash containing two lists.

C<$hash{'selected-values'}> contains a list of all the values that are marked
as I<selected>.

C<$hash{'unselected-values'}> contains a list of all the values that are B<not>
marked as I<selected>.

=head2 get_selected_indices;

Returns a hash containing two lists. 

C<$hash{'selected-indices'}> contains a list of all the indices that are marked
as I<selected>.

C<$hash{'unselected-indices'}> contains a list of all the indices that are B<not>
marked as I<selected>.

=head2 show;

Call this method to display the ComboBox. Typically on a C<'button-release-event'>
on the parent widget.

	$button->signal_connect('button-release-event' => sub { $combobox->show; } );

=head2 hide;

Call this method to hide the ComboBox. This method does not have to be called 
explicitly since the ComboBox is automatically closed if the user clicks anywhere
outside.

=head1 SIGNALS

C<changed> - This signal gets emitted whenever the selection is changed.

	$combobox1->signal_connect('changed' => 
		sub {
			print "combobox1 selection changed\n";
		}
	);

=head1 AUTHOR

Ofey Aikon

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list.

=head1 SEE ALSO

Gtk2::Ex::PopupWindow

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut
