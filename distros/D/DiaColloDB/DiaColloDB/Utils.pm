## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Utils.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic DiaColloDB utilities

package DiaColloDB::Utils;
use DiaColloDB::Logger;
use Exporter;
use JSON;
use IO::Handle;
use IO::File;
use IPC::Run;
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Copy qw();
use File::Spec qw(); ##-- for tmpdir()
use File::Temp qw(); ##-- for tempdir(), tempfile()
use Fcntl qw(:DEFAULT SEEK_SET SEEK_CUR SEEK_END);
use Time::HiRes qw(gettimeofday tv_interval);
use POSIX qw(strftime);
use Carp;
use strict;

##==============================================================================
## Globals

our @ISA = qw(Exporter DiaColloDB::Logger);
our @EXPORT= qw();
our %EXPORT_TAGS =
    (
     fcntl => [qw(fcflags fcread fcwrite fctrunc fccreat fcperl fcopen fcgetfl)],
     json  => [qw(jsonxs loadJsonString loadJsonFile saveJsonString saveJsonFile)],
     sort  => [qw(csort_to csortuc_to)],
     run   => [qw(crun opencmd)],
     env   => [qw(env_set env_push env_pop)],
     pack  => [qw(packsize packsingle packFilterFetch packFilterStore)],
     math  => [qw(isNan isInf isFinite $LOG2 log2 min2 max2 lmax lmin lsum)],
     list  => [qw(luniq sluniq xluniq lcounts)],
     regex => [qw(regex)],
     html  => [qw(htmlesc)],
     ddc   => [qw(ddc_escape)],
     time  => [qw(s2hms s2timestr timestamp)],
     file  => [qw(file_mtime file_timestamp du_file du_glob copyto moveto copyto_a cp_a fh_flush fh_reopen)],
     si    => [qw(si_str)],
     pdl   => [qw(_intersect_p _union_p _complement_p _setdiff_p),
	       qw(readPdlFile writePdlFile writePdlHeader writeCcsHeader mmzeroes mmtemp),
	       qw(maxval mintype),
	      ],
     temp  => [qw($TMPDIR tmpdir tmpfh tmpfile tmparray tmparrayp tmphash)],
    );
our @EXPORT_OK = map {@$_} values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = [@EXPORT_OK];

##==============================================================================
## Functions: Fcntl

## $flags = PACKAGE::fcflags($flags)
##  + returns Fcntl flags for symbolic string $flags
sub fcflags {
  my $flags = shift;
  $flags //= 'r';
  return $flags if ($flags =~ /^[0-9]+$/); ##-- numeric flags are interpreted as Fcntl bitmask
  my $fread  = $flags =~ /[r<]/;
  my $fwrite = $flags =~ /[wa>\+]/;
  my $fappend = ($flags =~ /[a]/ || $flags =~ />>/);
  my $iflags = ($fread
		? ($fwrite ? (O_RDWR|O_CREAT)   : O_RDONLY)
		: ($fwrite ? (O_WRONLY|O_CREAT) : 0)
	       );
  $iflags |= O_TRUNC  if ($fwrite && !$fappend);
  return $iflags;
}

## $fcflags = fcgetfl($fh)
##  + returns Fcntl flags for filehandle $fh
sub fcgetfl {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $fh = shift;
  return CORE::fcntl($fh,F_GETFL,0);
}

## $bool = fcread($flags)
##  + returns true if any read-bits are set for $flags
sub fcread {
  my $flags = fcflags(shift);
  return ($flags&O_RDONLY)==O_RDONLY || ($flags&O_RDWR)==O_RDWR;
}

## $bool = fcwrite($flags)
##  + returns true if any write-bits are set for $flags
sub fcwrite {
  my $flags = fcflags(shift);
  return ($flags&O_WRONLY)==O_WRONLY || ($flags&O_RDWR)==O_RDWR;
}

## $bool = fctrunc($flags)
##  + returns true if truncate-bits are set for $flags
sub fctrunc {
  my $flags = fcflags(shift);
  return ($flags&O_TRUNC)==O_TRUNC;
}

## $bool = fccreat($flags)
sub fccreat {
  my $flags = fcflags(shift);
  return ($flags&O_CREAT)==O_CREAT;
}

## $str = fcperl($flags)
##  + return perl mode-string for $flags
sub fcperl {
  my $flags = fcflags(shift);
  return (fcread($flags)
	  ? (fcwrite($flags)    ##-- +read
	     ? (fctrunc($flags) ##-- +read,+write
		? '+>' : '+<')  ##-- +read,+write,+/-trunc
	     : '<')
	  : (fcwrite($flags)    ##-- -read
	     ? (fctrunc($flags) ##-- -read,+write
		? '>' : '>>')   ##-- -read,+write,+/-trunc
	     : '<')             ##-- -read,-write : default
	 );
}

## $fh_or_undef = fcopen($file,$flags)
## $fh_or_undef = fcopen($file,$flags,$mode,$perms)
##  + opens $file with fcntl-style flags $flags
sub fcopen {
  my ($file,$flags,$perms) = @_;
  $flags    = fcflags($flags);
  $perms  //= (0666 & ~umask);
  my $mode = fcperl($flags);

  my ($sysfh);
  if (ref($file)) {
    ##-- dup an existing filehandle
    $sysfh = $file;
  }
  else {
    ##-- use sysopen() to honor O_CREAT and O_TRUNC
    sysopen($sysfh, $file, $flags, $perms) or return undef;
  }

  ##-- now open perl-fh from system fh
  open(my $fh, "${mode}&=", fileno($sysfh)) or return undef;
  if (fcwrite($flags) && !fctrunc($flags)) {
    ##-- append mode: seek to end of file
    seek($fh, 0, SEEK_END) or return undef;
  }
  return $fh;
}

