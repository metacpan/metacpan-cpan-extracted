# -*- perl -*-

use strict;

my $script = <<'SCRIPT';
~startperl~ -w

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

use strict;
use Error qw(:try);
use File::Basename;

# Globals
my $basename=basename($0);

# Get options
my $dev;
my $h = 0;
my $o = '';
use Getopt::Long;
if ( ! GetOptions(
    'h' => \$h,
    'dev=s' => \$dev,
    'o=s' => \$o,
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
    use IO::File;
    $fh = IO::File->new( "> $o" );
    defined($fh) ||
        throw Error::Simple ("ERROR: $basename: Failed to open file '$o' for writing.");
} else {
    use IO::File;
    $fh = IO::Handle->new_from_fd( fileno(STDOUT), 'w' );
}

# Make entry
use InfoSys::FreeDB::Entry;
my $entry;
if ($dev) {
    $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia( $dev );
} else {
    $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia();
}

# Write the entry
$entry->write_fh( $fh );

# Exit OK
exit(0);

sub usage {
    print STDERR <<EOF;
Usage: $basename [--h] [--dev <dev>] [--o <outfile>]
  NOTES:
     --h shows this message
     --dev defaults to InfoSys::FreeDB's default
     --o defaults to STDOUT
EOF
}

__END__

=head1 NAME

isfdcdi - InfoSys::FreeDB's get CD info

=head1 SYNOPSIS

isfdcdi [--h] [--dev <dev>] [--o <outfile>]

=head1 DESCRIPTION

This is a simple command to read track information from a CD and to store it into a FreeDB formatted file.

It is intended to illustrate the usage of the C<InfoSys::FreeDB> modules.

=head2 Options:

=over

=item --h

Show usage.

=item --dev

CD device. If none specified, C<cdparanoia>'s default device is used.

=item --o

Output file. Defaults to STDOUT.

=head1 SEE ALSO

L<isfdlscat>,
L<isfdmotd>,
L<isfdoggenc>,
L<isfdquery>,
L<isfdrip>,
L<isfdsites>

=head1 EXAMPLE

Quick and dirty rip:
 $ isfdrip

Slightly more sophisticated rip:
 $ isfdcdi --o cd-tech.cddb
 $ isfdquery --i cd-tech.cddb --o cd-query.cddb
 $ # Edit file cd-query.cddb
 $ isfdrip --i cd-query.cddb

=head1 BUGS

None known (yet).

=head1 HISTORY

First development: September 2002
Last update: September 2003

=head1 AUTHOR

Vincenzo Zocca E<lt>Vincenzo@Zocca.comE<gt>

=head1 COPYRIGHT

Copyright 2002, 2003, Vincenzo Zocca.

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
if ( ! ( open(FILE, ">$file") )  ||
    ! ( print FILE $script)  ||
    ! ( close(FILE) )
        ) {
    die "Error while writing $file: $!\n";
}
print "Extracted $file from ",__FILE__," with variable substitutions.\n";

# end
