package Lingua::ZH::TaBE;
$VERSION = '0.07';

use 5.005;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(
    TsiDBOpen
    TsiInfoLookupPossibleTsiYin
    TsiYinDBOpen
    ChuInfoToChunkInfo
    ChunkSegmentationSimplex
    ChunkSegmentationComplex
    ChunkSegmentationBackward
    TsiInfoLookupZhiYin
    YinLookupZhiList
    YinToZuYinSymbolSequence
    ZuYinSymbolSequenceToYin
    ZuYinIndexToZuYinSymbol
    ZuYinSymbolToZuYinIndex
    ZozyKeyToZuYinIndex
    ZhiIsBig5Code
    ZhiToZhiCode
    ZhiCodeToZhi
    ZhiCodeToPackedBig5Code
    ZhiCodeLookupRefCount
    DB_TYPE_DB
    DB_TYPE_LAST
    DB_FLAG_OVERWRITE
    DB_FLAG_CREATEDB
    DB_FLAG_READONLY
    DB_FLAG_NOSYNC
    DB_FLAG_SHARED
    DB_FLAG_NOUNPACK_YIN
);

%EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant DB_TYPE_DB			=> 0;
use constant DB_TYPE_LAST		=> 1;
use constant DB_FLAG_OVERWRITE		=> 0x01;
use constant DB_FLAG_CREATEDB		=> 0x02;
use constant DB_FLAG_READONLY		=> 0x04;
use constant DB_FLAG_NOSYNC		=> 0x08;
use constant DB_FLAG_SHARED		=> 0x10;
use constant DB_FLAG_NOUNPACK_YIN	=> 0x20;

bootstrap Lingua::ZH::TaBE $VERSION;

my %cache;

sub new {
    my ($class, %args) = @_;

    $args{tsi_db} ||= '/usr/local/lib/tabe/tsi.db';
    $args{tsi_db} ||= '/usr/local/share/tabe/tsiyin/tsi.db'
	unless -e $args{tsi_db};
    $args{tsi_db} ||= '/usr/local/tabe/lib/tsi.db'
	unless -e $args{tsi_db};

    $args{tsiyin_db} ||= '/usr/local/lib/tabe/yin.db';
    $args{tsiyin_db} ||= '/usr/local/share/tabe/tsiyin/yin.db'
	unless -e $args{tsiyin_db};
    $args{tsi_db} ||= '/usr/local/tabe/lib/yin.db'
	unless -e $args{tsi_db};

    my $self = {};

    $self->{tsi_db} = (
	$cache{join($;, %args)} ||= Lingua::ZH::TaBE::TsiDB->new(
	    Lingua::ZH::TaBE::DB_TYPE_DB(),
	    $args{tsi_db},
	    Lingua::ZH::TaBE::DB_FLAG_READONLY() |
	    Lingua::ZH::TaBE::DB_FLAG_SHARED(),
	)
    ) if -e $args{tsi_db};

    $self->{tsiyin_db} = (
	$cache{join($;, %args)} ||= Lingua::ZH::TaBE::TsiYinDB->new(
	    Lingua::ZH::TaBE::DB_TYPE_DB(),
	    $args{tsiyin_db},
	    Lingua::ZH::TaBE::DB_FLAG_READONLY() |
	    Lingua::ZH::TaBE::DB_FLAG_SHARED(),
	)
    ) if -e $args{tsiyin_db};

    return bless($self, $class);
}

sub split {
    map $_->tsi,
    map $_->tsis($_[1]),
    shift->Chu($_[0])->chunks;
}

sub Chu {
    my $class = shift;
    return Lingua::ZH::TaBE::Chu->new(
	join('，', $_[-1] =~ m/((?:[\xa1-\xf9][\x40-\x7e\xa1-\xfe])+)/g)
    );
}

sub Chunk {
    my $class = shift;
    return Lingua::ZH::TaBE::Chunk->new(
	join('', $_[-1] =~ m/((?:[\xa1-\xf9][\x40-\x7e\xa1-\xfe])+)/g)
    );
}

sub Tsi {
    my $self = shift;
    return Lingua::ZH::TaBE::Tsi->new(
	($_[0] =~ m/((?:[\xa1-\xf9][\x40-\x7e\xa1-\xfe])+)/) ? $1 : ''
    );
}

sub Zhi {
    my $class = shift;
    return Lingua::ZH::TaBE::Zhi->new(
	$_[0] =~ /^\d+$/
	    ? Lingua::ZH::TaBE::ZhiCodeToZhi($_[0])
	    : $_[0] =~ m/((?:[\xa1-\xf9][\x40-\x7e\xa1-\xfe]))/
    );
}

sub Yin {
    my $class = shift;
    return Lingua::ZH::TaBE::Yin->new(
	$_[0] =~ /^\d+$/
	    ? $_[0]
	    : Lingua::ZH::TaBE::ZuYinSymbolSequenceToYin($_[0])
    );
}

sub ZuYin {
    my $class = shift;
    return Lingua::ZH::TaBE::ZuYin->new(
	$_[0] =~ /^\d+$/
	    ? $_[0]
	    : Lingua::ZH::TaBE::ZuYinSymbolToZuYinIndex($_[0])
    );
}

sub ZozyKey {
    my $class = shift;
    return Lingua::ZH::TaBE::ZuYin->new(
	ZozyKeyToZuYinIndex($_[0])
    );
}

sub TsiDB { shift->{tsi_db} }
sub TsiYinDB { shift->{tsiyin_db} }

package Lingua::ZH::TaBE::Chu;
use overload '""' => sub { shift->chu }, fallback => 1;

sub chunks {
    my $chu = shift;
    $chu->ToChunkInfo if $chu->num_chunk <= 0;
    return unless defined wantarray;
    wantarray ? $chu->chunk : [ $chu->chunk ];
}

package Lingua::ZH::TaBE::Chunk;
use overload '""' => sub { shift->chunk }, fallback => 1;

my %methods = (
    s  => 'SegmentationSimplex',
    c  => 'SegmentationComplex',
    b  => 'SegmentationBackward',
);

sub tsis {
    my $chunk = shift;
    $chunk->Segmentation(@_) if $chunk->num_tsi <= 0;
    return unless defined wantarray;
    wantarray ? $chunk->tsi : [ $chunk->tsi ];
}

sub Segmentation {
    my $chunk = shift;

    if ($chunk->chunk =~ /^[\xa4-\xf9]/) {
	my $method = shift || 's';

	my $func = $methods{lc(substr($method, 0, 1))}
	    or die "Unknown segmentation method: $method";

	$chunk->$func(@_);
    }
}

package Lingua::ZH::TaBE::Tsi;
use overload '""' => sub { shift->tsi }, fallback => 1;

sub zhis {
    my $tsi = shift;
    return unless defined wantarray;
    wantarray ? (
	map Lingua::ZH::TaBE->Zhi($_),
	$tsi->tsi =~ m/([\xa1-\xf9][\x40-\x7e\xa1-\xfe])/g
    ) : [
	map Lingua::ZH::TaBE->Zhi($_),
	$tsi->tsi =~ m/([\xa1-\xf9][\x40-\x7e\xa1-\xfe])/g
    ];
}

sub yins {
    my $tsi = shift;
    $tsi->LookupZhiYin(@_) unless $tsi->yinnum;
    return unless defined wantarray;
    wantarray ? $tsi->yindata : [ $tsi->yindata ];
};

package Lingua::ZH::TaBE::Zhi;
use overload '0+' => sub { shift->ToZhiCode },
	     '""' => sub { shift->zhi },
	     fallback => 1;

sub yins {
    my $tsi = Lingua::ZH::TaBE->Tsi(shift->zhi);
    $tsi->LookupZhiYin(@_);
    return unless defined wantarray;
    wantarray ? $tsi->yindata : [ $tsi->yindata ];
}

sub zhi { ${+shift} }
sub new {
    bless(\$_[1], $_[0]);
}

