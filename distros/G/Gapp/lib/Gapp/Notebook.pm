package Gapp::Notebook;
{
  $Gapp::Notebook::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use Gapp::Meta::Widget::Native::Trait::NotebookPage;

extends 'Gapp::Container';

has '+gclass' => (
    default => 'Gtk2::Notebook',
);

has 'action_widget' => (
    is => 'rw',
    isa => 'Maybe[Gapp::Widget]',
    trigger => sub {
       $_[1]->set_parent( $_[0] ) if $_[1];
    }
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(scrollable) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}



sub current_page {
    my ( $self ) = @_;
    my $n = $self->gobject->get_current_page;
    return if ! defined $n;
    
    my $gtkw = $self->gobject->get_nth_page( $n );
    $gtkw->{_gapp};
}



1;


__END__

=pod

=head1 NAME

Gapp::Notebook - Box widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Notebook>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item scrollable

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut