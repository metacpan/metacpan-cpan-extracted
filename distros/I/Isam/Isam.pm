use Class::Struct;

struct( Keydesc => [ 
		k_flags 	=> '$', 
		k_nparts 	=> '$', 
		k_part 		=> '@' 
	]);

struct( Dictinfo => [
		di_nkeys	=> '$',
		di_recsize	=> '$',
		di_idxsize	=> '$',
		di_nrecords	=> '$'
	]);

package Isam;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	AUDGETNAME
	AUDHEADSIZE
	AUDINFO
	AUDSETNAME
	AUDSTART
	AUDSTOP
	CHARTYPE
	DECIMALTYPE
	DOUBLETYPE
	FLOATTYPE
	INTTYPE
	LONGTYPE
	MINTTYPE
	MLONGTYPE
	STRINGTYPE
	ISAUTOLOCK
	ISCLOSED
	ISCURR
	ISD1
	ISD2
	ISDD
	ISDESC
	ISDUPS
	ISEQUAL
	ISEXCLLOCK
	ISFIRST
	ISFIXLEN
	ISGREAT
	ISGTEQ
	ISINOUT
	ISINPUT
	ISLAST
	ISLCKW
	ISLOCK
	ISMANULOCK
	ISMASKED
	ISNEXT
	ISNOCARE
	ISNODUPS
	ISNOLOG
	ISOUTPUT
	ISPREV
	ISRDONLY
	ISSYNCWR
	ISTRANS
	ISVARCMP
	ISVARLEN
	ISWAIT
);

$VERSION = '0.2';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Isam macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap Isam $VERSION;

# Preloaded methods go here.

#---------------------------------------
# Isam->iserrno or Isam->iserrno(value)
#---------------------------------------

sub iserrno
{
   @_ == 1 or @_ == 2 or croak 'usage: Isam->iserrno or Isam->iserrno(INTVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      iserrno_put($value);
      }
   else {
      return iserrno_get();
   }
}

#---------------------------------------
# Isam->isrecnum or Isam->isrecnum(value)
#---------------------------------------

sub isrecnum
{
   @_ == 1 or @_ == 2 or croak 'usage: Isam->isrecnum or Isam->isrecnum(LONGVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      isrecnum_put($value);
      }
   else {
      return isrecnum_get();
   }
}

#---------------------------------------
# Isam->isreclen or Isam->isreclen(value)
#---------------------------------------

sub isreclen
{
   @_ == 1 or @_ == 2 or croak 'usage: Isam->isreclen or Isam->isreclen(INTVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      isreclen_put($value);
      }
   else {
      return isreclen_get();
   }
}

#---------------------------------------
# Isam->iserrio or Isam->iserrio(value)
#---------------------------------------

sub iserrio
{
   @_ == 1 or @_ == 2 or croak 'usage: Isam->iserrio or Isam->iserrio(INTVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      iserrio_put($value);
      }
   else {
      return iserrio_get();
   }
}

#---------------------------------------
# $fd->fd
#---------------------------------------

sub fd
{
   @_ == 1 or croak 'usage: $fd->fd';
   my $this = shift;
   return $this->{fd};
}

#---------------------------------------
# $fd->name
#---------------------------------------

sub name
{
   @_ == 1 or croak 'usage: $fd->name';
   my $this = shift;
   return $this->{name};
}

#---------------------------------------
# $fd->isaddindex(kd)
#---------------------------------------

sub isaddindex
{
   @_ == 2 or croak 'usage: $fd->isaddindex(KEYDESC)';
   my $this = shift;
   my $kd = shift;
   my @param=();
   push(@param, $this->fd);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   return (isaddindex1( @param ) >= 0);
}

#---------------------------------------
# $fd->isaudit(name,mode)
#---------------------------------------

sub isaudit
{
   @_ == 3 or croak 'usage: $fd->isaudit(NAME, MODE)';
   my $this = shift;
   my $name = shift;
   my $mode = shift;
   return ( isaudit1($this->fd,$name,$mode) >= 0);
}

