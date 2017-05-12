package Gapp::ScrolledWindow;
{
  $Gapp::ScrolledWindow::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Bin';

has '+gclass' => (
    default => 'Gtk2::ScrolledWindow',
);

has 'policy' => (
    is => 'rw',
    isa => 'Maybe[ArrayRef]',
);

has 'use_viewport' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


1;



__END__

=pod

=head1 NAME

Gapp::Bin - Bin widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item +-- L<Gapp::Container>

=item ....+-- L<Gapp::Bin>

=item ........+-- L<Gapp::ScrolledWindow>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<policy>

=over 4

=item is rw

=item isa ArrayRef[$hscrollpolicy, $vscrollpolicy]|Undef

=back

Set the policy of the scrolled window. Possible values for C<hscrollpolicy> and C<vscrollpolicy> are
C<automatic>, C<always>, and C<never>.

=item B<use_viewport>

=over 4

=item is rw

=item isa Bool

=item default 0

=back

Whether the scrolled window should use a viewport when packing widgets. Use this when packing widgets
that do not support scrolling.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut