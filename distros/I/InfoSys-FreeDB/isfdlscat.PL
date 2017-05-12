# -*- perl -*-

use strict;

my $script = <<'SCRIPT';
~startperl~ -w

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

use strict;
use Error qw(:try);
use File::Basename;
use Getopt::Long;
use IO::File;
use InfoSys::FreeDB;
use InfoSys::FreeDB::Entry;

# Default options
my $client_name_def = 'isfdcmds';
my ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;
my $client_version_def = $VERSION;

# Globals
my $basename=basename($0);

# Get options
my $h = 0;
my ($i, $o, $dev, $span, $oggenc_b, $protocol, $proto_level);
my $client_name = $client_name_def;
my $client_version = $client_version_def;
my ($freedb_host, $freedb_port, $freedb_cgi, $proxy_host, $proxy_port);
my ($proxy_user, $proxy_passwd);
if (! GetOptions(
        'h' => \$h,
        'i=s' => \$i,
        'o=s' => \$o,
        'dev=s' => \$dev,
        'oggenc_b=s' => \$oggenc_b,
        'span=s' => \$span,
        'protocol=s' => \$protocol,
        'proto_level=s' => \$proto_level,
        'client_name=s' => \$client_name,
        'client_version=s' => \$client_version,
        'freedb_host=s' => \$freedb_host,
        'freedb_port=s' => \$freedb_port,
        'freedb_cgi=s' => \$freedb_cgi,
        'proxy_host=s' => \$proxy_host,
        'proxy_port=s' => \$proxy_port,
        'proxy_user=s' => \$proxy_user,
        'proxy_passwd=s' => \$proxy_passwd,
            ) ) {
    &usage;
    exit(1);
}

# Show usage
if ($h) {
    &usage;
    exit(0);
}

# Open output file
my $fh;
if ($o) {
    $fh = IO::File->new("> $o");
    defined($fh) ||
        throw Error::Simple ("ERROR: $basename: Failed to open file '$o' for writing.");
} else {
    $fh = IO::Handle->new_from_fd(fileno(STDOUT), 'w');
}

# Make connection
my $fact = InfoSys::FreeDB->new();
my %opt;
foreach my $pair (
            [ 'protocol', $protocol ],
            [ 'proto_level', $proto_level ],
            [ 'client_name', $client_name ],
            [ 'client_version', $client_version ],
            [ 'freedb_host', $freedb_host ],
            [ 'freedb_port', $freedb_port ],
            [ 'freedb_cgi', $freedb_cgi ],
            [ 'proxy_host', $proxy_host ],
            [ 'proxy_port', $proxy_port ],
            [ 'proxy_user', $proxy_user ],
            [ 'proxy_passwd', $proxy_passwd ],
        ) {
    $opt{ $pair->[0] } = $pair->[1] if ( $pair->[1] );
}
&get_passwd();
my $conn = $fact->create_connection( \%opt );

