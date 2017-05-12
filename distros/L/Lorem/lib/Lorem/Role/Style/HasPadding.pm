package Lorem::Role::Style::HasPadding;
{
  $Lorem::Role::Style::HasPadding::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Lorem::Style::Util qw( parse_padding );
use Lorem::Types qw( LoremStyleLength );

has [qw(padding_left padding_right padding_top padding_bottom)] => (
    is => 'rw',
    isa => LoremStyleLength,
    default => 0,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    
    my %args = @_;
    my %new_args;
    
    # delegate padding property
    if ( exists $args{padding} ) {
        my $parsed = parse_padding $args{padding};
        for my $s ( qw/left right top bottom/) {
            if ( defined $parsed->{$s} ) {
                $new_args{ 'padding_' . $s } = $parsed->{$s};
            }
        }
        delete $args{padding};
    }
    
    my %return = (%args, %new_args);    
    return $class->$orig(%return);
};


sub set_padding {
    my ( $self, $input ) = @_;
    my $padding = parse_padding $input;
    $self->set_padding_left( $padding->{left} );
    $self->set_padding_right( $padding->{right} );
    $self->set_padding_top( $padding->{top} );
    $self->set_padding_bottom( $padding->{bottom} );
}

1;
