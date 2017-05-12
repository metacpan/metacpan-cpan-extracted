=head1 NAME

Lingua::JA::Romanize::DictJA - Dictionary converter

=head1 SYNOPSIS

    perl -MLingua::JA::Romanize::DictJA -e 'Lingua::JA::Romanize::DictJA->update();'

=head1 DESCRIPTION

This module creates dictionary cache files for
L<Lingua::JA::Romanize::Japanese> module.

Source dictionary file per default: (included in this package)

    http://openlab.jp/skk/skk/dic/SKK-JISYO.S

Optional/external dictionary files:

    http://openlab.jp/skk/dic/SKK-JISYO.L.gz
    http://openlab.jp/skk/dic/SKK-JISYO.jinmei.gz
    http://openlab.jp/skk/dic/SKK-JISYO.geo.gz
    http://openlab.jp/skk/dic/SKK-JISYO.station.gz
    http://openlab.jp/skk/dic/SKK-JISYO.propernoun.gz

Cached dictionary files:

    @INC / Lingua/JA/Romanize/Japanese.store

The DictJA module is called only from Makefile.PL
on installing this package.

=head1 REQUIRED MODULES

L<DB_File> module is required to create cached dictionary files.
L<Jcode> module is required on Perl 5.8.0 or less to install
this package. L<Encode> module is used on Perl 5.8.1 or above.
L<LWP::UserAgent> module is optional and used to fetch external
dictionary files.
L<IO::Zlib> module is optional and used to parse gzipped files.

=head1 SEE ALSO

L<Lingua::JA::Romanize::Japanese>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2008 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package Lingua::JA::Romanize::DictJA;
use strict;
use vars qw( $VERSION );
$VERSION = "0.23";
use Lingua::JA::Romanize::Kana;
use ExtUtils::MakeMaker;
use Fcntl;
use IO::File;

my $PERL581 = 1 if ( $] >= 5.008001 );
my $FETCH_CACHE = "skk";
my $DICT_DB     = 'Japanese.bdb';
my $DIC_SMALL   = [ qw(
    skk/SKK-JISYO.S
) ];
my $DIC_LARGE = [ qw(
    http://openlab.jp/skk/skk/dic/SKK-JISYO.L
    http://openlab.jp/skk/skk/dic/SKK-JISYO.jinmei
    http://openlab.jp/skk/skk/dic/SKK-JISYO.propernoun
    http://openlab.jp/skk/skk/dic/SKK-JISYO.geo
    http://openlab.jp/skk/skk/dic/SKK-JISYO.station
) ];
my $DIC_GZIPED = [ qw(
    http://openlab.jp/skk/dic/SKK-JISYO.L.gz
    http://openlab.jp/skk/dic/SKK-JISYO.jinmei.gz
    http://openlab.jp/skk/dic/SKK-JISYO.propernoun.gz
    http://openlab.jp/skk/dic/SKK-JISYO.geo.gz
    http://openlab.jp/skk/dic/SKK-JISYO.station.gz
) ];

