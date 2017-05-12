#!/usr/bin/perl

package Mac::iPod::GNUpod::iTunesDBread;

# This package split off from iTunesDB.pm in the GNUpod toolset. Original code
# (C) 2002-2003 Adrian Ulrich <pab at blinkenlights.ch>. Part of the
# gnupod-tools collection, URL: http://www.gnu.org/software/gnupod/
#
# Code rewrite and adaptation for CPAN by JS Bangs <jaspax at cpan.org>.

use strict;
use warnings;
no warnings 'uninitialized'; # Useful throughout script (we deal with lots of intended undefs)
use Unicode::String;
use Mac::iPod::GNUpod::Utils;

#mk_mhod() will take care of lc() entries
my %mhod_id = (
    title => 1,
    path => 2,
    album => 3,
    artist => 4, 
    genre => 5, 
    fdesc => 6, 
    eq => 7, 
    comment => 8, 
    composer => 12
);# SPLPREF =>50, SPLDATA =>51, PLTHING => 100) ;

my @mhod_array;
foreach(keys(%mhod_id)) {
    $mhod_array[$mhod_id{$_}] = $_;
}

# Open the iTunesDB file..
sub open_itunesdb {
 open(FILE, $_[0]);
}

# Close the iTunesDB file..
sub close_itunesdb {
 close(FILE);
}

# Get a INT value
sub get_int {
    my($start, $anz) = @_;
    my $buffer = undef;

    # paranoia checks
    $start = int($start);
    $anz = int($anz);

    #seek to the given position
    seek(FILE, $start, 0);

    #start reading
    read(FILE, $buffer, $anz);
    return shx2int($buffer);
}

