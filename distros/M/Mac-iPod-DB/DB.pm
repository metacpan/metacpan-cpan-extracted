# $Id: DB.pm,v 1.1.1.1 2003/07/30 01:55:25 sps Exp $
#  Copyright (C) 2003 Sean P. Scanlon <sps at bluedot.net>
#
#  contains large chunks of code written and copyrighted by: Adrian Ulrich
#  Copyright (C) 2002-2003 Adrian Ulrich <pab at blinkenlights.ch>
#
#
#  large portions of this module have been taken from "tunes2pod.pl"
#  Part of the gnupod-tools collection
#  URL: http://www.gnu.org/software/gnupod/
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# iTunes and iPod are trademarks of Apple
#
# This product is not supported/written/published by Apple!

package Mac::iPod::DB;

require 5.005_03;
use strict;



our $VERSION = '0.01';

# header of a valid iTunesDB
use constant IPODMAGIC => '6d 68 62 64 68 00 00 00';

#the HARDCODED start of the first mhit #FIXME .. shouldn't be hardcooded...
use constant FIRST_MHIT => 292;

my @MHOD_ID = (
	       0,
	       'title',
	       'path',
	       'album',
	       'artist',
	       'genre',
	       'fdesc',
	       'comment',
	       'composer'
	      );


sub playlists {

    my $self = shift();

    return values %{ $self->{_playlists} };

}

sub songIds {

    my $self = shift();

    return sort keys %{ $self->{_songs} };

}

sub songs {

    my $self = shift();

    return values %{ $self->{_songs} };

}

sub song {

    my $self = shift();

    my $id = shift();

    if (defined $self->{_songs}->{$id}) {

	return $self->{_songs}->{$id};

    }

    return undef;

}

sub new {

    my $class = shift();

    my $file = shift();

    return undef if ! $file;

    my $self = {};

    bless $self, ref $class || $class;

    open($self->{_dbfh}, $file) || die $!;

    if($self->_bin2hex(0, (length(IPODMAGIC)+2)/3) ne IPODMAGIC)  {

	printf "found header: %s\n", $self->_bin2hex(0, (length(IPODMAGIC)+2)/3);

	die "** ERROR ** : Could open your iTunesDB, but: Wrong Header found..\n";

    }


    my $pos = FIRST_MHIT;

    # get every <file entry

    while($pos != -1) {

	#get_nod_a returns wher it's guessing the next MHIT, if it fails, it returns '-1'

    	$pos = $self->_get_nod_a($pos);

    }

    ## search PL start
    $pos = $self->_getshoe(112, 4) + 292;

    my ($mpl, $cont, $plname);

    #get every playlist (no items)

    while($pos != -1) {

	#get_nod_a returns where it's guessing the next MHIT, if it fails, it returns '-1'

	($pos, $mpl, $cont, $plname) = $self->_get_pl($pos);

	my $p = Mac::iPod::DB::Playlist::new();

	$p->name($plname);

	$p->_songs($cont);

	$self->{_playlists}->{$plname} = $p if $plname;

    }

    close($self->{_dbfh});

    return $self;

}




sub _get_pl {

    my($self, $offset) = @_;

    my($is_mpl, $oid, $mht, $plname, $px, $ret) = undef;

    if($self->_getstr($offset,4) eq "mhyp") {

	$is_mpl = $self->_getshoe($offset + 20, 4);

	$offset += $self->_getshoe($offset + 4, 4);

	#Get the name of the playlist...
	#You would think that a playlist only has one name.. forget it!
	#Ehpod does funny things here and writes the playlist name two times.. *plenk*
	#MusicMatch does also funny things here (Like writing *no* plname for the MPL)

	while($oid != -1) {

	    $offset+=$oid;

	    ($oid, $mht, $px) = $self->_get_mhod($offset);

	    $plname = $px if $mht == 1;

	}

	#Now get the PL items..
	$oid = undef;

	while($oid != -1) {

	    $offset+=$oid;

	    ($oid, $px) = $self->_get_mhip($offset);

	    push @{ $ret }, $px if $px;

	}

	return ($offset, $is_mpl, $ret, $plname);

    }

    return -1;

}


