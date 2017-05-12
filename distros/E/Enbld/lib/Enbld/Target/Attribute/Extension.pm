package Enbld::Target::Attribute::Extension;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{value} = 'tar.gz';
        $self->{is_evaluated}++;

        return $self;
    }

    if ( $param ) { 
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'Extension' isn't defined" ) );
}

our @extensions = qw/tar.gz tgz tar.bz2/;

sub validate {
    my ( $self, $string ) = @_;

    $self->SUPER::validate( $string );

    return $string if ( grep { $string eq $_ } @extensions );

    my $err = "Attribute 'Extension' is invalid string";
    require Enbld::Exception;
    croak( Enbld::Exception->new( $err, $string ));
}

1;