#---------------------------------------
# Isam->isbegin
#---------------------------------------

sub isbegin
{
   @_ == 1 or croak 'usage: Isam->isbegin';
   return (isbegin1() >= 0); 
}

#---------------------------------------
# Isam->isbuild (name,len,kd,mode)
#---------------------------------------

sub isbuild
{
   @_ == 5 or croak 'usage: Isam->isbuild(NAME, RECLEN, KEYDESC, MODE)';
   my $class = shift;
   my ($name,$len,$kd,$mode) = @_;
   my @param=();
   push(@param, $name);
   push(@param, $len);
   push(@param, $mode);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   my $this = {};
   bless($this, $class);
   my $fd = isbuild1( @param );
   if ($fd < 0) {
      return undef;
      }
   else {
      $this->{fd} = $fd;  
      $this->{name} = $name;  
      return $this;
   }
}

#---------------------------------------
# Isam->iscleanup
#---------------------------------------

sub iscleanup
{
   @_ == 1 or croak 'usage: Isam->iscleanup';
   return (iscleanup1() >= 0); 
}

#---------------------------------------
# $fd->isclose()
#---------------------------------------

sub isclose
{
   @_ == 1 or croak 'usage: $fd->isclose';
   my $this = shift;
   return ( isclose1($this->fd) >= 0);
}

#---------------------------------------
# $fd->iscluster(kd)
#---------------------------------------

sub iscluster
{
   @_ == 2 or croak 'usage: $fd->iscluster(KEYDESC)';
   my $this = shift;
   my $kd = shift;
  
   my @param=();
   push(@param, $this->fd);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   my $class = ref($this);
   my $new = {};
   bless($new, $class);
   my $fd = iscluster1( @param );
   if ($fd < 0) {
      return undef;
      }
   else {
      $new->{fd} = $fd;
      $new->{name} = $this->name;
      return $new;
   }
}

#---------------------------------------
# Isam->iscommit
#---------------------------------------

sub iscommit
{
   @_ == 1 or croak 'usage: Isam->iscommit';
   return (iscommit1() >= 0); 
}

#---------------------------------------
# $fd->isdelcurr()
#---------------------------------------

sub isdelcurr
{
   @_ == 1 or croak 'usage: $fd->isdelcurr';
   my $this = shift;
   return ( isdelcurr1($this->fd) >= 0);
}

#---------------------------------------
# $fd->isdelete(data)
#---------------------------------------

