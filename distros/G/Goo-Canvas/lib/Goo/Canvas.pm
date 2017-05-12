package Goo::Canvas;
use Gtk2;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Goo::Canvas ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Goo::Canvas', $VERSION);

# FIXME: Why ancestor not added?
push @ISA, 'Gtk2::Container';

# Preloaded methods go here.

1;
__END__
# documents.

=head1 NAME

Goo::Canvas - Perl interface to the GooCanvas

=head1 SYNOPSIS

    use Goo::Canvas;
    use Gtk2 '-init';
    use Glib qw(TRUE FALSE);

    my $window = Gtk2::Window->new('toplevel');
    $window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
    $window->set_default_size(640, 600);

    my $swin = Gtk2::ScrolledWindow->new;
    $swin->set_shadow_type('in');
    $window->add($swin);

    my $canvas = Goo::Canvas->new();
    $canvas->set_size_request(600, 450);
    $canvas->set_bounds(0, 0, 1000, 1000);
    $swin->add($canvas);

    my $root = $canvas->get_root_item();
    my $rect = Goo::Canvas::Rect->new(
        $root, 100, 100, 400, 400,
        'line-width' => 10,
        'radius-x' => 20,
        'radius-y' => 10,
        'stroke-color' => 'yellow',
        'fill-color' => 'red'
    );
    $rect->signal_connect('button-press-event',
                          \&on_rect_button_press);

    my $text = Goo::Canvas::Text->new(
        $root, "Hello World", 300, 300, -1, 'center',
        'font' => 'Sans 24',
    );
    $text->rotate(45, 300, 300);
    $window->show_all();
    Gtk2->main;

    sub on_rect_button_press {
        print "Rect item pressed!\n";
        return TRUE;
    }

=head1 DESCRIPTION

GTK+ does't has an buildin canvas widget. GooCanvas is wonderful. It
is easy to use and has powerful and extensible way to create items in
canvas. Just try it.

For more documents, please read GooCanvas Manual and the demo programs
provided in the source distribution in both perl-Goo::Canvas and
GooCanvas.

=head1 SEE ALSO

L<Gtk2>(3pm)

=head1 AUTHOR

Ye Wenbin E<lt>wenbinye@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by ywb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
