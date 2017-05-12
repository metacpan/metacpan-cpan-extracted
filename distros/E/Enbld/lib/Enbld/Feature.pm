package Enbld::Feature;

use strict;
use warnings;

require Enbld::Error;

our $feature = {
    force       =>  undef,
    make_test   =>  undef,
    deploy      =>  undef,
    current     =>  undef,
};

sub initialize {
    my $pkg = shift;

    $feature = {
        force       =>  undef,
        make_test   =>  undef,
        deploy      =>  undef,
        current     =>  undef,
        @_,
    };

    $pkg->set_deploy_mode( $feature->{deploy} ) if $feature->{deploy};
}

sub set_deploy_mode {
    my $pkg     = shift;
    my $path    = shift;

    $pkg->_validate_deploy_path( $path );

    $feature->{deploy} = $path;
}

sub _validate_deploy_path {
    my $pkg = shift;
    my $deploy_path = shift;
    
    if ( ! -d $deploy_path ) {
        my $err = "'$deploy_path' is nonexistent directory.";
        Enbld::Error->throw( $err );
    }

    if ( ! -w $deploy_path ) {
        my $err = "no permission to write directory:$deploy_path";
        Enbld::Error->throw( $err );
    }

    return $deploy_path;
}

sub is_deploy_mode {
    return $feature->{deploy};
}

sub deploy_path {
    return $feature->{deploy};
}

sub is_force_install {
    return $feature->{force};
}

sub is_make_test_all {
    return $feature->{make_test};
}

sub is_current_mode {
    return $feature->{current};
}

sub reset {

    $feature = {
        force       =>  undef,
        make_test   =>  undef,
        deploy      =>  undef,
        current     =>  undef,
    };

}

1;
