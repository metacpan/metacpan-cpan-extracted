package FormValidator::Nested::Filter::DateTime;
use strict;
use warnings;
use utf8;

use DateTime;
use DateTime::TimeZone;
use FormValidator::Nested::FilterInvalid;

our $time_zone = DateTime::TimeZone->new(name => 'Asia/Tokyo');


sub date {
    my ( $value, $options, $req ) = @_;
    my %datetime_args = ();

    if ( $options->{prefix} ) {
        foreach my $target ( qw/year month day/ ) {
            my $val = $req->param($options->{prefix} . '_' . $target);
            if ( !defined($val) || $val eq '') {
                return '';
            }
            $datetime_args{$target} = $val;
        }
    }
    elsif ( $options->{regex} ) {
        if ( !defined($value) || $value eq '' ) {
            return '';
        }
        my $params = $options->{params} || [qw/year month day/];
        if ( $value =~ /$options->{regex}/ ) {
            for my $idx ( 1..@$params ) {
                $datetime_args{$params->[$idx-1]} = eval "\$$idx"; ## no critic
            }
        }
    }

    my $dt;
    eval {
        $dt = DateTime->new(
            time_zone => $time_zone,
            %datetime_args,
        );
    };
    if ( $@ ) {
        return FormValidator::Nested::FilterInvalid->new;
    }
    return $dt;
}

1;

