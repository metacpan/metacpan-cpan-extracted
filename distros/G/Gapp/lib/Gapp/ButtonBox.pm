package Gapp::ButtonBox;
{
  $Gapp::ButtonBox::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

use Carp;
use Gapp::Button;
use Gapp::Types qw( GappWidget GappActionOrArrayRef );

extends 'Gapp::Container';

has '+gclass' => (
    default => 'Gtk2::ButtonBox',
);

has 'buttons' => (
    is => 'rw',
    isa => 'Maybe[ArrayRef]',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    # headers visible
    for my $att ( qw(layout_style) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}


before '_construct_gobject' => sub {
    my ( $self ) = @_;
    
    if ( $self->buttons && ! @{ $self->content } ) {
        
        my @content;
        
        for ( @{ $self->buttons } ) {
            
            if ( is_GappWidget( $_ ) ) {
                push @content, $_;
            }
            elsif ( is_GappActionOrArrayRef( $_ ) ) {
                push @content, Gapp::Button->new( action => $_ );
            }
            else {
                carp qq[invalid value ($_) passed to buttons attribute: ] .
                qq[ must be a GappWidget or a GappAction ];
            }
            
        }
        
        $self->set_content( \@content );
    }
};

1;


__END__

=pod

=head1 NAME

Gapp::ButtonBox - ButtonBox widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item +-- L<Gapp::Container>

=item ....+-- L<Gapp::Box>

=item ........+-- L<Gapp::ButtonBox>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<buttons>

=over 4

=item is rw

=item isa ArrayRef[Gapp::Action|Gapp::Button].

=back

An C<ArrayRef> of buttons or actions to add to the button box. You may still
add buttons using the C<content> attribute, however using the C<buttons> attribute
allows you to use actions.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut