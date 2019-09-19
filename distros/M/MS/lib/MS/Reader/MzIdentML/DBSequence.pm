package MS::Reader::MzIdentML::DBSequence;

use strict;
use warnings;

use parent qw/MS::Reader::MzIdentML::SequenceItem/;

sub id        { return $_[0]->{id}                 } 
sub acc       { return $_[0]->{accession}          } 
sub search_db { return $_[0]->{searchDatabase_ref} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzIdentML::DBSequence - mzIdentML database sequence object

=head1 SYNOPSIS

    my $pro = $search->fetch_dbsequence_by_id('FooBarProtein');

    say $pro->id;
    say $pro->acc;
    say $pro->search_db;

=head1 DESCRIPTION

C<MS::Reader::MzIdentML::DBSequence> is a class representing an
mzIdentML search database sequence (typically a protein).

=head1 METHODS

=head2 id

=head2 acc

    my $id  = $pro->id;
    my $acc = $pro->acc;

Return the ID and accession of the sequence, respectively

=head2 search_db

    my $db_id = $seq->search_db;

Returns the identifier of the search database that the sequence belongs to.
This can be used to link to the database used. Currently the database is not
implemented as a class, so an understanding of the data structure is needed to
extract this information.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
