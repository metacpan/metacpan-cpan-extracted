package EBook::Ishmael::EBook::PalmDoc;
use 5.016;
our $VERSION = '1.09';
use strict;
use warnings;

use Encode qw(decode);

use EBook::Ishmael::Decode qw(palmdoc_decode);
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::PDB;
use EBook::Ishmael::TextToHtml;

my $TYPE    = 'TEXt';
my $CREATOR = 'REAd';

my $RECSIZE = 4096;

sub heuristic {

    my $class = shift;
    my $file  = shift;
    my $fh    = shift;

    return 0 unless -s $file >= 68;

    seek $fh, 32, 0;
    read $fh, my ($null), 1;

    # Last byte in title must be null
    unless ($null eq "\0") {
        return 0;
    }

    seek $fh, 60, 0;
    read $fh, my ($type),    4;
    read $fh, my ($creator), 4;

    return $type eq $TYPE && $creator eq $CREATOR;

}

sub _decode_record {

    my $self = shift;
    my $rec  = shift;

    $rec++;

    my $encode = $self->{_pdb}->record($rec)->data;

    if ($self->{_compression} == 1) {
        return $encode;
    } elsif ($self->{_compression} == 2) {
        return palmdoc_decode($encode);
    }

}

sub new {

    my $class = shift;
    my $file  = shift;
    my $enc   = shift // 'UTF-8';

    my $self = {
        Source       => undef,
        Metadata     => EBook::Ishmael::EBook::Metadata->new,
        Encoding     => $enc,
        _pdb         => undef,
        _compression => undef,
        _textlen     => undef,
        _recnum      => undef,
        _recsize     => undef,
        _curpos      => undef,
    };

    bless $self, $class;

    $self->{Source} = File::Spec->rel2abs($file);

    $self->{_pdb} = EBook::Ishmael::PDB->new($file);

    my $hdr = $self->{_pdb}->record(0)->data;

    (
        $self->{_compression},
        undef,
        $self->{_textlen},
        $self->{_recnum},
        $self->{_recsize},
        $self->{_curpos},
    ) = unpack "n n N n n N", $hdr;

    if ($self->{_compression} != 1 and $self->{_compression} != 2) {
        die "$self->{Source} is not a PalmDoc file\n";
    }

    if ($self->{_recsize} != 4096) {
        die "$self->{Source} is not a PalmDoc file\n";
    }

    $self->{Metadata}->title([ $self->{_pdb}->name ]);

    if ($self->{_pdb}->cdate) {
        $self->{Metadata}->created([ scalar gmtime $self->{_pdb}->cdate ]);
    }
    if ($self->{_pdb}->mdate) {
        $self->{Metadata}->modified([ scalar gmtime $self->{_pdb}->mdate ]);
    }

    if ($self->{_pdb}->version) {
        $self->{Metadata}->format([
            sprintf(
                "PalmDOC %s.%s",
                ($self->{_pdb}->version >> 8) & 0xff,
                $self->{_pdb}->version & 0xff
            )
        ]);
    } else {
        $self->{Metadata}->format([ 'PalmDOC' ]);
    }

    return $self;

}

sub html {

    my $self = shift;
    my $out  = shift;

    my $html = decode(
        $self->{Encoding},
        text2html(
            join('', map { $self->_decode_record($_) } 0 .. $self->{_recnum} - 1)
        ),
    );

    if (defined $out) {
        open my $fh, '>', $out
            or die "Failed to open $out for writing: $!\n";
        binmode $fh, ':utf8';
        print { $fh } $html;
        close $fh;
        return $out;
    } else {
        return $html;
    }

}

sub raw {

    my $self = shift;
    my $out  = shift;

    my $raw = decode(
        $self->{Encoding},
        join('', map { $self->_decode_record($_) } 0 .. $self->{_recnum} - 1)
    );

    if (defined $out) {
        open my $fh, '>', $out
            or die "Failed to open $out for writing: $!\n";
        binmode $fh, ':utf8';
        print { $fh } $raw;
        close $fh;
        return $out;
    } else {
        return $raw;
    }

}

sub metadata {

    my $self = shift;

    return $self->{Metadata}->hash;

}

sub has_cover { 0 }

sub cover { undef }

sub image_num { 0 }

sub image { undef }

1;
