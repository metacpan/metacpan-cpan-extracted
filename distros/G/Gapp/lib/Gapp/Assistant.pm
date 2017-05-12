package Gapp::Assistant;
{
  $Gapp::Assistant::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( HashRef );

use MooseX::Types::Moose qw( Undef );
use Gapp::Types qw( GappActionOrArrayRef );
use Gapp::Meta::Widget::Native::Trait::AssistantPage;
extends 'Gapp::Window';

has '+gclass' => (
    default => 'Gtk2::Assistant',
);

has 'forward_page_func' => (
    is => 'rw',
    isa => GappActionOrArrayRef|Undef,
);


sub current_page {
    my ( $self ) = @_;
    
    my @pages = $self->children;
    
    my $num = $self->gobject->get_current_page;
    
    for my $page ( @pages ) {
        return $page if $page->page_num == $num;
    }
}

sub find_page {
    my ( $self, $page_name ) = @_;
    
    if ( ! defined $page_name || $page_name eq '' ) {
        $self->meta->throw_errow(
            qq[you did not supply a page name,\n] .
            qq[usage: Gapp::Assistant::find_page( $self, $page_name )]
        );
        return;
    }
    
    for my $page ( $self->children ) {
        return $page if $page->name eq $page_name;
    }
}

sub set_current_page {
    my ( $self, $page_name ) = @_;
    
    if ( ! defined $page_name ) {
        $self->meta->throw_errow(
            qq[you did not supply a page name,\n] .
            qq[usage: Gapp::Assistant::find_page( $self, $page_name )]
        );
        return;
    }
    
    for my $page ( $self->children ) {
        if ( $page->page_name eq $page_name ) {
            $self->gobject->set_current_page( $page->num );
        }
    }
}




sub BUILD {
    my $self = shift;
    $self->signal_connect( 'prepare' => sub {
        my ( $self ) = @_;
        my $page = $self->current_page;
        $page->validate if $page->validator;
    }, $self);
}


1;

__END__

=pod

=head1 NAME

Gapp::Assistant - Assistant Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Bin>

=item ............+-- L<Gapp::Window>

=item ................+-- L<Gapp::Assistant>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<forward_page_func>

=over 4

=item is rw

=item isa CodeRef

=back

Called when user moves forward through the assistant.

=back

=head1 PROVIDED METHODS

=over 4

=item B<set_current_page $page>

Sets the currently displayed page.

=item B<find_page $page_name>

Finds and returns the page with the given C<$page_name>.

=item B<current_page>

Returns the currently displayed page.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut





1;
