package EBook::Ishmael::EBook::Mobi;
use 5.016;
our $VERSION = '1.09';
use strict;
use warnings;

use Encode qw(from_to);

use XML::LibXML;

use EBook::Ishmael::Decode qw(palmdoc_decode);
use EBook::Ishmael::ImageID;
use EBook::Ishmael::PDB;
use EBook::Ishmael::MobiHuff;

# Many thanks to Tommy Persson, the original author of mobi2html, a script
# which much of this code is based off of.

# TODO: Implement AZW4 support
# TODO: Add support for UTF16 MOBIs (65002)

my $TYPE    = 'BOOK';
my $CREATOR = 'MOBI';

my $RECSIZE = 4096;

my $NULL_INDEX = 0xffffffff;

my %EXTH_RECORDS = (
    100 => sub { author      => shift },
    101 => sub { contributor => shift },
    103 => sub { description => shift },
    104 => sub { id          => shift },
    105 => sub { genre       => shift },
    106 => sub { created     => shift },
    108 => sub { contributor => shift },
    114 => sub { format      => "MOBI " . shift },
    524 => sub { language    => shift },
);

sub heuristic {

    my $class = shift;
    my $file  = shift;
    my $fh    = shift;

    return 0 unless -s $file >= 68;

    seek $fh, 32, 0;
    read $fh, my ($null), 1;

    unless ($null eq "\0") {
        return 0;
    }

    seek $fh, 60, 0;
    read $fh, my ($type),    4;
    read $fh, my ($creator), 4;

    return 0 unless $type eq $TYPE && $creator eq $CREATOR;

    seek $fh, 78, 0;
    read $fh, my ($off), 4;
    $off = unpack "N", $off;
    seek $fh, $off + 36, 0;
    read $fh, my ($ver), 4;
    $ver = unpack "N", $ver;

    return $ver != 8;

}

sub _clean_html {

    my $html = shift;

    $$html =~ s/<mbp:pagebreak\s*\//<br style=\"page-break-after:always\" \//g;
    $$html =~ s/<mbp:pagebreak\s*/<br style=\"page-break-after:always\" \//g;
    $$html =~ s/<\/mbp:pagebreak>//g;
    $$html =~ s/<guide>.*?<\/guide>//g;
    $$html =~ s/<\/?mbp:nu>//g;
    $$html =~ s/<\/?mbp:section//g;
    $$html =~ s/<\/?mbp:frameset>//g;
    $$html =~ s/<\/?mbp:slave-frame>//g;

    return 1;

}

sub _trailing_entry_size {

    my $data = shift;

    my $res = 0;

    my $trail = substr $data, -4;

    for my $c (unpack "C4", $trail) {
        if ($c & 0x80) {
            $res = 0;
        }
        $res = ($res << 7) | ($c & 0x7f);
    }

    return $res;

}

sub _trailing_entries_size {

    my $self = shift;
    my $data = shift;

    my $res = 0;

    for my $i (0 .. $self->{_trailers} - 1) {
        my $n = _trailing_entry_size($data);
        $res += $n;
        substr $data, -$n, $n, '';
    }

    if ($self->{_extra_data} & 1) {
        $res += (ord(substr $data, -1) & 3) + 1;
    }

    return $res;

}

# Index processing code was adapted from KindleUnpack

