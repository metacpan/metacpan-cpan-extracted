package Gapp::Container;
{
  $Gapp::Container::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Widget';

use Gapp::Types qw( GappContent );

# the contents of the widget
has 'content' => (
    is => 'rw',
    isa => GappContent,
    default => sub { [ ] },
    traits => [qw( Array )],
    trigger => sub {
        my ( $self, $content ) = @_;
        map {
            confess 'cannot add undefined value to ' . $self if ! $_;
            $_->set_parent( $self );
        } @$content;
    },
    initializer => sub {
        my ( $self, $content, $writer ) = @_;
        map {
            confess 'cannot add undefined value to ' . $self if ! $_;
            $_->set_parent( $self );
        } @$content;
        return $writer->($content);
    },
    handles => {
        _add_content => 'push',
        children => 'elements',
    },
    lazy => 1,
);


sub BUILD {
    my ( $self ) = @_;
        
    for my $child ( @{$self->content} ) {
        $child->set_parent( $self );
    }
}


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(border_width resize_mode) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}



after '_build_gobject' => sub {
    my $self = shift;
    
    for ( @{$self->content} ) {
        #$_->set_parent( $self );
        $self->find_layout->pack_widget( $_, $self);
    }
};

sub add {
    my ( $self, @args ) = @_;
    
    # TODO: SHOULD JUST ADD TO CONTENT ARRAY IF OBJECT NOT BUILD
    # IF OBJECT IS BUILT, THEN PACK IMEDIATELY
    for ( @args ) {
        $_->set_parent ( $self );
        
        $self->find_layout->pack_widget( $_, $self) if $self->has_gobject;
        $self->_add_content( $_ );
    }
}

sub find {
    my ( $self, $name ) = @_;
    
    my @array = $self->children;
    
    while ( my $c = shift @array ) {
        return $c if $c->name eq $name;
        push @array, $c->children if $c->can('children');
    }
}



# return a list of all descendants
sub find_descendants {
    my ( $self ) = @_;
    
    my @descendants;
    
    for my $w ( @{ $self->content } ) {
        push @descendants, $w;
        push @descendants, $w->find_descendants if $w->can( 'find_descendants' );
    }
    
    return @descendants;
}


1;



__END__

=pod

=head1 NAME

Gapp::Container - Container Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<content>

=over 4

=item isa ArrayRef[Gapp::Widget]

=back

These widgets will be packed into the container at construction time.

=back

=head1 PROVIDED METHODS

=over 4

=item B<add @widgets>

Adds widgets to C<content> to be packed into the container at construction time.

=over 4

=item B<find_descendants>

Returns a list of all descendants of this container.

=back 

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

