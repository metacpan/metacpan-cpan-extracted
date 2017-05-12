package Enbld::Target::Attribute::Version;

use strict;
use warnings;

use version;
use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{callback} = sub {
            my $attributes = shift;

            my $list = $attributes->SortedVersionList;

            if ( $attributes->VersionCondition eq 'latest' ) {
                return $list->[-1];
            }

            if ( grep { $attributes->VersionCondition eq $_ } @{ $list} ) {
                return $attributes->VersionCondition;
            }

            my $err = "Invalid Version Condition:" .
                        $attributes->VersionCondition . ", ".
                        "please check install condition";
            require Enbld::Error;
            croak( Enbld::Error->new( $err ));
        };

        return $self;
    }

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    my $err = "Attribute 'Version' isn't defined";
    croak( Enbld::Exception->new( $err )); 
}

sub validate {
    my ( $self, $string ) = @_;

    $self->SUPER::validate( $string );

    my $form = $self->{attributes}->VersionForm;
    unless ( $string =~ /^$form$/ ) {
        my $err = 'Attribute Version is NOT valid version string.';
        require Enbld::Exception;
        croak( Enbld::Exception->new( $err, $string ));
    }

    return $string;
}

1;
