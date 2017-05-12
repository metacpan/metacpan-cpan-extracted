package File::Stat::ModeString;

=head1 NAME

File::Stat::ModeString - conversion file stat(2) mode to/from string representation.

=head1 SYNOPSIS

 use File::Stat::ModeString;

 $string  = mode_to_string  ( $st_mode );
 $st_mode = string_to_mode  ( $string  );
 $type    = mode_to_typechar( $st_mode );

 $record = <IN>; chomp $record;
 $record =~ m/^some_prefix\s+$MODE_STRING_RE\s+some_suffix$/o
	or die "invalid record format";

 die "Invalid mode in $string"
	if is_mode_string_valid( $string );


=head1 DESCRIPTION

This module provides a few functions for conversion between
binary and literal representations of file mode bits,
including file type.

All of them use only symbolic constants for mode bits
from B<File::Stat::Bits>.


=cut

require 5.005;
use strict;
local $^W=1; # use warnings only since 5.006
use integer;

use Carp;
use File::Stat::Bits;


BEGIN
{
    use Exporter;
    use vars qw($VERSION @ISA @EXPORT $MODE_STRING_RE
	@type_to_char %char_to_typemode %ugorw_to_mode %ugox_to_mode
	@perms_clnid @perms_setid @perms_stick);

    $VERSION = do { my @r = (q$Revision: 0.28 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

    @ISA = ('Exporter');

    @EXPORT = qw( &is_mode_string_valid $MODE_STRING_RE
		  &mode_to_typechar &mode_to_string &string_to_mode
		);

    @type_to_char = ();
    $type_to_char[S_IFDIR  >> 9] = 'd';
    $type_to_char[S_IFCHR  >> 9] = 'c';
    $type_to_char[S_IFBLK  >> 9] = 'b';
    $type_to_char[S_IFREG  >> 9] = '-';
    $type_to_char[S_IFIFO  >> 9] = 'p';
    $type_to_char[S_IFLNK  >> 9] = 'l';
    $type_to_char[S_IFSOCK >> 9] = 's';

    @perms_clnid = qw(--- --x -w- -wx r-- r-x rw- rwx);
    @perms_setid = qw(--S --s -wS -ws r-S r-s rwS rws);
    @perms_stick = qw(--T --t -wT -wt r-T r-t rwT rwt);

    %char_to_typemode =
	(
	 'd' => S_IFDIR ,
	 'c' => S_IFCHR ,
	 'b' => S_IFBLK ,
	 '-' => S_IFREG ,
	 'p' => S_IFIFO ,
	 'l' => S_IFLNK ,
	 's' => S_IFSOCK
	);

    %ugorw_to_mode =
	(
	 'u--' => 0,
	 'ur-' => S_IRUSR,
	 'u-w' => S_IWUSR,
	 'urw' => S_IRUSR|S_IWUSR,

	 'g--' => 0,
	 'gr-' => S_IRGRP,
	 'g-w' => S_IWGRP,
	 'grw' => S_IRGRP|S_IWGRP,

	 'o--' => 0,
	 'or-' => S_IROTH,
	 'o-w' => S_IWOTH,
	 'orw' => S_IROTH|S_IWOTH
	);

    %ugox_to_mode =
	(
	 'u-' => 0,
	 'ux' => S_IXUSR,
	 'us' => S_IXUSR|S_ISUID,
	 'uS' =>         S_ISUID,

	 'g-' => 0,
	 'gx' => S_IXGRP,
	 'gs' => S_IXGRP|S_ISGID,
	 'gS' =>         S_ISGID,

	 'o-' => 0,
	 'ox' => S_IXOTH,
	 'ot' => S_IXOTH|S_ISVTX,
	 'oT' =>         S_ISVTX,
	);
}


=head1 CONSTANTS

=head2 $MODE_STRING_RE

Regular expression to match mode string (without ^$).

=cut

BEGIN {
    $MODE_STRING_RE = '[-dcbpls]([r-][w-][xsS-]){2}?[r-][w-][xtT-]';
}



=head1 FUNCTIONS

=head2

is_mode_string_valid( $string )

Returns true if argument matches mode string pattern.

=cut
sub is_mode_string_valid
{
    my $string = shift;

    return $string =~ m/^$MODE_STRING_RE$/o;
}


=head2

$type = mode_to_typechar( $mode )

Returns file type character of binary mode, '?' on unknown file type.

=cut
sub mode_to_typechar
{
    my $mode = shift;
    my $type = $type_to_char[ ($mode & S_IFMT) >> 9 ];
    return defined $type ? $type : '?';
}


=head2

$string = mode_to_string( $mode )

Converts binary mode value to string representation.
'?' in file type field on unknown file type.

=cut
sub mode_to_string
{
    my $mode = shift;
    my $string;
    my $perms;

    $string = mode_to_typechar($mode);

    # user
    $perms = ( $mode & S_ISUID ) ? \@perms_setid : \@perms_clnid;
    $string .= $perms->[($mode & S_IRWXU) >> 6];

    # group
    $perms = ( $mode & S_ISGID ) ? \@perms_setid : \@perms_clnid;
    $string .= $perms->[($mode & S_IRWXG) >> 3];

    # other
    $perms = ( $mode & S_ISVTX ) ? \@perms_stick : \@perms_clnid;
    $string .= $perms->[($mode & S_IRWXO)];

    return $string;
}


=head2

$mode = string_to_mode( $string )

Converts string representation of file mode to binary one.

=cut
sub string_to_mode
{
    my $string = shift;
    my @list   = split //, $string;
    my $mode   = 0;
    my $char;

    # type
    $char  = shift @list;
    $mode |= $char_to_typemode{$char};

    # user read | write
    $char  = 'u' . shift(@list) . shift(@list);
    $mode |= $ugorw_to_mode{$char};

    # user execute
    $char  = 'u' . shift @list;
    $mode |= $ugox_to_mode{$char};

    # group read | write
    $char  = 'g' . shift(@list) . shift(@list);
    $mode |= $ugorw_to_mode{$char};

    # group execute
    $char  = 'g' . shift @list;
    $mode |= $ugox_to_mode{$char};

    # others read | write
    $char  = 'o' . shift(@list) . shift(@list);
    $mode |= $ugorw_to_mode{$char};

    # others execute
    $char  = 'o' . shift @list;
    $mode |= $ugox_to_mode{$char};


    return $mode;
}


=head1 SEE ALSO

L<stat(2)>;

L<File::Stat::Bits(3)>;

L<Stat::lsMode(3)>;

=head1 AUTHOR

Dmitry Fedorov <dm.fedorov@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2003 Dmitry Fedorov <dm.fedorov@gmail.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

=head1 DISCLAIMER

The author disclaims any responsibility for any mangling of your system
etc, that this script may cause.

=cut


1;

