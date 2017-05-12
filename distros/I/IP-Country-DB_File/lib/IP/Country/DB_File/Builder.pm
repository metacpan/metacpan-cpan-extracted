package IP::Country::DB_File::Builder;
$IP::Country::DB_File::Builder::VERSION = '3.03';
use strict;
use warnings;

# ABSTRACT: Build an IP address to country code database

use DB_File ();
use Fcntl ();
use Math::Int64 qw(
    int64 int64_to_net net_to_int64
    :native_if_available
);
use Net::FTP ();
use Socket 1.94 ();

# Regional Internet Registries
my @rirs = (
    { name=>'arin',    server=>'ftp.arin.net'    },
    { name=>'ripencc', server=>'ftp.ripe.net'    },
    { name=>'afrinic', server=>'ftp.afrinic.net' },
    { name=>'apnic',   server=>'ftp.apnic.net'   },
    { name=>'lacnic',  server=>'ftp.lacnic.net'  },
);

# Constants
sub _EXCLUDE_IPV4 { 1 }
sub _EXCLUDE_IPV6 { 2 }

# IPv6 support is broken in some Socket versions with older Perls.
# (RT #98248)
sub _ipv6_socket_broken {
    return $^V < 5.14 && $Socket::VERSION >= 2.010;
}

sub _ipv6_supported {
    my ($err, $result) = Socket::getaddrinfo('::1', undef, {
        flags    => Socket::AI_NUMERICHOST,
        family   => Socket::AF_INET6,
        socktype => Socket::SOCK_STREAM,
    });

    return !$err && $result ? 1 : 0;
}

sub new {
    my ($class, $db_file) = @_;
    $db_file = 'ipcc.db' unless defined($db_file);

    my $this = {
        num_ranges_v4    => 0,
        num_ranges_v6    => 0,
        num_addresses_v4 => 0,
    };

    my %db;
    my $flags = Fcntl::O_RDWR|Fcntl::O_CREAT|Fcntl::O_TRUNC;
    $this->{db} = tie(%db, 'DB_File', $db_file, $flags, 0666,
                      $DB_File::DB_BTREE)
        or die("Can't open database $db_file: $!");

    return bless($this, $class);
}

# Accessors
sub num_ranges_v4    { $_[0]->{num_ranges_v4} }
sub num_ranges_v6    { $_[0]->{num_ranges_v6} }
sub num_addresses_v4 { $_[0]->{num_addresses_v4} }

sub _store_ip_range {
    my ($this, $type, $start, $end, $cc) = @_;

    my ($key, $data);

    if ($type eq 'ipv4') {
        $key  = pack('aN', '4', $end - 1);
        $data = pack('Na2', $start, $cc);

        $this->{num_ranges_v4}    += 1;
        $this->{num_addresses_v4} += $end - $start;
    }
    elsif ($type eq 'ipv6') {
        $key  = '6' . int64_to_net($end - 1);
        $data = pack('a8a2', int64_to_net($start), $cc);

        $this->{num_ranges_v6} += 1;
    }

    $this->{db}->put($key, $data) >= 0 or die("dbput: $!");
}

sub _store_private_networks {
    my ($this, $flags) = @_;

    if (!($flags & _EXCLUDE_IPV4)) {
        # 10.0.0.0
        $this->_store_ip_range('ipv4', 0x0a000000, 0x0b000000, '**');
        # 172.16.0.0
        $this->_store_ip_range('ipv4', 0xac100000, 0xac200000, '**');
        # 192.168.0.0
        $this->_store_ip_range('ipv4', 0xc0a80000, 0xc0a90000, '**');
    }

    if (!($flags & _EXCLUDE_IPV6)) {
        # fc00::/7
        $this->_store_ip_range(
            'ipv6',
            int64(0xfc) << 56, int64(0xfe) << 56,
            '**',
        );
    }
}

sub _import_file {
    my ($this, $file, $flags) = @_;

    my $seen_header;
    my (@ranges_v4, @ranges_v6);

    while (my $line = readline($file)) {
        next if $line =~ /^#/ or $line !~ /\S/;

        if (!$seen_header) {
            # Ignore first line.
            $seen_header = 1;
            next;
        }

        my ($registry, $cc, $type, $start, $value, $date, $status) =
            split(/\|/, $line);

        next if $start eq '*'; # Summary lines.
        next if $cc eq '';

        $cc = uc($cc);
        die("Invalid country code '$cc'")
            if $cc !~ /^[A-Z]{2}\z/;

        # TODO (paranoid): validate $start and $value

        if ($type eq 'ipv4') {
            next if $flags & _EXCLUDE_IPV4;

            my $ip_num = unpack('N', pack('C4', split(/\./, $start)));
            my $size   = $value;

            push(@ranges_v4, [ $ip_num, $size, $cc ]);
        }
        elsif ($type eq 'ipv6') {
            next if $flags & _EXCLUDE_IPV6;

            die("IPv6 range too large: $value")
                if $value > 64;

            my ($err, $result) = Socket::getaddrinfo($start, undef, {
                flags    => Socket::AI_NUMERICHOST,
                family   => Socket::AF_INET6,
                socktype => Socket::SOCK_STREAM,
            });
            die($err) if $err;
            my (undef, $addr) = Socket::unpack_sockaddr_in6($result->{addr});

            my $ip_num = net_to_int64(substr($addr, 0, 8));
            my $size   = int64(1) << (64 - $value);

            push(@ranges_v6, [ $ip_num, $size, $cc ]);
        }
        else {
            next;
        }
    }

    my $count = 0;
    $count += $this->_store_ip_ranges('ipv4', \@ranges_v4);
    $count += $this->_store_ip_ranges('ipv6', \@ranges_v6);

    return $count;
}

