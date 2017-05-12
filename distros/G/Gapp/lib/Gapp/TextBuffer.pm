package Gapp::TextBuffer;
{
  $Gapp::TextBuffer::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Object';

use Gapp::TextTagTable;

has '+gclass' => (
    default => 'Gtk2::TextBuffer',
);

has 'tag_table' => (
    is => 'rw',
    isa => 'Maybe[Gapp::TextTagTable]',
);


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for ( qw[has_selection text] ) {
        $args{properties}{$_} = delete $args{$_} if exists $args{$_}; 
    }
    
    if ( exists $args{tag_table} && defined $args{tag_table} ) {
        $args{args} = [ $args{tag_table}->gobject ];
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}




1;


__END__

=pod

=head1 NAME

Gapp::TextBuffer - TextBuffer widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item ....+-- L<Gapp::Widget>

=item ........+-- L<Gapp::TextBuffer>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item has_selection

=item text

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<tag_table>

=over 4

=item isa: Gapp::TextTagTable|Undef

=item default: undef

=back

Assigned to the TextBuffer upon construction.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

