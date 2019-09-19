package MS::Reader::MzIdentML::PeptideEvidence;

use strict;
use warnings;

use parent qw/MS::Reader::MzIdentML::SequenceItem/;

sub id         { return $_[0]->{id}                   } 
sub peptide_id { return $_[0]->{peptide_ref}          } 
sub search_db  { return $_[0]->{dBSequence_ref}       }
sub start      { return $_[0]->{start}                }
sub end        { return $_[0]->{end}                  }
sub pre        { return $_[0]->{pre}                  }
sub post       { return $_[0]->{post}                 }
sub frame      { return $_[0]->{frame}                }
sub is_decoy   { return $_[0]->{isDecoy}              }
sub trl_table  { return $_[0]->{translationTable_ref} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzIdentML::PeptideEvidence - mzIdentML peptide evidence object

=head1 SYNOPSIS

    my $pe = $search->fetch_peptideevidence_by_id($EV_ID);

    say $pe->id;
    say $pe->start;
    say $pe->end;
    say $pe->pre;
    say $pe->post;
    say $pe->frame;
    
    my $pep_id   = $pe->peptide_id;
    my $db_id    = $pe->search_db;
    my $is_decoy = $pe->is_decoy;
    my $tbl_id   = $pe->trl_table;

=head1 DESCRIPTION

The C<MS::Reader::MzIdentML::PeptideEvidence> class represents a
<PeptideEvidence> element in the search results. This links peptide sequences
to their location in a database protein, as well as including other
information such as decoy status.

=head1 METHODS

=head2 id

    my $id = $pe->id;

Returns the peptide evidence ID, which is a unique identifier within the results file

=head2 peptide_id

    my $pep_id = $pe->peptide_id;
    my $pep = $search->fetch_peptide_by_id( $pep_id );

Returns the ID of the associated Peptide element, which can be used to look up
a corresponding C<MS::Reader::MzIdentML::Peptide> object.

=head2 search_db

    my $db_id = $pe->search_db;

Returns the ID of the search database the evidence comes from.

=head2 start

=head2 end

=head2 pre

=head2 post

    my $start_loc = $pe->start;
    my $end_loc   = $pe->end;
    my $prev_aa   = $pe->pre;
    my $next_aa   = $pe->post;

Return information related to a peptide's context within it's parent protein:
start coordinate, end coordinate, previous amino acid, and subsequent amino
acid. None of these values are guaranteed to be defined.

=head2 frame

    my $reading_frame   = $pe->frame;

The translation frame of the peptide, in the range of -3 to -1 or 1 to 3. Not
guaranteed to be defined.

=head2 is_decoy

    next if ($pe->is_decoy);

Returns a boolean value indicating whether the peptide evidence is from a
decoy protein.

=head2 trl_table

    my $tbl_id = $pe->trl_table;

Returns the ID of the translation table associated with the peptide evidence.


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
