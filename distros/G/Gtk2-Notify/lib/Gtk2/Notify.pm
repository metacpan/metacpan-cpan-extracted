package Gtk2::Notify;

use strict;
use warnings;
use Gtk2;
require DynaLoader;

our @ISA = qw( DynaLoader );
our $VERSION = '0.05';

sub import {
    my $class = shift;
    my $init = 0;

    while (my $arg = shift @_) {
        if ($arg =~ /^-init$/) {
            my $app_name;
            if (!defined ($app_name = shift @_)) {
                require Carp;
                Carp::croak('-init requires the application name to use as its first argument');
            }

            Gtk2->init;
            Gtk2::Notify->init($app_name);
        } else {
            $class->VERSION($arg);
        }
    }
}

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

__END__
=head1 NAME

Gtk2::Notify - Perl interface to libnotify

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Gtk2::Notify -init, "app_name";

    my $notification = Gtk2::Notify->new($summary, $message, $icon, $attach_widget);
    $notification->show;

=head1 INITIALISATION

    use Gtk2::Notify qw/-init app_name/;

=over

=item -init

Importing Gtk2::Notify with the -init option requires one additional argument:
the application name to use. This is equivalent to
Gtk2::Notify->init($app_name).

=back

=head1 AUTHOR

Florian Ragwitz, C<< <rafl at debian.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gtk2-notify at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-Notify>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::Notify

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-Notify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-Notify>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-Notify>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-Notify>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Florian Ragwitz, all rights reserved.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA  02111-1307  USA.

=cut

1; # End of Gtk2::Notify