sub IsBig5Code {
    Lingua::ZH::TaBE::ZhiIsBig5Code(shift->zhi)
}
sub ToZhiCode {
    Lingua::ZH::TaBE::ZhiToZhiCode(shift->zhi)
}
sub ToZhi {
    shift->zhi
}
sub ToPackedBig5Code {
    Lingua::ZH::TaBE::ZhiCodeToPackedBig5Code(shift->ToZhiCode)
}
sub LookupRefCount {
    Lingua::ZH::TaBE::ZhiCodeLookupRefCount(shift->ToZhiCode)
}

package Lingua::ZH::TaBE::Yin;
use overload '0+' => sub { shift->yin },
	     '""' => sub { shift->ToZuYinSymbolSequence },
	     fallback => 1;

sub yin { ${+shift} }
sub ToZuYinSymbolSequence { 
    Lingua::ZH::TaBE::YinToZuYinSymbolSequence(shift->yin)
}
sub new { bless(\$_[1], $_[0]) }
sub zuyins {
    return unless defined wantarray;
    wantarray ? (
	map Lingua::ZH::TaBE->ZuYin($_),
	shift->ToZuYinSymbolSequence =~ m/([\xa1-\xf9][\x40-\x7e\xa1-\xfe])/g
    ) : [
	map Lingua::ZH::TaBE->ZuYin($_),
	shift->ToZuYinSymbolSequence =~ m/([\xa1-\xf9][\x40-\x7e\xa1-\xfe])/g
    ];
}

sub zhis {
    return unless defined wantarray;
    wantarray ? (
	map Lingua::ZH::TaBE->Zhi($_),
	shift->LookupZhiList =~ m/([\xa1-\xf9][\x40-\x7e\xa1-\xfe])/g
    ) : [
	map Lingua::ZH::TaBE->Zhi($_),
	shift->LookupZhiList =~ m/([\xa1-\xf9][\x40-\x7e\xa1-\xfe])/g
    ];
}
sub LookupZhiList {
    return Lingua::ZH::TaBE::YinLookupZhiList(shift->yin);
}
sub ToYin {
    shift->yin
}

package Lingua::ZH::TaBE::ZuYin;
use overload '0+' => sub { shift->zuyin },
	     '""' => sub { shift->zhi },
	     fallback => 1;

sub zuyin { ${+shift} }
sub yin {
    Lingua::ZH::TaBE->Yin(
	shift->ToZuYinSymbol->zhi
    );
}
sub new {
    bless(\$_[1], $_[0]);
}

sub zhi {
    Lingua::ZH::TaBE->Zhi(
	Lingua::ZH::TaBE::ZuYinIndexToZuYinSymbol(shift->zuyin)
    );
}

sub ToZuYinSymbol {
    shift->zhi
}
sub ToZuYinIndex {
    shift->zuyin
}

1;

__END__

=encoding big5

=head1 NAME

Lingua::ZH::TaBE - Chinese processing via libtabe

=head1 VERSION

This document describes version 0.07 of Lingua::ZH::TaBE, released
December 31, 2005.

=head1 SYNOPSIS

    use Lingua::ZH::TaBE;

    my $tabe = Lingua::ZH::TaBE->new;

    # Phrase splitter
    my @phrases = $tabe->split(
	"當我們在電腦中處理中文資訊時，相信其中最惱人的".
	"狀況之一，莫過於想打的字打不出來了。"
    );

    # Chaining various components
    print $tabe->Chu("道可道，非常道。")    # sentence
	->chunks->[2]	    # 非常道	    # chunk
	->tsis->[0]	    # 非常	    # phrase
	->zhis->[1]	    # 常	    # character
	->yins->[0]	    # ㄔㄤˊ	    # pronounciation
	->zuyins->[0],	    # ㄔ	    # phonetic symbols

=head1 DESCRIPTION

This module is a Perl interface to the B<TaBE> (Taiwan and Big5
Encoding) library, an unified interface and library dealing with Chinese
words, phrases, sentences, and phonetic symbols; it is intended to be
used as the foundation of Chinese text processing.

