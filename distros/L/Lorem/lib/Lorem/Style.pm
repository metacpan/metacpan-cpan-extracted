package Lorem::Style;
{
  $Lorem::Style::VERSION = '0.22';
}
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Lorem::Meta::Attribute::Trait::Inherit;
use Lorem::Style::Util qw( parse_style );

with 'MooseX::Clone';
with 'Lorem::Role::Style::HasBorders';
with 'Lorem::Role::Style::HasDimensions';
with 'Lorem::Role::Style::HasMargin';
with 'Lorem::Role::Style::HasPadding';
with 'Lorem::Role::Style::HasText';

use Pango;
use Lorem::Types qw( LoremElement LoremStyle LoremStyleVerticalAlign );

has 'color' => (
    is => 'rw',
    traits  => [qw(Inherit)],
);

has 'vertical_align' => (
    is => 'rw',
    isa => LoremStyleVerticalAlign,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    # if a single argument, then we are parsing a style string
    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( %{parse_style $_[0]} );
    }
    else {
        return $class->$orig(@_);
    }
};


sub parse {
    my ( $self, $input ) = @_;
    my $parsed = parse_style $input;
    
    my $style = Lorem::Style->new( %{$parsed} );
    $self->merge( $style );
}

sub merge {
    my ( $self, $style ) = @_;

    for my $att ( map { $self->meta->get_attribute( $_ ) } $self->meta->get_attribute_list ) {
        my $newvalue = $att->get_value( $style );
        
        if ( defined $newvalue ) {
            $att->set_value( $self, $newvalue );
        }
        
    }
    return $self;
}

1;
