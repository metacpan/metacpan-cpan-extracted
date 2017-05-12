package Lorem::Role::HasMargin;
{
  $Lorem::Role::HasMargin::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;


use Lorem::Types qw( LoremStyleLength );

has [qw(margin_left margin_right margin_top margin_bottom)] => (
    is => 'rw',
    isa => LoremStyleLength,
    default => 0,
);

sub _apply_margin_style  {
    my ( $self, $style ) = @_;
    $self->set_margin_left( $style->margin_left ) if defined $style->margin_left;
    $self->set_margin_right( $style->margin_right ) if defined $style->margin_right;
    $self->set_margin_top( $style->margin_top ) if defined $style->margin_top;
    $self->set_margin_bottom( $style->margin_bottom ) if defined $style->margin_bottom;
}

1;
