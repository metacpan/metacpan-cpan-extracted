package IP::QQWry;

use 5.008;
use warnings;
use strict;
use Carp;
use version; our $VERSION = qv('0.0.20');

my %cache;
my $tmp;            # used for hold temporary data

sub new {
    my ( $class, $db ) = @_;
    my $self = {};
    bless $self, $class;
    if ($db) {
        $self->set_db($db);
    }
    return $self;
}

# set db file of which the name is `QQWry.Dat' most of the time.
sub set_db {
    my ( $self, $db ) = @_;
    if ( $db && -r $db ) {
        open $self->{fh}, '<', $db or croak "how can this happen? $!";
        $self->_init_db;
        return 1;
    }
    carp 'set_db failed';
    return;
}

sub _init_db {
    my $self = shift;
    read $self->{fh}, $tmp, 4;
    $self->{first_index} = unpack 'V', $tmp;
    read $self->{fh}, $tmp, 4;
    $self->{last_index} = unpack 'V', $tmp;
}

# sub query is the the interface for user.
# the parameter is a IPv4 address

sub query {
    my ( $self, $input ) = @_;
    unless ( $self->{fh} ) {
        carp 'database is not provided';
        return;
    }

    my $ip = $self->_convert_input($input);

    if ($ip) {
        $cache{$ip} = [ $self->_result($ip) ] unless $self->cached($ip);
        return wantarray ? @{ $cache{$ip} } : join '', @{ $cache{$ip} };
    }
    return;
}

sub _convert_input {
    my ( $self, $input ) = @_;
    if ( $input =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ ) {
        return $1 * 256**3 + $2 * 256**2 + $3 * 256 + $4;
    }
    elsif ( $input =~ /(\d+)/ ) {
        return $1;
    }
    else {
        return;
    }
}

sub cached {
    my ( $self, $input ) = @_;
    my $ip = $self->_convert_input($input);
    return $cache{$ip} ? 1 : 0;
}

sub clear {
    my ( $self, $ip ) = @_;
    if ($ip) {
        undef $cache{$ip};
    }
    else {
        undef %cache;
    }
}

sub db_version {
    return shift->query('255.255.255.0');    # db version info is held there
}

# get the useful infomation which will be returned to user

sub _result {
    my ( $self, $ip ) = @_;
    my $index = $self->_index($ip);
    return unless $index;                    # can't find index

    my ( $base, $ext ) = (q{}) x 2;

    seek $self->{fh}, $index + 4, 0;
    read $self->{fh}, $tmp, 3;

    my $offset = unpack 'V', $tmp . chr 0;
    seek $self->{fh}, $offset + 4, 0;
    read $self->{fh}, $tmp, 1;

    my $mode = ord $tmp;

    if ( $mode == 1 ) {
        $self->_seek;
        $offset = tell $self->{fh};
        read $self->{fh}, $tmp, 1;
        $mode = ord $tmp;
        if ( $mode == 2 ) {
            $self->_seek;
            $base = $self->_str;
            seek $self->{fh}, $offset + 4, 0;
            $ext = $self->_ext;
        }
        else {
            seek $self->{fh}, -1, 1;
            $base = $self->_str;
            $ext  = $self->_ext;
        }
    }
    elsif ( $mode == 2 ) {
        $self->_seek;
        $base = $self->_str;
        seek $self->{fh}, $offset + 8, 0;
        $ext = $self->_ext;
    }
    else {
        seek $self->{fh}, -1, 1;
        $base = $self->_str;
        $ext  = $self->_ext;
    }

    # 'CZ88.NET' means we don't have useful information
    $base = '' if $base =~ /CZ88\.NET/;
    $ext = '' if $ext =~ /CZ88\.NET/;
    return ( $base, $ext );
}

