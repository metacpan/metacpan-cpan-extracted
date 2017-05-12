package Gapp::Meta::Widget::Native::Role::FileChooser;
{
  $Gapp::Meta::Widget::Native::Role::FileChooser::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'action' => (
    is => 'rw',
    isa => 'Str',
    default => 'open',
);

has 'filters' => (
    isa => 'ArrayRef',
    default => sub { [] },
    traits => [qw( Array )],
    handles => {
        add_filter => 'push',
        filters => 'elements',
    }
);


1;

__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Role::FileChooser - Role for FileChooser widgets
   
=head1 PROVIDED ATTRIBUTES

=over 4

=item B<action>

Can be 'open', 'save', 'select-folder', 'create-folder'.

=over 4

=item is rw

=item isa Str

=item default C<'open'>

=back

=item B<filters>

List of file filters to add to the selection dialog.

=over 4

=item is rw

=item isa ArrayRef

=item default []

=item handles

=over 4

=item add_filter $filter

Add a file filter to the selection dialog.

=item filters

Returns a list of filters.

=back

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut