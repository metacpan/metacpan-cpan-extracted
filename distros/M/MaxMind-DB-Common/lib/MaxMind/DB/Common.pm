package MaxMind::DB::Common;

use strict;
use warnings;

our $VERSION = '0.040001';

my $separator_size;

BEGIN {
    $separator_size = 16;
}

use constant {
    LEFT_RECORD                 => 0,
    RIGHT_RECORD                => 1,
    DATA_SECTION_SEPARATOR_SIZE => $separator_size,
    DATA_SECTION_SEPARATOR      => ( "\0" x $separator_size ),
    METADATA_MARKER             => "\xab\xcd\xefMaxMind.com",
};

use Exporter qw( import );

## no critic (Variables::ProhibitPackageVars)
our %TypeNumToName = (
    0  => 'extended',
    1  => 'pointer',
    2  => 'utf8_string',
    3  => 'double',
    4  => 'bytes',
    5  => 'uint16',
    6  => 'uint32',
    7  => 'map',
    8  => 'int32',
    9  => 'uint64',
    10 => 'uint128',
    11 => 'array',
    12 => 'container',
    13 => 'end_marker',
    14 => 'boolean',
    15 => 'float',
);

our %TypeNameToNum = reverse %TypeNumToName;

our @EXPORT_OK = qw(
    LEFT_RECORD
    RIGHT_RECORD
    DATA_SECTION_SEPARATOR_SIZE
    DATA_SECTION_SEPARATOR
    METADATA_MARKER
    %TypeNumToName
    %TypeNameToNum
);

1;

# ABSTRACT: Code shared by the MaxMind DB reader and writer modules

__END__

=pod

=head1 NAME

MaxMind::DB::Common - Code shared by the MaxMind DB reader and writer modules

=head1 VERSION

version 0.040001

=head1 DESCRIPTION

This distribution provides some shared code for use by both the MaxMind DB
reader and writer Perl modules.

For now, the only piece documented for public consumption is
L<MaxMind::DB::Metadata>.

=head1 VERSIONING POLICY

This module uses semantic versioning as described by
L<http://semver.org/>. Version numbers can be read as X.YYYZZZ, where X is the
major number, YYY is the minor number, and ZZZ is the patch number.

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/MaxMind-DB-Common-perl/issues>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Olaf Alders <oalders@maxmind.com>

=back

=head1 CONTRIBUTOR

=for stopwords Greg Oschwald

Greg Oschwald <goschwald@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
