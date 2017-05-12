package FormValidator::Nested::Validator::DateTime;
use strict;
use warnings;
use utf8;

use Scalar::Util qw/blessed/;

sub date {
    my ( $value, $options, $req ) = @_;

    if ( blessed $value ne 'DateTime' ) {
        return 0;
    }
    return 1;
}

sub greater_than_equal {
    my ( $value, $options, $req ) = @_;

    my $target_dt = $req->param($options->{target});

    if ( 
           !date($value, $options, $req)
        || !date($target_dt, $options, $req)
    ) {
        # 日付形式不具合もokとする
        return 1;
    }

    if ( $value < $target_dt ) {
        return 0;
    }
    return 1;
}

sub greater_than {
    my ( $value, $options, $req ) = @_;

    my $target_dt = $req->param($options->{target});

    if ( 
           !date($value, $options, $req)
        || !date($target_dt, $options, $req)
    ) {
        # 日付形式不具合もokとする
        return 1;
    }

    if ( $value <= $target_dt ) {
        return 0;
    }
    return 1;
}


1;