sub _store_ip_ranges {
    my ($this, $type, $ranges) = @_;

    my @sorted_ranges = sort { $a->[0] <=> $b->[0] } @$ranges;

    my $count   = 0;
    my $prev_cc = '';
    my ($prev_start, $prev_end);

    if ($type eq 'ipv4') {
        $prev_start = 0;
        $prev_end   = 0;
    }
    elsif ($type eq 'ipv6') {
        $prev_start = int64(0);
        $prev_end   = int64(0);
    }

    for my $range (@sorted_ranges) {
        my ($ip_num, $size, $cc) = @$range;

        if ($ip_num == $prev_end && $prev_cc eq $cc) {
            # Concat ranges of same country
            $prev_end += $size;
        }
        else {
            $this->_store_ip_range($type, $prev_start, $prev_end, $prev_cc)
                if $prev_cc;

            $prev_start = $ip_num;
            $prev_end   = $ip_num + $size;
            $prev_cc    = $cc;
            ++$count;
        }
    }

    $this->_store_ip_range($type, $prev_start, $prev_end, $prev_cc)
        if $prev_cc;

    return $count;
}

sub _sync {
    my $this = shift;

    $this->{db}->sync() >= 0 or die("dbsync: $!");
}

sub build {
    my ($this, $dir, $flags) = @_;
    $dir   = '.' if !defined($dir);
    $flags = 0   if !defined($flags);

    if (!($flags & _EXCLUDE_IPV6) && !_ipv6_supported()) {
        warn("IPv6 support disabled. It doesn't seem to be supported on"
             . " your system.");
        warn("This is probably because getaddrinfo is broken in Perl $^V"
             . " with Socket $Socket::VERSION.")
            if _ipv6_socket_broken();
        $flags |= _EXCLUDE_IPV6;
    }

    for my $rir (@rirs) {
        my $file;
        my $filename = "$dir/delegated-$rir->{name}";
        CORE::open($file, '<', $filename)
            or die("Can't open $filename: $!, " .
                   "maybe you have to fetch files first");

        eval {
            $this->_import_file($file, $flags);
        };

        my $error = $@;
        close($file);
        die("$filename: $error") if $error;
    }

    $this->_store_private_networks($flags);

    $this->_sync();
}

sub fetch_files {
    my ($class, $dir, $verbose) = @_;
    $dir = '.' unless defined($dir);

    for my $rir (@rirs) {
        my $server = $rir->{server};
        my $name = $rir->{name};
        my $ftp_dir = "/pub/stats/$name";
        my $filename = "delegated-$name-extended-latest";

        print("Fetching ftp://$server$ftp_dir/$filename\n") if $verbose;

        my $ftp = Net::FTP->new($server)
            or die("Can't connect to FTP server $server: $@");
        $ftp->login('anonymous', '-anonymous@')
            or die("Can't login to FTP server $server: " . $ftp->message());
        $ftp->cwd($ftp_dir)
            or die("Can't find directory $ftp_dir on FTP server $server: " .
                   $ftp->message());
        $ftp->get($filename, "$dir/delegated-$name")
            or die("Get $filename from FTP server $server failed: " .
                   $ftp->message());
        $ftp->quit();
    }
}

sub remove_files {
    my ($class, $dir) = @_;
    $dir = '.' unless defined($dir);

    for my $rir (@rirs) {
        my $name = $rir->{name};
        unlink("$dir/delegated-$name");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IP::Country::DB_File::Builder - Build an IP address to country code database

=head1 VERSION

version 3.03

=head1 SYNOPSIS

    use IP::Country::DB_File::Builder;

    IP::Country::DB_File::Builder->fetch_files();
    my $builder = IP::Country::DB_File::Builder->new('ipcc.db');
    $builder->build();
    IP::Country::DB_File::Builder->remove_files();

=head1 DESCRIPTION

This module builds the database used to lookup country codes from IP addresses
with L<IP::Country::DB_File>.

The database is built from the publically available statistics files of the
Regional Internet Registries. Currently, the files are downloaded from the
following hard-coded locations:

    ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
    ftp://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest
    ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest
    ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-extended-latest
    ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-extended-latest

You can build the database directly from Perl, or by calling the
C<build_ipcc.pl> command. Since the country code data changes occasionally,
you should consider updating the database from time to time. You can also use
a database built on a different machine as long as the I<libdb> versions are
compatible.

=head1 CONSTRUCTOR

=head2 new

    my $builder = IP::Country::DB_File::Builder->new( [$db_file] );

Creates a new builder object and the database file I<$db_file>. I<$db_file>
defaults to F<ipcc.db>. The database file is truncated if it already exists.

=head1 METHODS

=head2 build

    $builder->build( [$dir] );

Builds a database from the statistics files in directory I<$dir>. I<$dir>
defaults to the current directory.

=head2 num_ranges_v4

    my $num = $builder->num_ranges_v4;

Return the number of (possibly merged) IPv4 address ranges with country
codes after a database build.

=head2 num_ranges_v6

    my $num = $builder->num_ranges_v6;

Return the number of (possibly merged) IPv6 address ranges with country
codes after a database build.

=head2 num_addresses_v4

    my $num = $builder->num_addresses_v4;

Return the number of IPv4 addresses with country codes after a database
build.

=head1 CLASS METHODS

=head2 fetch_files

    IP::Country::DB_File::Builder->fetch_files( [$dir] );

Fetches the statistics files from the FTP servers of the RIRs and stores them
in I<$dir>. I<$dir> defaults to the current directory.

This function only fetches files and doesn't build the database yet.

=head2 remove_files

    IP::Country::DB_File::Builder->remove_files( [$dir] );

Deletes the previously fetched statistics files in I<$dir>. I<$dir> defaults
to the current directory.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