sub _get_mhip {

    my($self, $sum) = @_;

    if($self->_bin2hex($sum, 4) eq "6d 68 69 70") {

	my $oof = $self->_getshoe($sum+4, 4);

	my($oid, $mht, $txt) = $self->_get_mhod($sum+$oof);

	return -1 if $oid == -1; #fatal error..

	my $px = $self->_getshoe($sum+$oof-52, 4);

	return ($oid+$oof, $px);

    }

    #we are lost
    return -1;
}

#get a mhod entry
#
# get_nod_a(START) - Get mhits..

sub _get_nod_a {

    my(@jerk, $zip, $state, $sa, $sl, $sb, $sid, $cdnum, $cdanz, $songnum, $songanz, $year);

    my($sbr, $oid, $otxt);

    my ($self, $sum) = @_;

    if($self->_bin2hex($sum, 4) eq "6d 68 69 74") { #aren't we lost?

	$sid = $self->_getshoe($sum + 16, 4);
	$sa = $self->_getshoe($sum + 36, 4);
	$sl = $self->_getshoe($sum + 40, 4);
	$cdnum = $self->_getshoe($sum + 92, 4);   #cd nr
	$cdanz = $self->_getshoe($sum + 96, 4);   #cd nr of..
	$songnum = $self->_getshoe($sum + 44, 4); #song number
	$songanz = $self->_getshoe($sum + 48, 4); #song num of..
	$year = $self->_getshoe($sum + 52, 4); #year

	$sbr = $self->_getshoe($sum + 56, 4);

	$sum += 156;                 #1st mhod starts here!

	while($zip != -1) {

	    $sum = $zip + $sum;

	    #returns the number where its guessing the next mhod, -1 if it's failed

	    ($zip, $oid, $otxt) = $self->_get_mhod($sum);

	    $jerk[$oid] = $otxt;

	}

	my $s = Mac::iPod::DB::Song::new();

	$s->id($sid);

	$s->bitrate($sbr);

	$s->time($sl);

	$s->filesize($sa);

	$s->songnum($songnum);

	$s->songs($songanz);

	$s->cdnum($cdnum);

	$s->cds($cdanz);

	$s->year($year);

	for(my $i=1;$i<=int(@jerk)-1;$i++)  {

	    #print "\t$i $MHOD_ID[$i]  = $jerk[$i]\n" if $jerk[$i] && $MHOD_ID[$i];

	    my $att = $MHOD_ID[$i];

	    $s->$att($jerk[$i]) if $jerk[$i] && $MHOD_ID[$i];

	}

	$self->{_songs}->{$sid} = $s;

	return ($sum - $zip - 1);	#black magic

    }

    else {

	return "-1";

    }

}

# get a SINGLE mhod entry:
#
# get_mhod(START_OF_MHOD);
#
# return+seek = new_mhod should be there

sub _get_mhod() {

    my($xl, $ml, $mty, $foo, $id );

    my ($self, $seek, $dbg) = @_;

    $id = $self->_bin2hex($seek, 4);		#are we lost?

    $ml = $self->_getshoe($seek+8, 4);

    $mty = $self->_getshoe($seek+12, 4);	#genre number

    $xl = $self->_getshoe($seek+28,4);		#Entrylength

    if($id ne "6d 68 6f 64") { $ml = -1;}	#is the id INcorrect?? 

    else {

	#get the TYPE of the DB-Entry

	$foo = $self->_getstr($seek + 40, $xl); #string of the entry

	$foo =~ tr/\0//d; #we have many \0.. killem!

	return ($ml, $mty, $foo);

    }

}


sub _getstr {

    #reads $anz chars from FILE and returns a string!

    my($buffer, $xx, $xr );

    my ($self, $start, $anz, $noseek) = @_;

    # paranoia checks

    if(!$start) { $start = 0; }

    if(!$anz) { $anz = "1"; }


    #seek to the given position
    #if 3th ARG isn't defined

    seek($self->{_dbfh}, $start, 0);

    #start reading

    read($self->{_dbfh}, $buffer, $anz);

    return $buffer;

}


