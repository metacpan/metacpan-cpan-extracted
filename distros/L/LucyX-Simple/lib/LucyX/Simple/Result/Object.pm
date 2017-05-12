package LucyX::Simple::Result::Object;
use strict;
use warnings;

sub new{
    my ( $invocant, $data ) = @_;

    my $class = ref( $invocant ) || $invocant;
    my $self = bless( $data, $class );

#serious business
    foreach my $key ( keys( %{$data} ) ){
        if ( !$self->can( $key ) ){
            $self->_mk_accessor( $key );
        }
    }
 
    return $self;
}

sub _mk_accessor{
    my ( $self, $name ) = @_;

    my $class = ref( $self ) || $self;
    {
        no strict 'refs';
        *{$class . '::' . $name} = sub {
            return shift->{ $name } || undef;
        };
    }
}

1;