B<Lingua::ZH::TaBE> provides an object-oriented interface (preferred),
as well as a procedural interface consisting of all C functions in
C<tabe.h>.

=head1 Object-Oriented Interface

=head2 Lingua::ZH::TaBE

=over 4

=item new( [tsi_db => $file, tsiyin_db => $file] )

Creates a LibTaBE handle and opens databases.  If unspecified, find in
the usual libtabe data directory automatically.

=item split( $string [, $method] )

Split the text in C<$string>; returns a list of strings representing the
words obtained.  You may specify C<Complex> or C<Backward> as C<$method>
to use an alternate segmentation algorithm.

=item Chu(), Chunk(), Tsi(), Zhi(), Yin(), ZuYin()

Constructors for various level of objects, each taking one argument for
initialization.

=back

=head2 Lingua::ZH::TaBE::Chu

=over 4

=item chunks()

=back

=head2 Lingua::ZH::TaBE::Chunk

=over 4

=item tsis([$method])

=back

=head2 Lingua::ZH::TaBE::Tsi

=over 4

=item zhis()

=item yins()

=back

=head2 Lingua::ZH::TaBE::Zhi

=over 4

=item yins()

=item ToZhi()

=item ToZhiCode()

=item IsBig5Code()

=item ToPackedBig5Code()

=item LookupRefCount()

=back

=head2 Lingua::ZH::TaBE::Yin

=over 4

=item zuyins()

=item zhis()

=item ToYin()

=item ToZuYinSymbolSequence()

=back

=head2 Lingua::ZH::TaBE::ZuYin

=over 4

=item yin()

=item zhi()

=back

=head1 Procedural Interface

All functions below belong to the B<Lingua::ZH::TaBE> class; they are
not exported by default, but may be imported explicitly, or implicitly
via C<use Lingua::ZH::TaBE ':all'>.

    $TsiDB	= TsiDBOpen($type, $db_name, $flags);
    $num	= TsiInfoLookupPossibleTsiYin($TsiDB, $Tsi);
    $TsiYinDB	= TsiYinDBOpen($type, $db_name, $flags);
    $num	= ChuInfoToChunkInfo($Chu);
    $num	= ChunkSegmentationSimplex($TsiDB, $Chunk);
    $num	= ChunkSegmentationComplex($TsiDB, $Chunk);
    $num	= ChunkSegmentationBackward($TsiDB, $Chunk);
    $num	= TsiInfoLookupZhiYin($TsiDB, $Tsi);
    $string     = YinLookupZhiList($Yin);
    $string     = YinToZuYinSymbolSequence($Yin);
    $yin	= ZuYinSymbolSequenceToYin($string);
    $zhi	= ZuYinIndexToZuYinSymbol($ZuYin);
    $zuyin	= ZuYinSymbolToZuYinIndex($Zhi);
    $zuyin	= ZozyKeyToZuYinIndex($key);
    $num	= ZhiIsBig5Code($Zhi);
    $zhicode	= ZhiToZhiCode($Zhi);
    $zhi        = ZhiCodeToZhi($zhicode);
    $num	= ZhiCodeToPackedBig5Code($zhicode);
    $num	= ZhiCodeLookupRefCount($zhicode);

=head1 Constants

All constants below belong to the B<Lingua::ZH::TaBE> class; they are
not exported by default, but may be imported explicitly, or implicitly
via C<use Lingua::ZH::TaBE ':all'>.

    DB_TYPE_DB			0
    DB_TYPE_LAST		1
    DB_FLAG_OVERWRITE		0x01
    DB_FLAG_CREATEDB		0x02
    DB_FLAG_READONLY		0x04
    DB_FLAG_NOSYNC		0x08
    DB_FLAG_SHARED		0x10
    DB_FLAG_NOUNPACK_YIN	0x20

=head1 CAVEATS

The B<TsiYin> family of functions are yet incomplete.

=head1 SEE ALSO

L<ftp://xcin.linux.org.tw/pub/xcin/libtabe/devel/>

L<http://libtabe.sourceforge.net/>

=head1 AUTHORS

Audrey Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, 2004, 2005 by Audrey Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
