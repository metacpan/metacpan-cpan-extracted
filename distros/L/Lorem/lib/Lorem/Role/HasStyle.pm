package Lorem::Role::HasStyle;
{
  $Lorem::Role::HasStyle::VERSION = '0.22';
}

use Moose::Role;
use MooseX::Clone;
use MooseX::SemiAffordanceAccessor;

use Lorem::Types qw( LoremStyle );
use Lorem::Style;

has 'style' => (
    is => 'rw',
    isa => LoremStyle,
    traits => [qw(Clone)],
    lazy_build => 1,
    coerce => 1,
);

has 'merged_style' => (
    is => 'rw',
    isa => LoremStyle,
    traits => [qw(NoClone)],
    lazy_build => 1,
);

sub _build_style {
    Lorem::Style->new
}

sub _build_merged_style {
    my $self = shift;
    
    my $style = $self->style;
    my $parent_style = $self->parent ? $self->parent->merged_style : undef;
    
    my $merged = Lorem::Style->new;
    for my $att ( map { $merged->meta->get_attribute( $_ ) } $merged->meta->get_attribute_list ) {
        my $my_value = $att->get_value( $style );
        if ( defined $my_value ) {
            $att->set_value( $merged, $my_value );
        }
        elsif ( $att->does('Inherit') && $self->parent ) {
            $att->set_value( $merged, $att->get_value( $parent_style ) ) if $att->get_value( $parent_style );
        }
    }
    return $merged;
}



1;
