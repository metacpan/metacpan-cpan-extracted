package Gapp::TreeStore;
{
  $Gapp::TreeStore::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( HashRef );

extends 'Gapp::Object';


has '+gclass' => (
    default => 'Gtk2::TreeStore',
);

has 'columns' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

has 'content' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    if ( exists $args{columns} ) {
        $args{args} = [ @{ $args{columns} } ] if ! exists $args{args};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;



__END__

=pod

=head1 NAME

Gapp::TreeStore - TreeStore object

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::TreeStore>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<columns>

=over 4

=item isa ArrayRef[GType]

=back

=item B<content>

=over 4

=item isa ArrayRef[Any]

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


