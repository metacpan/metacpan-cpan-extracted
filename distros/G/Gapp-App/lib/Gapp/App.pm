package Gapp::App;
{
  $Gapp::App::VERSION = '0.222';
}

use Moose;

use Gapp::App::Widget::Traits::HasApp;


1;

__END__

=pod

=head1 NAME

Gapp::App - Build Gapp applications from components

=head1 DESCRIPTION

Provides base classes and patterns for building GUI Applications using the Gapp framework.
Gapp is a layer over the Gtk2 library.

=head1 SEE ALSO

=over4

=item L<Gapp>

=item L<Gtk2>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2012 Jeffrey Ray Hallock.
    
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