sub _get_index_data {

    my $self = shift;
    my $idx  = shift;

    return {} if $idx == $NULL_INDEX;

    my $outtbl = [];
    my $ctoc   = {};

    my $data;
    $$data = $self->{_pdb}->record($idx)->data;

    my ($idxhdr, $hordt1, $hordt2) = $self->_parse_indx_header($data);
    my $icount = $idxhdr->{count};
    my $roff = 0;
    my $off = $idx + $icount + 1;

    for my $i (0 .. $idxhdr->{nctoc} - 1) {
        my $cdata = $self->{_pdb}->record($off + $i)->data;
        my $ctocdict = $self->_read_ctoc(\$cdata);
        for my $j (sort keys %$ctocdict) {
            $ctoc->{ $j + $roff } = $ctocdict->{ $j };
        }
        $roff += 0x10000;
    }

    my $tagstart = $idxhdr->{len};
    my ($ctrlcount, $tagtbl) = _read_tag_section($tagstart, $data);

    for my $i ($idx + 1 .. $idx + 1 + $icount - 1) {
        my $d = $self->{_pdb}->record($i)->data;
        my ($hdrinfo, $ordt1, $ordt2) = $self->_parse_indx_header(\$d);
        my $idxtpos = $hdrinfo->{start};
        my $ecount  = $hdrinfo->{count};
        my $idxposits = [];
        for my $j (0 .. $ecount - 1) {
            my $pos = unpack "n", substr $d, $idxtpos + 4 + (2 * $j), 2;
            push @$idxposits, $pos;
        }
        for my $j (0 .. $ecount - 1) {
            my $spos = $idxposits->[$j];
            my $epos = $idxposits->[$j + 1];
            my $txtlen = ord(substr $d, $spos, 1);
            my $txt = substr $d, $spos + 1, $txtlen;
            if (@$hordt2) {
                $txt = join '',
                    map { chr $hordt2->[ ord $_ ] }
                    split //, $txt;
            }
            my $tagmap = _get_tagmap(
                $ctrlcount,
                $tagtbl,
                \$d,
                $spos + 1 + $txtlen,
                $epos
            );
            push @$outtbl, [ $txt, $tagmap ];
        }
    }

    return ( $outtbl, $ctoc );

}

sub _parse_indx_header {

    my $self = shift;
    my $data = shift;

    unless (substr($$data, 0, 4) eq 'INDX') {
        die "Index section is not INDX\n";
    }

    my @words = qw(
        len nul1 type gen start count code lng total ordt ligt nligt nctoc
    );
    my $num = scalar @words;
    my @values = unpack "N$num", substr $$data, 4, 4 * $num;
    my $header = {};

    for my $i (0 .. $#words) {
        $header->{ $words[$i] } = $values[$i];
    }

    my $ordt1 = [];
    my $ordt2 = [];

    my (
        $ocnt,
        $oentries,
        $op1,
        $op2,
        $otagx
    ) = unpack "N N N N N", substr $$data, 0xa4, 4 * 5;

    if ($header->{code} == 0xfdea or $ocnt != 0 or $oentries > 0) {

        unless ($ocnt == 1) {
            die "Corrupted INDX record\n";
        }
        unless (substr($$data, $op1, 4) eq 'ORDT') {
            die "Corrupted INDX record\n";
        }
        unless (substr($$data, $op2, 4) eq 'ORDT') {
            die "Corrupted INDX record\n";
        }

        $ordt1 = [
            unpack("C$oentries", substr $$data, $op1 + 4, $oentries)
        ];
        $ordt2 = [
            unpack("n$oentries", substr $$data, $op2 + 4, $oentries * 2)
        ];

    }

    return ( $header, $ordt1, $ordt2 );

}

sub _read_ctoc {

    my $self = shift;
    my $data = shift;

    my $ctoc = {};

    my $off = 0;
    my $len = length $$data;

    while ($off < $len) {
        if (substr($$data, $off, 1) eq "\0") {
            last;
        }

        my $idxoff = $off;

        my ($pos, $ilen) = _vwv($data, $off);
        $off += $pos;

        my $name = substr $$data, $off, $ilen;
        $off += $ilen;

        my $ctoc->{ $idxoff } = $name;

    }

    return $ctoc;

}

sub _vwv {

    my $data = shift;
    my $off  = shift;

    my $value = 0;
    my $consume = 0;
    my $fin = 0;

    while (!$fin) {
        my $v = substr $$data, $off + $consume, 1;
        $consume++;
        if (ord($v) & 0x80) {
            $fin = 1;
        }
        $value = ($value << 7) | (ord($v) & 0x7f);
    }

    return ( $consume, $value );

}

