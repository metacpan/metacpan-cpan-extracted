package Gapp::Toolbar;
{
  $Gapp::Toolbar::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
extends 'Gapp::Container';
with 'Gapp::Meta::Widget::Native::Role::HasIconSize';

has '+gclass' => (
    default => 'Gtk2::Toolbar',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(toolbar_style show_arrow tooltips orientation ) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    if ( exists $args{style} ) {
        $args{properties}{'toolbar_style'} = $args{style};
        delete $args{style};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;


__END__

=pod

=head1 NAME

Gapp::Toolbar - Window Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Toolbar>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::HasIconSize>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item B<toolbar_style>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
