package Gapp::TextTagTable;
{
  $Gapp::TextTagTable::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Object';

has '+gclass' => (
    default => 'Gtk2::TextTagTable',
);


1;


__END__

=pod

=head1 NAME

Gapp::Object - TextTagTable widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item +-- L<Gapp::TextTagTable>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

