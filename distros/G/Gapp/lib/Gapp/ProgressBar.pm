package Gapp::ProgressBar;
{
  $Gapp::ProgressBar::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Widget';

has '+gclass' => (
    default => 'Gtk2::ProgressBar',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(fraction text) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
   
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;

__END__

=pod

=head1 NAME

Gapp::ProgressBar - ProgressBar widget

=head1 OBJECT HIERARCHY

=over 4

=item l<Gapp::Object>

=item +--L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Paned>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item fraction

=item text

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut