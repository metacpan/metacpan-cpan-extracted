package Enum::Declare::Common::FileType;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Type :Str :Type :Export {
	File      = "file",
	Directory = "directory",
	Symlink   = "symlink",
	Socket    = "socket",
	Pipe      = "pipe",
	Block     = "block",
	Char      = "char"
};

1;

=head1 NAME

Enum::Declare::Common::FileType - File type constants

=head1 SYNOPSIS

    use Enum::Declare::Common::FileType;

    say File;       # "file"
    say Directory;  # "directory"
    say Symlink;    # "symlink"

=head1 ENUMS

=head2 Type :Str :Export

File="file", Directory="directory", Symlink="symlink", Socket="socket",
Pipe="pipe", Block="block", Char="char".

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
