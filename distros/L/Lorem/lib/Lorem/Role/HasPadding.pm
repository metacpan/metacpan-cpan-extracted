package Lorem::Role::HasPadding;
{
  $Lorem::Role::HasPadding::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;


use Lorem::Types qw( LoremStyleLength );

has [qw(padding_left padding_right padding_top padding_bottom)] => (
    is => 'rw',
    isa => LoremStyleLength,
    default => 0,
);

sub _apply_padding_style {
    my ( $self, $style ) = @_;
    $self->set_padding_left( $style->padding_left );
    $self->set_padding_right( $style->padding_right );
    $self->set_padding_top( $style->padding_top );
    $self->set_padding_bottom( $style->padding_bottom );
}

1;
