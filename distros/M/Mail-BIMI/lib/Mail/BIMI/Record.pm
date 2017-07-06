package Mail::BIMI::Record;

use strict;
use warnings;

our $VERSION = '1.20170626'; # VERSION

use Carp;
use English qw( -no_match_vars );

sub new {
    my ( $Class, $Args ) = @_;

    my $Self = {};
    bless $Self, ref($Class) || $Class;

    $Self->{ 'record' } = $Args->{ 'record' };
    $Self->{ 'domain' } = $Args->{ 'domain' } || q{};
    $Self->{ 'selector' } = $Args->{ 'selector' } || q{};
    $Self->{ 'url_list' } = [];
    $Self->{ 'data' }     = {};
    $Self->{ 'error' }    = [];

    if ( my $Record = $Self->{ 'record' } ) {
        $Self->parse_record();
        $Self->validate_record();
        $Self->construct_url_list();
    }
    else {
        $Self->error( 'No record supplied' );
    }

    return $Self;
}

sub error {
    my ( $Self, $Error ) = @_;
    if ( $Error ) {
        push @{ $Self->{ 'error' } } , $Error;
        return;
    }
    else {
        return join( ', ', @{ $Self->{ 'error' } } );
    }
}

sub is_valid {
    my ( $Self ) = @_;
    if ( scalar @{ $Self->{ 'error' } } > 0 ) {
        return 0;
    }
    return 1;
}

sub parse_record {
    my ( $Self ) = @_;
    my $Record = $Self->{ 'record' };

    my $Data = {};
    my @Parts = split ';', $Record;
    foreach my $Part ( @Parts ) {
        $Part =~ s/^ +//;
        $Part =~ s/ +$//;
        my ( $Key, $Value ) = split '=', $Part, 2;
        $Key = lc $Key;
        if ( exists $Data->{ $Key } ) {
            $Self->error( 'Duplicate key in record' );
        }
        if ( $Key eq 'v' || $Key eq 'a' ) {
            $Data->{ $Key } = $Value;
        }
        elsif ( $Key eq 'f' || $Key eq 'l' || $Key eq 'z' ) {
            my @Values = split ',', $Value;
            $Data->{ $Key } = \@Values;
        }
        else {
            #$Self->error( 'Record has unknown tag' ); # This is to be ignored
        }
    }
    $Self->{ 'data' } = $Data;
    return;
}

sub data {
    my ( $Self ) = @_;
    return $Self->{ 'data' };
}

sub is_vector {
    my ( $Self, $Type ) = @_;
    return 1 if lc $Type eq 'svg';
    return 0;
}

sub construct_url_list {
    my ( $Self ) = @_;
    my @UrlList;
    # Need to decode , and ; as per spec
    foreach my $Location ( @{ $Self->{ 'data' }->{ 'l' } } ) {
        foreach my $Size ( @{ $Self->{ 'data' }->{ 'z' } } ) {
            foreach my $Type ( @{ $Self->{ 'data' }->{ 'f' } } ) {
                if ( $Self->is_vector( $Type ) ) {
                    last unless (
                        $Size eq @{ $Self->{ 'data' }->{ 'z' } }[0]
                        ||
                        $Size eq @{ $Self->{ 'data' }->{ 'z' } }[-1]
                    );
                }
                my $Url = $Location . $Size . '.' . $Type;
                push @UrlList, $Url;
            }
        }
    }
    $Self->{ 'url_list' } = \@UrlList;
    return;
}

sub url_list {
    my ( $Self ) = @_;
    return $Self->{ 'url_list' };
}

sub validate_record {
    my ( $Self ) = @_;
    my $Data = $Self->{ 'data' };

    # Missing or invalid v
    if ( ! exists ( $Data->{ 'v' } ) ) {
        $Self->error( 'Missing v tag' );
    }
    else {
        $Self->error( 'Empty v tag' ) if lc $Data->{ 'v' } eq '';
        $Self->error( 'Invalid v tag' ) if lc $Data->{ 'v' } ne 'bimi1';
    }

    # Missing l
    # Invalid l url
    # l is hot https://
    if ( ! exists ( $Data->{ 'l' } ) ) {
        $Self->error( 'Missing l tag' );
    }
    else {
        if ( scalar @{ $Data->{ 'l' } } == 0 ) {
                $Self->error( 'Empty l tag' );
        }
        else {
            foreach my $l ( @{ $Data->{ 'l' } } ) {
                $Self->error( 'Empty l tag' ) if $l eq '';
                if ( ! ( $l =~ /^https:\/\// ) ) {
                    $Self->error( 'Invalid transport in l tag' );
            }
        }
        }
    }

    # Missing z (indicates opt out)
    # Validate a auth

    # Missing f
    if ( ! exists ( $Data->{ 'f' } ) ) {
        # png is the default
        $Data->{ 'f' } = [ 'png' ];
    }
    elsif ( scalar @{ $Data->{ 'f' } } == 0 ) {
        $Self->error( 'Empty f entry' );
    }
    else {
        # Unknown f png tiff tif jpg jpeg svg
        foreach my $f ( @{ $Data->{ 'f' } } ) {
            if ( $f eq '' ) {
                $Self->error( 'Empty f entry' );
                next;
            }
            next if ( $f eq 'png' );
            next if ( $f eq 'tif' );
            next if ( $f eq 'tiff' );
            next if ( $f eq 'jpg' );
            next if ( $f eq 'jpeg' );
            next if ( $f eq 'svg' );
            $Self->error( 'Unknown value in f tag' );
        }
    }

    # Missing z
    # Empty z indicates no image
    # z is not a WxH size
    # z is < minimum of 32
    # z is > maximum of 1024
    if ( ! exists ( $Data->{ 'z' } ) ) {
        # Undefined result?
        $Self->error( 'Missing z tag' );
    }
    else {
        foreach my $z ( @{ $Data->{ 'z' } } ) {
            if ( $z eq '' ) {
                $Self->error( 'Empty z entry' );
                ## ToDo this is not an error if the entire tag is empty
                next;
            }
            my ( $x, $y ) = split 'x', $z, 2;
            if ( ! $x ) {
                $Self->error( 'Invalid z tag' );
            }
            elsif ( ! ( $x =~ /^\d+$/ ) ) {
                $Self->error( 'Invalid z tag' );
            }
            else {
                $Self->error( 'Invalid dimension in z tag' ) if $x < 32;
                $Self->error( 'Invalid dimension in z tag' ) if $x > 1024;
            }
            if ( ! $y ) {
                $Self->error( 'Invalid z tag' );
            }
            elsif ( ! ( $y =~ /^\d+$/ ) ) {
                $Self->error( 'Invalid z tag' );
            }
            else {
                $Self->error( 'Invalid dimension in z tag' ) if $y < 32;
                $Self->error( 'Invalid dimension in z tag' ) if $y >1024;
            }
        }
    }

    return;
}

1;
