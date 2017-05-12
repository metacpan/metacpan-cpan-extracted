package Gapp::Model::List;
{
  $Gapp::Model::List::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( HashRef );

use Gapp::Gtk2;
extends 'Gapp::Object';


has '+gclass' => (
    default => 'Gapp::Gtk2::Model::List',
);

has '+gobject' => (
    handles => [qw( clear append append_record )],
);


has 'content' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);





1;

__END__

=pod

=head1 NAME

Gapp::Model::SimpleList - A Simple List

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- Gapp::Model::SimpleList

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<content>

=over 4

=item isa ArrayRef

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