sub _index {
    my ( $self, $ip ) = @_;
    my $low = 0;
    my $up  = ( $self->{last_index} - $self->{first_index} ) / 7;
    my ( $mid, $ip_start, $ip_end );

    # find the index using binary search
    while ( $low <= $up ) {
        $mid = int( ( $low + $up ) / 2 );
        seek $self->{fh}, $self->{first_index} + $mid * 7, 0;
        read $self->{fh}, $tmp, 4;
        $ip_start = unpack 'V', $tmp;

        if ( $ip < $ip_start ) {
            $up = $mid - 1;
        }
        else {
            read $self->{fh}, $tmp, 3;
            $tmp = unpack 'V', $tmp . chr 0;
            seek $self->{fh}, $tmp, 0;
            read $self->{fh}, $tmp, 4;
            $ip_end = unpack 'V', $tmp;

            if ( $ip > $ip_end ) {
                $low = $mid + 1;
            }
            else {
                return $self->{first_index} + $mid * 7;
            }
        }
    }

    return;
}

sub _seek {
    my $self = shift;
    read $self->{fh}, $tmp, 3;
    my $offset = unpack 'V', $tmp . chr 0;
    seek $self->{fh}, $offset, 0;
}

# get string ended by \0

sub _str {
    my $self = shift;
    my $str;

    read $self->{fh}, $tmp, 1;
    while ( ord $tmp > 0 ) {
        $str .= $tmp;
        read $self->{fh}, $tmp, 1;
    }
    return $str;
}

sub _ext {
    my $self = shift;
    read $self->{fh}, $tmp, 1;
    my $mode = ord $tmp;

    if ( $mode == 1 || $mode == 2 ) {
        $self->_seek;
        return $self->_str;
    }
    else {
        return chr($mode) . $self->_str;
    }
}

sub DESTROY {
    my $self = shift;
    close $self->{fh} if $self->{fh};
}

1;

__END__

=head1 NAME

IP::QQWry - a simple interface for QQWry IP database(file).


=head1 VERSION

This document describes IP::QQWry version 0.0.16


=head1 SYNOPSIS

    use IP::QQWry;
    my $qqwry = IP::QQWry->new('QQWry.Dat');
    my $info = $qqwry->query('166.111.166.111');
    my ( $base, $ext ) = $qqwry->query(2792334959);
    my $version = $qqwry->db_version;
    $qqwry->clear;

=head1 DESCRIPTION


'QQWry.Dat' L<http://www.cz88.net/fox/> is an IP file database.  It provides
some useful infomation such as the geographical position of the host bound
with some IP address, the IP's owner, etc. L<IP::QQWry> provides a simple
interface for this file database.

For more about the format of the database, take a look at this:
L<http://lumaqq.linuxsir.org/article/qqwry_format_detail.html>

Caveat: The 'QQWry.Dat' database uses gbk or big5 encoding, C<IP::QQWry> doesn't
do any decoding stuff, use C<IP::QQWry::Decoded> if you want the returned info
decoded.

=head1 INTERFACE

=over 4

=item new

Accept one optional parameter for database file name.
Return an object of L<IP::QQWry>.

=item set_db

Set database file.
Accept a IP database file path as a parameter.
Return 1 for success, undef for failure.

=item query

Accept one parameter, which has to be an IPv4 address such as
`166.111.166.111` or an integer like 2792334959.

In list context, it returns a list containing the base part and the extension
part of infomation, respectively. The base part is usually called the country
part though it doesn't refer to country all the time. The extension part is
usually called the area part.

In scalar context, it returns a string which is just a catenation of the base
and extension parts.

If it can't find useful information, return undef.

Caveat: the domain name as an argument is not supported any more since v0.0.12.
Because a domain name could have more than one IP address bound, the
previous implementation is lame and not graceful, so I decided to dump it.

=item clear

clear cache

=item cached($ip)

return 1 if $ip is cached, 0 otherwise

=item db_version

return database version.

=back

=head1 DEPENDENCIES

L<version>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2011, sunnavy C<< <sunnavy@gmail.com> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
