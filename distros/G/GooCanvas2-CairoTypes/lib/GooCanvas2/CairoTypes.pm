use strict;
use warnings;
use Gtk3;
package GooCanvas2::CairoTypes;
our $VERSION = '0.001';
require XSLoader;
XSLoader::load();
1;
__END__
=pod

=head1 NAME

GooCanvas2::CairoTypes - Bridge between GooCanvas2 and Cairo types

=head1 SYNOPSIS

	use GooCanvas2;
	use GooCanvas2::CairoTypes;

	my $pattern = Cairo::SolidPattern->create_rgba(0, 0, 0, 0);
	my $rect = GooCanvas2::CanvasRect->new(
		...,
		'fill-pattern' => $pattern,  # fails without CairoTypes, just works with
	);

	# Sometimes (but not always, no idea why) this fails:
	$rect->get('fill-pattern')->set_filter('linear);
	# Here's the solution:
	GooCanvas2::CairoTypes::cairoize_pattern($rect->get('fill-pattern'))
		->set_filter('linear);

=head1 DESCRIPTION

There is an issue in the interaction between GooCanvas, GObject Introspection, Cairo, and their Perl bindings, which causes some functionality to be unusable from Perl side. This is better described L<here|https://stackoverflow.com/questions/64625955/cairosolidpattern-is-not-of-type-goocanvas2cairopattern>, and there was an L<attempt|https://gitlab.gnome.org/GNOME/goocanvas/-/merge_requests/9> to fix it upstream. Until it's fixed, this can serve as a workaround for it.

Currently this module only "fixes" C<Cairo::Pattern/GooCanvas2::CairoPattern> interop. For certain calls it just works if this module was included; for some other calls you need to explicitly convert the type.

If you have any idea how to fix those cases to not require such call, or need to bridge more types, L<pull requests|https://github.com/DarthGandalf/GooCanvas2-CairoTypes> are welcome!

=head1 AUTHOR

Alexey Sokolov, E<lt>sokolov@google.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Google

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
