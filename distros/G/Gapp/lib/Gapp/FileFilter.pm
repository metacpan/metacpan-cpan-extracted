package Gapp::FileFilter;
{
  $Gapp::FileFilter::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Widget';

has '+gclass' => (
    default => 'Gtk2::FileFilter',
);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'mime_types' => (
    isa => 'ArrayRef',
    traits => [qw( Array )],
    default => sub { [ ] },
    handles => {
        add_mime_type => 'push',
        mime_types => 'elements',
    }
);


has 'patterns' => (
    isa => 'ArrayRef',
    traits => [qw( Array )],
    default => sub { [ ] },
    handles => {
        add_pattern => 'push',
        patterns => 'elements',
    }
);





1;



__END__

=pod

=head1 NAME

Gapp::FileFilter - FileFilter Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::FileFilter>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<name>

=over 4

=item is rw

=item isa Str

=back

The name of the filter. This will be displayed to the user.

=item B<mime_types>

=over 4

=item isa Array

=back

The mime types to add to be included in the filter.

=item B<patterns>

=over 4

=item isa Array

=back

The file glob patters to be included in the filter.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


