package Gapp::Expander;
{
  $Gapp::Expander::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Container';

has '+gclass' => (
    default => 'Gtk2::Expander',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(expanded label label_fill spacing use_markup use_underline) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }

    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;

__END__

=pod

=head1 NAME

Gapp::Expander - Expander widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Bin>

=item ............+-- Gapp::Expander

=back

=head1 DELEGATED PROPERTIES

=over 4

=item b<expanded>

=item b<label>

=item b<label_fill>

=item b<spacing>

=item b<use_markup>

=item b<use_underline>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut