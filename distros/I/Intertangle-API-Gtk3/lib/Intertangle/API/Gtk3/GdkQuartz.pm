use Renard::Incunabula::Common::Setup;
package Intertangle::API::Gtk3::GdkQuartz;
# ABSTRACT: Load the GdkQuartz library
$Intertangle::API::Gtk3::GdkQuartz::VERSION = '0.005';
use FFI::Platypus;
use FFI::CheckLib 0.06;

sub import {
	# Need to attach the `gdk_quartz_window_get_nsview` function.
	my $ffi = FFI::Platypus->new;

	$ffi->lib(find_lib_or_die lib => 'gdk-3');
	# NSView * gdk_quartz_window_get_nsview (GdkWindow *window)
	$ffi->attach( gdk_quartz_window_get_nsview => [ 'opaque' ], 'opaque', sub {
		my ($xs, $gdk_window) = @_;
		Gtk3::Gdk::threads_enter();
		my $view = $xs->( Glib::Object::get_pointer($gdk_window) );
		Gtk3::Gdk::threads_leave();
		return $view;
	});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Gtk3::GdkQuartz - Load the GdkQuartz library

=head1 VERSION

version 0.005

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
