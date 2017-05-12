#!/usr/bin/perl

package Mac::iPod::GNUpod::iTunesDBwrite;

# This package split off from iTunesDB.pm in the GNUpod toolset. Original code
# (C) 2002-2003 Adrian Ulrich <pab at blinkenlights.ch>. Part of the
# gnupod-tools collection, URL: http://www.gnu.org/software/gnupod/
#
# Code rewrite and adaptation for CPAN by JS Bangs <jaspax at cpan.org>.

use strict;
use warnings;
no warnings 'uninitialized';
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

# create an iTunesDB header
sub mk_mhbd {
    my ($hr) = @_;

    my $ret = "mhbd";
    $ret .= pack("h8", _itop(104));             #Header Size
    $ret .= pack("h8", _itop($hr->{size}+104)); #size of the whole mhdb
    $ret .= pack("H8", "01");                   #?
    $ret .= pack("H8", "01");                   #? - changed to 2 from itunes2 to 3 .. version?
    $ret .= pack("H8", "02");                   #?
    $ret .= pack("H160", "00");                 #dummy space

    return $ret;
}

# a iTunesDB has 2 mhsd's: (This is a child of mk_mhbd)
# mhsd1 holds every song on the ipod
# mhsd2 holds playlists
sub mk_mhsd {
    my ($hr) = @_;

    my $ret = "mhsd";
    $ret .= pack("h8", _itop(96));              #Headersize, static
    $ret .= pack("h8", _itop($hr->{size}+96));  #Size
    $ret .= pack("h8", _itop($hr->{type}));     #type .. 1 = song .. 2 = playlist
    $ret .= pack("H160", "00");                 #dummy space

    return $ret;
}

# Make a complete mhit/mhod from a file hashref
sub render_mhit {
    my ($file, $newid) = @_;
    return if not $file;
    my ($cumul_mhod, $count_mhod);

    # Copy the hashref and give it the new id
    #my %copy = %$file;
    #$copy{id} = $newid;

    # Make mhods
    while (my ($key, $val) = each %$file) {
        next unless $val; # No empty fields
        my $new_mhod = mk_mhod( { stype => $key, string => $val } );
        $cumul_mhod .= $new_mhod;
        $count_mhod++ if defined $new_mhod;
    }

    # Now make the mhit and tack the mhods to it
    my $mhit = mk_mhit({
        size => length($cumul_mhod),
        count => $count_mhod,
        fh => $file
    });

    return $mhit . $cumul_mhod;
}
        
# Create an mhit entry, needs to know about the length of his
# mhod(s) (You have to create them yourself..!)
sub mk_mhit {
    my($hr) = @_;
    my %file_hash = %{$hr->{fh}};

    #We have to fix 'volume'
    my $vol = sprintf("%.0f",( int($file_hash{volume})*2.55 ));

    if($vol >= 0 && $vol <= 255) { }  #Nothing to do
    elsif($vol < 0 && $vol >= -255) { #Convert value
        $vol = oct("0xFFFFFFFF") + $vol; 
    }
    else {
        $@ .= "Song id $file_hash{id} has volume set to $file_hash{volume} percent. Volume set to +-0%\n";
        $vol = 0; #We won't nuke the iPod with an ultra high volume setting..
    }

    foreach( ("rating", "prerating") ) {
        if($file_hash{$_} < 0 || $file_hash{$_} > 5) {
            $@ .= "Song $file_hash{id} has an invalid $_: $file_hash{$_}\n";
            $file_hash{$_} = 0;
        }
    }

    #Check for stupid input
    my ($c_id) = $file_hash{id} =~ /(\d+)/;
    if($c_id < 1) {
        $@ .= "ID can't be $c_id, must be > 0\n";
    }

    my $ret = "mhit";
    $ret .= pack("h8", _itop(156));                        #header size
    $ret .= pack("h8", _itop(int($hr->{size})+156));       #len of this entry
    $ret .= pack("h8", _itop($hr->{count}));               #num of mhods in this mhit
    $ret .= pack("h8", _itop($c_id));                      #Song index number
    $ret .= pack("h8", _itop(1));                          #?
    $ret .= pack("H8");                                    #dummyspace
    $ret .= pack("h8", _itop(256+(oct('0x14000000')
                            *$file_hash{rating})));        #type+rating .. this is very STUPID..
    $ret .= pack("h8", _mactime());                        #timestamp (we create a dummy timestamp, iTunes doesn't seem to make use of this..?!)
    $ret .= pack("h8", _itop($file_hash{filesize}));       #filesize
    $ret .= pack("h8", _itop($file_hash{time}));           #seconds of song
    $ret .= pack("h8", _itop($file_hash{songnum}));        #nr. on CD .. we dunno use it (in this version)
    $ret .= pack("h8", _itop($file_hash{songs}));          #songs on this CD
    $ret .= pack("h8", _itop($file_hash{year}));           #the year
    $ret .= pack("h8", _itop($file_hash{bitrate}));        #bitrate
    $ret .= pack("H4", "00");                              #??
    $ret .= pack("h4", _itop($file_hash{srate} || 44100)); #Srate (note: h4!)
    $ret .= pack("h8", _itop($vol));                       #Volume
    $ret .= pack("h8", _itop($file_hash{starttime}));      #Start time?
    $ret .= pack("h8", _itop($file_hash{stoptime}));       #Stop time?
    $ret .= pack("H8");
    $ret .= pack("h8", _itop($file_hash{playcount}));
    $ret .= pack("H8");                                    #Sometimes eq playcount .. ?!
    $ret .= pack("h8");                                    #Last playtime.. FIXME
    $ret .= pack("h8", _itop($file_hash{cdnum}));          #cd number
    $ret .= pack("h8", _itop($file_hash{cds}));            #number of cds
    $ret .= pack("H8");                                    #hardcoded space 
    $ret .= pack("h8", _mactime());                        #dummy timestamp again...
    $ret .= pack("H16");
    $ret .= pack("H8");                                    #??
    $ret .= pack("h8", _itop($file_hash{prerating}*oct('0x140000')));      #This is also stupid: the iTunesDB has a rating history
    $ret .= pack("H8");                                    # ???
    $ret .= pack("H56");                                   #
    return $ret;
}

# An mhod simply holds information
sub mk_mhod {
    ##   - type id
    #1   - titel
    #2   - ipod filename
    #3   - album
    #4   - interpret
    #5   - genre
    #6   - filetype
    #7   - EQ Setting
    #8   - comment
    #12  - composer
    #100 - Playlist item or/and PlaylistLayout (used for trash? ;))

    my ($hr) = @_;
    my $type_string = $hr->{stype};
    my $string = $hr->{string};
    my $fqid = $hr->{fqid};
    my $type = $mhod_id{lc($type_string)};

    #Appnd size for normal mhod's
    my $mod = 40;

    #Called with fqid, this has to be an PLTHING (100)
    if($fqid) { 
        #fqid set, that's a pl item!
        $type = 100;
        #Playlist mhods are longer
        $mod += 4;
    }
    elsif(!$type) { #No type and no fqid, skip it
        return undef;
    }
    else { #has a type, default fqid
        $fqid = 1;
    }

    if($type == 7 && $string !~ /#!#\d+#!#/) {
        $@ .= "Wrong format: '$type_string=\"$string\"', value should be like '#!#NUMBER#!#'. ignoring value\n";
        $string = undef;
    }

    $string = _ipod_string($string); #cache data
    my $ret = "mhod";                 		           #header
    $ret .= pack("h8", _itop(24));                     #size of header
    $ret .= pack("h8", _itop(length($string)+$mod));   # size of header+body
    $ret .= pack("h8", _itop("$type"));                #type of the entry
    $ret .= pack("H16");                               #dummy space
    $ret .= pack("h8", _itop($fqid));                  #Refers to this id if a PL item
                                                   #else ->  1
    $ret .= pack("h8", _itop(length($string)));        #size of string


    if($type != 100){ #no PL mhod
        $ret .= pack("h16");           #trash
        $ret .= $string;               #the string
    }
    else { #PL mhod
        $ret .= pack("h24"); #playlist mhods are a different
    }
    return $ret;
}