##==============================================================================
## Functions: JSON

##--------------------------------------------------------------
## JSON: load

## $data = PACKAGE::loadJsonString( $string,%opts)
## $data = PACKAGE::loadJsonString(\$string,%opts)
##  + %opts passed to JSON::from_json(), e.g. (relaxed=>0)
##  + supports $opts{json} = $json_obj
sub loadJsonString {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $bufr = ref($_[0]) ? $_[0] : \$_[0];
  my %opts = @_[1..$#_];
  return $opts{json}->decode($$bufr) if ($opts{json});
  return from_json($$bufr, {utf8=>!utf8::is_utf8($$bufr), relaxed=>1, allow_nonref=>1, %opts});
}

## $data = PACKAGE::loadJsonFile($filename_or_handle,%opts)
sub loadJsonFile {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $file = shift;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  return undef if (!$fh);
  binmode($fh,':raw');
  local $/=undef;
  my $buf = <$fh>;
  close($fh) if (!ref($file));
  return $that->loadJsonString(\$buf,@_);
}

##--------------------------------------------------------------
## JSON: save

## $str = PACKAGE::saveJsonString($data)
## $str = PACKAGE::saveJsonString($data,%opts)
##  + %opts passed to JSON::to_json(), e.g. (pretty=>0, canonical=>0)'
##  + supports $opts{json} = $json_obj
sub saveJsonString {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $data = shift;
  my %opts = @_;
  return $opts{json}->encode($data)  if ($opts{json});
  return to_json($data, {utf8=>1, allow_nonref=>1, allow_unknown=>1, allow_blessed=>1, convert_blessed=>1, pretty=>1, canonical=>1, %opts});
}

## $bool = PACKAGE::saveJsonFile($data,$filename_or_handle,%opts)
sub saveJsonFile {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $data = shift;
  my $file = shift;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $that->logconfess("saveJsonFile() failed to open file '$file': $!") if (!$fh);
  binmode($fh,':raw');
  $fh->print($that->saveJsonString($data,@_)) or return undef;
  if (!ref($file)) { close($fh) || return undef; }
  return 1;
}

##--------------------------------------------------------------
## JSON: object

## $json = jsonxs()
## $json = jsonxs(%opts)
## $json = jsonxs(\%opts)
sub jsonxs {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my %opts = (
	      utf8=>1, relaxed=>1, allow_nonref=>1, allow_unknown=>1, allow_blessed=>1, convert_blessed=>1, pretty=>1, canonical=>1,
	      (@_==1 ? %{$_[0]} : @_),
	     );
  my $jxs  = JSON->new;
  foreach (grep {$jxs->can($_)} keys %opts) {
    $jxs->can($_)->($jxs,$opts{$_});
  }
  return $jxs;
}

BEGIN { *json = \&jsonxs; }

##==============================================================================
## Functions: env


## \%setenv = PACKAGE::env_set(%setenv)
sub env_set {
  my $that   = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my %setenv = @_;
  my ($key,$val);
  while (($key,$val)=each(%setenv)) {
    if (!defined($val)) {
      delete($ENV{$key});
    } else {
      $ENV{$key} = $val;
    }
  }
  return \%setenv;
}

## \%oldvals = PACKAGE::env_push(%setenv)
our @env_stack = qw();
sub env_push {
  my $that   = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my %setenv = @_;
  my %oldenv = map {($_=>$ENV{$_})} keys %setenv;
  push(@env_stack, \%oldenv);
  $that->env_set(%setenv);
  return \%oldenv;
}

## \%restored = PACKAGE::env_pop(%setenv)
sub env_pop {
  my $that    = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $oldvals = pop(@env_stack);
  $that->env_set(%$oldvals) if ($oldvals);
  return $oldvals;
}


##==============================================================================
## Functions: run

## $fh_or_undef = PACKAGE::opencmd($cmd)
## $fh_or_undef = PACKAGE::opencmd($mode,@argv)
##  + does log trace at level $TRACE_RUNCMD
sub opencmd {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  $that->trace("CMD ", join(' ',@_));
  my $fh = IO::Handle->new();
  if ($#_ > 0) {
    open($fh,$_[0],$_[1],@_[2..$#_])
  } else {
    open($fh,$_[0]);
  }
  $that->logconfess("opencmd() failed for \`", join(' ',@_), "': $!") if (!$fh);
  return $fh;
}

## $bool = crun(@IPC_Run_args)
##  + wrapper for IPC::Run::run(@IPC_Run_args) with $ENV{LC_ALL}='C'
sub crun {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  $that->trace("RUN ", join(' ',
			    map {
			      (ref($_)
			       ? (ref($_) eq 'ARRAY'
				  ? join(' ', @$_)
				  : ref($_))
			       : $_)
			    } @_));
  $that->env_push(LC_ALL=>'C');
  my $rc = IPC::Run::run(@_);
  $that->env_pop();
  return $rc;
}

## $bool = csort_to(\@sortargs, \&catcher)
##  + runs system sort and feeds resulting lines to \&catcher
sub csort_to {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($sortargs,$catcher) = @_;
  return crun(['sort',@$sortargs], '>', IPC::Run::new_chunker("\n"), $catcher);
}

## $bool = csortuc_to(\@sortargs, \&catcher)
##  + runs system sort | uniq -c and feeds resulting lines to \&catcher
sub csortuc_to {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($sortargs,$catcher) = @_;
  return crun(['sort',@$sortargs], '|', [qw(uniq -c)], '>', IPC::Run::new_chunker("\n"), $catcher);
}


##==============================================================================
## Functions: pack filters

## $len = PACKAGE::packsize($packfmt)
## $len = PACKAGE::packsize($packfmt,@args)
##  + get pack-size for $packfmt with args @args
sub packsize {
  use bytes; #use bytes; ##-- deprecated in perl v5.18.2
  no warnings;
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return bytes::length(pack($_[0],@_[1..$#_]));
}

## $bool = PACKAGE::packsingle($packfmt)
## $bool = PACKAGE::packsingle($packfmt,@args)
##  + guess whether $packfmt is a single-element (scalar) format
sub packsingle {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return (packsize($_[0],0)==packsize($_[0],0,0)
	  && $_[0] !~ m{\*|(?:\[(?:[2-9]|[0-9]{2,})\])|(?:[[:alpha:]].*[[:alpha:]])});
}

## \&filter_sub = PACKAGE::packFilterStore($pack_template)
## \&filter_sub = PACKAGE::packFilterStore([$pack_template_store, $pack_template_fetch])
## \&filter_sub = PACKAGE::packFilterStore([\&pack_code_store,   \&pack_code_fetch])
##   + returns a DB_File-style STORE-filter sub for transparent packing of data to $pack_template
sub packFilterStore {
  my $that   = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $packas = shift;
  $packas    = $packas->[0] if (UNIVERSAL::isa($packas,'ARRAY'));
  return $packas  if (UNIVERSAL::isa($packas,'CODE'));
  return undef    if (!$packas || $packas eq 'raw');
  if ($that->packsingle($packas)) {
    return sub {
      $_ = pack($packas,$_) if (defined($_));
    };
  } else {
    return sub {
      $_ = pack($packas, ref($_) ? @$_ : split(/\t/,$_)) if (defined($_));
    };
  }
}

## \&filter_sub = PACKAGE::packFilterFetch($pack_template)
## \&filter_sub = PACKAGE::packFilterFetch([$pack_template_store, $pack_template_fetch])
## \&filter_sub = PACKAGE::packFilterFetch([\&pack_code_store,   \&pack_code_fetch])
##   + returns a DB_File-style FETCH-filter sub for transparent unpacking of data from $pack_template
sub packFilterFetch {
  my $that   = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $packas = shift;
  $packas    = $packas->[1] if (UNIVERSAL::isa($packas,'ARRAY'));
  return $packas  if (UNIVERSAL::isa($packas,'CODE'));
  return undef    if (!$packas || $packas eq 'raw');
  if ($that->packsingle($packas)) {
    return sub {
      $_ = unpack($packas,$_);
    };
  } else {
    return sub {
      $_ = [unpack($packas,$_)];
    }
  }
}

##==============================================================================
## Math stuff

sub isNan {
  no warnings qw(uninitialized numeric);
  return !($_[0]<=0||$_[0]>=0);
}
sub isInf {
  no warnings qw(uninitialized numeric);
  return !($_[0]<=0||$_[0]>=0) || ($_[0]==+"INF") || ($_[0]==-"INF");
}
sub isFinite {
  no warnings qw(uninitialized numeric);
  return ($_[0]<=0||$_[0]>=0) && ($_[0]!=+"INF") && ($_[0]!=-"INF");
}

our ($LOG2);
BEGIN {
  $LOG2 = log(2.0);
}

## $log2 = log2($x)
sub log2 {
  return $_[0]==0 ? -inf : log($_[0])/$LOG2;
}

## $max2 = max2($x,$y)
sub max2 {
  return $_[0] > $_[1] ? $_[0] : $_[1];
}

## $min2 = min2($x,$y)
sub min2 {
  return $_[0] < $_[1] ? $_[0] : $_[1];
}

## $max = lmax(@vals)
sub lmax {
  my $max = undef;
  foreach (@_) {
    $max = $_ if (!defined($max) || (defined($_) && $_ > $max));
  }
  return $max;
}

## $min = lmin(@vals)
sub lmin {
  my $min = undef;
  foreach (@_) {
    $min = $_ if (!defined($min) || (defined($_) && $_ < $min));
  }
  return $min;
}

## $sum = lsum(@vals)
sub lsum {
  my $sum = 0;
  $sum += $_ foreach (grep {defined($_)} @_);
  return $sum;
}

##==============================================================================
## Functions: lists

## \@l_uniq = luniq(\@l)
##  + returns unique defined elements of @l; @l need not be sorted
sub luniq {
  my ($tmp);
  return [map {defined($tmp) && $tmp eq $_ ? qw() : ($tmp=$_)} sort grep {defined($_)} @{$_[0]//[]}];
}

## \@l_sorted_uniq = sluniq(\@l_sorted)
##  + returns unique defined elements of pre-sorted @l
sub sluniq {
  my ($tmp);
  return [map {defined($tmp) && $tmp eq $_ ? qw() : ($tmp=$_)} grep {defined($_)} @{$_[0]//[]}];
}

## \@l_uniq = xluniq(\@l,\&keyfunc)
##  + returns elements of @l with unique defined keys according to \&keyfunc (default=\&overload::StrVal)
sub xluniq {
  my ($l,$keyfunc) = @_;
  $keyfunc //= \&overload::StrVal;
  my $tmp;
  return [
	  map {$_->[1]}
	  map {defined($tmp) && $tmp->[0] eq $_->[0] ? qw() : ($tmp=$_)}
	  sort {$a->[0] cmp $b->[0]}
	  grep {defined($_->[0])}
	  map  {[$keyfunc->($_),$_]}
	  @{$l//[]}
	 ];
}

## \%l_counts = lcounts(\@l)
##  + return occurrence counts for elements of @l
sub lcounts {
  my %counts = qw();
  ++$counts{$_} foreach (grep {defined($_)} @{$_[0]//[]});
  return \%counts;
}

##==============================================================================
## Functions: regexes

## $re = regex($re_str)
##  + parses "/"-quoted regex $re_str
##  + parses modifiers /[gimsadlu] a la ddc
sub regex {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $re = shift;
  return $re if (ref($re));
  $re =~ s/^\s*\///;

  my $mods = ($re =~ s/\/([gimsadlux]*)\s*$// ? $1 : '');
  if ($mods =~ s/g//g) {
    $re = "^(?${mods}:${re})\$";  ##-- parse /g modifier a la ddc
  } elsif ($mods) {
    $re = "(?${mods}:$re)";
  }

  return qr{$re};
}

##==============================================================================
## Functions: html

## $escaped = htmlesc($str)
sub htmlesc {
  ##-- html escapes
  my $str = shift;
  $str =~ s/\&/\&amp;/sg;
  $str =~ s/\'/\&#39;/sg;
  $str =~ s/\"/\&quot;/sg;
  $str =~ s/\</\&lt;/sg;
  $str =~ s/\>/\&gt;/sg;
  return $str;
}

##==============================================================================
## Functions: ddc

## $escaped_str = ddc_escape($str)
## $escaped_str = ddc_escape($str, $addQuotes=1)
sub ddc_escape {
  shift(@_) if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return $_[0] if ($_[0] =~ /^[a-zA-Z][a-zA-Z0-9]*$/s); ##-- bareword ok
  my $s = shift;
  $s =~ s/\\/\\\\/g;
  $s =~ s/\'/\\'/g;
  return !exists($_[1]) || $_[1] ? "'$s'" : $s;
}

##==============================================================================
## Functions: time

## $hms       = PACKAGE::s2hms($seconds,$sfmt="%06.3f")
## ($h,$m,$s) = PACKAGE::s2hms($seconds,$sfmt="%06.3f")
sub s2hms {
  shift(@_) if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($secs,$sfmt) = @_;
  $sfmt ||= '%06.3f';
  my $h  = int($secs/(60*60));
  $secs -= $h*60*60;
  my $m  = int($secs/60);
  $secs -= $m*60;
  my $s = sprintf($sfmt, $secs);
  return wantarray ? ($h,$m,$s) : sprintf("%02d:%02d:%s", $h,$m,$s);
}

## $timestr = PACKAGE::s2timestr($seconds,$sfmt="%f")
sub s2timestr {
  shift(@_) if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($h,$m,$s) = s2hms(@_);
  if ($h==0 && $m==0) {
    $s =~ s/^0+(?!\.)//;
    return "${s}s";
  }
  elsif ($h==0) {
    return sprintf("%2dm%ss",$m,$s)
  }
  return sprintf("%dh%02dm%ss",$h,$m,$s);
}

## $rfc_timestamp = PACAKGE->timestamp()
## $rfc_timestamp = PACAKGE->timestamp($time)
sub timestamp {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return POSIX::strftime("%Y-%m-%dT%H:%M:%SZ", (@_ ? gmtime($_[0]) : gmtime()));
}

##==============================================================================
## Functions: file

## $mtime = PACKAGE->file_mtime($file_or_fh)
sub file_mtime {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return (stat($_[0]))[9] // 0;
}

## $timestamp = PACKAGE->file_timestamp($file_or_fh)
sub file_timestamp {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return timestamp(file_mtime(@_));
}

## $nbytes = du_file(@filenames_or_dirnames_or_fhs)
sub du_file {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $du = 0;
  foreach (@_) {
    $du += (!ref($_) && -d $_ ? du_glob("$_/*") : (-s $_))//0;
  }
  return $du;
}

## $nbytes = du_glob(@globs)
sub du_glob {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return du_file(map {glob($_)} @_);
}

## $bool = PACKAGE->copyto($srcfile,   $dstdir, %opts)
## $bool = PACKAGE->copyto(\@srcfiles, $dstdir, %opts)
##  + copies file(s) $srcfile (first form) or @srcfiles (second form) to $dstdir, creating $dstdir if it doesn't already exist;
##    options %opts:
##    (
##     from   => $from,      ##-- replace prefix $from in file(s) with $todir; default=undef: flat copy to $todir
##     method => \&method,   ##-- use CODE-ref \&method as underlying copy routing; default=\&File::Copy::copy
##     label  => $label,     ##-- report errors as '$label'; (default='copyto()')
##    )
sub copyto {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($srcfiles,$todir,%opts) = @_;
  my $method = $opts{method} || \&File::Copy::copy;
  my $label  = $opts{label}  || 'copyto()';
  my $from   = $opts{from};
  my ($src,$dst,$dstdir);
  foreach $src (UNIVERSAL::isa($srcfiles,'ARRAY') ? @$srcfiles : $srcfiles) {
    if (defined($from)) {
      ($dst = $src) =~ s{^\Q$from\E}{$todir};
    } else {
      $dst = "$todir/".basename($src);
    }
    $dstdir = dirname($dst);
    -d $dstdir
      or make_path($dstdir)
      or $that->logconfess("$label: failed to create target directory '$dstdir': $!");
    $method->($src,$dst)
      or $that->logconfess("$label: failed to transfer file '$src' to to '$dst': $!");
  }
  return 1;
}

## $bool = PACKAGE->copyto_a($src,$dstdir,%opts)
## + wrapper for PACKAGE->copyto($src,$dstdir, %opts,method=>PACKAGE->can('cp_a'),label=>'copyto_a()')
sub copyto_a {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  return $that->copyto(@_, method=>\&cp_a, label=>'copyto_a()');
}

## $bool = PACKAGE->moveto($src,$dstdir, %opts)
## + wrapper for PACKAGE->copyto($src,$dstdir, %opts,method=>\&File::Copy::move,label=>'moveto()')
sub moveto {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  return $that->copyto(@_, method=>\&File::Copy::move, label=>'moveto()');
}

## $bool = PACKAGE->cp_a($src,$dst)
## $bool = PACKAGE->cp_a($src,$dstdir)
##  + copies file $src to $dst, propagating ownership, permissions, and timestamps
sub cp_a {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($src,$dst) = @_;
  if (File::Copy->can('syscopy') && File::Copy->can('syscopy') ne File::Copy->can('copy')) {
    ##-- use File::copy::syscopy() if available
    return File::Copy::syscopy($src,$dst,3);
  }
  ##-- copy and then manually propagate file attributes
  my $rc = File::Copy::copy($src,$dst) or return undef;
  $dst = "$dst/".basename($src) if (-d $dst);
  my @stat = stat($src);
  my ($perm,$gid,$atime,$mtime) = @stat[2,5,8,9];
  my $uid = $>==0 ? $stat[4] : $>;  ##-- don't try to set uid unless we're running as root
  $rc &&= CORE::chown($uid,$gid,$dst)
      or $that->warn("cp_a(): failed to propagate ownership from '$src' to '$dst': $!");
  $rc &&= CORE::chmod(($perm & 07777), $dst)
      or $that->warn("cp_a(): failed to propagate persmissions from '$src' to '$dst': $!");
  $rc &&= CORE::utime($atime,$mtime,$dst)
      or $that->warn("cp_a(): failed to propagate timestamps from '$src' to '$dst': $!");
  return $rc;
}

## $fh_or_undef = PACKAGE->fh_flush($fh)
##  + flushes filehandle $fh using its flush() method if available
sub fh_flush {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $fh = shift;
  return UNIVERSAL::can($fh,'flush') ? $fh->flush() : $fh;
}

## $fh_or_undef = PACKAGE->fh_reopen($fh,$file)
##  + closes and re-opens filehandle $fh
sub fh_reopen {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($fh,$file) = @_;
  my $flags      = fcgetfl($fh) & (~O_TRUNC);
  my @layers0    = PerlIO::get_layers($fh);
  CORE::close($fh) || return undef;
  CORE::open($fh, fcperl($flags), $file) or return undef;
  my @layers1    = PerlIO::get_layers($fh);
  while (@layers0 && @layers1 && $layers0[0] eq $layers1[0]) {
    shift(@layers0);
    shift(@layers1);
  }
  binmode($fh,":$_") foreach (@layers1);
  return $fh;
}



##==============================================================================
## Utils: SI

## $str = si_str($float)
sub si_str {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $x = shift;
  return sprintf("%.2fY", $x/10**24) if ($x >= 10**24);  ##-- yotta
  return sprintf("%.2fZ", $x/10**21) if ($x >= 10**21);  ##-- zetta
  return sprintf("%.2fE", $x/10**18) if ($x >= 10**18);  ##-- exa
  return sprintf("%.2fP", $x/10**15) if ($x >= 10**15);  ##-- peta
  return sprintf("%.2fT", $x/10**12) if ($x >= 10**12);  ##-- tera
  return sprintf("%.2fG", $x/10**9)  if ($x >= 10**9);   ##-- giga
  return sprintf("%.2fM", $x/10**6)  if ($x >= 10**6);   ##-- mega
  return sprintf("%.2fk", $x/10**3)  if ($x >= 10**3);   ##-- kilo
  return sprintf("%.2f",  $x)        if ($x >= 1);       ##-- (natural units)
  return sprintf("%.2fm", $x*10**3)  if ($x >= 10**-3);  ##-- milli
  return sprintf("%.2fu", $x*10**6)  if ($x >= 10**-6);  ##-- micro
  return sprintf("%.2fn", $x*10**9)  if ($x >= 10**-9);  ##-- nano
  return sprintf("%.2fp", $x*10**12) if ($x >= 10**-12); ##-- pico
  return sprintf("%.2ff", $x*10**15) if ($x >= 10**-15); ##-- femto
  return sprintf("%.2fa", $x*10**18) if ($x >= 10**-18); ##-- atto
  return sprintf("%.2fz", $x*10**21) if ($x >= 10**-21); ##-- zepto
  return sprintf("%.2fy", $x*10**24) if ($x >= 10**-24); ##-- yocto
  return sprintf("%.2g", $x); ##-- default
}

##==============================================================================
## Functions: pdl: setops

## $pi = CLASS::_intersect_p($p1,$p2)
## $pi = CLASS->_intersect_p($p1,$p2)
##  + intersection of 2 piddles; undef is treated as the universal set
##  + argument piddles MUST be sorted in ascending order
sub _intersect_p {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return (defined($_[0])
	  ? (defined($_[1])
	     ? $_[0]->v_intersect($_[1]) ##-- v_intersect is 1.5-3x faster than PDL::Primitive::intersect()
	     : $_[0])
	  : $_[1]);
}
## $pu = CLASS::_union_p($p1,$p2)
## $pi = CLASS->_intersect_p($p1,$p2)
##  + union of 2 piddles; undef is treated as the universal set
##  + argument piddles MUST be sorted in ascending order
sub _union_p {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return (defined($_[0])
	  ? (defined($_[1])
	     ? $_[0]->v_union($_[1])  ##-- v_union is 1.5-3x faster than PDL::Primitive::setops($a,'OR',$b)
	     : $_[0])
	  : $_[1]);
}

## $pneg = CLASS::_complement_p($p,$N)
## $pneg = CLASS->_complement_p($p,$N)
##  + index-piddle negation; undef is treated as the universal set
##  + $N is the total number of elements in the index-universe
BEGIN { *_not_p = *_negate_p = \&_complement_p; }
sub _complement_p {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($p,$N) = @_;
  if (!defined($p)) {
    ##-- neg(\universe) = \emptyset
    return PDL->null->long;
  }
  elsif ($p->nelem==0) {
    ##-- neg(\emptyset) = \universe
    return undef;
  }
  else {
    ##-- non-trivial negation
    ##
    ##-- mask: ca. 2.2x faster than v_setdiff
    no strict 'subs';
    my $mask = PDL->ones(PDL::byte(),$N);
    (my $tmp=$mask->index($p)) .= 0;
    return $mask->which;
    ##
    ##-- v_setdiff: ca. 68% slower than mask
    #my $U = sequence($p->type, $N);
    #return scalar($U->v_setdiff($p));
  }
}


## $pdiff = CLASS::_setdiff_p($a,$b,$N)
## $pdiff = CLASS->_setdiff_p($a,$b,$N)
##  + index-piddle difference; undef is treated as the universal set
##  + $N is the total number of elements in the index-universe
sub _setdiff_p {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($a,$b,$N) = @_;
  if (!defined($a)) {
    ##-- \universe - b = \neg(b)
    return _complement_p($b,$N);
  }
  elsif (!defined($b)) {
    ##-- a - \universe = \emptyset
    return PDL->null->long;
  }
  elsif ($a->nelem==0) {
    ##-- \empyset - b = \emptyset
    return $a;
  }
  elsif ($b->nelem==0) {
    ##-- a - \emptyset = a
    return $a;
  }
  else {
    ##-- non-trivial setdiff
    return scalar($a->v_setdiff($b));
  }
}

##==============================================================================
## Functions: pdl: I/O

## $pdl_or_undef = CLASS->readPdlFile($basename, %opts)
##  + %opts:
##     class=>$class,    # one of qw(PDL PDL::CCS::Nd)
##     mmap =>$bool,     # use mapfraw() (default=1)
##     log=>$level,      # log-level (default=undef: off)
##     ...               # other keys passed to CLASS->mapfraw() rsp. CLASS->readfraw()
sub readPdlFile {
  #require PDL::IO::FastRaw;
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($file,%opts) = @_;
  my $class = $opts{class} // 'PDL';
  my $mmap  = $opts{mmap}  // 1;
  my $ro    = (!$mmap || (exists($opts{ReadOnly}) ? $opts{ReadOnly} : (!-w "$file.hdr"))) || 0;
  $that->vlog($opts{log}, "readPdlFile($file) [class=$class,mmap=$mmap,ReadOnly=$ro]");
  delete @opts{qw(class mmap ReadOnly verboseIO)};
  return undef if (!-e "$file.hdr");
  return $mmap ? $class->mapfraw($file,{%opts,ReadOnly=>$ro}) : $class->readfraw($file,\%opts);
}

## $bool = CLASS->writePdlFile($pdl_or_undef, $basename, %opts)
##  + unlinks target file(s) if $pdl is not defined
##  + %opts:
##     log => $bool,       # log-level (default=undef: off)
##     ...                 # other keys passed to $pdl->writefraw()
sub writePdlFile {
  #require PDL::IO::FastRaw;
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($pdl,$file,%opts) = @_;
  if (defined($pdl)) {
    ##-- write: raw
    $that->vlog($opts{log}, "writePdlFile($file)");
    delete($opts{verboseIO});
    return $pdl->writefraw($file,\%opts);
  }
  else {
    ##-- write: undef: unlink
    $that->vlog($opts{log}, "writePdlFile($file): unlink");
    foreach (grep {-e "file$_"} ('','.hdr','.ix','.ix.hdr','.nz','.nz.hdr','.fits')) {
      unlink("file$_") or $that->logconfess(__PACKAGE__, "::writePdlFile(): failed to unlink '$file$_': $!");
    }
  }
  return 1;
}

## $bool = CLASS->writePdlHeader($filename, $type, $ndims, @dims)
##  + writes a PDL::IO::FastRaw-style header $filename (e.g. "pdl.hdr")
##  + adapted from PDL::IO::FastRaw::_writefrawhdr()
##  + arguments
##     $type   ##-- PDL::Type or integer
##     $ndims  ##-- number of piddle dimensions
##     @dims   ##-- dimension size list, piddle, or ARRAY-ref
sub writePdlHeader {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($file,$type,$ndims,@dims) = @_;
  $that->logconfess("writePdlHeader(): missing required parameter (FILE,TYPE,NDIMS,DIMS...)") if (@_ < 3);
  $type = $type->enum if (UNIVERSAL::isa($type,'PDL::Type'));
  @dims = map {UNIVERSAL::isa($_,'PDL') ? $_->list : (UNIVERSAL::isa($_,'ARRAY') ? @$_ : $_)} @dims;
  open(my $fh, ">$file")
    or return undef;
    #$that->logconfess("writePdlHeader(): open failed for '$file': $!");
  print $fh join("\n", $type, $ndims, join(' ', @dims), '');
  close($fh);
}

## $bool = CLASS->writeCcsHeader($filename, $itype, $vtype, $pdims, %opts)
##  + writes a PDL::CCS::IO::FastRaw-style header $filename (e.g. "pdl.hdr")
##  + arguments:
##     $itype,          ##-- PDL::Type for index (default: PDL::CCS::Utils::ccs_indx())
##     $vtype,          ##-- PDL::Type for values (default: $PDL::IO::Misc::deftype)
##     $pdims,          ##-- dimension piddle or ARRAY-ref
##  + %opts:            ##-- passed to PDL::CCS::Nd->newFromWich
sub writeCcsHeader {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  $that->logconfess("writeCcsFile(): missing required parameter (FILE,ITYPE,VTYPE,DIMS...)") if (@_ < 3);
  my ($file,$itype,$vtype,$pdims,%opts) = @_;
  $itype = PDL::CCS::Utils::ccs_indx() if (!defined($itype));
  $vtype = $PDL::IO::Misc::deftype  if (!defined($vtype));
  $pdims = PDL->pdl($itype, $pdims) if (!UNIVERSAL::isa($pdims,'PDL'));
  my $ccs = PDL::CCS::Nd->newFromWhich(PDL->zeroes($itype,$pdims->nelem,1),
				       PDL->zeroes($vtype,2),
				       pdims=>$pdims, sorted=>1, steal=>1, %opts);
  return PDL::CCS::IO::Common::_ccsio_write_header($ccs, $file);
}

##==============================================================================
## Functions: pdl: mmap temporaries

## $pdl = mmzeroes($file?, $type?, @dims, \%opts?)
## $pdl = $pdl->mmzeroes($file?, $type?, \%opts?)
##  + create a temporary mmap()ed pdl using DiaColloDB::PDL::MM; %opts:
##    (
##     file => $template,   ##-- file basename or File::Temp template; default='pdlXXXX'
##     suffix => $suffix,   ##-- File::Temp::tempfile() suffix (default='.pdl')
##     log  => $level,      ##-- logging verbosity (default=undef: off)
##     temp => $bool,       ##-- delete on END (default: $file =~ /X{4}/)
##    )
sub mmzeroes {
  require DiaColloDB::PDL::MM;
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return DiaColloDB::PDL::MM::new(@_);
}
sub mmtemp {
  require DiaColloDB::PDL::MM;
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return DiaColloDB::PDL::MM::mmtemp(@_);
}

## $bool = mmunlink(@mmfiles)
## $bool = mmunlink($mmpdl,@mmfiles)
##  + unlinkes file(s) generated by mmzeroes($basename)
sub mmunlink {
  require DiaColloDB::PDL::MM;
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return DiaColloDB::PDL::MM::unlink(@_);
}

##==============================================================================
## Functions: pdl: misc

## $type = CLASS->mintype($pdl,    @types)
## $type = CLASS->mintype($maxval, @types)
##  + returns minimum PDL::Types type from @types required for representing $maxval ($pdl->max if passed as a PDL)
##  + @types defaults to all known PDL types
sub mintype {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($arg,@types) = @_;
  $arg   = $arg->max if (UNIVERSAL::isa($arg,'PDL'));
  @types = map {$_->{ioname}} values(%PDL::Types::typehash) if (!@types);
  @types = sort {$a->enum <=> $b->enum} map {ref($_) ? $_ : (PDL->can($_) ? PDL->can($_)->() : qw())} @types;
  foreach my $type (@types) {
    return $type if (maxval($type) >= $arg);
  }
  return PDL::float(); ##-- float is enough to represent anything, in principle
}
BEGIN {
  *PDL::mintype = \&mintype;
}

## $maxval = $type->maxval()
## $maxval = CLASS::maxval($type_or_name)
sub maxval {
  no warnings 'pack';
  my $type = shift;
  $type    = PDL->can($type)->() if (!ref($type) && PDL->can($type));
  return 'inf' if ($type >= PDL::float());
  my $nbits  = 8*length(pack($PDL::Types::pack[$type->enum],0));
  return (PDL->pdl($type,2)->pow(PDL->sequence($type,$nbits+1))-1)->double->max;
}
BEGIN {
  *PDL::Type::maxval = \&maxval;
}


## ($vals,$counts) = $pdl->valcounts()
##  + wrapper for $pdl->flat->qsort->rle() with masking lifted from MUDL::PDL::Smooth
sub valcounts {
  my $pdl = shift;
  my ($counts,$vals) = $pdl->flat->qsort->rle;
  my $mask = ($counts > 0);
  return ($vals->where($mask), $counts->where($mask));
}
BEGIN {
  no warnings 'redefine'; ##-- avoid irritating "PDL::valcounts redefined" messages when running together with (legacy) MUDL & DocClassify code
  *PDL::valcounts = \&valcounts;
}

##==============================================================================
## Functions: temporaries

## $TMPDIR : global temp directory to use
our $TMPDIR = undef;

## TMPFILES : temporary files to be unlinked on END
our @TMPFILES = qw();
END {
  foreach (@TMPFILES) {
    !-e $_
      or CORE::unlink($_)
      or __PACKAGE__->logwarn("failed to unlink temporary file $_ in final cleanup");
  }
}

## $tmpdir = CLASS->tmpdir()
## $tmpdir = CLASS_>tmpdir($template, %opts)
##  + in first form, get name of global tempdir ($TMPDIR || File::Spec::tmpdir())
##  + in second form, create and return a new temporary directory via File::Temp::tempdir()
sub tmpdir {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $tmpdir = $TMPDIR || File::Spec->tmpdir();
  return @_ ? File::Temp::tempdir($_[0], DIR=>$tmpdir, @_[1..$#_]) : $tmpdir;
}

## $fh = CLASS->tmpfh()
## $fh = CLASS->tmpfh($template_or_filename, %opts)
##  + get a new temporary filehandle or undef on error
##  + in list context, returns ($fh,$filename) or empty list on error
sub tmpfh {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $template = shift // 'tmpXXXXX';
  my ($fh,$filename);
  if ($template =~ /X{4}/) {
    ##-- use File::Temp::tempfile()
    ($fh,$filename) = File::Temp::tempfile($template, DIR=>$that->tmpdir(), @_) or return qw();
  } else {
    ##-- use literal filename, honoring DIR, TMPDIR, and SUFFIX options
    my %opts  = @_;
    $filename = $template;
    do { $opts{DIR} =~ s{/$}{}; $filename  = "$opts{DIR}/$filename"; } if ($filename !~ m{^/} && defined($opts{DIR}));
    $filename  = $that->tmpdir."/".$filename if ($filename !~ m{^/} && $opts{TMPDIR});
    $filename .= $opts{SUFFIX} if (defined($opts{SUFFIX}));
    CORE::open($fh, "+>", $filename)
	or $that->logconfess("tmpfh(): open failed for file '$filename': $!");
    push(@TMPFILES, $filename) if ($opts{UNLINK});
  }
  return wantarray ? ($fh,$filename) : $fh;
}

## $filename = CLASS->tmpfile()
## $filename = CLASS->tmpfile($template, %opts)
sub tmpfile {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($fh,$filename) = $that->tmpfh(@_) or return undef;
  $fh->close();
  return $filename;
}

## \@tmparray = CLASS->tmparray($template, %opts)
##  + ties a new temporary array via $class (default='Tie::File::Indexed::JSON')
##  + calls tie(my @tmparray, 'DiaColloDB::Temp::Array', $tmpfilename, %opts)
sub tmparray {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($template,%opts) = @_;

  ##-- load target module
  eval { require "DiaColloDB/Temp/Array.pm" }
    or $that->logconfess("tmparray(): failed to load class DiaColloDB::Temp::Array: $@");

  ##-- default options
  $template     //= 'dcdbXXXXXX';
  $opts{SUFFIX} //= '.tmpa';
  $opts{UNLINK}   = 1 if (!exists($opts{UNLINK}));

  ##-- tie it up
  my $tmpfile = $that->tmpfile($template, %opts);
  tie(my @tmparray, 'DiaColloDB::Temp::Array', $tmpfile, %opts)
    or $that->logconfess("tmparray(): failed to tie file '$tmpfile' via DiaColloDB::Temp::Array: $@");
  return \@tmparray;
}

## \@tmparrayp = CLASS->tmparrayp($template, $packas, %opts)
##  + ties a new temporary integer-array via DiaColloDB::PackedFile)
##  + calls tie(my @tmparray, 'DiaColloDB::PackedFile', $tmpfilename, %opts)
sub tmparrayp {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($template,$packas,%opts) = @_;

  ##-- load target module
  eval { require "DiaColloDB/PackedFile.pm" }
    or $that->logconfess("tmparrayp(): failed to load class DiaColloDB::PackedFile: $@");

  ##-- default options
  $template     //= 'dcdbXXXXXX';
  $opts{SUFFIX} //= '.pf';
  $opts{UNLINK}   = 1 if (!exists($opts{UNLINK}));

  ##-- tie it up
  my $tmpfile = $that->tmpfile($template, %opts);
  tie(my @tmparray, 'DiaColloDB::PackedFile', $tmpfile, 'rw', packas=>$packas, temp=>$opts{UNLINK}, %opts)
    or $that->logconfess("tmparrayp(): failed to tie file '$tmpfile' via DiaColloDB::PackedFile: $@");
  return \@tmparray;
}

## \%tmphash = CLASS->tmphash($template, %opts)
##  + ties a new temporary hash via $class (default='DB_File')
##  + calls tie(my @tmparray, $class, $tmpfilename, temp=>1, %opts)
sub tmphash {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my ($template,%opts) = @_;

  ##-- load target module
  eval { require "DiaColloDB/Temp/Hash.pm" }
    or $that->logconfess("tmparray(): failed to load class DiaColloDB::Temp::Hash: $@");

  ##-- default options
  $template     //= 'dcdbXXXXXX';
  $opts{SUFFIX} //= '.tmph';
  $opts{UNLINK}   = 1 if (!exists($opts{UNLINK}));

  ##-- tie it up
  my $tmpfile = $that->tmpfile($template, %opts);
  tie(my %tmphash, 'DiaColloDB::Temp::Hash', $tmpfile, %opts)
    or $that->logconfess("tmphash(): failed to tie file '$tmpfile' via DiaColloDB::Temp::Hash: $@");
  return \%tmphash;
}

##==============================================================================
## Footer
1; ##-- be happy
