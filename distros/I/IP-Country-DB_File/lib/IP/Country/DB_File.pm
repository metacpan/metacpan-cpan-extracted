package IP::Country::DB_File;
$IP::Country::DB_File::VERSION = '3.03';
use strict;
use warnings;

# ABSTRACT: IPv4 and IPv6 to country translation using DB_File

use DB_File ();
use Fcntl ();
use Socket 1.94 ();

sub new {
    my ($class, $db_file) = @_;
    $db_file = 'ipcc.db' unless defined($db_file);

    my $this = {};
    my %db;

    $this->{db} = tie(%db, 'DB_File', $db_file, Fcntl::O_RDONLY, 0666,
                      $DB_File::DB_BTREE)
        or die("Can't open database $db_file: $!");

    return bless($this, $class);
}

sub inet_ntocc {
    my ($this, $addr) = @_;

    my ($key, $data);
    $this->{db}->seq($key = "4$addr", $data, DB_File::R_CURSOR()) == 0
        or return undef;
    # Verify that key starts with '4' and isn't from IPv6 range.
    return undef if ord($key) != 52;

    my $start = substr($data, 0, 4);
    my $cc    = substr($data, 4, 2);

    return $addr ge $start ? $cc : undef;
}

sub inet_atocc {
    my ($this, $ip) = @_;

    my $addr = Socket::inet_aton($ip);
    return undef unless defined($addr);

    my ($key, $data);
    $this->{db}->seq($key = "4$addr", $data, DB_File::R_CURSOR()) == 0
        or return undef;
    # Verify that key starts with '4' and isn't from IPv6 range.
    return undef if ord($key) != 52;

    my $start = substr($data, 0, 4);
    my $cc    = substr($data, 4, 2);

    return $addr ge $start ? $cc : undef;
}

sub inet6_ntocc {
    my ($this, $addr) = @_;

    $addr = substr($addr, 0, 8);

    my ($key, $data);
    $this->{db}->seq($key = "6$addr", $data, DB_File::R_CURSOR()) == 0
        or return undef;
    my $start = substr($data, 0, 4);
    my $cc    = substr($data, 4, 2);

    return $addr ge $start ? $cc : undef;
}

sub inet6_atocc {
    my ($this, $host) = @_;

    my ($err, $result) = Socket::getaddrinfo($host, undef, {
        family   => Socket::AF_INET6,
        socktype => Socket::SOCK_STREAM,
    });
    return undef if $err || !$result;
    my (undef, $addr) = Socket::unpack_sockaddr_in6($result->{addr});

    $addr = substr($addr, 0, 8);

    my ($key, $data);
    $this->{db}->seq($key = "6$addr", $data, DB_File::R_CURSOR()) == 0
        or return undef;
    my $start = substr($data, 0, 8);
    my $cc    = substr($data, 8, 2);

    return $addr ge $start ? $cc : undef;
}

sub db_time {
    my $this = shift;

    my $file;
    my $fd = $this->{db}->fd();
    open($file, "<&$fd")
        or die("Can't dup DB file descriptor: $!\n");
    my @stat = stat($file)
        or die("Can't stat DB file descriptor: $!\n");
    close($file);

    return $stat[9]; # mtime
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IP::Country::DB_File - IPv4 and IPv6 to country translation using DB_File

=head1 VERSION

version 3.03

=head1 SYNOPSIS

    use IP::Country::DB_File;

    my $ipcc = IP::Country::DB_File->new();
    my $cc = $ipcc->inet_atocc('1.2.3.4');
    my $cc = $ipcc->inet_atocc('host.example.com');
    my $cc = $ipcc->inet6_atocc('1a00:300::');
    my $cc = $ipcc->inet6_atocc('ipv6.example.com');

=head1 DESCRIPTION

IP::Country::DB_File is a light-weight module for fast IP address to country
translation based on L<DB_File>. The country code database is stored in a
Berkeley DB file. You have to build the database using C<build_ipcc.pl> or
L<IP::Country::DB_File::Builder> before you can lookup country codes.

This module tries to be API compatible with the other L<IP::Country> modules.
The installation of L<IP::Country> is not required.

There are many other modules for locating IP addresses. Neil Bowers posted
an L<excellent review|http://neilb.org/reviews/ip-location.html>. Some
features that make this module unique:

=over

=item *

IPv6 support.

=item *

Pure Perl. Math::Int64 is needed to build a database with IPv6 addresses
but the lookup code only uses Perl core modules.

=item *

Reasonably fast and accurate.

=item *

Builds the database directly from the statistics files of the regional
internet registries. No third-party tie-in.

=back

=head1 CONSTRUCTOR

=head2 new

    my $ipcc = IP::Country::DB_File->new( [$db_file] );

Creates a new object and opens the database file I<$db_file>. I<$db_file>
defaults to F<ipcc.db>. The database file can be built with
L<IP::Country::DB_File::Builder> or the C<build_ipcc.pl> command.

=head1 METHODS

=head2 inet_atocc

    my $cc = $ipcc->inet_atocc($host);

Looks up the country code of host I<$host>. I<$host> can either be an
IPv4 address in dotted quad notation or a hostname.

If successful, returns the country code. In most cases this is an ISO-3166-1
alpha-2 country code, but there are also generic codes like C<EU> for Europe
or C<AP> for Asia/Pacific. All country codes consist of two uppercase
letters.

Returns C<**> for private IP addresses.

Returns undef if there's no country code listed for the IP address, the DNS
lookup fails, or the host string is invalid.

=head2 inet_ntocc

    my $cc = $ipcc->inet_ntocc($packed_address);

Like I<inet_atocc> but works with a packed IPv4 address.

=head2 inet6_atocc

    my $cc = $ipcc->inet6_atocc($host);

Like I<inet_atocc> but works with IPv6 addresses or hosts.

=head2 inet6_ntocc

    my $cc = $ipcc->inet6_ntocc($packed_address);

Like I<inet_ntocc> but works with a packed IPv6 address.

=head2 db_time

    my $time = $ipcc->db_time();

Returns the mtime of the DB file.

=head1 SEE ALSO

L<IP::Country>, L<IP::Country::DB_File::Builder>

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