# Create a spl-pref (type=50) mhod
sub mk_splprefmhod {
    my($hs) = @_;
    my($live, $chkrgx, $chklim, $mos) = 0;
    
    #Bool stuff
    $live = 1 if $hs->{liveupdate};
    my $checkrule = int($hs->{checkrule});
    $mos = 1 if $hs->{mos};

    if($checkrule < 1 || $checkrule > 3) {
        $@ .= "'checkrule' ($checkrule) out of range. Value set to 1 (=LimitMatch)\n";
        $checkrule = 1;
    }

    $chkrgx = 1 if $checkrule>1;
    $chklim = $checkrule-$chkrgx*2;
    #lim-only = 1 / match only = 2 / both = 3

    my $ret = "mhod";
    $ret .= pack("h8", _itop(24));    #Size of header
    $ret .= pack("h8", _itop(96));
    $ret .= pack("h8", _itop(50));
    $ret .= pack("H16");
    $ret .= pack("h2", _itop($live)); #LiveUpdate ?
    $ret .= pack("h2", _itop($chkrgx)); #Check regexps?
    $ret .= pack("h2", _itop($chklim)); #Check limits?
    $ret .= pack("h2", _itop($hs->{item})); #Wich item?
    $ret .= pack("h2", _itop($hs->{sort})); #How to sort
    $ret .= pack("h6");
    $ret .= pack("h8", _itop($hs->{value})); #lval
    $ret .= pack("h2", _itop($mos));        #mos
    $ret .= pack("h118");
}

# Create a spl-data (type=51) mhod
sub mk_spldatamhod {
    my($hs) = @_;

    my $anymatch = 1 if $hs->{anymatch};

    if(ref($hs->{data}) ne "ARRAY") {
        $@ .= "No spldata found in spl, iTunes4-workaround enabled";
        push(@{$hs->{data}}, {field=>4,action=>2,string=>""});
    }

    my $cr = undef;
    foreach my $chr (@{$hs->{data}}) {
        my $string = undef;
        #Fixme: this is ugly (same as read_spldata)
        if($chr->{field} =~ /^(2|3|4|8|9|14|18)$/) {
            $string = Unicode::String::utf8($chr->{string})->utf16;
        }
        else {
            my ($from, $to) = $chr->{string} =~ /(\d+):?(\d*)/;
            $to ||=$from;
            $string  = pack("H8");
            $string .= pack("H8", _x86itop($from));
            $string .= pack("H24");
            $string .= pack("H8", _x86itop(1));
            $string .= pack("H8");
            $string .= pack("H8", _x86itop($to));
            $string .= pack("H24");
            $string .= pack("H8", _x86itop(1));
            $string .= pack("H40");
            #  __hd($string);
        }

        if(length($string) > 254) { #length field is limited to 0xfe!
            $@ .= "Splstring too long for iTunes, cropping\n";
            $string = substr($string,0,254);
        }

        $cr .= pack("H6");
        $cr .= pack("h2", _itop($chr->{field}));
        $cr .= pack("H6", reverse("010000"));
        $cr .= pack("h2", _itop($chr->{action}));
        $cr .= pack("H94");
        $cr .= pack("h2", _itop(length($string)));
        $cr .= $string;
    }

    my $ret = "mhod";
    $ret .= pack("h8", _itop(24));    #Size of header
    $ret .= pack("h8", _itop(length($cr)+160));    #header+body size
    $ret .= pack("h8", _itop(51));    #type
    $ret .= pack("H16");
    $ret .= "SLst";                   #Magic
    $ret .= pack("H8", reverse("00010001")); #?
    $ret .= pack("h6");
    $ret .= pack("h2", _itop(int(@{$hs->{data}})));     #HTM (Childs from cr)
    $ret .= pack("h6");
    $ret .= pack("h2", _itop($anymatch));     #anymatch rule on or off
    $ret .= pack("h240");


    $ret .= $cr;
    return $ret;
}