# Get a x86INT value
sub get_x86_int {
    my($start, $anz) = @_;

    my($buffer, $xx, $xr) = undef;

    # paranoia checks
    $start = int($start);
    $anz = int($anz);

    #seek to the given position
    seek(FILE, $start, 0);

    #start reading
    read(FILE, $buffer, $anz);
    foreach(split(//, $buffer)) {
        $xx = sprintf("%02X", ord($_));
        $xr .= $xx;
    }
    $xr = oct("0x".$xr);
    return $xr;
}

# Get all SPL items
sub read_spldata {
    my($hr) = @_;

    my $diff = $hr->{start}+160;
    my @ret = ();

    for(1..$hr->{htm}) {
        my $field = get_int($diff+3, 1);
        my $action= get_int($diff+7, 1);
        my $slen  = get_int($diff+55,1); #Whoa! This is true: string is limited to 0xfe (254) chars!! (iTunes4)
        my $rs    = undef; #ReturnSting

        #Fixme: this is ugly
        if($field =~ /^(2|3|4|8|9|14|18)$/) { #Is a string type
            my $string= get_string($diff+56, $slen);
            #No byteswap here?? why???
            $rs = Unicode::String::utf16($string)->utf8;
        }

        else { #Is INT (Or range)
            my $xfint = get_x86_int($diff+56+4,4);
            my $xtint = get_x86_int($diff+56+28,4);
            $rs = "$xfint:$xtint";
        }
        $diff += $slen+56;
        push(@ret, {field=>$field,action=>$action,string=>$rs});
    }
    return \@ret;
}

# Read SPLpref data
sub read_splpref {
    my($hs) = @_;
    my ($live, $chkrgx, $chklim, $mos);

    $live    = 1 if   get_int($hs->{start}+24,1);
    $chkrgx  = 1 if get_int($hs->{start}+25,1);
    $chklim  = 1 if get_int($hs->{start}+26,1);
    my $item =    get_int($hs->{start}+27,1);
    my $sort =    get_int($hs->{start}+28,1);
    my $limit=   get_int($hs->{start}+32,4);
    $mos     = 1 if get_int($hs->{start}+36,1);
    return({
        live=>$live,
        value=>$limit, 
        iitem=>$item, 
        isort=>$sort,
        mos=>$mos,
        checkrule=>($chklim+($chkrgx*2))
    });
}

# Do a hexDump DEBUGGING ONLY
sub __hd {
    open(KK,">/tmp/XLZ"); print KK $_[0]; close(KK);
    system("hexdump -vC /tmp/XLZ");
}

#get a SINGLE mhod entry:
# return+seek = new_mhod should be there
sub get_mhod {
    my ($seek) = @_;

    my $id  = get_string($seek, 4);          #are we lost?
    my $ml  = get_int($seek+8, 4);           #Length of this mhod
    my $mty = get_int($seek+12, 4);          #type number
    my $xl  = get_int($seek+28,4);           #String length

    ## That's spl stuff, only to be used with 51 mhod's
    my $htm = get_int($seek+35,1); #Only set for 51
    my $anym= get_int($seek+39,1); #Only set for 51
    my $spldata = undef; #dummy
    my $splpref = undef; #dummy

    if($id eq "mhod") { #Seek was okay
        my $foo = get_string($seek+($ml-$xl), $xl); #string of the entry 
        #$foo is now UTF16 (Swapped), but we need an utf8
        $foo = Unicode::String::byteswap2($foo);
        $foo = Unicode::String::utf16($foo)->utf8;

        ##Special handling for SPLs
        if($mty == 51) { #Get data from spldata mhod
            $foo = undef;
            $spldata = read_spldata({start=>$seek, htm=>$htm});
        }
        elsif($mty == 50) { #Get prefs from splpref mhod
            $foo = undef;
            $splpref = read_splpref({start=>$seek, end=>$ml});
        }
        return({size=>$ml,string=>$foo,type=>$mty,spldata=>$spldata,splpref=>$splpref,matchrule=>$anym});

    }
    else {
        return({size => -1});
    }
}

# get an mhip entry
sub get_mhip {
    my($pos) = @_;
    my $oid = 0;
    if(get_string($pos, 4) eq "mhip") {
        my $oof = get_int($pos+4, 4);
        my $mhods=get_int($pos+12,4);

        for(my $i=0;$i<$mhods;$i++) {
            my $mhs = get_mhod($pos+$oof)->{size};
            die "Fatal seek error in get_mhip, can't continue\n" if $mhs == -1;
            $oid+=$mhs;
        }

        my $plid = get_int($pos+5*4,4);
        my $sid  = get_int($pos+6*4, 4);
        return({size=>($oid+$oof),sid=>$sid,plid=>$plid});
    }

    #we are lost
    return ({size=>-1});
}

# Reads a string
sub get_string {
    my ($start, $anz) = @_;
    my($buffer) = undef;

    # paranoia
    $start = int($start);
    $anz = int($anz);
    seek(FILE, $start, 0);

    #start reading
    read(FILE, $buffer, $anz);
    return $buffer;
}

# Get a playlist (Should be called get_mhyp, but it does the whole playlist)
sub get_pl {
    my($pos) = @_;

    my %ret_hash = ();
    my @pldata = ();

    if(get_string($pos, 4) eq "mhyp") { #Ok, its an mhyp
        $ret_hash{type}= get_int($pos+20, 4); #Is it a main playlist?
        my $scount     = get_int($pos+16, 4); #How many songs should we expect?
        my $header_len = get_int($pos+4, 4);  #Size of the header
        my $mhyp_len   = get_int($pos+8, 4);   #Size of mhyp
        my $mhods      = get_int($pos+12,4); #How many mhods we have here

        #Its a MPL, do a fast skip
        if($ret_hash{type}) {
            return ($pos+$mhyp_len, {type=>1}) 
        }

        $pos += $header_len; #set pos to start of first mhod
        #We can now read the name of the Playlist
        #Ehpod is buggy and writes the playlist name 2 times.. well catch both of them
        #MusicMatch is also stupid and doesn't create a playlist mhod
        #for the mainPlaylist
        my ($oid, $plname, $itt) = undef;
        for(my $i=0;$i<$mhods;$i++) {
            my $mhh = get_mhod($pos);
            if($mhh->{size} == -1) {
                die "FATAL: Expected to find $mhods mhods, but I failed to get nr. $i. iTunesDBread.pm panic";
            }
            $pos+=$mhh->{size};
            if($mhh->{type} == 1) {
                $ret_hash{name} = $mhh->{string};
            }
            elsif(ref($mhh->{splpref}) eq "HASH") {
                $ret_hash{splpref} = $mhh->{splpref};
            }
            elsif(ref($mhh->{spldata}) eq "ARRAY") {
                $ret_hash{spldata} = $mhh->{spldata};
                $ret_hash{matchrule}=$mhh->{matchrule};
            }
        }

        #Now get the items
        for(my $i = 0; $i<$scount;$i++) {
            my $mhih = get_mhip($pos);
            if($mhih->{size} == -1) {
                die "FATAL: Expected to find $scount songs, but I failed to get nr. $i. iTunesDBread.pm panic";
            }
            $pos += $mhih->{size};
            push(@pldata, $mhih->{sid}) if $mhih->{sid};
        }
        $ret_hash{content} = \@pldata;
        return ($pos, \%ret_hash);   
    }

    #Seek was wrong
    return -1;
}

# Get mhit + child mhods
sub get_mhits {
    my ($sum) = @_;
    if(get_string($sum, 4) eq "mhit") { #Ok, its a mhit

    my %ret     = ();

    #Infos stored in mhit
    $ret{id}       = get_int($sum+16,4);
    $ret{filesize} = get_int($sum+36,4);
    $ret{time}     = get_int($sum+40,4);
    $ret{cdnum}    = get_int($sum+92,4);
    $ret{cds}      = get_int($sum+96,4);
    $ret{songnum}  = get_int($sum+44,4);
    $ret{songs}    = get_int($sum+48,4);
    $ret{year}     = get_int($sum+52,4);
    $ret{bitrate}  = get_int($sum+56,4);
    $ret{srate}    = get_int($sum+62,2); #What is 60-61 ?!!
    $ret{volume}   = get_int($sum+64,4);
    $ret{starttime}= get_int($sum+68,4);
    $ret{stoptime} = get_int($sum+72,4);
    $ret{playcount}= get_int($sum+80,4); #84 has also something to do with playcounts. (Like rating + prerating?)
    $ret{lastplay} = get_int($sum+88,4);
    $ret{addtime}  = get_int($sum+104,4);
    $ret{bookmark} = get_int($sum+108,4);
    $ret{bpm}      = get_int($sum+122,2);

    $ret{rating}   = int((get_int($sum+28,4)-256)/oct('0x14000000'));
    $ret{prerating}= int(get_int($sum+120,4) / oct('0x140000'));

    ####### We have to convert the 'volume' to percent...
    ####### The iPod doesn't store the volume-value in percent..
    #Minus value (-X%)
    $ret{volume} -= oct("0xffffffff") if $ret{volume} > 255;

    #Convert it to percent
    $ret{volume} = sprintf("%.0f",($ret{volume}/2.55));

    ## Paranoia check
    if(abs($ret{volume}) > 100) {
        $@ .= "Volume is $ret{volume} percent for song $ret{id}.. set to 0 percent";
        $ret{volume} = 0;
    }

    #Now get the mhods from this mhit
    my $mhods = get_int($sum+12,4);
    $sum += get_int($sum+4,4);

    for(my $i=0; $i < $mhods; $i++) {
        my $mhh = get_mhod($sum);
        if($mhh->{size} == -1) {
            die "FATAL: Expected to find $mhods mhods, but I failed to get nr $i. iTunesDBread.pm panic";     
        }
        $sum+=$mhh->{size};
        my $xml_name = $mhod_array[$mhh->{type}];
        if($xml_name) { #Has an xml name.. sounds interesting
            $ret{$xml_name} = $mhh->{string};
        }
        else {
            warn "iTunesDB.pm: found unhandled mhod type '$mhh->{type}'\n";
        }
    }

    return ($sum,\%ret); #black magic, returns next (possible?) start of the mhit
    }
    
    #Was no mhod
    return -1;
}

# Returns start of part1 (files) and part2 (playlists)
sub get_starts {
    #Get start of first mhit:
    my $mhbd_s     = get_int(4,4);
    my $pdi        = get_int($mhbd_s+8,4); #Used to calculate start of playlist
    my $mhsd_s     = get_int($mhbd_s+4,4);
    my $mhlt_s     = get_int($mhbd_s+$mhsd_s+4,4);
    my $pos = $mhbd_s+$mhsd_s+$mhlt_s; #pos is now the start of the first mhit (always 292?);

    #How many songs are on the iPod ?
    my $sseek = $mhbd_s + $mhsd_s;
    my $songs = get_int($sseek+8,4);

    #How many playlists should we find ?
    $sseek = $mhbd_s + $pdi;
    $sseek += get_int($sseek+4,4);
    my $pls = get_int($sseek+8,4);
    return({position=>$pos,pdi=>($pos+$pdi),songs=>$songs,playlists=>$pls});
}

1;
