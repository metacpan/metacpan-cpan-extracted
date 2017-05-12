package Gapp::ToolItemGroup;
{
  $Gapp::ToolItemGroup::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Container';
with 'Gapp::Meta::Widget::Native::Role::HasLabel';

has '+gclass' => (
    default => 'Gtk2::ToolItemGroup',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    $args{args} = [exists $args{label} ? $args{label} : ''];
    
    for my $att ( qw(collapsed ellipsize header_relief label_widget) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;


__END__

=pod

=head1 NAME

Gapp::ToolItemGroup - ToolItemGroup widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::ToolItemGroup>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::HasLabel>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item collapsed

=item ellipsize

=item header_relief

=item label

=item label_widget

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut