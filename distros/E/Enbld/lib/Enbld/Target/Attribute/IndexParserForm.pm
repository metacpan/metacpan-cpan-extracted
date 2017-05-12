package Enbld::Target::Attribute::IndexParserForm;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::RegEx/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{callback} = sub {
            my $attributes = $self->{attributes};
            my $form = '<a href="' . quotemeta( $attributes->ArchiveName );
            $form .= '-' . $attributes->VersionForm . '\.';
            $form .= quotemeta( $attributes->Extension ) . '">';

            return $form;
        };

        return $self;
    }

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    my $err = "Attribute 'IndexParserForm' isn't defined";
    require Enbld::Exception;
    croak( Enbld::Exception->new( $err ));
}

1;
