package Gapp::Label;
{
  $Gapp::Label::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Widget';

has '+gclass' => (
    default => 'Gtk2::Label',
);

has 'text' => (
    is => 'rw',
    isa => 'Str',
);

has 'markup' => (
    is => 'rw',
    isa => 'Str',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    
    #my %args;
    #if ( @_ == 1 ) {
    #    if ( is_Str( $_[0] ) ) {
    #        $args{text} = $_[0];
    #    }
    #    elsif ( is_HashRef( $_[0] ) ) {
    #        %args = %{$_[0]};
    #    }
    #    else {
    #        $class->meta->throw_error( 'Single parameter to constructor must be a sting a hash reference.' );
    #    }
    #}
    #else {
    #    %args = ( @_ );
    #}
    
    
    #if ( exists $args{markup} ) {
    #    $args{args} = [ $args{markup} ];
    #    $args{constructor} = 'new_with_markup';
    #}
    #elsif ( exists $args{mnemonic} ) {
    #    $args{args} = [ $args{mnemonic} ];
    #    $args{constructor} = 'new_with_mnemonic';
    #}
    if ( exists $args{text} ) {
        $args{args} = [ $args{text} ];
    }
    #delete $args{markup};
    #delete $args{mnemonic};
    #delete $args{text};
    
    
    
    for my $att ( qw( angle ellipsize cursor_position max_width_chars mnemonic_keyval pattern selectable selection_bound single_line_mode track_visited_links use_markup use_underline width_chars wrap wrap_mode xalign yalign justify  ) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;



__END__

=pod

=head1 NAME

Gapp::Label - Label Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Label>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item B<markup>

=item B<mnemonic>

=item B<text>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


