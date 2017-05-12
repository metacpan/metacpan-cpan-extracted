package Gapp::StatusIcon;
{
  $Gapp::StatusIcon::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;


extends 'Gapp::Widget';

has '+gclass' => (
    default => 'Gtk2::StatusIcon',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;

    for ( qw[pixbuf stock icon_name] ) {
        $args{properties}{$_} = delete $args{$_} if exists $args{$_};
    }
    if ( exists $args{tooltip} ) {
        $args{properties}{has_tooltip} = 1;
        $args{properties}{tooltip_text} = delete $args{tooltip};
    }
    
    

    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;

__END__

=pod

=head1 NAME

Gapp::StatusIcon - StatusIcon Widget

=head1 OBJECT HIERARCHY

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::StatusIcon>

=head1 DELEGATED

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut