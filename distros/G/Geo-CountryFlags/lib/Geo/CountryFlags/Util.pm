#!/usr/bin/perl
package Geo::CountryFlags::Util;

use strict;
use File::SafeDO qw(DO);
use LWP::Simple;
use vars qw($VERSION $LIBpath);
$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
$LIBpath = 'lib/Geo/CountryFlags/';

=head1 NAME

Geo::CountryFlags::Util - Makefile.PL and update utilities

=head1 SYNOPSIS

  require Geo::CountryFlags::Util;
  my $gcu = new Geo::CountryFlags::Util;

  
=head1 DESCRIPTION

Methods and functions to facilitate the update and rebuild the various cross
reference tables in these modules as the CIA and ISO committees update the
country codes and country flags.

=over 4

=item * $rv = remdir($dir);

Recursive decent directory and file removal. USE WITH CAUTION
This function removes all the files and directories BELOW its argument but
does not remove the directory itself. If the function returns DEFINED, the
argument directory may safely be removed with:

  rmdir $dir;

  input:	directory/path
  returns:	number of files & dirs removed
		or undef on error

If an error is returned, the delete may be partially complete.

NOTE: an error is considered to be a non-existent directory
or a file that is not a real file or directory. i.e. a link, pipe, etc...

=cut

sub remdir {
  my $dir = shift;
  return undef unless -e $dir && -w $dir;
  unless (-d $dir) {
    return (-f $dir) ? 0 : undef;
  }
  my $fc = 0;		# filecount
  opendir(D,$dir);
  my @dir = grep($_ ne '.' && $_ ne '..',readdir(D));
  closedir D;
  foreach(@dir) {
    if (-d $dir .'/'. $_) {
      my $rv = remdir($dir .'/'. $_);
      return undef unless defined $rv;
      $fc += $rv;
    }
  }
  $fc += unlink @dir if @dir;	# unlink all files and dirs
}

=item * $newversion = mkversion($oldversion);

Return an updated version number. Called from within this module

  input:	[optional] old version number
  returns:	new or updated version number

=cut

sub mkversion {
  my $curversion = $_[0] || '0.0';
  $curversion = '0.0' if $curversion =~ /[^0-9\.]/;
  my $top = 0;
  my $bot = 0;
  if ($curversion =~ /^(\d+)\.(\d+)$/) {
    $top = $1;
    $bot = $2;
  } elsif ($curversion =~ /\.(\d+)$/) {
    $bot = $1;
  } else {
    $top = $curversion;
  }
  my($year,$yday) = (gmtime())[5,7];
  $year += 1900 if $year < 999;
  my $up = sprintf("%04d%03d",$year,$yday);
  if ($up <= $top) {
    if (++$bot > 999) {
      $bot = 1;
      ++$top;
    }
  }
  else {
    $bot = 1;
    $top = $up;
  }
  return $top .'.'. sprintf("%03d",$bot);
}

=item * $gcu = new Geo::CountryFlags::Util;

Return a method pointer to the Geo::CountryFlags::Util package.

  input:	none
  returns:	method pointer

=cut

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $self = {};
  bless $self, $class;
}

=item * $rv = $gcu->is_obsolete($firstfile,$secondfile);

Compare files and return true if the second file is missing or the 
modification time of the second file is
older than the modification time of the first file.

  input:	path/to/firstfile,
		path/to/secondfile
  return:	true/false
		returns false if
		first file is missing

=cut

sub is_obsolete {
  my($self,$ff,$sf) = @_;
  return 0 unless $ff && -e $ff;
  return 1 unless $sf && -e $sf;
  return (stat($ff))[9] > (stat($sf))[9] ? 1 : 0;
}

=item * $rv = $gcu->is_current($file,$timestamp);

Check that C<file> exists and that its modification time
is not less than C<timestamp>.

  input:	path/to/file,
		timestamp	seconds since epoch
  returns:	false, file missing
		true, file && timestamp missing
		true if current
		else false
=cut

sub is_current {
  my($f,$t) = @_;
  return undef unless -e $f;
  return 1 unless $t;
  return (stat($f))[9] > $t ? 1 : 0;
}

=item * $path = mkmodule($hp,$mtitle);

=item * blessed $hp->mkmodule($mtitle);

Remake a module for this distribution. A module of name:

  Geo::CountryFlags::${mtitle}.pm

is made or updated in the lib/Geo/CountryFlags directory.

  input:	hash pointer to contents
		module title (short version),
  creates:	new module in lib/Geo/CountryFlags
  returns:	path to module

=cut

sub mkmodule {
  my($hp,$mt) = @_;
  die "invalid module title\n" unless $mt;
  die "invalid hash pointer\n" unless
	ref $hp && keys %$hp;
  my $modpath = $LIBpath;		# check that path exists and is writable
  die "module path '$modpath' is missing or not writable,\nrun only from module build directory\n"
	unless -d $modpath && -w $modpath;
  $modpath .= $mt .'.pm';
  my $version = '0.0';
  (my $package = __PACKAGE__) =~ s/Util/$mt/;
  if (-e $modpath && eval { require $modpath } && !$@) {		# get the old version if module exists
    local *v = $package .'::VERSION';
    $version = ${*v} || '0.0';
  }
  $version = mkversion($version);		# update the version number
  local *Module;
  open (Module,'>',$modpath .'.tmp') or die "could not open 'module' for write\n";
  my $now = scalar gmtime();

  $mt =~ /^./;
  my $gcv = 'gc'. (lc $&);

  print Module q|#!/usr/bin/perl
package |. $package .q|;

################################################################
# WARNING! this module is automatically generated DO NOT EDIT! #
#            see Geo::CountryFlags::Util instead               #
#                                                              #
# creation date:  |. $now .q| GMT	               #
################################################################

use strict;
use vars qw($VERSION);
$VERSION = '|. $version .q|';

my $|. $mt .q| = {
|;

foreach (sort keys %$hp) {	# watch it below using q#....#;
  print Module q|    '|. ($_) .q#' => q|#. $hp->{$_} .q#|,
#;
}

  print Module q|};

sub AUTOLOAD {
  no strict;
  $AUTOLOAD =~ /[^:]+$/;
  value($&);
}

sub new {
  my $proto = shift;
  my $class = ref $proto |.'|| $proto ||'.q| __PACKAGE__;
  my $self = {};
  bless $self, $class;
}

sub hashptr {
  my($proto,$class) = @_;
  $proto = $class if $class;
  $class = ref $proto |.'||'.q| $proto;
  my $rv = {};
  %$rv = %$|. $mt .q|;
  bless $rv, $class;
}

sub value {
  return (exists $|. $mt .q|->{$_[0]}) ? $|. $mt .q|->{$_[0]} : undef;
}

sub subref {
  return \&value;
}

1;
__END__

=pod

|. $package .q| is autogenerated by Makefile.PL

Last updated |. (scalar gmtime()) .q| GMT

=head1 NAME

|. $package .'::'. $mt .q| - hash to map values

=head1 SYNOPSIS

|. $package .q| provides a variety of methods and functions to lookup values
either as hash-like constants (recommended) or directly from a hash array.

    require $|. $package .q|;
    my $|. $gcv .q| = new |. $package .q|;
    $value = $|. $gcv .q|->KEY;

  Perl 5.6 or greater can use syntax
    $value = $|. $gcv .q|->$key;

  or
    $subref = subref |. $package .q|;
    $value = $subref->($key);
    $value = &$subref($key);

  or
    $value = value |. $package .q|($key);
    |. $package .q|->value($key);

  to return a reference to the map directly

  $hashref = hashptr |. $package .q|($class);
  $value = $hashref->{$key};

=head1 DESCRIPTION

|. $package .q| maps |. $mt .q| values.

Values may be returned directly by designating the KEY as a method or
subroutine of the form:

    $value = |. $package .q|::KEY;
    $value = |. $package .q|->KEY;
  or in Perl 5.6 and above
    $value = |. $package .q|->$key;
  or
    $|. $gcv .q| = new |. $package .q|;
    $value = $|. $gcv .q|->KEY;
  or in Perl 5.6 and above
    $value= =  $|. $gcv .q|->$key;

=over 4

=item * $|. $gcv .q| = new |. $package .q|;

Return a reference to the modules in this package.

=item * $hashptr = hashptr |. $package .q|($class);

Return a blessed reference to a copy of the hash in this package.

  input:	[optional] class or class ref
  returns:	a reference blessed into $class
		if $class is present otherwise
		blessed into |. $package .q|

=item * $value = value |. $package .q|($key);

=item * $value = $|. $gcv .q|->value($key);

Return the value in the map hash or undef if it does not exist.

=item * $subref = subref |. $package .q|;

=item * $subref = $|. $gcv .q|->subref;

Return a subroutine reference that will return the value of a key or undef
if the key is not present.

  $value = $subref->($key);
  $value = &$subref($key);

=back

=head1 EXPORTs

Nothing

=head1 AUTHOR 

Michael Robinton michael@bizsystems.com

=head1 COPYRIGHT and LICENSE

  Copyright 2006 Michael Robinton, michael@bizsystems.com

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free Software 
Foundation; either version 1, or (at your option) any later version,

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of  
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 SEE ALSO

L<|. __PACKAGE__ .q|>

=cut

1;
|;
  close Module;
  rename $modpath .'.tmp', $modpath;	# atomic move
  return $modpath;
}

=item * $timestamp = $gcu->url_date($name);

Return the last modified time for the web page designated by $name.

  input:	CIA or ISO
  returns:	seconds since the epoch
		or false on error

=cut

sub url_date {
  my($gcc,$n) = @_;
  my $url = &url_fetch or return undef;
  return (head($url))[2] or undef;
}

=item * $hashptr = $gcu->xcp_fetch($path_to_file);

Fetch the Map_Exceptions file and extract the contents, returning a hash
pointer of the form:

     ISO compressed name    CIA short name
 i.e.   'korea republic' => 'korea south',

The ISO compressed name is 'exactly' as produced by Makefile.PL when
rebuilding the ISO/CIA flag cross reference. The CIA short names are at
least enough of the compressed name produced by Makefile.PL to uniquely
identify the entry.

  input:	[optional] path to file
  returns:	blessed reference
	    or	undef on failure

=cut

sub xcp_fetch {
  my($proto,$fp) = @_;
  $fp = './Map_Exceptions' unless
	$fp && -e $fp && -r $fp;
  my $class = ref $proto || $proto;
  my $hp = DO $fp or return undef;
  bless $hp, $class;
}

=item * $hashptr = $gcu->url_fetch($path_to_file);

Fetch the Valid_Urls file and extract the contents, returning a hash pointer
of the form:

  keys               vals
  CIA		CIA factbook flags page URL
  CIAFLAGS	CIA flags file directory URL
  ISO		ISO country code file URL

  input:	[optional] path to file
  returns:	blessed reference
	    or	undef on failure

=cut

sub url_fetch {
  my($proto,$fp) = @_;
  $fp = './Valid_Urls' unless
	$fp && -e $fp && -r $fp;
  my $class = ref $proto || $proto;
  my $hp = DO $fp or return undef;
  return undef unless
	$hp->{CIA} &&
	$hp->{CIAFLAGS} &&
	$hp->{ISO};
  return bless $hp, $class;
}

=item * $hashptr = $gcu->cia_fetch($url);

Fetch the page text from the CIA web site, parse it and return a hash pointer of the form:

    keys          vals
  country_code  country_name

  input:	[optional] cia page url
  returns:	blessed reference
	    or	undef on failure

=cut

# load the URLs package if necessary and return the page shown by the URL
#
# input:	key, url [optional]
#
# returns:	page
#
sub _fetch {
  (my $pkg = __PACKAGE__) =~ s/Util/URLs/;
  $_ = $pkg .'::{VERSION}';
  my $key = shift;
  return undef unless $key eq 'CIA' || $key eq 'CIAFLAGS' || $key eq 'ISO';
  my $url = shift || eval "(exists \$$_ || require $pkg) && $key $pkg";
  return undef unless $url;
  get($url);
}

sub cia_fetch {
  my($proto,$url) = @_;
  my $rv = _fetch('CIA',$url);
  return undef unless $rv;
  my @list = split(/\n/,$rv);
  my $list = {};
  foreach (@list) {
    next unless $_ =~ m|\<option.+geos/([a-zA-Z]{2})\.html">([^<]+)|i;
    $list->{$1} = $2;
  }
  return exists $list->{us}
	? bless $list, (ref $proto || $proto)
	: undef;
}

=item * $hashptr = $gcu->iso_fetch($url);

Fetch the page text from the ISO web site, parse it and return a hash
pointer of the form:

    keys          vals
  country_code  country_name

  input:	[optional] iso page url
  returns:	blessed reference
	    or	undef on failure

=cut

sub iso_fetch {
  my($proto,$url) = @_;
  my $rv = _fetch('ISO',$url);
  return undef unless $rv;
  my @list = split(/\n/,$rv);
  my $list = {};
  while ($rv = shift @list) {		# throw away random stuff a top of page
    last if $rv =~ /^\s*A\w+;/;
  }
  do {
    next unless $rv =~ /\s*(.+)\s*;\s*([a-zA-Z]{2})/;
    my $key = uc $2;
    my $val = $1;
    $val =~ s/\b([a-zA-Z]+)/$_ = lc $1;ucfirst $_/eg;
    $val =~ s/\b(And|The)\b/lc $1/eg;
    $list->{$key} = $val;
  } while ($rv = shift @list);
  return exists $list->{US}
	? bless $list, (ref $proto || $proto)
	: undef;
}

=back

=head1 ISO to CIA flag mapping functions

These methods/functions are used to create the ISO => CIA flag map and are mostly
used within this module.

=over 4

=item * mapexceptions($rgci,$excp);

=item * $rgci->mapexceptions($excp);

Map the known exceptions into the reverse ISO hash

  input:	ref to reverse ISO hash,
		ref to exceptions hash
  returns:	nothing

Replaces the original keys with the exception keys

=cut

sub mapexceptions {
  my($rgci,$excp) = @_;
  foreach (keys %$rgci) {
    if (exists $excp->{$_}) {
      my $key = $excp->{$_};
      $rgci->{$key} = delete $rgci->{$_};
    }
  }
}

=item * $revhp = revcomp($hashptr);

=item * $revhp = $hashptr->revcomp;

Return a new blessed reference to hash with the keys and values reversed and
compressed where the values are all lowercased and all non-alphanumeric characters and
extra spaces are removed. The fill words C<of the and de da> are deleted
from the key string.

  i.e. 		vals => keys

  input:	ref to blessed hash
  returns:	blessed reference to 
		compressed/reversed hash

=cut

sub revcomp {
  my $p = shift;
  my $r = {};
  while (my($val,$key) = each %$p) {
    $key = lc $key;
    $key =~ tr/a-z0-9 //cd;
    $key =~ s/\b(?:of|the|and|de|da)\b//g;
    $key =~ s/\s+/ /g;
    $key =~ s/^\s*(.+?)\s*$/$1/;
    $r->{$key} = $val;
  }
  bless $r, (ref $p || __PACKAGE__);
}

=item * $crossref = matcheq($rgci,$rgcc,$crossref);

=item * $crossref = $rgci->matcheq($rgcc,$crossref);

Return or update a cross reference hash of the form:

  val rgci  =>  val rgcc

where the keys in rgci and rgcc match exactly

  input:	ISO reverse hash,
		CIA reverse hash,
		[optional] cross ref hash
  returns:	blessed reference to
		cross reference hash

=cut

sub matcheq {
  my($rgci,$rgcc,$cr) = @_;
  $cr = {} unless $cr;
  foreach(keys %$rgci) {
    if (exists $rgcc->{$_}) {
      my $key = delete $rgci->{$_};
      $cr->{$key} = delete $rgcc->{$_}; # val
    }
  }
  bless $cr, (ref $rgci || __PACKAGE__);
}

=item * $rv = pars_can($rgci,$rgcc,$crossref,\@candidates,$ikey,$regexp);

=item * $rv = $rgci->pars_can($rgcc,$crossref,\@candidates,$ikey,$regexp);

Parse the key values in @candidates for matches in $rgcc keys to the regular expression
supplied in $regexp. If only one match is found, update the $cross->{hash}
and delete the entry in $rgci pointed to by $ikey and the match entry in
$rgcc, then return B<true>. If no match is found or more than one match is
found, return false.

  input:	ptr to reverse gci hash
		ptr to reverse gcc hash
		ptr to  cross reference hash
		ptr to candidates array
		reverse gci key
		regular expression

  returns:	true if unique match found
		else returns false

=cut

sub pars_can {
  my($rgci,$rgcc,$cr,$ca,$ikey,$regexp) = @_;
  @_ = @$ca;
  @$ca = ();
  foreach (@_) {
    if ($_ =~ /^$regexp/) {
     push @$ca, $_;
    }
  }
  if (@$ca == 1) {
    my $key = delete $rgci->{$ikey};
    $cr->{$key} = delete $rgcc->{$ca->[0]}; # val
    return 1;
  }
  return 0;
};

=item * parsBYword($rgci,$rgcc,$crossref);

=item * $rgci->parsBYword($rgcc,$crossref);

Look for near matches of $rgci keys to $rgcc keys by doing a string match a
word at a time using the key values in $rgci checked against all keys in
$rgcc.

  i.e.	@words = split(/\s/,$rgcikey)

  first	$rgcckey =~ /word[0]/;
  then	$rgcckey =~ /word[0] word[1]/
  and so on...

  input:	ptr to reverse gci hash
		ptr to reverse gcc hash
		ptr to cross reference
  returns:	nothing

=cut

sub parsBYword {
  my($rgci,$rgcc,$cr) = @_;
 KEY:
  foreach my $ikey (keys %$rgci) {
    my @candidates = keys %$rgcc;
    my @iwords = split(/\s+/,$ikey);
    foreach my $i (0..$#iwords) {
      my $regex = '';
      foreach(0..$i) {
	$regex .= '\s+' unless $i == 0;
	$regex .= $iwords[$i];
      }
      next KEY unless pars_can($rgci,$rgcc,$cr,\@candidates,$ikey,$regex);
    }
  }
}

=pod

=back

=cut

1;