sub _read_tag_section {

    my $start = shift;
    my $data  = shift;

    my $ctrlcount = 0;

    my $tags = [];

    if (substr($$data, $start, 4) eq 'TAGX') {
        my $foff   = unpack "N", substr $$data, $start + 4, 4;
        $ctrlcount = unpack "N", substr $$data, $start + 8, 4;
        for (my $i = 12; $i < $foff; $i += 4) {
            my $pos = $start + $i;
            push @$tags, [ unpack "C4", substr $$data, $pos, 4 ];
        }
    }

    return ( $ctrlcount, $tags );

}

sub _count_setbits {

    my $val  = shift;
    my $bits = shift // 8;

    my $count = 0;
    for my $i (0 .. $bits - 1) {
        if (($val & 0x01) == 0x01) {
            $count++;
        }
        $val >>= 1;
    }

    return $count;

}

sub _get_tagmap {

    my $ctrlcount = shift;
    my $tagtbl    = shift;
    my $entry     = shift;
    my $spos      = shift;
    my $epos      = shift;

    my $tags = [];
    my $tagmap = {};
    my $ctrli = 0;
    my $start = $spos + $ctrlcount;

    for my $t (@$tagtbl) {
        my ($tag, $values, $mask, $endflag) = @$t;
        if ($endflag == 1) {
            $ctrli++;
            next;
        }
        my $cbyte = ord(substr $$entry, $spos + $ctrli, 1);
        my $val = $cbyte & $mask;
        if ($val != 0) {
            if ($val == $mask) {
                if (_count_setbits($mask) > 1) {
                    my ($consume, $val) = _vwv($entry, $start);
                    $start += $consume;
                    push @$tags, [ $tag, undef, $val, $values ];
                } else {
                    push @$tags, [ $tag, 1, undef, $values ];
                }
            } else {
                while (($mask & 0x01) == 0) {
                    $mask >>= 1;
                    $val  >>= 1;
                }
                push @$tags, [ $tag, $val, undef, $values ];
            }
        }
    }

    for my $t (@$tags) {
        my ($tag, $count, $bytes, $per_entry) = @$t;
        my $values = [];
        if (defined $count) {
            for my $i (1 .. $count) {
                for my $j (1 .. $per_entry) {
                    my ($consume, $data) = _vwv($entry, $start);
                    $start += $consume;
                    push @$values, $data;
                }
            }
        } else {
            my $constotal = 0;
            while ($constotal < $bytes) {
                my ($consume, $data) = _vwv($entry, $start);
                $start += $consume;
                push @$values, $data;
            }
            # Should we warn if $constotal does not match $bytes?
        }
        $tagmap->{ $tag } = $values;
    }

    return $tagmap;

}