sub isdelete
{
   @_ == 2 or croak 'usage: $fd->isdelete(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( isdelete1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# $fd->isdelindex(kd)
#---------------------------------------

sub isdelindex
{
   @_ == 2 or croak 'usage: $fd->isdelindex(KEYDESC)';
   my $this = shift;
   my $kd = shift;
  
   my @param=();
   push(@param, $this->fd);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   return ( isdelindex1( @param ) >= 0);
}

#---------------------------------------
# $fd->isdelrec(recnum)
#---------------------------------------

sub isdelrec
{
   @_ == 2 or croak 'usage: $fd->isdelrec(RECNUM)';
   my $this = shift;
   my $recnum = shift;
   return ( isdelrec1($this->fd,$recnum) >= 0);
}

#---------------------------------------
# Isam->iserase(name)
#---------------------------------------

sub iserase
{
   @_ == 2 or croak 'usage: Isam->iserase(NAME)';
   my $class = shift;
   my $name = shift;
   return (iserase1($name) >= 0);
}

#---------------------------------------
# $fd->isflush()
#---------------------------------------

sub isflush
{
   @_ == 1 or croak 'usage: $fd->isflush';
   my $this = shift;
   return ( isflush1($this->fd) >= 0);
}

#---------------------------------------
# $fd->isindexinfo(idx)
#---------------------------------------

sub isindexinfo
{
   @_ == 2 or croak 'usage: $fd->isindexinfo(INDEX)';
   my ($this,$idx) = @_;
   my ($cc, $kd);

   if ($idx == 0) {
      $kd = new Dictinfo;
      my @ret = isisaminfo1($this->fd);
      $cc = shift @ret;
      $kd->di_nkeys(shift @ret);
      $kd->di_recsize(shift @ret);
      $kd->di_idxsize(shift @ret);
      $kd->di_nrecords(shift @ret);
      }
   else {
      $kd = new Keydesc;
      my @ret = isindexinfo1($this->fd,$idx);
      $cc = shift @ret;
      $kd->k_flags( shift @ret );
      $kd->k_nparts( shift @ret );
      for my $ind (0..$kd->k_nparts) {
         $kd->k_part($ind, [shift @ret, shift @ret, shift @ret]);
      }

   }
   if ($cc < 0) {
      return undef;
      }
   else {
      return $kd;
   }
}

#---------------------------------------
# $fd->islock()
#---------------------------------------

sub islock
{
   @_ == 1 or croak 'usage: $fd->islock';
   my $this = shift;
   return ( islock1($this->fd) >= 0);
}

#---------------------------------------
# Isam->islogclose
#---------------------------------------

sub islogclose
{
   @_ == 1 or croak 'usage: Isam->islogclose';
   return (islogclose1() >= 0); 
}

#---------------------------------------
# Isam->islogopen(name)
#---------------------------------------

sub islogopen
{
   @_ == 2 or croak 'usage: Isam->islogopen(NAME)';
   my $class = shift;
   my $name = shift;
   return (islogopen1($name) >= 0);
}

#---------------------------------------
# Isam->isopen(name,mode)
#---------------------------------------

sub isopen
{
   @_ == 3 or croak 'usage: Isam->isopen(NAME, MODE)';
   my $class = shift;
   my $this = {};
   my $name = shift;
   my $mode = shift;
   bless($this, $class);
   my $fd = isopen1($name, $mode);
   if ($fd < 0) {
      return undef;
      }
   else {
      $this->{fd} = $fd;
      $this->{name} = $name;
      return $this;
   }
}

#---------------------------------------
# $fd->isread(data,mode)
#---------------------------------------

sub isread
{
   @_ == 3 or croak 'usage: $fd->isread(ISAMDATA, MODE)';
   my $this = shift;
   my $rdata = shift;
   my $mode = shift;
   return ( isread1($this->fd,$$rdata,$mode) >= 0);
}

#---------------------------------------
# Isam->isrecover
#---------------------------------------

sub isrecover
{
   @_ == 1 or croak 'usage: Isam->isrecover';
   return (isrecover1() >= 0); 
}

#---------------------------------------
# $fd->isrelease()
#---------------------------------------

sub isrelease
{
   @_ == 1 or croak 'usage: $fd->isrelease';
   my $this = shift;
   return ( isrelease1($this->fd) >= 0);
}

#---------------------------------------
# Isam->isrename(oldname,newname)
#---------------------------------------

sub isrename
{
   @_ == 3 or croak 'usage: Isam->isrename(OLDNAME, NEWNAME)';
   my $class = shift;
   my $oldname = shift;
   my $newname = shift;
   return (isrename1($oldname,$newname) >= 0);
}

#---------------------------------------
# $fd->isrewcurr(data)
#---------------------------------------

sub isrewcurr
{
   @_ == 2 or croak 'usage: $fd->isrewcurr(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( isrewcurr1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# $fd->isrewrec(recnum,data)
#---------------------------------------

sub isrewrec
{
   @_ == 3 or croak 'usage: $fd->isrewrec(RECNUM, ISAMDATA)';
   my $this = shift;
   my $recnum = shift;
   my $rdata = shift;
   return ( isrewrec1($this->fd,$recnum,$$rdata) >= 0);
}

#---------------------------------------
# $fd->isrewrite(data)
#---------------------------------------

sub isrewrite
{
   @_ == 2 or croak 'usage: $fd->isrewrite(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( isrewrite1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# Isam->isrollback
#---------------------------------------

sub isrollback
{
   @_ == 1 or croak 'usage: Isam->isrollback';
   return (isrollback1() >= 0); 
}

#---------------------------------------
# $fd->issetunique(uniqueid)
#---------------------------------------

sub issetunique
{
   @_ == 2 or croak 'usage: $fd->issetunique(UNIQUEID)';
   my $this = shift;
   my $uniqueid = shift;
   return ( issetunique1($this->fd,$uniqueid) >= 0);
}

#---------------------------------------
# $fd->isstart(kd,len,data,mode)
#---------------------------------------

sub isstart
{
   @_ == 5 or croak 'usage: $fd->isstart(KEYDESC, LENGTH, ISAMDATA, MODE)';
   my $this = shift;
   my $kd = shift;
   my $length = shift;
   my $rdata = shift;
   my $mode = shift;
  
   my @param=();
   push(@param, $this->fd);
   push(@param, $length);
   push(@param, $$rdata);
   push(@param, $mode);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   return ( isstart1( @param ) >= 0);
}

#---------------------------------------
# $fd->isuniqueid()
#---------------------------------------

sub isuniqueid
{
   @_ == 1 or croak 'usage: $fd->isuniqueid';
   my $this = shift;
   my $uniqueid;
   my $cc = isuniqueid1($this->fd,$uniqueid);
   if ($cc >= 0) {
      return $uniqueid;
      }
   else {
      return undef;
   }
}

#---------------------------------------
# $fd->isunlock()
#---------------------------------------

sub isunlock
{
   @_ == 1 or croak 'usage: $fd->isunlock';
   my $this = shift;
   return ( isunlock1($this->fd) >= 0);
}

#---------------------------------------
# $fd->iswrcurr(data)
#---------------------------------------

sub iswrcurr
{
   @_ == 2 or croak 'usage: $fd->iswrcurr(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( iswrcurr1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# $fd->iswrite(data)
#---------------------------------------

sub iswrite
{
   @_ == 2 or croak 'usage: $fd->iswrite(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( iswrite1($this->fd,$$rdata) >= 0);
}



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Isam - Perl extension for ISAM files

=head1 SYNOPSIS

use Isam;

=head1 DESCRIPTION

Isam.pm is a thin wrapper to the C-ISAM functions calls.
IsamData.pm is a facility to access the record's fields.

=head1 Exported constants

  AUDGETNAME
  AUDHEADSIZE
  AUDINFO
  AUDSETNAME
  AUDSTART
  AUDSTOP 
  CHARTYPE
  DECIMALTYPE
  DOUBLETYPE
  FLOATTYPE
  INTTYPE
  LONGTYPE
  MINTTYPE
  MLONGTYPE
  STRINGTYPE
  ISAUTOLOCK
  ISCLOSED
  ISCURR
  ISD1
  ISD2
  ISDD
  ISDESC
  ISDUPS
  ISEQUAL
  ISEXCLLOCK
  ISFIRST
  ISFIXLEN
  ISGREAT
  ISGTEQ
  ISINOUT
  ISINPUT
  ISLAST
  ISLCKW
  ISLOCK
  ISMANULOCK
  ISMASKED
  ISNEXT
  ISNOCARE
  ISNODUPS
  ISNOLOG
  ISOUTPUT
  ISPREV
  ISRDONLY
  ISSYNCWR
  ISTRANS
  ISVARCMP
  ISVARLEN
  ISWAIT

=head1 AUTHOR

Philippe Chane-You-Kaye, philippe.cyk@wanadoo.fr

=head1 METHODS

=over 4

Isam.pm module include class methods indicated by Isam->method
and object methods indicated by $fd->method where $fd is a 
reference to an instance obtained by isopen, isbuild or iscluster
eg. my $fd = Isam->isopen("myfile",&ISINOUT);

=item Isam->iserrno([INTVALUE])

Returns the value of the global Isam variable iserrno unless C<INTVALUE>
is specified, in which case, sets the value of iserrno.

=item Isam->isrecnum([LONGVALUE])

Returns the value of the global Isam variable isrecnum unless C<LONGVALUE>
is specified, in which case, sets the value of isrecnum.

=item Isam->isreclen([INTVALUE])

Returns the value of the global Isam variable isreclen unless C<INTVALUE>
is specified, in which case, sets the value of isreclen.

=item Isam->iserrio([INTVALUE])

Returns the value of the global Isam variable iserrio unless C<INTVALUE>
is specified, in which case, sets the value of iserrio.

=item $fd->fd

Returns Isam file descriptor

=item $fd->name
 
Returns the filename 

=item $fd->isaddindex(KEYDESC)

Returns TRUE if successfully adds an index to $fd

=item Isam->isbuild(NAME, LEN, KEYDESC, MODE)

Returns a reference to an Isam object or undef if unsuccessful

=item Isam->iscleanup

Returns TRUE if successful

=item $fd->isclose

Returns TRUE if successful

=item $fd->iscluster(KEYDESC)

KEYDESC is a reference to a Keydesc object.
Returns a reference to an Isam object or undef if unsuccessful 

=item Isam->iscommit

Returns TRUE if successful

=item $fd->isdelcurr

Returns TRUE if successful

=item $fd->isdelete(DATA)

DATA is a reference to a scalar. Returns TRUE if successful

=item $fd->isdelindex(KEYDESC)

KEYDESC is a reference to a Keydesc object.
Returns TRUE if successful

=item $fd->isdelrec(RECNUM)

RECNUM is a long integer
Returns TRUE if successful

=item Isam->iserase(NAME)

NAME is a filename. Returns TRUE if successful

=item $fd->isflush

Returns TRUE if successful 

=item $fd->isindexinfo(IDX)

IDX is an integer. returns undef if unsuccessful.
If IDX == 0, returns a reference to a Dictinfo object.
If IDX > 0, returns a reference to a Keydesc object

=item $fd->islock

Returns TRUE if successful

=item Isam->islogclose

Returns TRUE if successful

=item Isam->islogopen

Returns TRUE if successful

=item Isam->isopen(NAME, MODE)

NAME is a filename, MODE is an integer
Returns undef if unsuccessful, otherwise returns a reference
to an Isam object

=item $fd->isread(DATA, MODE)

DATA is a reference to a scalar. MODE is an integer.
Returns TRUE if successful

=item Isam->isrecover

Returns TRUE if successful

=item $fd->isrelease

Returns TRUE if successful

=item Isam->isrename(OLDNAME, NEWNAME) 

Returns TRUE if successful

=item $fd->isrewcurr(DATA)

DATA is a reference to a scalar. Returns TRUE if successful 

=item $fd->isrewrec(RECNUM, DATA)

RECNUM is the record number, DATA is a reference to the Data. 
Returns TRUE if successful

=item $fd->isrewrite(DATA)

DATA is a reference to the Data. Returns TRUE if successful 

=item Isam->isrollback 

Returns TRUE if successful

=item $fd->issetunique(UNIQUEID) 

UNIQUEID is an integer scalar. Returns TRUE if successful

=item $fd->isstart(KEYDESC, LENGTH, DATA, MODE)

KEYDESC is a reference to a Keydesc object, LENGTH is 0 or the
number of bytes of the key, DATA is a reference to a scalar,
MODE is an integer value.

Returns TRUE if successful

=item $fd->isuniqueid

Returns undef if unsuccessful or an long value

=item $fd->isunlock

Returns TRUE if successful

=item $fd->iswrcurr(DATA)

DATA is a reference to a scalar. Returns TRUE if successful

=item $fd->iswrite(DATA)
 
DATA is a reference to a scalar. Returns TRUE if successful






=back
 
=head1 SEE ALSO 


=head1 SEE ALSO 

perl(1). 
IsamData.


=cut