# ----------------------------------------------------------------
sub update {
    my $package = shift;
    my $base    = shift;
    print "Updater: ", __PACKAGE__, " (", $VERSION, ")\n";

    unless ( defined $base ) {
        $base = $INC{ join( "/", split( "::", (__PACKAGE__) . ".pm" ) ) };
        $base =~ s#/[^/]*$##;
    }

    local $| = 1;

    my $dbpath = $base . "/" . $DICT_DB;
    if ( -r $dbpath ) {
        print "DB_File is already exist: $dbpath\n";
        my $mess = 'Do you wish to overwrite this?';
        my $yes = ExtUtils::MakeMaker::prompt( $mess, 'y' );
        if ( $yes ne 'y' ) {
            print "Canceled to update the dictionary.\n";
            return;
        }
    } else {
        print "Path: ", $dbpath, "\n";
    }

    print "Loading module: DB_File.pm\n";
    &require_db_file();    # required

    print "Loading module: LWP::UserAgent\n";
    &require_lwp_useragent();

    print "Loading module: IO::Zlib\n";
    &require_io_zlib();

    if ($PERL581) {
        print "Loading module: Encode.pm\n";
        &require_encode();    # Perl 5.8.x
    }
    else {
        print "Loading module: Jcode.pm\n";
        &require_jcode();     # Perl 5.005/5.6.x
    }

    my $diclist = $DIC_SMALL;    # default dictionary
    print "External dictionaries:\n";
    my $cand = defined $IO::Zlib::VERSION ? $DIC_GZIPED : $DIC_LARGE;
    print "\t", $_, "\n" foreach (@$cand);
    my $mess = 'Do you wish to download these files?';
    my $yes = ExtUtils::MakeMaker::prompt( $mess, 'y' );
    if ( $yes eq 'y' ) {
        $diclist = $cand;
    }
    else {
        print "Okay, the default dictionary is used:\n";
        print "\t", $_, "\n" foreach (@$diclist);
    }

    # load all dictionaries

    my $tmphash = {};
    foreach my $jisyo (@$diclist) {
        $tmphash = &read_skk_jisyo( $jisyo, $tmphash );
    }

    # multiple romanizations

    print "Optimizing dictionary: ";
    foreach my $kanji ( keys %$tmphash ) {
        next unless ref $tmphash->{$kanji};
        my $uniq = { map { $_ => 1 } @{ $tmphash->{$kanji} } };
        $tmphash->{$kanji} = join( "/", sort keys %$uniq );
    }

    # add dummy entries for partical matching
    # to use seq() method with R_CURSOR flag is better way on DB_File, but...

    foreach my $kanji ( keys %$tmphash ) {
        while ($kanji) {
            $kanji =~ s/([\x00-\x7F]|[\xC0-\xFF][\x80-\xBF]+)$// or last;
            last if exists $tmphash->{$kanji};
            $tmphash->{$kanji} = "";
        }
    }
    printf( "%d keywords.\n", scalar keys %$tmphash );

    # create DB_File

    print "Writing DB_File: $dbpath\n";
    my $dbhash = {};
    my $flags  = Fcntl::O_RDWR() | Fcntl::O_CREAT();
    my $mode   = 0644;
    my $btree  = DB_File::BTREEINFO->new();
    tie( %$dbhash, 'DB_File', $dbpath, $flags, $mode, $btree )
      or die "$! - $dbpath\n";
    my $cnt = 0;
    foreach my $key ( keys %$tmphash ) {
        $dbhash->{$key} = $tmphash->{$key};
        next if ( ++$cnt % 2000 );
        print ".";
        printf( " %6d\n", $cnt ) unless ( $cnt % 100000 );
    }
    printf( " %d keywords saved.\n", $cnt );
    untie(%$dbhash);

    print "Done.\n";

    undef;
}

