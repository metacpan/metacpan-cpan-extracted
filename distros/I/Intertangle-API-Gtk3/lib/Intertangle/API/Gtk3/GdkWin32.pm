use Renard::Incunabula::Common::Setup;
package Intertangle::API::Gtk3::GdkWin32;
# ABSTRACT: Load the GdkWin32 library
$Intertangle::API::Gtk3::GdkWin32::VERSION = '0.005';
use Glib::Object::Introspection;
use FFI::Platypus;
use FFI::CheckLib 0.06;

my $_GDKWIN32_BASENAME = 'GdkWin32';
my $_GDKWIN32_VERSION = '3.0';
my $_GDKWIN32_PACKAGE = __PACKAGE__;

my @_FLATTEN_ARRAY_REF_RETURN_FOR = qw/
/;

sub import {
	Glib::Object::Introspection->setup(
		basename => $_GDKWIN32_BASENAME,
		version  => $_GDKWIN32_VERSION,
		package  => $_GDKWIN32_PACKAGE,
		flatten_array_ref_return_for => \@_FLATTEN_ARRAY_REF_RETURN_FOR,
	);

	# Need to attach the `gdk_win32_window_get_handle` function.
	# See bug: The gdk_win32_window_get_handle of GdkWin32Window is not exposed to
	# introspection <https://gitlab.gnome.org/GNOME/gtk/issues/510>.
	my $ffi = FFI::Platypus->new;
	$ffi->lib(find_lib_or_die lib => 'gdk');
	# HGDIOBJ gdk_win32_window_get_handle (GdkWindow *window);
	$ffi->attach( gdk_win32_window_get_handle => [ 'opaque' ], 'opaque', sub {
		my ($xs, $gdk_window) = @_;
		Gtk3::Gdk::threads_enter();
		my $hwnd = $xs->( Glib::Object::get_pointer($gdk_window) );
		Gtk3::Gdk::threads_leave();
		return $hwnd;
	});
	# GdkWindow * gdk_win32_window_foreign_new_for_display (GdkDisplay *display, HWND anid)
	$ffi->attach(
		[ gdk_win32_window_foreign_new_for_display => __PACKAGE__ . '::Win32Window::foreign_new_for_display'  ]
		=> [ 'opaque', 'opaque' ], 'opaque', sub {
		my ($xs, $package, $gdk_display, $hwnd) = @_;
		Gtk3::Gdk::threads_enter();
		my $gdk_window = $xs->( Glib::Object::get_pointer($gdk_display), $hwnd );
		Gtk3::Gdk::threads_leave();
		return Gtk3::Gdk::Window->new_from_pointer($gdk_window);
	});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Gtk3::GdkWin32 - Load the GdkWin32 library

=head1 VERSION

version 0.005

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
