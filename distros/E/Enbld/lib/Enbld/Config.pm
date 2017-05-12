package Enbld::Config;

use strict;
use warnings;

use Carp;

require Enbld::Exception;

sub new {
    my $class = shift;

    my $self = {
        name        =>  undef,
        enabled     =>  undef,
        installed   =>  {},
        @_,
    };

    bless $self, $class;

    return $self;
}

sub name {
    return $_[0]->{name};
}

sub installed {
    return $_[0]->{installed};
}

sub condition {
    my ( $self, $version ) = @_;

    require Enbld::Condition;

    if ( ! $version ) {
        return  Enbld::Condition->new(
                %{ $self->{installed}{$self->enabled} }
                );
    }

    if ( exists $self->{installed}{$version} ) {
        return Enbld::Condition->new(
                %{ $self->{installed}{$version} }
                );
    }

    return;
}

sub is_installed_version {
    my ( $self, $version ) = @_;

    return unless $version;
    return unless keys %{ $self->{installed} };

    return $version if ( exists $self->{installed}{$version} );

    return;
}

sub enabled {
    return $_[0]->{enabled};
}

sub drop_enabled {
    my $self = shift;

    return ( $self->{enabled} = undef );
}

sub set_enabled {
    my ( $self, $version, $condition ) = @_;

    $self->{enabled} = $version;
    $self->{installed}{$version} = $condition->serialize;

    return $self->{enabled};
}

sub serialize {
    my $self = shift;

    my $serialized;
    foreach my $key ( sort keys %{ $self } ) {
        $serialized->{$key} = $self->{$key};
    }

    return $serialized;
}

sub DSL {
    my $self = shift;

    my @config;

    require Enbld::Feature;
    my $version = Enbld::Feature->is_current_mode ?
        $self->enabled : $self->condition->version;

    push @config, "target '" . $self->name . "' => define {\n";
    push @config, "    version '". $version . "';\n";
    if ( $self->condition->make_test ) {
        push @config, "    make_test '" . $self->condition->make_test . "';\n";
    }

    if ( $self->condition->arguments ) {
        push @config, "    arguments '" . $self->condition->arguments . "';\n";
    }

    if ( $self->condition->annotation ) {
        push @config, "    annotation '" . $self->condition->annotation ."';\n";
    }

    if ( $self->condition->module_file ) {
        push @config, "    module_file '" . $self->condition->module_file ."';\n";

    }

    push @config, "};\n";

    return \@config;
}

1;
