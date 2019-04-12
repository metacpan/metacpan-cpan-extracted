package Lemonldap::NG::Common::Conf::Wrapper;

use strict;
use JSON;

our $VERSION = '2.0.3';

sub TIEHASH {
    my ( $class, $conf, $overrides ) = @_;
    my %h = %$overrides;
    foreach ( keys %h ) {
        if ( $h{$_} =~ /^[\[\{]/ ) {
            my $tmp = eval { JSON::from_json( $h{$_} ) };
            if ($@) {
                print STDERR "Wrapper: unable to compile $_ key, skipping\n";
            }
            else {
                $h{$_} = $tmp;
            }
        }
    }
    return bless {
        _wrapC => $conf,
        _wrapO => \%h,
    }, $class;
}

sub FETCH {
    my ( $self, $key ) = @_;
    return (
        exists( $self->{_wrapO}->{$key} )
        ? $self->{_wrapO}->{$key}
        : $self->{_wrapC}->{$key}
    );
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    return $self->{_wrapO}->{$key} = $value;
}

sub DELETE {
    my ( $self, $key ) = @_;
    my $res = $self->{_wrapO}->{$key} // $self->{_wrapC}->{$key};
    $self->{_wrapO}->{$key} = undef;
    return $res;
}

sub EXISTS {
    my ( $self, $key ) = @_;
    return (
             exists( $self->{_wrapC}->{$key} )
          or exists( $self->{_wrapO}->{$key} )
    );
}

sub DESTROY {
    my $self = shift;
    delete $self->{_wrapO};
    delete $self->{_wrapC};
}

sub FIRSTKEY {
    return each %{ $_[0]->{_wrapC} };
}

sub NEXTKEY {
    return each %{ $_[0]->{_wrapC} };
}

1;