sub read_skk_jisyo {
    my $jisyo = shift or return;
    my $hash = shift || {};
    my $conv = Lingua::JA::Romanize::Kana->new();

    local $| = 1;
    my $cnt = 0;

    if ( $jisyo =~ m#^http://# ) {
        my $name = ( $jisyo =~ m#([^/]+)$# )[0];
        my $cache = "$FETCH_CACHE/$name";
        if ( -r $cache ) {
            print "Cached file found: $cache\n";
        }
        else {
            print "Fetching file: $jisyo\n";
            if ( !defined $LWP::UserAgent::VERSION ) {
                die "LWP::UserAgent module is required: $jisyo\n";
            }
            my $ua = LWP::UserAgent->new;
            $ua->timeout(30);
            $ua->env_proxy();
            $ua->get( $jisyo, ':content_file' => $cache );
        }
        $jisyo = $cache;
    }

    print "Loading dictionary: $jisyo\n";
    my $fh;
    if ( $jisyo =~ /\.gz$/i ) {
        if ( !defined $IO::Zlib::VERSION ) {
            die "IO::Zlib module is required: $jisyo\n";
        }
        $fh = new IO::Zlib( $jisyo, "rb" ) or die "$! - $jisyo\n";
    }
    else {
        $fh = new IO::File( $jisyo, "r" ) or die "$! - $jisyo\n";
    }

    while ( my $line = <$fh> ) {
        next if ( $line =~ /^;/ );
        chomp $line;

        # convert encoding from EUC-JP to UTF-8
        if ($PERL581) {
            Encode::from_to( $line, "EUC-JP", "UTF-8" );
        }
        else {
            Jcode::convert( \$line, "utf8", "euc" );
        }

        my ( $kana, $slash ) = split( /\s+/, $line, 2 );
        next unless ( $kana =~ /\W/ );    # roman only entry
        my $okuri = $1 if ( $kana =~ s/(?<=\W)(\w)$// );
        my $roman = $conv->chars($kana) or next;
        $roman =~ s/\s+//g;
        next if ( $roman =~ /\W/ );       # kigou

        foreach my $kanji ( grep { $_ ne "" } split( "/", $slash ) ) {
            next unless ( $kanji =~ /^([\xE0-\xEF][\x80-\xBF]{2})/ );
            next unless &is_japanese($1);    # kigou
            $kanji =~ s/;.*$//s;
            $kanji .= $okuri if $okuri;      # okuri-ari
            if ( !exists $hash->{$kanji} ) {
                $hash->{$kanji} = $roman;
            }
            elsif ( !ref $hash->{$kanji} ) {
                $hash->{$kanji} = [ $hash->{$kanji}, $roman ];
            }
            else {
                push( @{ $hash->{$kanji} }, $roman );
            }
        }
        unless ( ++$cnt % 200 ) {
            print ".";
            printf( " %6d\n", $cnt ) unless ( $cnt % 10000 );
        }
    }
    $fh->close();
    printf( " %d lines loaded.\n", $cnt );

    $hash;
}

sub is_japanese {
    my ( $c1, $c2, $c3 ) = unpack( "C*", $_[0] );
    my $ucs2 =
      ( ( $c1 & 0x0F ) << 12 ) | ( ( $c2 & 0x3F ) << 6 ) | ( $c3 & 0x3F );
    return 1 if ( 0x3400 <= $ucs2 && $ucs2 <= 0x9FFF );    # CJK unified
    return 1 if ( 0x3041 <= $ucs2 && $ucs2 <= 0x3093 );    # hiragana
    return 1 if ( 0x30A1 <= $ucs2 && $ucs2 <= 0x30F6 );    # katakana
    undef;
}

sub require_db_file {
    return if defined $DB_File::VERSION;
    local $@;
    eval { require DB_File; };
    die "DB_File module is required.\n" if $@;
}

sub require_encode {
    return if defined $Encode::VERSION;
    local $@;
    eval { require Encode; };
    die "Encode module is required.\n" if $@;
}

sub require_jcode {
    return if defined $Jcode::VERSION;
    local $@;
    eval { require Jcode; };
    die "Jcode module is required.\n" if $@;
}

sub require_io_zlib {
    return if defined $IO::Zlib::VERSION;
    local $@;
    eval { require IO::Zlib; };
    print "IO::Zlib module is not loaded.\n" if $@;
}

sub require_compress_zlib {
    return if defined $Compress::Zlib::VERSION;
    local $@;
    eval { require Compress::Zlib; };
    print "Compress::Zlib module is not loaded.\n" if $@;
}

sub require_lwp_useragent {
    return if defined $LWP::UserAgent::VERSION;
    local $@;
    eval { require LWP::UserAgent; };
    print "LWP::UserAgent module is not loaded.\n" if $@;
}

# ----------------------------------------------------------------
1;
