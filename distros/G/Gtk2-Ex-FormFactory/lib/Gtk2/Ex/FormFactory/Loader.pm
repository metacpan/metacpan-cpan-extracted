package Gtk2::Ex::FormFactory::Loader;

use strict;

@Gtk2::Ex::FormFactory::Button::ISA		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::CheckButtonGroup::ISA	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::CheckButton::ISA	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Combo::ISA		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::DialogButtons::ISA	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Entry::ISA		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Expander::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::ExecFlow::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Form::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::GtkWidget::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::HBox::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::HSeparator::ISA 	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Image::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Label::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::List::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Menu::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Notebook::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Popup::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::ProgressBar::ISA 	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::RadioButton::ISA 	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Table::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::TextView::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Timestamp::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::ToggleButton::ISA 	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::VBox::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::VSeparator::ISA 	= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::VPaned::ISA 	        = qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::HPaned::ISA 	        = qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::Window::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );
@Gtk2::Ex::FormFactory::YesNo::ISA 		= qw( Gtk2::Ex::FormFactory::Loader );

sub new {
	my $class = shift;
	eval "use $class; shift \@$class:\:ISA";
	if ( $@ ) {
		print $@;
		exit;
	}
	return $class->new(@_);
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Loader - Dynamic loading of FormFactory modules

=head1 SYNOPSIS

No synposis, internally used by Gtk2::Ex::FormFactory.

=head1 DESCRIPTION

This class implements dynamic loading of Gtk2::Ex::FormFactory
widget classes and has no external interface.

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
