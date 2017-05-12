#!/usr/bin/perl

package Mac::iPod::GNUpod::Utils;

# This file is based on code from FooBar.pm and XMLhelper.pm in the GNUpod
# toolset. The original code is (C) 2002-2003 Adrian Ulrich <pab at
# blinkenlights.ch>.
#
# Much rewriting and adaptation by JS Bangs <jaspax at glossopoesis.org>, (C)
# 2003-2004.

use Exporter;
use Unicode::String;
use File::Spec;
use MP3::Info qw(:all); 
use MP4::Info;
use Audio::Wav;

@ISA = qw/Exporter/;
@EXPORT = qw/shx2int xescaped realpath mkhash mktag matches/;

use strict;
use warnings;

BEGIN {
    MP3::Info::use_winamp_genres();
    MP3::Info::use_mp3_utf8(0);
    MP4::Info::use_mp4_utf8(0);
}

# Reformat shx numbers
sub shx2int {
    my($shx) = @_;
    my $buff = '';
    foreach(split(//,$shx)) {
        $buff = sprintf("%02X",ord($_)).$buff;
    }
    return hex($buff);
}

# Escape strings for XML
sub xescaped {
    my $txt = shift;
    for ($txt) {
        s/&/&amp;/g;
        s/"/&quot;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        #s/'/&apos;/g;
    }

    return $txt;
}

# Create a hash
sub mkhash {
    my($base, @content) = @_;
    my $href = ();
    for(my $i=0;$i<int(@content);$i+=2) {
        $href->{$base}->{$content[$i]} = Unicode::String::utf8($content[$i+1])->utf8;
    }
    return $href;
}

# Create an XML tag 
sub mktag {
    my($elm, $attr, %opt) = @_;
    my $r = '<' . xescaped($elm) . ' ';
    foreach (sort keys %$attr) {
        next if $attr->{$_} eq ''; # Ignore empty vals
        $r .= xescaped($_). "=\"" . xescaped($attr->{$_}) . "\" ";
    }
    if ($opt{noend}) {
        $r .= ">";
    }
    else {
        $r .= " />";
    }

    return $r;
    #return getutf8($r);
}

# Find if two things match, w/ opts
sub matches {
    my ($left, $right, %opts) = @_;
    no warnings 'uninitialized';
    if ($opts{nocase}) {
        $left = lc $left;
        $right = lc $right;
    }
    if ($opts{nometachar}) {
        $right = quotemeta $right;
    }

    if ($opts{exact}) {
        return $left eq $right;
    }
    else {
        return $left =~ /$right/;
    }
}

# Try to discover the file format
sub wtf_is {
    my $file = shift;
    my $h;

    # Try to recognize by extension
    if ($file =~ m/\.mp3$/) {
        $h = mp3_info($file);
    }
    elsif ($file =~ m/\.wav$/) {
        $h = wav_info($file);
    }
    elsif ($file =~ m/\.(mp4|m4a)$/) {
        $h = mp4_info($file);
    }

    # Unrecognized file types
    else {
        $@ = "Unsupported/unknown file type: $file";
        return undef;
    }

    if ($h) {
        $h->{orig_path} = File::Spec->rel2abs($file);
        return $h;
    }
}

# Check if the file is an PCM (WAV) File
sub wav_info {
    my $file = shift;

    my $wav = Audio::Wav->new;
    my ($nfo, $details);
    eval {
        no warnings;
        my $read = $wav->read($file);
        $nfo = $read->get_info;
        $details = $read->details;
    };
    return undef if $@;

    my %rh = ();

    # Get basic info from $details
    $rh{bitrate}  = $details->{bytes_sec} * 8;
    $rh{srate}    = $details->{sample_rate};
    $rh{time}     = $details->{length};
    $rh{fdesc}    = "RIFF Audio File";

    # No id3 tags for WAV, so we check the nfo hash and file path
    my @path = File::Spec->splitdir((File::Spec->splitpath($file))[1]);
    no warnings 'uninitialized';
    $rh{title}  = $nfo->{name}    || $path[-1] || "Unknown Title";
    $rh{album}  = $nfo->{product} || $path[-2] || "Unknown Album";
    $rh{artist} = $nfo->{artist}  || $path[-3] || "Unknown Artist";
    $rh{genre}  = $nfo->{genre};
    $rh{comment}= $nfo->{comments};
    $rh{year}   = int($nfo->{copyright});

    return \%rh;
}

sub get_last_nested {
    my $ref = shift;
    if (ref($ref) eq 'ARRAY') {
        return get_last_nested($ref->[-1]);
    }
    return $ref;
}


# Read mp3 tags, return undef if file is not an mp3
sub mp3_info {
    my $file = shift;

    my $h = MP3::Info::get_mp3info($file);
    return undef unless $h; #Not an mp3

    #This is our default fallback:
    #If we didn't find a title, we'll use the
    #Filename.. why? because you are not able
    #to play the file without a filename ;)
    my $cf = (File::Spec->splitpath($file))[-1];

    my %rh = ();

    $rh{bitrate}  = $h->{BITRATE};
    $rh{filesize} = $h->{SIZE};
    $rh{srate}    = int($h->{FREQUENCY}*1000);
    $rh{time}     = int($h->{SECS}*1000);
    $rh{fdesc}    = "MPEG $h->{VERSION} layer $h->{LAYER} file";

    $h = MP3::Info::get_mp3tag($file,1);  #Get the IDv1 tag
    my $hs = MP3::Info::get_mp3tag($file, 2, 2); #Get the IDv2 tag

    # If any of these are array refs (multiple values), take last value
    for (keys %$hs) {
        $hs->{$_} = get_last_nested($hs->{$_});
    }

    #IDv2 is stronger than IDv1..
    #Try to parse things like 01/01
    no warnings 'uninitialized';
    no warnings 'numeric';
    my @songa = parseslashes($hs->{TRCK} || $h->{TRACKNUM});
    my @cda   = parseslashes($hs->{TPOS});
    $rh{songs}    = int($songa[1]);
    $rh{songnum}  = int($songa[0]);
    $rh{cdnum}    = int($cda[0]);
    $rh{cds}      = int($cda[1]);
    $rh{year}     = $hs->{TYER} || $h->{YEAR}   || 0;
    $rh{title}    = $hs->{TIT2} || $h->{TITLE}  || $cf || "Untitled";
    $rh{album}    = $hs->{TALB} || $h->{ALBUM}  || "Unknown Album";
    $rh{artist}   = $hs->{TPE1} || $h->{ARTIST} || "Unknown Artist";
    $rh{genre}    =                $h->{GENRE}  || "";
    $rh{comment}  = $hs->{COMM} || $h->{COMMENT}|| "";
    $rh{composer} = $hs->{TCOM} || "";
    $rh{playcount}= int($hs->{PCNT}) || 0;

    return \%rh;
}

# This subroutine written by Masanori Hara, added in v. 1.22
sub mp4_info {
    my $file = shift;

    my $h = MP4::Info::get_mp4info($file);
    return unless $h; #Not an mp3

    #This is our default fallback:
    #If we didn't find a title, we'll use the
    #Filename.. why? because you are not able
    #to play the file without a filename ;)
    my $cf = (File::Spec->splitpath($file))[-1];

    my %rh = ();

    $rh{bitrate}  = $h->{BITRATE};
    $rh{filesize} = $h->{SIZE};
    $rh{srate}    = int($h->{FREQUENCY}*1000);
    $rh{time}     = int($h->{SECS}*1000);
    $rh{fdesc}    = $h->{TOO};

    $h = MP4::Info::get_mp4tag($file,1);  #Get the IDv1 tag
    my $hs = MP4::Info::get_mp4tag($file, 2, 2); #Get the IDv2 tag
    # If any of these are array refs (multiple values), take last value
    for (keys %$hs) {
        if (ref($hs->{$_}) eq 'ARRAY') {
            $hs->{$_} = $hs->{$_}->[-1];
        }
    }

    #IDv2 is stronger than IDv1..
    #Try to parse things like 01/01
    no warnings 'uninitialized';
    no warnings 'numeric';
    my @songa = parseslashes($hs->{TRCK} || $h->{TRACKNUM});
    my @cda   = parseslashes($hs->{TPOS});
    $rh{songs}    = int($songa[1]);
    $rh{songnum}  = int($songa[0]);
    $rh{cdnum}    = int($cda[0]);
    $rh{cds}      = int($cda[1]);
    $rh{year}     = $hs->{TYER} || $h->{YEAR}   || 0;
    $rh{title}    = $hs->{TIT2} || $h->{TITLE}  || $cf || "Untitled";
    $rh{album}    = $hs->{TALB} || $h->{ALBUM}  || "Unknown Album";
    $rh{artist}   = $hs->{TPE1} || $h->{ARTIST} || "Unknown Artist";
    $rh{genre}    =                $h->{GENRE}  || "";
    $rh{comment}  = $hs->{COMM} || $h->{COMMENT}|| "";
    $rh{composer} = $hs->{TCOM} || "";
    $rh{playcount}= int($hs->{PCNT}) || 0;

    return \%rh;
}

# Guess format
sub parseslashes {
    my($string) = @_;
    no warnings 'numeric';
    no warnings 'uninitialized';
    if(my($s,$n) = $string =~ m!(\d+)/(\d+)!) {
        return int($s), int($n);
    }
    else {
        return int($string);
    }
}

# Try to 'auto-guess' charset and return utf8
sub getutf8 {
    my $in = shift;

    no warnings 'uninitialized';
    if(ord($in) > 0 && ord($in) < 32) {
        $@ = "Unsupported ID3 encoding found: " .ord($in)."\n";
        return undef;
    }
    # autoguess (accept invalid id3tags)
    else { 
        #Remove all 00's
        $in =~ tr/\0//d;
        no warnings;
        my $bfx = Unicode::String::utf8($in);
        if($bfx ne $in) {
            #Input was not valid utf8, assume latin1 input
            $in =~  s/[\000-\037]//gm; #Kill stupid chars..
            $in = Unicode::String::latin1($in);
        }
        else { #Return the unicoded input
            $in = $bfx;
        }
    }
    return $in;
}

1;
