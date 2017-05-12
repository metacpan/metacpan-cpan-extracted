#!/usr/bin/perl
package LaBrea::Tarpit::Util;
#
# 5-17-02, michael@bizsystems.com
#
use strict;
#use diagnostics;
use vars qw($VERSION @ISA @EXPORT_OK);
use AutoLoader 'AUTOLOAD';
use Fcntl qw(:DEFAULT :flock);

$VERSION = do { my @r = (q$Revision: 0.06 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw (
	cache_is_valid
	update_cache
	upd_cache
	daemon2_cache
	page_is_current
	share_open
	ex_open
	close_file
	http_date
	script_name
	reap_kids
	labrea_whoami
);

# autoload declarations

sub cache_is_valid;
sub update_cache;
sub upd_cache;
sub daemon2_cache;
sub share_open;
sub ex_open;
sub close_file;
sub http_date;
sub script_name;
sub page_is_current;
sub reap_kids;
sub labrea_whoami;
sub DESTROY {};  

1;
__END__

=head1 NAME

LaBrea::Tarpit::Util

=head1 SYNOPSIS

  use LaBrea::Tarpit::Util qw( .... );

  $rv = cache_is_valid(*HANDLE,\%look_n_feel,$short);
  $rv = update_cache(\%look_n_feel,\$html,\$short);  
  ($modtime,$update)=daemon2_cache($cache,$src,$age);
  $modtime = page_is_current($cache_time,$page);
  $rv = share_open(*LOCK,*FILE,$filename,$nblock,$umask);   
  $rv = ex_open(*LOCK,*FILE,$filename,$func,$nblock,$umask);
  $rv = close_file(*LOCK,*FILE)
  $time_string = http_date(time);
  $name = script_name($depth);
  $alive = reap_kids(\%kids);  deprecated in this module

=head1 DESCRIPTION - LaBrea::Tarpit::Util

A collection of utility programs used by other modules and applications of
LaBrea::Tarpit

=over 2

=item $rv=cache_is_valid(*HANDLE,\%look_n_feel,$short);

  input:	HANDLE
		\look_n_feel
		flag, true  = check short cache
		      false = standard

  returns:	size of file, HANDLE open
		if cache valid
		false, cache requires update

  dispose:	close HANDLE;

=cut
  
# returns true if cache ready, otherwise false
# cache is not locked, it is updated atomicaly
#
# input:	*HANDLE,\%look_n_feel, short_flag
# returns:	size of file, HANDLE open, if cache valid
#		false, cache requires update
#
sub cache_is_valid {
  my ($FH,$lnf,$f) = @_;
  return undef unless
	exists $lnf->{html_cache_file} &&
	exists $lnf->{html_expire} &&
	$lnf->{html_expire} > 0 &&
	($f = ($f) ? $lnf->{html_cache_file}.'.short' : $lnf->{html_cache_file}) &&
	-e $f &&
	-r $f;
  my ($size,$mtime) = (stat($f))[7,9];
  return undef unless
	$mtime + $lnf->{html_expire}  > time &&
	open($FH,$f);
  return $size;
}

=item $rv = update_cache(\%look_n_feel,\$html,\$short);

  Write new cache file with contents of 
  optional $html and/or $short

  The filename for the short cache is taken from 
  $look_n_feel{html_cache_file} . '.short'

  returns:	true on success
		false if failed

=cut

sub update_cache {
  my ($lnf,$htm,$sht) = @_;
  return undef unless exists $lnf->{html_cache_file};
  @_ = ($lnf->{html_cache_file},'',$htm,$sht);
  goto &upd_cache;
}

=item $rv=upd_cache($filename,$pagename,$html,$short);

This is the way B<update_cache> should have worked the first time, sigh....

Update a cache for a page and short report.

  Write new cache file with contents of 
  optional $html and/or $short

  The filename for the short cache is taken from 
  $filename . '.short'

  The page file name is taken from the $filename stub
  $filename.$pagename

  i.e.	$filename = mycache
	$pagename = page2

  eq => mycache.page2

  returns:	true on success
		false if failed

=cut

sub upd_cache {
  my($f,$pn,$htm,$sht) = @_;
  return undef unless $htm || $sht;	# must want to do something
  $pn = ($pn) ? '.'.$pn : '';		# insert dot or make null
  local (*LOCK,*FH,*SH);
  return undef unless
	$f.$pn &&
# open new file non-blocking with exclusive lock
	ex_open(*LOCK,*FH,$f.$pn.'.tmp',-1,1);

  if ( $htm ) {		# html present
    print FH $$htm;
    if ($sht &&		# short report present too
	open(SH,'>'.$f.$pn.'.short.tmp' )) {
      $_ = select SH;
      $| = 1;
      select $_;
      print SH $$sht;
      close SH;
      rename 		# atomic update
	$f.$pn.'.short.tmp',
	$f.'.short';
    }
    close_file(*LOCK,*FH);
# atomic update, return true on success
      rename 		# atomic update
	$f.$pn.'.tmp',
	$f.$pn;
  } elsif ( $sht ) {	# unconditional 'else'
    print FH $$sht;
    close_file(*LOCK,*FH);
    rename		# atomic update
      $f.$pn.'.tmp',
      $f.'.short';
  } else {
    close_file(*LOCK,*FH);	# should not get here
    return undef;
  }
  1;
}

=item ($modtime,$update)=daemon2_cache($cache,$src,$age);

  Return the last modified time of the cache
  file, update cache if older than $age seconds.
  Set $@ on error;

  input:	cache file,
		src file,
		  or
		hash->{d_host}
		    ->{d_port} 
		    ->{d_timeout}
		age in seconds 
		timeout in seconds [default 60]
  returns:	(mod time, 0), no update
		(mod time, 1), updated
		or () on failure

=cut

# $debug is the alarm time of the eval

sub daemon2_cache {
  my ($cf,$sf,$age,$debug) = @_;
  require LaBrea::NetIO;
  import LaBrea::NetIO qw (daemon_handler);
  $age = 0 unless $age;
  local(*LOCK,*IN,*OUT);
  my $update = 0;
  my $time = time;
  my @return;
  my $timeout = (ref $sf eq 'HASH' && !exists $sf->{file} && $sf->{d_timeout})
	? $sf->{d_timeout} : 180;
  $timeout = $debug if $debug;
  local $SIG{ALRM} = sub { die "remote connect timeout"; };
  eval {
  die 'missing output cache file' unless $cf;
  alarm $timeout;
  while (1) {
    my $cmt = (-e $cf) ? (stat($cf))[9] : 0;	# cache last modified time
    unless ($cmt + $age < $time) {
      @return = ($cmt,$update);
      last;
    }
    my $nblock = ! $debug; 			# will block if debug
    if ( ex_open(*LOCK,*OUT,$cf.'.tmp',-1,$nblock) ) {	# attempt non blocking open
      my $subref;
      unless ($subref = daemon_handler(*IN,$sf)) {
	@return = ();
	close_file(*LOCK,*OUT);
	last;
      }
      print IN "standard\n" 
	if ref $sf eq 'HASH' && !exists $sf->{file};
      while ($_ = &$subref) {
	print OUT $_;
      }
      close OUT;
      close IN;
      rename $cf.'.tmp', $cf;	# atomic update
      close LOCK;
      $update = 1;
    } else {
      sleep 1;			# another process is updating, wait
    }
  } # end while
  alarm 0;
  }; # end eval
  @return = () if $@;		# oops
  return (wantarray) ? @return : $return[0];
}

=item $modtime=page_is_current($cache_time,$page);

  Check to see if page is current

  input:	cache time, path to page file
  returns:	mtime of file or false on failure

=cut

sub page_is_current {
  my ($ct,$page) = @_;
  my $mtime;
  return (-e $page && $ct <= ($mtime =(stat($page))[9])) ? $mtime : 0;
}

=item $rv=share_open(*LOCK,*FILE,$filename,$nblock,$umask);

Open a file for shared (read only) access.

  input:	LOCK handle, 
		FILE handle, 
		filename, 
		non-blocking, 
		umask		(default 0117)

  returns:	true on success

  dispose by:
  close FILE;
  close LOCK;

  This is a READ ONLY OPERATION

=cut

sub share_open {
  my ($LOCK, $fh, $fn, $nblock, $umask) = @_;
  $nblock = ($nblock) ? LOCK_NB : 0;
  $umask = 0117 unless $umask;
  umask $umask;
  return undef unless sysopen $LOCK, $fn . '.flock', O_RDWR|O_CREAT|O_TRUNC;
#	die(&me . ': could not open file shared ' . $fn . '.flock');
  unless (flock($LOCK,LOCK_SH|$nblock)) {
    close $LOCK; 
    return undef;
  }
  return 1 if sysopen $fh, $fn, O_RDONLY|O_CREAT;
#	die(&me . ': could not open file shared ' . $fn);
  close $LOCK;
  return undef;
}

=item $rv=ex_open(*LOCK,*FILE,$filename,$func,$nblock,$umask);

Open a file for exclusive access.

  input:    LOCK handle, 
	    FILE handle, 
	    filename, 
	    function,
	    non-blocking,
	    umask		(default 0117)

  returns:  true on success

  function:  1			append
	     false or [^\d]	rw access
	    -1			new/truncate rw access

  nblock:    false		blocking access
	     true		non-blocking access

  dispose by:
	close FILE;
	close LOCK;

=cut

sub ex_open {
  my ($LOCK, $fh, $fn, $func, $nblock, $umask) = @_;
  $nblock = ($nblock) ? LOCK_NB : 0;
  $umask = 0117 unless $umask;
  umask $umask;
  return undef unless sysopen $LOCK, $fn . '.flock', O_RDWR|O_CREAT|O_TRUNC;
#	die(&me . ': could not open file exclusive ' . $fn . '.flock');
  unless (flock($LOCK,LOCK_EX|$nblock)) {
    close $LOCK; 
    return undef;
  }
  if ( $func ) {
    if ( $func =~ /[^\d]/ || $func < 0 ) {
#print STDERR "open NEW $fn\n";
      $func = O_RDWR|O_CREAT|O_TRUNC;
    } else {
#print STDERR "open APPEND $fn\n";
      $func = O_RDWR|O_APPEND|O_CREAT;
    }
  } else {
# use sysopen FILEHANDLE,FILENAME,MODE,PERMS
#print STDERR "open RDRW $fn\n";
    $func = O_RDWR|O_CREAT;
  }
  unless (sysopen $fh, $fn, $func) {
    close $LOCK;
    return undef;
  }
  my $tmp = select $fh;
  $| = 1;
  select $tmp;
  return 1;
}

=item $rv = close_file(*LOCK,*FILE);

  close file and lock file

=cut

sub close_file {
  my ($fl, $fh) = @_;
  close $fh;
  close $fl;	# returns true on success
}

=item $time_string = http_date($time);

  Returns time string in HTTP date format, same as...

  Apache::Util::ht_time(time, "%a, %d %b %Y %T %Z",1));

  i.e. Sat, 13 Apr 2002 17:36:42 GMT

=cut

sub http_date {
  my($time) = @_;
  my($sec,$min,$hr,$mday,$mon,$yr,$wday) = gmtime($time);
  return
    (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday] . ', ' .			# "%a, "
    sprintf("%02d ",$mday) .						# "%d "
    (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon] . ' ' .	# "%b "
    ($yr + 1900) . ' ' .							# "%Y "
    sprintf("%02d:%02d:%02d ",$hr,$min,$sec) .				# "%T "
    'GMT';								# "%Z"
}

=item $name = script_name($depth);

  Returns the name of the calling script.
      (no path, just the name)

  input:	depth of call stack
		  (default = 0)
  returns:	name of calling script

=cut

sub script_name {
  my $depth = $_[0] || 0;
(caller($depth))[1] =~ m|([^/]+)$|; return $1;}

=item $mod_ver = labrea_whoami;

Returns a string of the form:

  $mod_ver = 'Tarpit 1.00 Util 0.04';

showing all the LaBrea modules loaded and their version numbers. The
version numbers follow their respective module name, space separated.

=cut

sub labrea_whoami {
  @_ = sort grep ( /^LaBrea/ && /\.pm$/ && ($_ = $`),keys %INC);
  my $whoami = '';
  foreach (@_) {
    $_ =~ s#/#::#g;
    $_ =~ /([^:]+)$/;
    $_ = '$'.$_.'::VERSION';
    $whoami .= $1 . ' ' . (eval "$_") . ' ';
  }
  chop $whoami;
  return $whoami;
}

=item $alive = reap_kids(\%kids);

Deprecated in this module, available for backwards 
compatibility only.

See: LaBrea::NetIO::reap_kids

=back

=cut

sub reap_kids {
  require LaBrea::NetIO;
  goto &LaBrea::NetIO::reap_kids;
}

=head1 EXPORT_OK

        cache_is_valid 
	daemon2_cache
        close_file
        ex_open
        http_date
	labrea_whoami
	page_is_current
	script_name
        share_open
        update_cache
	upd_cache
	reap_kids

=head1 COPYRIGHT

Copyright 2002, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or   
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 SEE ALSO

perl(1), LaBrea::Tarpit(3), LaBrea::Codes(3), LaBrea::Tarpit::Report(3),
LaBrea::Tarpit::Get(3), LaBrea::Tarpit::Util(3)

=cut

1;
