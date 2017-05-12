package Gapp::SeparatorMenuItem;
{
  $Gapp::SeparatorMenuItem::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
extends 'Gapp::MenuItem';

has '+gclass' => (
    default => 'Gtk2::SeparatorMenuItem',
);

has '+constructor' => (
    default => 'new',
);

has '+args' => (
    default => undef,
);


1;



__END__

=pod

=head1 NAME

Gapp::SeparatorMenuItem - SeparatorMenuItem Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::MenuItem>

=item ........+-- L<Gapp::SeparatorMenuItem>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut