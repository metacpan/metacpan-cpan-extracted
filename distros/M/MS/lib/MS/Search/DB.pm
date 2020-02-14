package MS::Search::DB;

use strict;
use warnings;

use BioX::Seq::Stream;
use BioX::Seq::Fetch;
use Net::FTP;
use HTTP::Tiny;
use URI;
use File::Temp;
use List::Util qw/shuffle/;
use Module::Pluggable
    require => 1, sub_name => 'sources', search_path => ['MS::Search::DB::Source'];

sub new {

    my ($class, $fn) = @_;

    my $self = bless {} => $class;

    $self->add_from_file($fn) if (defined $fn);

    return $self;

}

sub add_decoys {

    my ($self, %args) = @_;

    $self->{decoys} = [];
    my $type   = $args{type}   // 'reverse';
    my $prefix = $args{prefix} // 'DECOY_';
    my $added = 0;
    for my $seq (@{ $self->{seqs} }) {

        my $new = $type eq 'reverse' ? reverse $seq
                : $type eq 'shuffle' ? join( '', shuffle( split '', $seq ) )
                : die "Unknown decoy type: $type\n";
        my $decoy = BioX::Seq->new(
            $new,
            $prefix . $seq->id,
            $seq->desc,
            undef
        );

        push @{ $self->{decoys} }, $decoy;
        ++$added;
    } 

    return $added;

}

sub add_from_source {

    my ($self, %args) = @_;

    my $suffix = $args{id_suffix} // '';

    my $added = 0;
    for my $src ($self->sources) {
        next if ($src ne "MS::Search::DB::Source::$args{source}");
        delete $args{source};
        my $f = $src->new(%args);
        my ($fh, $pid) = $f->_fetch_fh;
        my $p = BioX::Seq::Stream->new($fh);
        while (my $seq = $p->next_seq) {
            $seq->id = $seq->id . $suffix;
            push @{ $self->{seqs} }, $seq;
            ++$added;
        }
        close $fh;
        waitpid($pid, 0);
        last;
    }

    return $added;

}

sub add_from_file {

    my ($self, $fn, %args) = @_;

    die "File not found\n" if (! -e $fn);

    my $suffix = $args{id_suffix} // '';

    my $added = 0;
    my $p = BioX::Seq::Stream->new($fn);
    while (my $seq = $p->next_seq) {
        $seq->id = $seq->id . $suffix;
        push @{ $self->{seqs} }, $seq;
        ++$added;
    }

    return $added;

}


sub add_from_url {

    my ($self, $url, %args) = @_;

    my $suffix = $args{id_suffix} // '';

    my $tmp = File::Temp->new(UNLINK => 1);

    my $added = 0;

    my $u = URI->new($url);
    if ($u->scheme eq 'ftp') {
        my $ftp = Net::FTP->new($u->host, Passive => 1);
        $ftp->binary();
        $ftp->login or die "Failed login: $@\n";
        $ftp->get($u->path => $tmp)
            or die "Download failed:" . $ftp->message . "\n";
    }
    elsif ($u->scheme eq 'http'|| $u->scheme eq 'https') {
        my $resp = HTTP::Tiny->new->get($u, { data_callback
            => sub { print {$tmp} $_[0] } } );
        die "Download failed\n" if (! $resp->{success});
    }
    else {
        die "Only FTP and HTTP downloads are currently supported\n";
    }

    close $tmp;

    my $p = BioX::Seq::Stream->new("$tmp");
    while (my $seq = $p->next_seq) {
        $seq->id = $seq->id . $suffix;
        push @{ $self->{seqs} }, $seq;
        ++$added;
    }

    return $added;

}

sub write {

    my ($self, %args) = @_;

    my $fh = $args{fh} // \*STDOUT;

    my @pool;
    push @pool, map {[$_,'seqs']} 0..$#{ $self->{seqs}   };
    push @pool, map {[$_,'decoys']} 0..$#{ $self->{decoys} };

    @pool = shuffle @pool if ($args{randomize});

    for (@pool) {
        print {$fh} $self->{$_->[1]}->[$_->[0]]->as_fasta;
    }

    return 1;

}

sub add_crap {

    my ($self, $url) = @_;

    $url //= 'ftp://ftp.thegpm.org/fasta/cRAP/crap.fasta';

    $self->add_from_url($url);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Search::DB - A class to facilitate construction of MS/MS protein search databases

=head1 SYNOPSIS

    use MS::Search::DB;

    my $db = MS::Search::DB->new;

    # add sequences from various sources

    $db->add_from_file("/path/to/proteins.faa");
    $db->add_from_url("http://foo.org/proteomes/XYZ.faa");
    $db->add_from_source(
        source   => 'uniprot',
        taxid    => '12345',
        ref_only => 1,
    );

    # add contaminant sequences from cRAP
    $db->add_crap();

    # generate decoy sequences
    $db->add_decoys(
        type => 'reverse',
        prefix => 'DECOY_',
    );

    # write to fh (default STDOUT)
    $db->write(
        fh        => $fh,
        randomize => 1,
    );


=head1 DESCRIPTION

C<MS::Search::DB> is intended to facilitate easy construction of MS/MS protein
search databases from various sources. It includes methods for fetching
protein sequence data, adding common contaminant sequences, adding decoy
sequences, and saving the database to disk.

=head1 METHODS

=head2 new

    my $db = MS::Search::DB->new();

    #or, initialize directly from a file
    my $db = MS::Search::DB->new('/path/to/proteins.faa');

Create a new C<MS::Search::DB> object. A single optional argument pointing to
a FASTA file is accepted, which will be loaded into the initial database.

=head2 add_from_file

    $db->add_from_file('/path/to/proteins.faa');

Takes one required argument (path to a protein FASTA file) and loads it
into the database. Optionally takes a suffix that is added to each sequence
ID. Returns the number of sequences added.


=head2 add_from_url

    $db->add_from_url(
        'http://somedb.org/proteomes/XYZ.faa',
        id_suffix => '_XYZ',
    );

Takes one required argument (URL referencing a FASTA file) and loads it into
the database. Optionally takes a suffix that is added to each sequence ID.
Returns the number of sequences added.

=head2 add_from_source

    $db->add_from_source(
        source    => 'uniprot',
        id_suffix => '_XYZ',
        # plugin-specific arguments
    );

Fetch data using an MS::Search::DB::Source plugin (specified via the 'source'
argument). These plugins facilitate searching common sources of protein
sequence data, such as NCBI or Uniprot. Please see the documentation for each
individual plugin (under the C<MS::Search::DB::Source::> namespace) for
details of the arguments each one accepts. Optionally takes a suffix that is
added to each sequence ID.  Returns the number of sequences added.

=head2 add_crap

    $db->add_crap();
    $db->add_crap($url);

Downloads common contaminant sequences and adds them to the database. By
default, downloads the "common Repository of Adventitious Proteins", aka
"cRAP", from GPM. An optional URL can be provided to fetch from another
source.

=head2 add_decoys

    $db->add_decoys(
        type => 'reverse',
        prefix => 'DECOY_',
    );

Generates a set of decoy sequences according to the arguments provided and
adds them to the database. One decoy will be added for each protein in the
original database. Possible arguments include:

=over

=item * type — how to generate the decoy sequences. Either 'reverse' or
'shuffle'. (default: reverse)

=item * prefix — the prefix to be added to each decoy ID. (default: "DECOY_")

=back

Note that the order in which this method is called matters. Only sequences
that have already been added to the database before it is called will be used
for decoy generation. 

=head2 write

    $db->write(
        fh => $fh,
        randomize => 1,
    );

Write database to disk as FASTA file. Possible arguments include:

=over

=item * fh — filehandle to write to (default: STDOUT)

=item * randomize — whether to randomly shuffle sequences before writing
(default: 0)

=back

=head1 CAVEATS AND BUGS

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<InSilicoSpectro>

=back

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