# Switch application
if ($basename =~ /lscat/) {
    # Get categories
    my $res = $conn->lscat();

    # Print the categories
    $fh->print( join(' ', $res->get_category() ), "\n");

} elsif ($basename =~ /motd/) {
    # Get motd
    my $res = $conn->motd();

    # Print motd
    $fh->print($res->get_message_text(), "\n");

} elsif ($basename =~ /sites/) {
    # Get sites
    my $res = $conn->sites();

    # Print sites
    foreach my $site ( $res->get_site() ) {
        print join(' ',
            $site->get_site(),
            $site->get_protocol(),
            $site->get_port(),
            $site->get_address(),
            $site->get_latitude(),
            $site->get_longitude(),
            $site->get_description(),
        ), "\n";
    }

} elsif ($basename =~ /query/) {
    # Read entry
    my $entry;
    if ($i) {
        $entry = InfoSys::FreeDB::Entry->new_from_fn( $i );
    } elsif ($dev) {
        $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia( $dev );
    } else {
        $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia();
    }

    # Query
    my $res = $conn->query($entry);
    $res->is_error() &&
        die('Oops, error quering FreeDB/CDDB');

    # Did we get a match match
    scalar( $res->get_match() ) ||
        die('No match found');

    # Read match
    $res = $conn->read( $res->shift_match() );
    $res->is_error() &&
        die('Oops, error reading FreeDB/CDDB');
    $entry = $res->get_entry();

    # Write entry
    $entry->write_fh( $fh );

} elsif ($basename =~ /rip/) {
    # Read entry
    my $entry;
    if ($i) {
        $entry = InfoSys::FreeDB::Entry->new_from_fn( $i );
    } else {
        my $entry_dev;
        if ($dev) {
            $entry_dev = InfoSys::FreeDB::Entry->new_from_cdparanoia( $dev );
        } else {
            $entry_dev = InfoSys::FreeDB::Entry->new_from_cdparanoia();
        }

        # Query
        my $res = $conn->query($entry_dev);
        $res->is_error() &&
            die('Oops, error quering FreeDB/CDDB');

        # Did we get a match match
        scalar( $res->get_match() ) ||
            die('No match found');

        # Read match
        $res = $conn->read( $res->shift_match() );
        $res->is_error() &&
            die('Oops, error reading FreeDB/CDDB');
        $entry = $res->get_entry();

        # Write entry
        $entry->write_fh( $fh );
    }

    # Rip the CD
    my ($min, $max) = &parse_range( $entry->get_track() );
    my @cmd = qw(cdparanoia);
    push(@cmd, '-d', $dev) if ($dev);
    push(@cmd, '-B');

    my $i = 0;
    foreach my $track ( $entry->get_track() ) {
        $i++;
        $i < $min && next;
        $i > $max && last;
        my $title = $track->get_title();
        $title =~ s/[\s\/]+/-/g;
        my @cmd = (@cmd, $i);

        # Execute command
        print STDERR "@cmd\n";
        system(@cmd);
        ($?>>8) &&
            die("Oops, command '@cmd' failed");

        # Rename output file
        my $src = sprintf("track%02d.cdda.wav", $i);
        my $dest = sprintf("%02d-%s.wav", $i, $title);
        print STDERR "mv $src $dest\n";
        rename($src, $dest);
    }
} elsif ($basename =~ /oggenc/) {
    # Read entry
    my $entry;
    if ($i) {
        $entry = InfoSys::FreeDB::Entry->new_from_fn( $i );
    } else {
        my $entry_dev;
        if ($dev) {
            $entry_dev = InfoSys::FreeDB::Entry->new_from_cdparanoia( $dev );
        } else {
            $entry_dev = InfoSys::FreeDB::Entry->new_from_cdparanoia();
        }

        # Query
        my $res = $conn->query($entry_dev);
        $res->is_error() &&
            die('Oops, error quering FreeDB/CDDB');

        # Did we get a match match
        scalar( $res->get_match() ) ||
            die('No match found');

        # Read match
        $res = $conn->read( $res->shift_match() );
        $res->is_error() &&
            die('Oops, error reading FreeDB/CDDB');
        $entry = $res->get_entry();

        # Write entry
        $entry->write_fh( $fh );
    }

    # Encode the tracks
    my ($min, $max) = &parse_range( $entry->get_track() );
    my @cmd = qw(oggenc);
    push(@cmd, '-b', $oggenc_b) if ($oggenc_b);
    foreach my $track ( $entry->get_track() ) {
        $i++;
        $i < $min && next;
        $i > $max && last;
        my $title = $track->get_title();
        $title =~ s/[\s\/]+/-/g;
        my @cmd = ( @cmd, sprintf("%02d-%s.wav", $i, $title) );

        push( @cmd, '-t', $track->get_title($i) ) if ( $track->get_title($i) );
        push( @cmd, '-a', $entry->get_artist() ) if ( $entry->get_artist() );
        push( @cmd, '-l', $entry->get_title() ) if ( $entry->get_title() );
        push( @cmd, '-o', sprintf("%02d-%s.ogg", $i, $title) );

        # Execute command
        print STDERR "@cmd\n";
        system(@cmd);
        die('Oops, command failed') if ($?>>8);
    }
}

