=head1 NAME

Debian::Copyright::Stanza::Header - header stanza of Debian copyright file

=head1 VERSION

This document describes Debian::Copyright::Stanza::Header version 0.2 .

=head1 SYNOPSIS

    my $copy = Debian::Copyright::Stanza::Header->new(\%data);
    print $copy;                         # auto-stringification

=head1 DESCRIPTION

Debian::Copyright::Stanza::Header can be used for representation and
manipulation of the header stanza of Debian copyright files in an
object-oriented way. Converts itself to a textual representation in string
context.

=head1 FIELDS

The supported fields for header stanzas are listed below.

Note that real copyright fields may contain dashes in their names. These are
replaced with underscores.

=over

=item Format

=item Upstream_Name

=item Comment

=item Upstream_Contact

=item Source

=item Disclaimer

=item License

=item Copyright

=back

=cut

package Debian::Copyright::Stanza::Header;
require v5.10.1;
use strict;
use warnings;
use base qw(Debian::Copyright::Stanza);

use constant fields => qw (
    Format
    Upstream_Name
    Upstream_Contact
    Source
    Disclaimer
    Comment
    License
    Copyright
);

our $VERSION = '0.2';

=head1 CONSTRUCTOR

=over

=item new

=item new( { field => value, ... } )

Creates a new L<Debian::Copyright::Stanza::Header> object and optionally
initialises it with the supplied data.

=back

=head1 SEE ALSO

Debian::Copyright::Stanza::Header inherits most of its functionality from
L<Debian::Copyright::Stanza>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-12 Nicholas Bamber L<nicholas@periapt.co.uk>

This module is substantially based upon L<Debian::Control::Stanza::Source>.
Copyright (C) 2009 Damyan Ivanov L<dmn@debian.org>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

1;
