package EncodeUpdate;
use strict;
use Encode ();
use Exporter;
our @ISA = qw(Encode);
our @EXPORT;

# This module overrides some Encode.pm functions when its version is less than 2.23 to pass our tests.

sub find_encoding($;$) {
    my ( $name, $skip_external ) = @_;
    return __PACKAGE__->getEncoding( $name, $skip_external );
}

sub encode ($$;$) {
    my ( $name, $string, $check ) = @_;
    return undef unless defined $string;
    $string .= '' if ref $string;    # stringify;
    $check ||= 0;
    my $enc = find_encoding($name);
    unless ( defined $enc ) {
        require Carp;
        Carp::croak("Unknown encoding '$name'");
    }
    my $octets = $enc->encode( $string, $check );
    $_[1] = $string if $check and !ref $check and !( $check & LEAVE_SRC() );
    return $octets;
}

sub decode ($$;$) {
    my ( $name, $octets, $check ) = @_;
    return undef unless defined $octets;
    $octets .= '' if ref $octets;
    $check ||= 0;
    my $enc = find_encoding($name);
    unless ( defined $enc ) {
        require Carp;
        Carp::croak("Unknown encoding '$name'");
    }
    my $string = $enc->decode( $octets, $check );
    $_[1] = $octets if $check and !ref $check and !( $check & LEAVE_SRC() );
    return $string;
}

sub from_to($$$;$) {
    my ( $string, $from, $to, $check ) = @_;
    return undef unless defined $string;
    $check ||= 0;
    my $f = find_encoding($from);
    unless ( defined $f ) {
        require Carp;
        Carp::croak("Unknown encoding '$from'");
    }
    my $t = find_encoding($to);
    unless ( defined $t ) {
        require Carp;
        Carp::croak("Unknown encoding '$to'");
    }
    my $uni = $f->decode($string);
    $_[0] = $string = $t->encode( $uni, $check );
    return undef if ( $check && length($uni) );
    return defined( $_[0] ) ? length($string) : undef;
}

my $encver = ($Encode::VERSION =~ /^([\d\.]+)/)[0];
if ($encver < 2.23) {
    *Encode::encode  = \&encode;
    *Encode::decode  = \&decode;
    *Encode::from_to = \&from_to;
}

1;
