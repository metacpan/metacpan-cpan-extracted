package Genealogy::Obituary::Lookup::obituaries;

use strict;
use warnings;
use autodie qw(:all);

use Database::Abstraction;

=head1 NAME

Genealogy::Obituary::Lookup::obituaries - SQLite driver for the obituary database

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

our @ISA = ('Database::Abstraction');

=head1 SYNOPSIS

This module is not intended to be used directly.  It is instantiated
internally by L<Genealogy::Obituary::Lookup>
as a driver to access the C<obituaries.sql> file.

    use Genealogy::Obituary::Lookup;
    my $obits = Genealogy::Obituary::Lookup->new();

=head1 DESCRIPTION

A thin subclass of L<Database::Abstraction> that points at the F<obituaries.sql>
SQLite database shipped with the distribution.
All query logic - SQL generation, caching, row mapping - is inherited from the parent class.

The database schema is:

    CREATE TABLE obituaries (
        first    VARCHAR NOT NULL,
        middle   VARCHAR,
        last     VARCHAR NOT NULL,
        maiden   VARCHAR,
        age      INTEGER,
        place    VARCHAR,
        newspaper VARCHAR NOT NULL,
        date     DATE    NOT NULL,
        source   CHAR    NOT NULL,   -- 'M', 'F', or 'L'
        page     VARCHAR NOT NULL    -- archive page number or direct URL
    );

=head1 LIMITATIONS

This class has no independent logic.  All limitations apply at the
L<Genealogy::Obituary::Lookup> level.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2026 Nigel Horne.  Released under GPL2.

=cut

1;
