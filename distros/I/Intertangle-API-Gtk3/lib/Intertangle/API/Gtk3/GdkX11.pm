use Renard::Incunabula::Common::Setup;
package Intertangle::API::Gtk3::GdkX11;
# ABSTRACT: Load the GdkX11 library
$Intertangle::API::Gtk3::GdkX11::VERSION = '0.006';
use Glib::Object::Introspection;
use FFI::CheckLib 0.06;
use FFI::Platypus;

my $_GDKX11_BASENAME = 'GdkX11';
my $_GDKX11_VERSION = '3.0';
my $_GDKX11_PACKAGE = __PACKAGE__;

my @_FLATTEN_ARRAY_REF_RETURN_FOR = qw/
/;

my ($ffi_gdk, $ffi_x11);
sub import {
	Glib::Object::Introspection->setup(
		basename => $_GDKX11_BASENAME,
		version  => $_GDKX11_VERSION,
		package  => $_GDKX11_PACKAGE,
		flatten_array_ref_return_for => \@_FLATTEN_ARRAY_REF_RETURN_FOR,
	);

	local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /Subroutine \Q@{[ $_GDKX11_PACKAGE ]}\E.* redefined/ };

	$ffi_gdk ||= do {
		my $ffi = FFI::Platypus->new;

		$ffi->lib(find_lib_or_die lib => 'gdk-3');
		# Visual * gdk_x11_visual_get_xvisual (GdkVisual *visual)
		$ffi->attach( [ gdk_x11_visual_get_xvisual => __PACKAGE__ . '::X11Visual::get_xvisual' ] => [ 'opaque' ], 'opaque', sub {
			my ($xs, $gdk_visual) = @_;
			Gtk3::Gdk::threads_enter();
			my $visual = $xs->( Glib::Object::get_pointer($gdk_visual) );
			Gtk3::Gdk::threads_leave();
			return bless \$visual, __PACKAGE__ . '::Xlib::Visual';
		});
		# Screen * gdk_x11_screen_get_xscreen (GdkScreen *screen);
		$ffi->attach( [ gdk_x11_screen_get_xscreen => __PACKAGE__ . '::X11Screen::get_xscreen' ] => [ 'opaque' ], 'opaque', sub {
			my ($xs, $gdk_visual) = @_;
			Gtk3::Gdk::threads_enter();
			my $visual = $xs->( Glib::Object::get_pointer($gdk_visual) );
			Gtk3::Gdk::threads_leave();
			return bless \$visual, __PACKAGE__ . '::Xlib::Screen';
		});

		$ffi;
	};

	$ffi_x11 ||= do {
		my $ffi = FFI::Platypus->new;
		$ffi->lib(find_lib_or_die lib => 'X11');
		# VisualID XVisualIDFromVisual(Visual *visual)
		$ffi->attach( [ XVisualIDFromVisual => __PACKAGE__ . '::Xlib::Visual::xvisualid' ], [ 'opaque' ], 'uint32_t', sub {
			my ($xs, $visual) = @_;
			my $id = $xs->( $$visual );
			return $id;
		});
		# Visual *XDefaultVisualOfScreen( Screen* screen );
		$ffi->attach( [ XDefaultVisualOfScreen => __PACKAGE__ . '::Xlib::Screen::DefaultVisual' ], [ 'opaque' ], 'opaque', sub {
			my ($xs, $screen) = @_;
			my $visual = $xs->( $$screen );
			return bless \$visual, __PACKAGE__ . '::Xlib::Visual';
		});

		$ffi;
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Gtk3::GdkX11 - Load the GdkX11 library

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
