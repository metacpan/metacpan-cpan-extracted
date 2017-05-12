package FormValidator::Nested::Validator::String;
use strict;
use warnings;
use utf8;

use List::MoreUtils;


sub max_length {
    my ( $value, $options, $req ) = @_;

    if ( length $value > $options->{max} ) {
        return 0;
    }
    return 1;
}

sub length {
    my ( $value, $options, $req ) = @_;

    if ( length $value != $options->{'length'} ) {
        return 0;
    }
    return 1;
}

sub between_length {
    my ( $value, $options, $req ) = @_;

    my $length = CORE::length $value;
    if ( $length < $options->{'min'} || $length > $options->{'max'} ) {
        return 0;
    }
    return 1;
}

sub alpha_num {
    my ( $value, $options, $req ) = @_;

    if ( $value =~ /[^0-9a-zA-Z]/ ) {
        return 0;
    }
    return 1;
}

sub ascii {
    my ( $value, $options, $req ) = @_;

    if ( $value =~ /\P{ASCII}/ ) {
        return 0;
    }
    return 1;
}

sub in {
    my ( $value, $options, $req ) = @_;

    if ( List::MoreUtils::none { $value eq $_ } @{$options->{list}} ) {
        return 0;
    }
    return 1;
}

sub no_break {
    my ( $value, $options, $req ) = @_;

    if ( $value =~ /[\x{0a}\x{0d}]/ ) {
        return 0;
    }
    return 1;
}


1;