sub _getshoe {

    #reads $anz chars from FILE and returns int 

    my($buffer, $xx, $xr, $xxt);

    my ($self, $start, $anz, $noseek) = @_;

    # paranoia checks

    if(!$start) { $start = 0; }

    if(!$anz) { $anz = "1"; }

    #seek to the given position

    seek($self->{_dbfh}, $start, 0);

    #start reading

    read($self->{_dbfh}, $buffer, $anz);

    foreach(split(//, $buffer)) {

	$xx = sprintf("%02X", ord($_));

	#print "XX: $xx XR: $xr\n";

	if ($xr) {

	    $xr = "$xx$xr";

	} else {

	    $xr = $xx;

	}

    }

    $xr = oct("0x".$xr);

    return $xr;

}


sub _bin2hex {

    #reads $anz chars from FILE and returns HEX values!

    my($buffer, $xx, $xr);

    my ($self, $start, $anz, $noseek) = @_;

    # paranoia checks

    if(!$start) { $start = 0; }

    if(!$anz) { $anz = "1"; }

    #seek to the given position

    seek($self->{_dbfh}, $start, 0);

    #start reading

    read($self->{_dbfh}, $buffer, $anz);

    foreach(split(//, $buffer)) {

	$xx = sprintf("%02x ", ord($_));

	$xr = "$xr$xx";

    }

    chop($xr);# no whitespace at end

    return $xr;

}

package Mac::iPod::DB::Song;

use strict;
use Class::Struct;

struct(
       id		=> '$',
       title		=> '$',
       path		=> '$',
       album		=> '$',
       artist		=> '$',
       genre		=> '$',
       fdesc		=> '$',
       comment		=> '$',
       composer		=> '$',
       bitrate		=> '$',
       time		=> '$',
       filesize		=> '$',
       songnum		=> '$',
       songs		=> '$',
       cdnum		=> '$',
       cds		=> '$',
       year		=> '$'
);

package Mac::iPod::DB::Playlist;

use strict;
use Class::Struct;

struct(name => '$', _songs => '$');

sub songs {

    my $self = shift();

    return @{ $self->_songs };

}

1;
__END__

=head1 NAME

Mac::iPod::DB - OO extension for reading iPod database

=head1 SYNOPSIS

 use Mac::iPod::DB;

 my $db = new Mac::iPod::DB('/Volumes/IPOD/iPod_Control/iTunes/iTunesDB');


 foreach my $pl ($db->playlists) {

    printf "playlist: %s\n", $pl->name;

    foreach my $sid ($pl->songs) {

	( my $path = $db->song($sid)->path() ) =~ s/\:/\//g;

	printf "Artist: %s title: %s path: %s\n", 
	$db->song($sid)->artist(), $db->song($sid)->title(), $path;

    }

 }


=head1 Mac::iPod::DB METHODS

    	new(<PATH_TO_DB_FILE>)
		instantiate a new object passing the path location
		of the iPod DB file

	$obj->playlists()
		returns an array of playlist objects

	$obj->songIds()
		returns an array of song ids (integers)

	$obj->songs()
		returns an array of song objects

	$obj->song(<song id>)
		returns a song object


=head1 Mac::iPod::DB::Song METHODS

       $obj->id
       $obj->title
       $obj->path
       $obj->album
       $obj->artist
       $obj->genre
       $obj->fdesc
       $obj->comment
       $obj->composer
       $obj->bitrate
       $obj->time
       $obj->filesize
       $obj->songnum
       $obj->songs
       $obj->cdnum
       $obj->cds
       $obj->year


=head1 Mac::iPod::DB::PlayList METHODS

       $obj->songs
		returns an array of song ids (integers)
		that are associated with the playlist



=head2 EXPORT

None by default.



=head1 AUTHOR

Sean Scanlon, E<lt>sps at bluedot.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Sean Scanlon.
Large portions of this module are
Copyright (C) 2002-2003 Adrian Ulrich <pab at blinkenlights.ch>

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
