use Renard::Incunabula::Common::Setup;
package Intertangle::API::Gtk3::WindowID;
# ABSTRACT: Module to help obtain the window ID
$Intertangle::API::Gtk3::WindowID::VERSION = '0.005';
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Module::Load;

method get_widget_id( (InstanceOf['Gtk3::Widget']) $widget ) {
	my $gdk_window = $widget->get_window;

	# Check both ISA because of loading of GIR happens after.
	if( $gdk_window->isa('Glib::Object::_Unregistered::GdkX11Window')
		|| $gdk_window->isa('Intertangle::API::Gtk3::GdkX11::X11Window')
	) {
		autoload 'Intertangle::API::Gtk3::GdkX11';
		return Intertangle::API::Gtk3::GdkX11::X11Window::get_xid( $gdk_window );
	} elsif( $gdk_window->isa('Glib::Object::_Unregistered::GdkWin32Window')
		|| $gdk_window->isa('Intertangle::API::Gtk3::GdkWin32::Win32Window')
	) {
		autoload 'Intertangle::API::Gtk3::GdkWin32';
		return Intertangle::API::Gtk3::GdkWin32::gdk_win32_window_get_handle( $gdk_window );
	} elsif( $gdk_window->isa('Glib::Object::_Unregistered::GdkQuartzWindow') ) {
		autoload 'Intertangle::API::Gtk3::GdkQuartz';
		return Intertangle::API::Gtk3::GdkQuartz::gdk_quartz_window_get_nsview( $gdk_window );
	} else {
		die "Unknown GdkWindow type: $gdk_window";
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Gtk3::WindowID - Module to help obtain the window ID

=head1 VERSION

version 0.005

=head1 METHODS

=head2 get_widget_id

  method get_widget_id( (InstanceOf['Gtk3::Widget']) $widget )

Retrieves platform-specific windows ID / handle which can be used for
re-parenting windows.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