# Render a playlist
sub r_mpl { 
    # Expects a hash w/ the following keys:
    #   name => $ name of the pl
    #   type => $ type of the pl
    #   ids => [] list of songids of in pl
    #   curid => $ current id in db
    #   splprefs => {} holds spl prefs
    #   spldata => {} holds spl data
    my %dat = @_;
    my ($pl, $fc, $mhp) = ('', 0, 0);

    # Spls handled here
    if(ref($dat{splprefs}) eq "HASH") {
        my $spl = $dat{splprefs};
        $pl .= mk_splprefmhod({
              item => $spl->{limititem},
              sort => $spl->{limitsort},
              mos => $spl->{moselected},
              liveupdate => $spl->{liveupdate},
              value => $spl->{limitval},
              checkrule => $spl->{checkrule}
        });

        $pl .= mk_spldatamhod({anymatch => $spl->{matchany}, data => $dat{spldata}});
        $mhp=2;
    }

    foreach(@{$dat{ids}}) {
        $dat{curid}++;
        my $cmhip = mk_mhip({childs => 1, plid => $dat{curid}, sid => $_});
        my $cmhod = mk_mhod({fqid => $_});
        next unless (defined($cmhip) && defined($cmhod)); #mk_mhod needs to be ok
        $fc++;
        $pl .= $cmhip . $cmhod;
    }
    my $plsize = length($pl);

    #mhyp appends a listview to itself
    my $mhyp = mk_mhyp({
        size => $plsize, name => $dat{name}, type => $dat{type}, files => $fc, mhods => $mhp
    });
    return $mhyp . $pl, $dat{curid};
}


# header for all files (like you use mk_mhlp for playlists)
sub mk_mhlt {
    my ($hr) = @_;

    my $ret = "mhlt";
    $ret .= pack("h8", _itop(92)); 		    #Header size (static)
    $ret .= pack("h8", _itop($hr->{songs})); #songs in this itunesdb
    $ret .= pack("H160", "00");                      #dummy space

    return $ret;
}

# header for ALL playlists
sub mk_mhlp {
    my ($hr) = @_;

    my $ret = "mhlp";
    $ret .= pack("h8", _itop(92));                   #Static header size
    $ret .= pack("h8", _itop($hr->{playlists}));          #playlists on iPod (including main!)
    $ret .= pack("h160", "00");                     #dummy space
    return $ret;
}

# Creates an header for a new playlist (child of mk_mhlp)
sub mk_mhyp {
    my($hr) = @_;

    # We need to create a listview-layout and an mhod with the name. iTunes
    # prefs for this PL & PL name (default PL has  device name as PL name)
    my $appnd = mk_mhod({stype=>"title", string=>$hr->{name}}).__dummy_listview();   

    ##Child mhods calc..
    ##We create 2 mhod's here.. mktunes may have created more mhods.. so we
    ##have to adjust the childs here
    my $cmh = 2+$hr->{mhods};

    my $ret .= "mhyp";
    $ret .= pack("h8", _itop(108)); #type
    $ret .= pack("h8", _itop($hr->{size}+108+(length($appnd))));          #size
    $ret .= pack("h8", _itop($cmh));			      #mhods
    $ret .= pack("h8", _itop($hr->{files}));   #songs in pl
    $ret .= pack("h8", _itop($hr->{type}));    # 1 = main .. 0=not main
    $ret .= pack("H8", "00"); 			      #?
    $ret .= pack("H8", "00");                  #?
    $ret .= pack("H8", "00");                  #?
    $ret .= pack("H144", "00");       		  #dummy space

    return $ret.$appnd;
}


