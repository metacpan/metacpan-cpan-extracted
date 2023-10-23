package MS::Search::DB::Source::uniprot;

use strict;
use warnings;

use HTTP::Tiny;
use URI::Escape;
use FileHandle;

sub new {

    my ($class, %args) = @_;

    my $self = bless {%args} => $class;

    return $self;

}

sub _fetch_fh {

    my ($self) = @_;


    my ($rdr, $wtr) = FileHandle::pipe;
    my $pid = fork;

    if ($pid) {

        close $wtr;
        return($rdr, $pid);

    }
    else {

        close $rdr;

        my @proteomes;

        if (defined $self->{proteome}) {
            @proteomes = ($self->{proteome});
        }
        elsif (defined $self->{taxid} && ! defined $self->{proteome}) {
            my $ref_only = $self->{ref_only} ? 'true' : 'false';
            my $top_node = $self->{taxid} // die "No taxon specified\n";
            die "Taxon must be NCBI integer ID\n" if ($top_node =~ /\D/);

            #my $list_url = "http://www.uniprot.org/proteomes/?query=reference:$ref_only+taxonomy:$top_node&format=list";
            my $list_url = "https://rest.uniprot.org/proteomes/stream?query=reference:$ref_only+taxonomy_id:$top_node&format=list";

            my $resp = HTTP::Tiny->new->get($list_url);
            die "Failed to fetch proteome list: $resp->{status} $resp->{reason}\n"
                if (! $resp->{success});
            @proteomes = split /\r?\n/, $resp->{content};
        }
        else {
            die "No taxonomy ID or proteome ID given!\n";
        }

        my $fasta;
        my $want;
        my $reviewed = $self->{reviewed_only}
            ? '+AND+reviewed:true'
            : '';
        my $include  = $self->{include_isoforms}
            ? 'yes'
            : 'no';
        for (@proteomes) {
            my $id = uri_escape($_);
            warn "Fetching $id\n";
            #my $fetch_url = "http://www.uniprot.org/uniprot/?query=proteome:$id$reviewed&include=$include&format=fasta";
            my $fetch_url = "https://rest.uniprot.org/uniprotkb/stream?query=proteome:$id$reviewed&include=$include&format=fasta";
            my $resp = HTTP::Tiny->new->get( $fetch_url, { data_callback
                => sub { print {$wtr} $_[0] if ($_[1]->{status} < 300 ) } } );
            die "Failed to fetch sequences for $_: $resp->{status} $resp->{reason}\n"
                if (! $resp->{success});
        }
        close $wtr;
        exit;

    }

}

1;
        
__END__

=head1 NAME

MS::Search::DB::Source::uniprot - interface for Uniprot downloads

=head1 SYNOPSIS

    use MS::Search::DB;

    my $db = MS::Search::DB->new();

    $db->add_from_source(
        source           => 'uniprot',
        taxid            => '12345',
        ref_only         => 1,
        reviewed_only    => 0,
        include_isoforms => 0,
    );

=head1 DESCRIPTION

C<MS::Search::DB::Source::uniprot> provides an interface to the Uniprot
database for fetching proteomes based on taxonomic ID. It is not intended to
be called directly, but rather used via the 'source' argument to the
L<MS::Search::DB> C<add_from_source> method.

=head1 ARGUMENTS

The following arguments should be provided to the L<MS::Search::DB>
C<add_from_source> method call:

=over 4

=item B<source> <plugin>

Should be 'uniprot'

=item B<taxid> <id>

A numeric NCBI taxonomic ID for the organim of interest (one of 'taxid' or
'proteome' is required)

=item B<proteome> <id>

A Uniprot ID for the proteome of interest (one of 'taxid' or 'proteome' is
required)

=item B<ref_only> <bool>

Whether to only fetch reference proteomes (default: 0)

=item B<reviewed_only> <bool>

Whether to only fetch reviewed protein sequences (default: 0)

=item B<include_isoforms> <bool>

Whether to include protein isoform sequences in the dataset (default: 0)

=back

=head1 CAVEATS AND BUGS

Please report bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Jeremy Volkening

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