sub _kf8_init {

    my $self = shift;

    if ($self->{_fdst} != $NULL_INDEX) {
        my $hdr = $self->{_pdb}->record($self->{_fdst})->data;
        unless (substr($hdr, 0, 4) eq 'FDST') {
            die "KF8 Mobi missing FDST info\n";
        }
        my $secnum = unpack "N", substr $hdr, 0x08, 4;
        my $sc2 = $secnum * 2;
        my @secs = unpack "N$sc2", substr $hdr, 12, 4 * $sc2;
        $self->{_fdsttbl} = [
            map({ $secs[$_] } grep { $_ % 2 == 0 } 0 .. $#secs)
        ];
        push @{ $self->{_fdsttbl} }, $self->{_textlen};
    }

    if ($self->{_skelidx} != $NULL_INDEX) {
        my ($outtbl, $ctoc) = $self->_get_index_data($self->{_skelidx});
        my $fptr = 0;
        for my $o (@$outtbl) {
            my ($txt, $tagmap) = @$o;
            push @{ $self->{_skeltbl} }, [
                $fptr, $txt, $tagmap->{1}[0], $tagmap->{6}[0], $tagmap->{6}[1]
            ];
            $fptr++;
        }
    }

    # TODO: The $cdat is usually undef. Not too important as we don't use it
    # for anything at the moment.
    if ($self->{_fragidx} != $NULL_INDEX) {
        my ($outtbl, $ctoc) = $self->_get_index_data($self->{_fragidx});
        for my $o (@$outtbl) {
            my ($txt, $tagmap) = @$o;
            my $coff = $tagmap->{2}[0];
            my $cdat = $ctoc->{ $coff };
            push @{ $self->{_fragtbl} }, [
                int($txt), $cdat, $tagmap->{3}[0], $tagmap->{4}[0],
                $tagmap->{6}[0], $tagmap->{6}[1]
            ];
        }
    }

    if ($self->{_guideidx} != $NULL_INDEX) {
        my ($outtbl, $ctoc) = $self->_get_index_data($self->{_guideidx});
        for my $o (@$outtbl) {
            my ($txt, $tagmap) = @$o;
            my $coff = $tagmap->{1}[0];
            my $rtitle = $ctoc->{ $coff };
            my $rtype  = $txt;
            my $fno;
            if (exists $tagmap->{3}) {
                $fno = $tagmap->{3}[0];
            }
            if (exists $tagmap->{6}) {
                $fno = $tagmap->{6}[0];
            }
            push @{ $self->{_guidetbl} }, [ $rtype, $rtitle, $fno ];
        }
    }

    return 1;

}

sub _kf8_xhtml {

    my $self = shift;

    my @parts;

    my $rawml = $self->rawml;

    # xhtml is the first flow piece
    my $source = substr(
        $rawml,
        $self->{_fdsttbl}[0],
        $self->{_fdsttbl}[1] - $self->{_fdsttbl}[0]
    );

    my $fragptr = 0;
    my $baseptr = 0;

    for my $s (@{ $self->{_skeltbl} }) {
        my (
            $skelnum,
            $skelnam,
            $fragcnt,
            $skelpos,
            $skellen
        ) = @$s;
        my $baseptr = $skelpos + $skellen;
        my $skeleton = substr $source, $skelpos, $skellen;
        for my $i (0 .. $fragcnt - 1) {
            my (
                $inpos,
                $idtxt,
                $fnum,
                $seqnum,
                $spos,
                $len
            ) = @{ $self->{_fragtbl}[$fragptr] };
            my $slice = substr $source, $baseptr, $len;
            $inpos -= $skelpos;
            my $head = substr $skeleton, 0, $inpos;
            my $tail = substr $skeleton, $inpos;
            $skeleton = $head . $slice . $tail;
            $baseptr += $len;
            $fragptr++;
        }
        push @parts, $skeleton;
    }

    return @parts;

}

sub _decode_record {

    my $self = shift;
    my $rec  = shift;

    $rec++;

    my $encode = $self->{_pdb}->record($rec)->data;
    my $trail = $self->_trailing_entries_size($encode);
    substr $encode, -$trail, $trail, '';

    if ($self->{_compression} == 1) {
        return $encode;
    } elsif ($self->{_compression} == 2) {
        return palmdoc_decode($encode);
    } elsif ($self->{_compression} == 17480) {
        return $self->{_huff}->decode($encode);
    }

}

# TODO: Could probably optimize this.
sub _read_exth {

    my $self = shift;
    my $exth = shift;

    # Special exth handlers that do not handle normal metadata.
    my %special = (
        201 => sub {
            defined $self->{_imgrec}
                ? $self->{_coverrec} = $self->{_imgrec} + unpack "N", $_[0]
                : undef
        },
    );

    my ($doctype, $len, $items) = unpack "a4 N N", $exth;

    my $pos = 12;

    for my $i (1 .. $items) {

        my (undef, $size) = unpack "N N", substr $exth, $pos;
        my $contlen = $size - 8;
        my ($id, undef, $content) = unpack "N N a$contlen", substr $exth, $pos;

        if (exists $EXTH_RECORDS{ $id }) {
            my ($k, $v) = $EXTH_RECORDS{ $id }->($content);
            push @{ $self->{Metadata}->$k }, $v;
        } elsif (exists $special{ $id }) {
            $special{ $id }->($content);
        }

        $pos += $size;

    }

    return 1;

}

sub new {

    my $class = shift;
    my $file  = shift;
    my $enc   = shift;
    my $net   = shift // 1;

    my $self = {
        Source       => undef,
        Metadata     => EBook::Ishmael::EBook::Metadata->new,
        Network      => $net,
        _pdb         => undef,
        _compression => undef,
        _textlen     => undef,
        _recnum      => undef,
        _recsize     => undef,
        _encryption  => undef,
        _doctype     => undef,
        _length      => undef,
        _type        => undef,
        _codepage    => undef,
        _uid         => undef,
        _version     => undef,
        _exth_flag   => undef,
        _extra_data  => undef,
        _trailers    => 0,
        _huff        => undef,
        _imgrec      => undef,
        _coverrec    => undef,
        _lastcont    => undef,
        _images      => [],
        # kf8 stuff
        _skelidx     => undef,
        _skeltbl     => [],
        _fragidx     => undef,
        _fragtbl     => [],
        _guideidx    => undef,
        _guidetbl    => [],
        _fdst        => undef,
        _fdsttbl     => [ 0, $NULL_INDEX ],
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
        $self->{_encryption},
        undef,
    ) = unpack "n n N n n n n", $hdr;

    unless (
        $self->{_compression} == 1 or
        $self->{_compression} == 2 or
        $self->{_compression} == 17480
    ) {
        die "Mobi $self->{Source} uses an unsupported compression level\n";
    }

    if ($self->{_recsize} != 4096) {
        die "$self->{Source} is not a Mobi file\n";
    }

    unless ($self->{_encryption} == 0) {
        die "Cannot read encrypted Mobi $self->{Source}\n";
    }

    (
        $self->{_doctype},
        $self->{_length},
        $self->{_type},
        $self->{_codepage},
        $self->{_uid},
        $self->{_version},
    ) = unpack "a4 N N N N N", substr $hdr, 16, 4 * 6;

    unless ($self->{_codepage} == 1252 or $self->{_codepage} == 65001) {
        die "Mobi $self->{Source} uses an unsupported text encoding\n";
    }

    # Read some parts of the Mobi header that we care about.
    my ($toff, $tlen)    = unpack "N N", substr $hdr, 0x54, 8;
    $self->{_imgrec}     = unpack "N",   substr $hdr, 0x6c, 4;
    my ($hoff, $hcount)  = unpack "N N", substr $hdr, 0x70, 8;
    $self->{_exth_flag}  = unpack "N",   substr $hdr, 0x80, 4;
    $self->{_lastcont}   = unpack "n",   substr $hdr, 0xc2, 2;
    $self->{_extra_data} = unpack "n",   substr $hdr, 0xf2, 2;

    if ($self->{_compression} == 17480) {

        unless ($EBook::Ishmael::MobiHuff::UNPACK_Q) {
            die "Cannot read AZW $self->{Source}; perl does not support " .
                "unpacking 64-bit integars\n";
        }

        my @huffs = map { $self->{_pdb}->record($_)->data } ($hoff .. $hoff + $hcount - 1);
        $self->{_huff} = EBook::Ishmael::MobiHuff->new(@huffs);
    }

    if ($self->{_length} >= 0xe3 and $self->{_version} >= 5) {
        my $flags = $self->{_extra_data};
        while ($flags > 1) {
            $self->{_trailers}++ if $flags & 2;
            $flags >>= 1;
        }
    }

    if ($self->{_version} == 8) {
        $self->{_fdst}     = unpack "N", substr $hdr, 0xc0,  4;
        $self->{_fragidx}  = unpack "N", substr $hdr, 0xf8,  4;
        $self->{_skelidx}  = unpack "N", substr $hdr, 0xfc,  4;
        $self->{_guideidx} = unpack "N", substr $hdr, 0x104, 4;
        $self->_kf8_init;
    }

    if ($self->{_lastcont} > $self->{_pdb}->recnum - 1) {
        $self->{_lastcont} = $self->{_pdb}->recnum - 1;
    }

    if ($self->{_imgrec} >= $self->{_lastcont}) {
        undef $self->{_imgrec};
    }

    if (defined $self->{_imgrec}) {
        for my $i ($self->{_imgrec} .. $self->{_lastcont}) {
            my $img = $self->{_pdb}->record($i)->data;
            my $id = image_id(\$img);
            push @{ $self->{_images} }, $i if defined $id;
        }
    }

    if ($self->{_exth_flag}) {
        $self->_read_exth(substr $hdr, $self->{_length} + 16);
    }

    if (
        defined $self->{_coverrec} and
        not grep { $self->{_coverrec} == $_ } @{ $self->{_images} }
    ) {
        undef $self->{_coverrec};
    }

    $self->{Metadata}->title([ substr $hdr, $toff, $tlen ]);

    unless (@{ $self->{Metadata}->created }) {
        $self->{Metadata}->created([ scalar gmtime $self->{_pdb}->cdate ]);
    }

    if ($self->{_pdb}->mdate) {
        $self->{Metadata}->modified([ scalar gmtime $self->{_pdb}->mdate ]);
    }

    if ($self->{_version} == 8) {
        $self->{Metadata}->format([ 'KF8' ]);
    } elsif (!@{ $self->{Metadata}->format }) {
        $self->{Metadata}->format([ 'MOBI' ]);
    }

    return $self;

}

sub rawml {

    my $self  = shift;
    my %param = @_;

    my $decode = $param{decode} // 0;
    my $clean  = $param{clean}  // 0;

    my $cont =
        join '',
        map { $self->_decode_record($_) }
        0 .. $self->{_recnum} - 1;

    _clean_html(\$cont) if $clean;

    if ($decode and $self->{_codepage} == 1252) {
        from_to($cont, "cp1252", "utf-8")
            or die "Failed to encode Mobi $self->{Source} text as utf-8\n";
    }

    return $cont;

}

sub html {

    my $self = shift;
    my $out  = shift;

    my $html;

    if ($self->{_version} == 8) {

        for my $part ($self->_kf8_xhtml) {

            my $dom = XML::LibXML->load_html(
                string => $part,
                no_network => !$self->{Network},
                recover => 2,
            );

            my ($body) = $dom->findnodes('/html/body') or next;

            $html .= join '', map { $_->toString } $body->childNodes;

        }

    } else {

        my $rawml = $self->rawml(clean => 1);
        my $enc = $self->{_codepage} == 1252 ? "cp1252" : "utf-8";
        my $dom = XML::LibXML->load_html(
            string => $rawml,
            no_network => !$self->{Network},
            encoding => $enc,
            recover => 2
        );
        $html = $dom->documentElement->toString;
    }

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

    my $raw;

    if ($self->{_version} == 8) {

        for my $part ($self->_kf8_xhtml) {
            my $dom = XML::LibXML->load_html(
                string => $part,
                no_network => !$self->{Network},
                recover => 2,
            );
            my ($body) = $dom->findnodes('/html/body') or next;
            $raw .= $body->textContent;
        }

    } else {

        my $rawml = $self->rawml(clean => 1);
        my $enc = $self->{_codepage} == 1252 ? "cp1252" : "utf-8";
        my $dom = XML::LibXML->load_html(
            string => $rawml,
            no_network => !$self->{Network},
            encoding => $enc,
            recover => 2,
        );

        $raw = $dom->documentElement->textContent;

    }

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

sub has_cover {

    my $self = shift;

    return defined $self->{_coverrec};

}

sub cover {

    my $self = shift;
    my $out  = shift;

    return undef unless $self->has_cover;

    my $bin = $self->{_pdb}->record($self->{_coverrec})->data;

    if (defined $out) {
        open my $fh, '>', $out
            or die "Failed to open $out for writing: $!\n";
        binmode $fh;
        print { $fh } $out;
        close $fh;
        return $out;
    } else {
        return $bin;
    }

}

sub image_num {

    my $self = shift;

    return scalar @{ $self->{_images} };

}

sub image {

    my $self = shift;
    my $n    = shift;

    if ($n >= $self->image_num) {
        return undef;
    }

    my $img = $self->{_pdb}->record($self->{_images}->[$n])->data;

    return \$img;

}

1;