# Exit OK
exit(0);

sub get_passwd {
    # Get proxy password if necessary
    if ($proxy_host && $proxy_user && !$proxy_passwd) {
        print STDERR "Enter password for $proxy_user\@$proxy_host: ";
        if ( system('stty -echo') != 0) {
            system('stty echo'); 
            die "Error setting terminal to not echo"; 
        }
        $proxy_passwd = <>;
        system('stty echo');
        print STDERR "\n";
        chomp($proxy_passwd);
        $opt{proxy_passwd} = $proxy_passwd;
    }
}

sub parse_range {
    my $max = int(shift);

    # Return full span if $span not defined
    defined($span) ||
        return(1, $max);

    # Check for single span
    if ($span =~ /^[0-9]+$/ && int($span) > 0) {
        if (int($span) > $max) {
            throw Error::Simple ("ERROR: basename: Range failure.");
        } else {
            return( int($span), int($span) );
        }
    }

    # Split the span parameter
    my @span = split(/-/, $span);

    # Check amount of parts
    (scalar(@span) > 2 || scalar(@span) < 1) &&
        throw Error::Simple ("ERROR: basename: Range failure.");

    # Replace undefined values
    $span[0] = 1 if ( ! defined( $span[0] ) || $span[0] eq '');
    $span[1] = $max if ( ! defined( $span[1] ) );

    # Check if $span[0] <= $span[1]
    $span[0] <= $span[1] ||
        throw Error::Simple ("ERROR: basename: Range failure.");

    # Ckech the span
    $span[0] <= 0 &&
        throw Error::Simple ("ERROR: basename: Range failure.");
    $span[1] > $max &&
        throw Error::Simple ("ERROR: basename: Range failure.");

    # Return
    return(@span);
}

sub usage {
    print STDERR <<EOF;
Usage: $basename [--h] [--i <infile>] [--o <outfile>] [--dev <device>]
        [--span <span>] [--protocol <protocol>] [--proto_level <proto_level>]
        [--client_name <client_name>] [--client_version <client_version>]
        [--freedb_host <freedb_host>] [--freedb_port <freedb_port>]
        [--freedb_cgi <freedb_cgi>]
        [--proxy_host <proxy_host>] [--proxy_port <proxy_port>]
        [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]
  NOTES:
     --h shows this message
     --i no default
     --o defaults to STDOUT
     --dev defaults to InfoSys::FreeDB's default
     --span defaults to all tracks
     --protocol defaults to InfoSys::FreeDB's default
     --proto_level defaults to InfoSys::FreeDB's default
     --client_name defaults to $client_name_def
     --client_version defaults to $client_version_def
     --freedb_host defaults to InfoSys::FreeDB's default
     --freedb_port defaults to InfoSys::FreeDB's default
     --freedb_cgi defaults to InfoSys::FreeDB's default
     --proxy_host defaults to InfoSys::FreeDB's default
     --proxy_port defaults to InfoSys::FreeDB's default
     --proxy_user
     --proxy_passwd if empty is asked during processing if --proxy_host
       and --proxy_user set.
EOF
}

__END__

=head1 NAME

isfdlscat, isfdmotd, isfdquery, isfdrip, isfdsites

=over

=item isfdlscat

Run a C<cddb lscat> command on a FreeDB/CDDB server

=item isfdmotd

Run a C<motd> command on a FreeDB/CDDB server

=item isfdquery

Run a C<cddb query> command on a FreeDB/CDDB server

=item isfdrip

Rip a CD using FreeDB/CDDB info

=item isfdsites

Run a C<sites> command on a FreeDB/CDDB server

=back

=head1 SYNOPSIS

=over

=item isfdlscat |isfdmotd |isfdsites