# header for new Playlist item (child if mk_mhyp)
sub mk_mhip {
    my ($hr) = @_;
    #sid = SongId
    #plid = playlist order ID

    my $ret = "mhip";
    $ret .= pack("h8", _itop(76));
    $ret .= pack("h8", _itop(76));
    $ret .= pack("h8", _itop($hr->{childs})); #Mhod childs !
    $ret .= pack("H8", "00");
    $ret .= pack("h8", _itop($hr->{plid})); #ORDER id
    $ret .= pack("h8", _itop($hr->{sid}));   #song id in playlist
    $ret .= pack("H96", "00");
    return $ret;
}

#Convert utf8 (what we got from XML::Parser) to utf16 (ipod)
sub _ipod_string {
    my $utf8 = shift;
    my $utf16;
    # We got utf8 from parser, the iPod likes utf16.., swapped..
    if (UNIVERSAL::isa($utf8, 'Unicode::String')) {
        $utf16 = $utf8->utf16;
    }
    else {
        $utf16 = Unicode::String::utf8($utf8)->utf16;
    }
    $utf16 = Unicode::String::byteswap2($utf16);
    return $utf16;
}

#returns a (dummy) timestamp in MAC time format
sub _mactime {
    my $x =    1234567890;
    return sprintf("%08X", $x);
}

#int to ipod
sub _itop {
    my($in) = @_;
    my($int) = $in =~ /(\d+)/;
    return scalar(reverse(sprintf("%08X", $int )));
}

#int to x86 ipodval (spl!!)
sub _x86itop {
    my($in) = @_;
    my($int) = $in =~ /(\d+)/;
    return scalar((sprintf("%08X", $int )));
}

#Create a dummy listview, this function could disappear in
#future, only meant to be used internal by this module, dont
#use it yourself..
sub __dummy_listview {
    my($ret, $foobar);
    $ret = "mhod";                          #header
    $ret .= pack("H8", reverse("18"));      #size of header
    $ret .= pack("H8", reverse("8802"));    #$slen+40 - size of header+body
    $ret .= pack("H8", reverse("64"));      #type of the entry
    $ret .= pack("H48", "00");                #?
    $ret .= pack("H8", reverse("840001"));  #? (Static?)
    $ret .= pack("H8", reverse("01"));      #?
    $ret .= pack("H8", reverse("09"));      #?
    $ret .= pack("H8", reverse("00"));      #?
    $ret .= pack("H8",reverse("010025")); #static? (..or width of col?)
    $ret .= pack("H8",reverse("00"));     #how to sort
    $ret .= pack("H16", "00");
    $ret .= pack("H8", reverse("0200c8"));
    $ret .= pack("H8", reverse("01"));
    $ret .= pack("H16","00");
    $ret .= pack("H8", reverse("0d003c"));
    $ret .= pack("H24","00");
    $ret .= pack("H8", reverse("04007d"));
    $ret .= pack("H24", "00");
    $ret .= pack("H8", reverse("03007d"));
    $ret .= pack("H24", "00");
    $ret .= pack("H8", reverse("080064"));
    $ret .= pack("H24", "00");
    $ret .= pack("H8", reverse("170064"));
    $ret .= pack("H8", reverse("01"));
    $ret .= pack("H16", "00");
    $ret .= pack("H8", reverse("140050"));
    $ret .= pack("H8", reverse("01"));
    $ret .= pack("H16", "00");
    $ret .= pack("H8", reverse("15007d"));
    $ret .= pack("H8", reverse("01"));
    $ret .= pack("H752", "00");
    $ret .= pack("H8", reverse("65"));
    $ret .= pack("H152", "00");

    # Every playlist has such an mhod, it tells iTunes (and other programs?) how the
    # the playlist shall look (visible coloums.. etc..)
    # But we are using always the same layout static.. we don't support this mhod type..
    # But we write it (to make iTunes happy)
    return $ret
}

1;
