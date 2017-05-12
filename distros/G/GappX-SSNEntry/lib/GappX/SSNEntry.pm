package GappX::SSNEntry;
{
  $GappX::SSNEntry::VERSION = '0.02';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Entry';

use GappX::Gtk2::SSNEntry;
use GappX::Moose::Meta::Attribute::Trait::GappSSNEntry;

has '+gclass' => (
    default => 'GappX::Gtk2::SSNEntry',
);


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(value) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }

    __PACKAGE__->SUPER::BUILDARGS( %args );
}

# returns the value of the widget
sub get_field_value {
    $_[0]->gobject->get_value eq '' ? undef : $_[0]->gobject->get_value;
}

sub set_field_value {
    my ( $self, $value ) = @_;
    $self->gobject->set_value( defined $value ? $value : '' );
}


1;


__END__

=pod

=head1 NAME

GappX::SSNEntry - SSNEntry Widget

=head1 SYNOPSIS

  use Gapp;

  use Gapp::SSNEntry;

  Gapp::SSNEntry->new( value => '0123456789' );

=head1 DESCRIPTION

A widget for viewing and editing social security numbers.

Navigate between the three components of a social security number using the
left and right arrow keys. The value of the widget will be stored internally
as a 9 character string consisting only of digits (i.e. "0123456789"). However,
the text that is displayed in the widget will be displayed with hyphens between
the components (i.e. "012-345-6789").

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Entry>

=item ........+-- GappX::SSNEntry

=back

=head1 DELEGATED PROPERTIES

=over 4

=item B<value>

=back 

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