[--h] [--o <outfile>] [--protocol <protocol>] [--proto_level <proto_level>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=item isfdquery

[--h] [--i <infile>] [--o <outfile>] [--dev <device>] [--protocol <protocol>] [--proto_level <proto_level>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=item isfdrip

[--h] [--i <infile>] [--dev <device>] [--span <span>] [--protocol <protocol>] [--proto_level <proto_level>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=item isfdoggenc

[--h] [--i <infile>] [--dev <device>] [--oggenc_b <bitrate>] [--span <span>] [--protocol <protocol>] [--proto_level <proto_level>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=back

=head1 DESCRIPTION

The programs C<isfdlscat>, C<isfdmotd>, C<isfdquery>, C<isfdrip>, C<isfdsites> and C<isfdoggenc> use L<InfoSys::FreeDB> modules to obtain information from FreeDB/CDDB servers and to process it.

All these programs are implemented through a single C<Perl> script which is intended to illustrate the usage of the C<InfoSys::FreeDB> modules.

=head2 Options:

=over

=item --h

Show usage.

=item --i

Input file. No default.

=item --o

Output file. Defaults to C<STDOUT>.

=item --dev

CD device. Defaults to C<InfoSys::FreeDB's> default.

=item --oggenc_b

Bitrate for OGG encoding. See L<oggenc>.

=item --span

Span to rip or encode. Defaults to all tracks on CD.

Examples:
 3-7 : from 3 until 7
 -7  : from 1 until 7
 7-  : from 7 until the end of the CD
 7   : 7 only
 7-7 : 7 only

=item --protocol

The communication protocol: C<HTTP> or C<CDDBP>. Defaults to C<InfoSys::FreeDB's> default.

=item --proto_level

The FreeDB protocol level. Defaults to C<InfoSys::FreeDB's> default.

=item --client_name

Client name. Defaults to C<isfdcmds>.

=item --client_version

Client version. Defaults to the version of the C<InfoSys::FreeDB> package.

=item --freedb_host

FreeDB/CDDB host. Defaults to C<InfoSys::FreeDB's> default.

=item --freedb_port

Port on FreeDB/CDDB host. Defaults to C<InfoSys::FreeDB's> default.

=item --freedb_cgi

Cgi on FreeDB/CDDB B<HTTP> host. Defaults to C<InfoSys::FreeDB's> default.

=item --proxy_host

Proxy host.

=item --proxy_port

Port on proxy host. Defaults to C<InfoSys::FreeDB's> default.

=item --proxy_user

User name for proxy host.

=item --proxy_passwd

Password for user on proxy host. Prompted for if empty and B<--proxy_host> and B<--proxy_user> are set.

=back

=head1 SEE ALSO

L<isfdcdi>

=head1 EXAMPLE

Quick and dirty rip:
 $isfdrip

Slightly more sophisticated rip:
 $ isfdcdi --o cd-tech.cddb
 $isfdquery --i cd-tech.cddb --o cd-query.cddb
 $ # Edit file cd-query.cddb
 $isfdrip --i cd-query.cddb

=head1 BUGS

None known (yet).

=head1 HISTORY

First development: September 2002

=head1 AUTHOR

Vincenzo Zocca E<lt>Vincenzo@Zocca.comE<gt>

=head1 COPYRIGHT

Copyright 2002, Vincenzo Zocca.

=head1 LICENSE

This file is part of the C<InfoSys::FreeDB> module hierarchy for Perl by
Vincenzo Zocca.

The InfoSys::FreeDB module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The InfoSys::FreeDB module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the InfoSys::FreeDB module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut
SCRIPT

use Config;

my $file = __FILE__; $file =~ s/\.PL$//;

$script =~ s/\~(\w+)\~/$Config{$1}/eg;
if ( ! ( open(FILE, ">$file") ) ||
    ! ( print FILE $script) ||
    ! ( close(FILE) ) ) {
    die "Error while writing $file: $!\n";
}
print "Extracted $file from ",__FILE__," with variable substitutions.\n";

# end

