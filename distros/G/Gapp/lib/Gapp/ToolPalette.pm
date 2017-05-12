package Gapp::ToolPalette;
{
  $Gapp::ToolPalette::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Container';

has '+gclass' => (
    default => 'Gtk2::ToolPalette',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(icon_size icon_size_set toolbar_style) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;


__END__

=pod

=head1 NAME

Gapp::ToolPalette - ToolPalette widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::ToolPalette>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item icon_size

=item icon_size_set

=item toolbar_style

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut