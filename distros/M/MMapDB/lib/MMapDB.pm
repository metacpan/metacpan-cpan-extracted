package MMapDB;

use 5.008008;
use strict;
use warnings;
no warnings qw/uninitialized/;

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# keep this in mind
use integer;
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

use Fcntl qw/:seek :flock/;
use File::Spec;
use File::Map qw/map_handle protect/;
use Exporter qw/import/;
use Encode ();

{				# limit visibility of "our"/"my" variables
  our $VERSION = '0.15';
  our %EXPORT_TAGS=
    (
     mode =>[qw/DATAMODE_NORMAL DATAMODE_SIMPLE/],
     error=>[qw/E_READONLY E_TWICE E_TRANSACTION E_FULL E_DUPLICATE
		E_OPEN E_READ E_WRITE E_CLOSE E_RENAME E_TRUNCATE E_LOCK
		E_RANGE E_NOT_IMPLEMENTED/],
    );
  my %seen;
  undef @seen{map {@$_} values %EXPORT_TAGS};
  our @EXPORT_OK=keys %seen;
  $EXPORT_TAGS{all}=\@EXPORT_OK;

  require XSLoader;
  XSLoader::load('MMapDB', $VERSION);

  our @attributes;
  BEGIN {
    # define attributes and implement accessor methods
    # !! keep in sync with MMapDB.xs !!
    @attributes=(qw/filename readonly intfmt _data _intsize _stringfmt
		    _stringtbl mainidx _ididx main_index id_index
		    _nextid _idmap _tmpfh _tmpname _stringfh _stringmap
		    _strpos lockfile flags dbformat_in dbformat_out
		    _stringfmt_out stringmap_prealloc _stringmap_end
		    index_prealloc _index_end _tmpmap
		   /);
    for( my $i=0; $i<@attributes; $i++ ) {
      my $method_num=$i;
      ## no critic
      no strict 'refs';
      *{__PACKAGE__.'::'.$attributes[$method_num]}=
	sub : lvalue {$_[0]->[$method_num]};
      ## use critic
    }
  }
}

my @dbformats=qw/MMDB MMDC/;
my %dbformats=do { my $i=0; map {($_=>$i++)} @dbformats };

BEGIN {
  use constant {
    FORMATVERSION => 0,		# magic number position (in bytes)
    INTFMT        => 4,		# INTFMT byte position (in bytes)
    BASEOFFSET    => 8,
    MAINIDX       => 0,		# (in words (units of _intsize bytes))
    IDIDX         => 1,		# (in words)
    NEXTID        => 2,		# (in words)
    STRINGTBL     => 3,		# (in words)
    DATASTART     => 4,		# (in words)

    DBFMT0        => 0,		# MMDB format
    DBFMT1        => 1,		# MMDC format with utf8 support

    # iterator questions
    IT_NTH        =>0,		# reposition iterator
    IT_CUR        =>1, 		# what is the current index
    IT_NELEM      =>2,          # how many elements does it iterate over

    DATAMODE_NORMAL=>0,
    DATAMODE_SIMPLE=>1,

    E_READONLY    => \'database is read-only',
    E_TWICE       => \'can\'t insert the same ID twice',
    E_TRANSACTION => \'there is already an active transaction',
    E_FULL        => \'can\'t allocate ID',
    E_DUPLICATE   => \'data records cannot be mixed up with subindices',

    E_OPEN        => \'can\'t open file',
    E_READ        => \'can\'t read from file',
    E_WRITE       => \'can\'t write to file',
    E_CLOSE       => \'file could not be closed',
    E_RENAME      => \'can\'t rename file',
    E_SEEK        => \'can\'t move file pointer',
    E_TRUNCATE    => \'can\'t truncate file',
    E_LOCK        => \'can\'t (un)lock lockfile',
    E_RANGE       => \'attempt move iterator out of its range',
    E_NOT_IMPLEMENTED => \'function not implemented',
  };
}

#sub D {
#  use Data::Dumper;
#  local $Data::Dumper::Useqq=1;
#  warn Dumper @_;
#}

sub _putdata {
  my ($I, $pos, $fmt, @param)=@_;

  my $pstr=pack $fmt, @param;
  my $map=$I->_tmpmap;
  if( $pos+length($pstr)>length $$map ) {
    my $prea=$I->index_prealloc;
    my $need=$prea*(($pos+length($pstr)+$prea-1)/$prea);
    eval {
      my $fh=$I->_tmpfh;
      sysseek $fh, $need, SEEK_SET and
	truncate $fh, $need and
	  map_handle $$map, $fh, '+>', 0, $need;
    };
    $I->_e(E_OPEN) if $@;
  }
  substr $$map, $pos, length($pstr), $pstr;
  return length($pstr);
}

sub set_intfmt {
  my ($I, $fmt)=@_;

  $fmt='N' unless $fmt;

  my %allowed; undef @allowed{qw/L N J Q/};
  return unless exists $allowed{$fmt};

  $I->intfmt=$fmt;
  $I->_intsize=length pack($fmt, 0);

  if( $I->dbformat_in>DBFMT0 ) {
    # new format with utf8 support
    $I->_stringfmt=$I->intfmt.'/a*C x!'.$I->_intsize;
  } else {
    $I->_stringfmt=$I->intfmt.'/a* x!'.$I->_intsize;
  }

  if( $I->dbformat_out>DBFMT0 ) {
    # new format with utf8 support
    $I->_stringfmt_out=$I->intfmt.'/a*C x!'.$I->_intsize;
  } else {
    $I->_stringfmt_out=$I->intfmt.'/a* x!'.$I->_intsize;
  }

  return 1;
}

sub new {
  my ($parent, @param)=@_;
  my $I;

  if (ref $parent) {
    $I=bless [@$parent]=>ref($parent);
    for my $k (qw/_nextid _idmap _tmpfh _tmpname _stringfh _stringmap
		  _strpos main_index id_index/) {
      undef $I->$k;
    }
    if( defined $I->_data ) {
      # parameters: PARENT POS DATAMODE
      tie %{$I->main_index=+{}}, 'MMapDB::Index', $I, $I->mainidx, 0;
      tie %{$I->id_index=+{}}, 'MMapDB::IDIndex', $I, undef, 0;
    }
  } else {
    $I=bless []=>$parent;
    $I->set_intfmt('N');
    $I->flags=0;
    $I->dbformat_in=$#dbformats; # use the newest by default
    $I->dbformat_out=$#dbformats; # use the newest by default
  }
  $I->stringmap_prealloc=1024*1024*10; # 10MB
  $I->index_prealloc=1024*1024*10; # 10MB

  if( @param==1 ) {
    $I->filename=$param[0];
  } else {
    while( my ($k, $v)=splice @param, 0, 2 ) {
      $I->$k=$v if $k=$I->can($k);
    }
    $I->set_intfmt($I->intfmt) unless $I->intfmt eq 'N';
  }

  return $I;
}

sub is_valid {
  my ($I)=@_;

  return unless $I->_data;
  # the INTFMT field serves 2 ways:
  #  1) it specifies the used integer format
  #  2) it works as VALID flag. commit() write a NULL byte here
  #     to mark the old file as invalid.
  #     we must reconnect if our cached fmt does not match.
  return substr( ${$I->_data}, INTFMT, 1 ) eq $I->intfmt;
}

sub start {
  my ($I)=@_;

  $I->_e(E_TRANSACTION) if defined $I->_tmpfh;

  my $retry=5;
  RETRY: {
      return unless $retry--;
      $I->stop if (defined $I->_data and
		   substr( ${$I->_data}, INTFMT, 1 ) ne $I->intfmt);

      unless( $I->_data ) {
	my ($dummy, $fmt);
	my $fh;
	if( $I->readonly ) {
	  open $fh, '<', $I->filename or return;
	} else {
	  open $fh, '+<', $I->filename or return;
	}

	# Map the main data always read-only. If we are in writable mode
	# map only the header page again writable.
	eval {
	  map_handle $dummy, $fh, '<';
	};
	close $fh;
	return if $@;		# perhaps throw something here
	return unless length $dummy;

	# check magic number
	return unless exists $dbformats{substr($dummy, FORMATVERSION, 4)};
	$I->dbformat_out=$I->dbformat_in=
	  $dbformats{substr($dummy, FORMATVERSION, 4)};

	# read integer format
	$fmt=unpack 'x4a', $dummy;
	if( $fmt eq "\0" ) {
	  select undef, undef, undef, 0.1;
	  redo RETRY;
	}
	return unless $I->set_intfmt($fmt);

	# read the byte just after the format character
	$I->flags=unpack 'x5C', $dummy;

	$I->_data=\$dummy;		# now mapped

	# read main index position
	$I->mainidx=unpack('x'.(BASEOFFSET+MAINIDX*$I->_intsize).$I->intfmt,
			   ${$I->_data});
	$I->_ididx=unpack('x'.(BASEOFFSET+IDIDX*$I->_intsize).$I->intfmt,
			  ${$I->_data});
	$I->_stringtbl=unpack('x'.(BASEOFFSET+STRINGTBL*$I->_intsize).
			      $I->intfmt, ${$I->_data});

	# parameters: PARENT POS DATAMODE
	tie %{$I->main_index=+{}}, 'MMapDB::Index', $I, $I->mainidx, 0;
	tie %{$I->id_index=+{}}, 'MMapDB::IDIndex', $I, undef, 0;
      }
    }

  return $I;
}

sub stop {
  my ($I)=@_;

  $I->_e(E_TRANSACTION) if defined $I->_tmpfh;

  return $I unless defined $I->_data;

  for my $k (qw/_data _stringtbl mainidx _ididx/) {
    undef $I->$k;
  }

  untie %{$I->main_index}; undef $I->main_index;
  untie %{$I->id_index};   undef $I->id_index;

  return $I;
}

sub index_iterator {
  my ($I, $pos, $nth)=@_;

  my $data=$I->_data;
  return sub {} unless $data and defined $pos;
  my $fmt=$I->intfmt;
  my $isz=$I->_intsize;
  my ($nrecords, $recordlen)=unpack 'x'.$pos.$fmt.'2', $$data;
  die E_RANGE if $nth>$nrecords;
  $recordlen*=$isz;
  my ($cur, $end)=($pos+2*$isz+$nth*$recordlen,
		   $pos+2*$isz+$nrecords*$recordlen);
  my $stroff=$I->_stringtbl;
  my $sfmt=$I->_stringfmt;
  my $dbfmt=$I->dbformat_in;

  my $it=MMapDB::Iterator->new
    ( sub {
	if( @_ ) {
	  for( my $i=0; $i<@_; $i++ ) {
	    if( $_[$i]==IT_NTH ) {
	      my $nth=$_[++$i];
	      $nth=$pos+2*$isz+$nth*$recordlen;
	      die E_RANGE unless( $pos+2*$isz<=$nth and $nth<=$end );
	      $cur=$nth;
	      # return in VOID context
	      return unless defined wantarray;
	    } elsif( $_[$i]==IT_CUR ) {
	      return ($cur-2*$isz-$pos)/$recordlen;
	    } elsif( $_[$i]==IT_NELEM ) {
	      return ($end-2*$isz-$pos)/$recordlen;
	    }
	  }
	}
	return if $cur>=$end;
	my ($key, $npos)=unpack 'x'.$cur.$fmt.'2', $$data;
	my @list=unpack 'x'.($cur+2*$isz).$fmt.$npos, $$data;
	$cur+=$recordlen;
	if( $dbfmt>DBFMT0 ) {
	  my ($str, $utf8)=unpack('x'.($stroff+$key).$sfmt, $$data);
	  Encode::_utf8_on($str) if( $utf8 );
	  return ($str, @list);
	} else {
	  return (unpack('x'.($stroff+$key).$sfmt, $$data), @list);
	}
      }
    );

  return wantarray ? ($it, $nrecords) : $it;
}

sub id_index_iterator {
  my ($I)=@_;

  my $data=$I->_data;
  return sub {} unless $data;
  my $pos=$I->_ididx;
  my ($nrecords)=unpack 'x'.$pos.$I->intfmt, $$data;
  my $isz=$I->_intsize;
  my $recordlen=2*$isz;
  my ($cur, $end)=($pos+$isz,
		   $pos+$isz+$nrecords*$recordlen);
  my $fmt=$I->intfmt.'2';

  my $it=MMapDB::Iterator->new
    ( sub {
	if( @_ ) {
	  for( my $i=0; $i<@_; $i++ ) {
	    if( $_[$i]==IT_NTH ) {
	      my $nth=$_[++$i];
	      $nth=$pos+$isz+$nth*$recordlen;
	      die E_RANGE unless( $pos+$isz<=$nth and $nth<=$end );
	      $cur=$nth;
	      # return in VOID context
	      return unless defined wantarray;
	    } elsif( $_[$i]==IT_CUR ) {
	      return ($cur-$isz-$pos)/$recordlen;
	    } elsif( $_[$i]==IT_NELEM ) {
	      return ($end-$isz-$pos)/$recordlen;
	    }
	  }
	}
	return if $cur>=$end;
	my @l=unpack 'x'.$cur.$fmt, $$data;
	$cur+=$recordlen;
	return @l;
      }
    );

  return wantarray ? ($it, $nrecords) : $it;
}

sub is_datapos {
  my ($I, $pos)=@_;
  return $pos<$I->mainidx;
}

sub datamode : lvalue {
  tied(%{$_[0]->main_index})->datamode;
}

sub id_datamode : lvalue {
  tied(%{$_[0]->id_index})->datamode;
}

sub _e {$_[0]->_rollback; die $_[1]}
sub _ct {$_[0]->_tmpfh or die E_TRANSACTION}

sub begin {
  my ($I, $dbfmt)=@_;

  $I->_e(E_TRANSACTION) if defined $I->_tmpfh;

  die E_READONLY if $I->readonly;

  if( defined $I->lockfile ) {
    # open lockfile
    unless( ref $I->lockfile ) {
      open my $fh, '>', $I->lockfile or die E_OPEN;
      $I->lockfile=$fh;
    }
    flock $I->lockfile, LOCK_EX or die E_LOCK;
  }

  if (defined $dbfmt) {
    $I->dbformat_out=($dbfmt==-1 ? $#dbformats : $dbfmt);
  }
  $I->set_intfmt($I->intfmt);	# adjust string format

  $I->_tmpname=$I->filename.'.'.$$;

  {
    # open stringtbl tmpfile
    open my $fh, '+>', $I->_tmpname.'.strings' or die E_OPEN;
    $I->_stringfh=$fh;
    $I->_stringmap=\my $strings;
    eval {
      sysseek $fh, $I->stringmap_prealloc, SEEK_SET and
	truncate $fh, $I->stringmap_prealloc and
	  map_handle $strings, $fh, '+>', 0, $I->stringmap_prealloc;
    };
    die E_OPEN if $@;
    $I->_stringmap_end=0;
  }

  {
    # open tmpfile
    open my $fh, '+>', $I->_tmpname or die E_OPEN;
    $I->_tmpfh=$fh;		# this starts the transaction
    $I->_tmpmap=\do{my $map=''};

    $I->_putdata(0, 'a4aC', $dbformats[$I->dbformat_out], $I->intfmt,
		$I->flags & 0xff);
    $I->_index_end=BASEOFFSET+DATASTART*$I->_intsize;
  }

  # and copy every *valid* entry from the old file
  # create _idmap on the way
  $I->_idmap={};
  $I->_strpos=[];
  for( my $it=$I->iterator; my ($pos)=$it->(); ) {
    $I->insert($I->data_record($pos));
  }
  if( $I->_data ) {
    $I->_nextid=unpack('x'.(BASEOFFSET+NEXTID*$I->_intsize).$I->intfmt,
		       ${$I->_data});
  } else {
    $I->_nextid=1;
  }

  return $I;
}

# The interator() below hops over the mmapped area. This one works on the file.
# It can be used only within a begin/commit cycle.
sub _fiterator {
  my ($I, $end)=@_;

  my $map=$I->_tmpmap;
  my $pos=BASEOFFSET+$I->_intsize*DATASTART;

  return sub {
  LOOP: {
      return if $pos>=$end;
      my $elpos=$pos;

      # valid id nkeys key1...keyn sort data
      # read (valid, id, nkeys)
      my ($valid, $id, $nkeys)=unpack 'x'.$pos.$I->intfmt.'3', $$map;

      # move iterator position
      # 5: valid, id, nkeys ... sort, data
      $pos+=$I->_intsize*(5+$nkeys);
      redo LOOP unless ($valid);

      my @l=unpack 'x'.($elpos+3*$I->_intsize).$I->intfmt.($nkeys+2), $$map;
      my $data=pop @l;
      my $sort=pop @l;

      return ([\@l, $sort, $data, $id], $elpos);
    }
  };
}

sub _really_write_index {
  my ($I, $map, $level)=@_;

  my $recordlen=1;		# in ints: (1): for subindexes there is one
                                #          position to store

  # find the max. number of positions we have to store
  foreach my $v (values %$map) {
    if( ref($v) eq 'ARRAY' ) {
      # list of data records
      $recordlen=@$v if @$v>$recordlen;
    }
    # else: recordlen is initialized with 1. So for subindexes there is
    #       nothing to do
  }
  # each record comes with a header of 2 integers, the key position in the
  # string table and the actual position count of the record. So we have to
  # add 2 to $recordlen.
  $recordlen+=2;

  # the index itself has a 2 integer header, the recordlen and the number
  # of index records that belong to the index.
  my $indexsize=(2+$recordlen*keys(%$map))*$I->_intsize; # in bytes

  my $pos=$I->_index_end;

  # make room
  $I->_index_end=$pos+$indexsize;

  # and write subindices after this index
  my $strings=$I->_stringmap;
  my $sfmt=$I->_stringfmt_out;
  my $dbfmt=$I->dbformat_out;
  foreach my $v (values %$map) {
    if( ref($v) eq 'HASH' ) {
      # convert the subindex into a position list
      $v=[$I->_really_write_index($v, $level+1)];
    } else {
      # here we already have a position list but it still contains
      # sorting ids.
      @$v=map {
	$_->[1];
      } sort {
	$a->[0] cmp $b->[0];
      } map {
	# fetch sort string from string table
	if( $dbfmt>DBFMT0 ) {
	  my ($str, $utf8)=unpack('x'.$_->[0].$sfmt, $$strings);
	  Encode::_utf8_on($str) if $utf8;
	  [$str, $_->[1]];
	} else {
	  [unpack('x'.$_->[0].$sfmt, $$strings), $_->[1]];
	}
      } @$v;
    }
  }

  my $fmt=$I->intfmt;
  my $written=$pos;
  $written+=$I->_putdata($written, $fmt.'2', 0+keys(%$map), $recordlen);

  $fmt.=$recordlen;
  # write the records
  foreach my $key (map {
    $_->[0]
  } sort {
    $a->[1] cmp $b->[1];
  } map {
    if( $dbfmt>DBFMT0 ) {
      my ($str, $utf8)=unpack('x'.$_.$sfmt, $$strings);
      Encode::_utf8_on($str) if $utf8;
      [$_, $str];
    } else {
      [$_, unpack('x'.$_.$sfmt, $$strings)];
    }
  } keys %$map) {
    my $v=$map->{$key};

    #D($key, $v);
    #warn "$prefix> idx rec: ".unpack('H*', pack($fmt, $key, 0+@$v, @$v))."\n";

    $written+=$I->_putdata($written, $fmt, $key, 0+@$v, @$v);
  }

  return $pos;
}

sub _write_index {
  my ($I)=@_;

  my %map;
  for( my $it=$I->_fiterator($I->_index_end); my ($el, $pos)=$it->(); ) {
    my $m=\%map;
    my @k=@{$el->[0]};
    while(@k>1 and ref($m) eq 'HASH') {
      my $k=shift @k;
      $m->{$k}={} unless exists $m->{$k};
      $m=$m->{$k};
    }
    $I->_e(E_DUPLICATE) unless ref($m) eq 'HASH';
    $m->{$k[0]}=[] unless defined $m->{$k[0]};
    $I->_e(E_DUPLICATE) unless ref($m->{$k[0]}) eq 'ARRAY';
    # Actually we want to save only positions but they must be ordered.
    # So either keep the order field together with the position here to
    # sort it later or do sort of ordered insert here.
    # The former is simpler. So it's it.
    push @{$m->{$k[0]}}, [$el->[1], $pos];
  }

  return $I->_really_write_index(\%map, 0);
}

sub _write_id_index {
  my ($I)=@_;

  my $map=$I->_idmap;
  my $fmt=$I->intfmt;

  my $pos=$I->_index_end;
  my $written=$pos;
  $written+=$I->_putdata($written, $fmt, 0+keys(%$map));

  $fmt.='2';
  # write the records
  foreach my $key (sort {$a <=> $b} keys %$map) {
    my $v=$map->{$key};

    #warn "id> idx rec: ".unpack('H*', pack($fmt, $key, $v))."\n";

    $written+=$I->_putdata($written, $fmt, $key, $v);
  }
  $I->_index_end=$written;

  #warn sprintf "id> index written @ %#x\n", $pos;

  return $pos;
}

sub invalidate {
  my ($I)=@_;
  $I->_e(E_READONLY) if $I->readonly;
  return unless defined $I->_data;
  protect ${$I->_data}, '+<';
  substr( ${$I->_data}, INTFMT, 1, "\0" );
  protect ${$I->_data}, '<';
}

sub commit {
  my ($I, $dont_invalidate)=@_;

  $I->_ct;

  # write NEXTID
  $I->_putdata(BASEOFFSET+NEXTID*$I->_intsize, $I->intfmt, $I->_nextid);

  # write MAINIDX and IDIDX
  my $mainidx=$I->_write_index;
  my $ididx=$I->_write_id_index;

  $I->_putdata(BASEOFFSET+MAINIDX*$I->_intsize,   $I->intfmt, $mainidx);
  $I->_putdata(BASEOFFSET+IDIDX*$I->_intsize,     $I->intfmt, $ididx);
  $I->_putdata(BASEOFFSET+STRINGTBL*$I->_intsize, $I->intfmt, $I->_index_end);

  # now copy the string table
  my $fh=$I->_tmpfh;
  my $strings=$I->_stringmap;
  my $map=$I->_tmpmap;
  my $need=$I->_index_end+$I->_stringmap_end;
  if( $need>length $$map ) {
    eval {
      sysseek $fh, $need, SEEK_SET and
	truncate $fh, $need and
	  map_handle $$map, $fh, '+>', 0, $need;
    };
    $I->_e(E_OPEN) if $@;
  }
  substr($$map, $I->_index_end, $I->_stringmap_end,
	 substr($$strings, 0, $I->_stringmap_end));
  truncate $fh, $need;

  #warn "mainidx=$mainidx, ididx=$ididx, strtbl=$strtbl\n";

  undef $I->_idmap;
  undef $I->_strpos;
  undef $I->_stringmap;

  close $I->_stringfh or $I->_e(E_CLOSE);
  undef $I->_stringfh;
  unlink $I->_tmpname.'.strings';

  undef $I->_tmpmap;
  close $fh or $I->_e(E_CLOSE);
  undef $I->_tmpfh;

  # rename is (at least on Linux) an atomic operation
  rename $I->_tmpname, $I->filename  or $I->_e(E_RENAME);

  $I->invalidate unless $dont_invalidate;

  if( $I->lockfile ) {
    flock $I->lockfile, LOCK_UN or die E_LOCK;
  }

  $I->start;
}

sub _rollback {
  my ($I)=@_;

  close $I->_tmpfh;
  undef $I->_tmpfh;
  unlink $I->_tmpname;

  close $I->_stringfh;
  undef $I->_stringfh;
  unlink $I->_tmpname.'.strings';

  undef $I->_stringmap;
  undef $I->_strpos;
  undef $I->_idmap;

  $I->_stringfmt_out=$I->_stringfmt;
  $I->dbformat_out=$I->dbformat_in;

  if( $I->lockfile ) {
    flock $I->lockfile, LOCK_UN or die E_LOCK;
  }
}

sub rollback {
  my ($I)=@_;

  $I->_e(E_TRANSACTION) unless defined $I->_tmpfh;
  $I->_rollback;
}

sub DESTROY {
  my ($I)=@_;

  $I->_rollback if defined $I->_tmpfh;
  $I->stop;
}

sub backup {
  my ($I, $fn)=@_;

  $I->start;

  my $backup=$I->new(filename=>(defined $fn ? $fn : $I->filename.'.BACKUP'));

  $backup->begin;
  $backup->commit(1);
}

sub restore {
  my ($I, $fn)=@_;

  $I->start;
  $fn=$I->filename.'.BACKUP' unless defined $fn;

  # rename is (at least on Linux) an atomic operation
  rename $fn, $I->filename  or die E_RENAME;
  $I->invalidate;

  return $I->start;
}

# Returns the position of $key in the stringtable
# If $key is not found it is inserted. @{$I->_strpos} is kept ordered.
# So, we can do a binary search.
# This implements something very similar to a HASH. So, why not use a HASH?
# A HASH is kept completely in core and the memory is not returned to the
# operating system when finished. The number of strings in the database
# can become quite large. So if a long running process updates the database
# only once it will consume much memory for nothing. To avoid this we map
# the string table currently under construction in a separate file that
# is mmapped into the address space of this process and keep here only
# a list of pointer into this area. When the transaction is committed the
# memory is returned to the OS. But on the other hand we need fast access.
# This is achieved by the binary search.
sub _string2pos {
  my ($I, $key)=@_;

  my $fmt=$I->_stringfmt_out;
  my $dbfmt=$I->dbformat_out;

  Encode::_utf8_off($key) if $dbfmt==DBFMT0;

  my $strings=$I->_stringmap;
  my $poslist=$I->_strpos;

  my ($low, $high)=(0, 0+@$poslist);
  #warn "_string2pos($key): low=$low, high=$high\n";

  my ($cur, $rel, $curstr);
  while( $low<$high ) {
    $cur=($high+$low)/2;	# "use integer" is active, see above
    if( $dbfmt>DBFMT0 ) {
      ($curstr, my $utf8)=unpack 'x'.$poslist->[$cur].$fmt, $$strings;
      Encode::_utf8_on($curstr) if $utf8;
    } else {
      $curstr=unpack 'x'.$poslist->[$cur].$fmt, $$strings;
    }
    #warn "  --> looking at $curstr: low=$low, high=$high, cur=$cur\n";
    $rel=($curstr cmp $key);
    if( $rel<0 ) {
      #warn "  --> moving low: $low ==> ".($cur+1)."\n";
      $low=$cur+1;
    } elsif( $rel>0 ) {
      #warn "  --> moving high: $high ==> ".($cur)."\n";
      # don't try to optimize here: $high=$cur-1 will not work in border cases
      $high=$cur;
    } else {
      #warn "  --> BINGO\n";
      return $poslist->[$cur];
    }
  }
  #warn "  --> NOT FOUND\n";
  my $pos=$I->_stringmap_end;
  splice @$poslist, $low, 0, $pos;
  #warn "  --> inserting $pos into poslist at $low ==> @$poslist\n";

  my $newstr;
  if( $dbfmt>DBFMT0 ) {
    if( Encode::is_utf8($key) ) {
      $newstr=pack($fmt, Encode::encode_utf8($key), 1);
    } else {
      $newstr=pack($fmt, $key, 0);
    }
  } else {
    $newstr=pack($fmt, $key);
  }

  if( $pos+length($newstr)>length $$strings ) {
    # remap
    my $prea=$I->stringmap_prealloc;
    my $need=$prea*(($pos+length($newstr)+$prea-1)/$prea);
    eval {
      my $fh=$I->_stringfh;
      sysseek $fh, $need, SEEK_SET and
	truncate $fh, $need and
	  map_handle $$strings, $fh, '+>', 0, $need;
    };
    $I->_e(E_OPEN) if $@;
  }

  substr $$strings, $pos, length($newstr), $newstr;
  $I->_stringmap_end=$pos+length($newstr);

  return $pos;
}

sub insert {
  my ($I, $rec)=@_;
  #my ($I, $key, $sort, $data, $id)=@_;

  #use Data::Dumper; $Data::Dumper::Useqq=1; warn Dumper $rec;

  $I->_ct;

  $rec->[0]=[$rec->[0]] unless ref $rec->[0];
  for my $v (@{$rec}[1,2]) {
    $v='' unless defined $v;
  }

  # create new ID if necessary
  my $id=$rec->[3];
  my $idmap=$I->_idmap;
  if( defined $id ) {
    $I->_e(E_TWICE) if exists $idmap->{$id};
  } else {
    $id=$I->_nextid;
    undef $idmap->{$id};	# allocate it

    my $mask=do{no integer; unpack( $I->intfmt, pack $I->intfmt, -1 )>>1};
    my $nid=($id+1)&$mask;
    $nid=1 if $nid==0;
    while(exists $idmap->{$nid}) {
      $nid=($nid+1)&$mask; $nid=1 if $nid==0;
      $I->_e(E_FULL) if $nid==$id;
    }
    $I->_nextid=$nid;
  }

  my $pos=$I->_index_end;
  $I->_index_end+=$I->_putdata($pos, $I->intfmt.'*', 1, $id, 0+@{$rec->[0]},
			      map {$I->_string2pos($_)}
			      @{$rec->[0]}, @{$rec}[1,2]);

  $idmap->{$id}=$pos;

  return ($id, $pos);
}

sub delete_by_id {
  my ($I, $id, $return_element)=@_;

#   warn "delete_by_id($id)\n";

  # no such id
  return unless exists $I->_idmap->{$id};

  my $map=$I->_tmpmap;
  my $idmap=$I->_idmap;
  my $pos;

  return unless defined($pos=delete $idmap->{$id});

  # read VALID, ID, NKEYS
  my ($valid, $elid, $nkeys)=unpack 'x'.$pos.$I->intfmt.'3', $$map;

  return unless $valid;
  return unless $id==$elid; # XXX: should'nt that be an E_CORRUPT

  my $rc=1;
  if( $return_element ) {
    my $strings=$I->_stringmap;
    my $sfmt=$I->_stringfmt_out;
    my $dbfmt=$I->dbformat_out;
    my @l=map {
      if( $dbfmt>DBFMT0 ) {
	my ($str, $utf8)=unpack('x'.$_.$sfmt, $$strings);
	Encode::_utf8_on($str) if $utf8;
	$str;
      } else {
	unpack('x'.$_.$sfmt, $$strings);
      }
    } unpack('x'.($pos+3*$I->_intsize).$I->intfmt.($nkeys+2), $$map);

    my $rdata=pop @l;
    my $rsort=pop @l;

    $rc=[\@l, $rsort, $rdata, $id];
  }

  $I->_putdata($pos, $I->intfmt, 0); # invalidate the record

  return $rc;
}

sub clear {
  my ($I)=@_;

  $I->_ct;

  $I->_index_end=BASEOFFSET+DATASTART*$I->_intsize;
  $I->_stringmap_end=0;

  $I->_idmap={};
  $I->_strpos=[];

  return;
}

# sub xdata_record {
#   my ($I, $pos)=@_;

#   return unless $pos>0 and $pos<$I->mainidx;

#   # valid id nkeys key1...keyn sort data
#   my ($id, $nkeys)=unpack('x'.($pos+$I->_intsize).' '.$I->intfmt.'3',
# 			  ${$I->_data});

#   my $off=$I->_stringtbl;
#   my $data=$I->_data;
#   my $sfmt=$I->_stringfmt;
#   my @l=map {
#     unpack('x'.($off+$_).$sfmt, $$data);
#   } unpack('x'.($pos+3*$I->_intsize).' '.$I->intfmt.($nkeys+2), $$data);

#   my $rdata=pop @l;
#   my $rsort=pop @l;

#   #warn "data_record: keys=[@l], sort=$rsort, data=$rdata, id=$id\n";
#   return [\@l, $rsort, $rdata, $id];
# }

sub iterator {
  my ($I, $show_invalid)=@_;

  return sub {} unless $I->_data;

  my $pos=BASEOFFSET+DATASTART*$I->_intsize;
  my $end=$I->mainidx;

  return MMapDB::Iterator->new
    (sub {
       die E_NOT_IMPLEMENTED if @_;
     LOOP: {
	 return if $pos>=$end;

	 # valid id nkeys key1...keyn sort data
	 my ($valid, undef, $nkeys)=
	   unpack 'x'.$pos.' '.$I->intfmt.'3', ${$I->_data};

	 if( $valid xor $show_invalid ) {
	   my $rc=$pos;
	   $pos+=$I->_intsize*($nkeys+5); # 5=(valid id nkeys sort data)
	   return $rc;
	 }
	 $pos+=$I->_intsize*($nkeys+5); # 5=(valid id nkeys sort data)
	 redo LOOP;
       }
     });
}

package MMapDB::Iterator;

use strict;

sub new {
  my ($class, $func)=@_;
  $class=ref($class) || $class;
  return bless $func=>$class;
}

sub nth {
  return $_[0]->(MMapDB::IT_NTH, $_[1]);
}

sub cur {
  return $_[0]->(MMapDB::IT_CUR);
}

sub nelem {
  return $_[0]->(MMapDB::IT_NELEM);
}

#######################################################################
# High Level Accessor Classes
#######################################################################

{
  package
    MMapDB::_base;

  use strict;
  use Carp qw/croak/;
  use Scalar::Util ();
  use Exporter qw/import/;

  use constant ({
                 PARENT=>0,
                 POS=>1,
                 DATAMODE=>2,
                 ITERATOR=>3,
                 SHADOW=>4,
                });
  BEGIN {our @EXPORT=(qw!PARENT POS DATAMODE ITERATOR SHADOW!)};

  sub new {
    my ($class, @param)=@_;
    $class=ref($class) || $class;
    $param[DATAMODE]=0 unless defined $param[DATAMODE];
    Scalar::Util::weaken $param[0];
    return bless \@param=>$class;
  }

  sub readonly {croak "Modification of a read-only value attempted";}

  sub datamode : lvalue {$_[0]->[DATAMODE]}

  BEGIN {
    *TIEHASH=\&new;
    # STORE must be allowed to support constructs like this (with aliases):
    #   map {
    #     local $_;
    #   } values %{$db->main_index};
    # or
    #   for (values %{$db->main_index}) {
    #     local $_;
    #   }
    *STORE=sub {
      my ($I, $key, $value)=@_;
      my $el;
      my $ll=MMapDB::_localizing();
      # Carp::cluck "PL_localizing=$ll";

      $el=($I->[SHADOW]||={});
      my $sh;
      if( $ll==0 and $sh=$el->{$key} ) { # is already localized
        # warn "  ==> already shadowed";
        $sh->[1]=$value;
      } elsif( $ll==1 ) {
        # warn "  ==> shadowing";
        $sh=($el->{$key}||=[]);
        $sh->[0]++;
        $sh->[1]=$value;
      } elsif( $ll==2 ) {
        if( --$sh->[0] ) {
          # warn "  ==> decremented shadow counter";
          $sh->[1]=$value;
        } else {
          # warn "  ==> deleting shadow";
          delete $el->{$key};
        }
      } else {
        # warn "  ==> ro";
        goto &readonly;
      }
    };
    *DELETE=\&readonly;
    *CLEAR=\&readonly;

    *TIEARRAY=\&new;
    #*STORE=sub {};
    *STORESIZE=\&readonly;
    *EXTEND=\&readonly;
    #*DELETE=\&readonly;
    #*CLEAR=\&readonly;
    *PUSH=\&readonly;
    *UNSHIFT=\&readonly;
    *POP=\&readonly;
    *SHIFT=\&readonly;
    *SPLICE=\&readonly;
  }
}

#######################################################################
# Normal Index Accessor
#######################################################################

{
  package MMapDB::Index;

  use strict;
  BEGIN {MMapDB::_base->import}
  {our @ISA=qw/MMapDB::_base/}

  sub FETCH {
    my ($I, $key)=@_;

    {
      my $shel;
      $shel=$I->[SHADOW] and
        keys %$shel and
          $shel=$shel->{$key} and
            return $shel->[1];
    }

    my @el=$I->[PARENT]->index_lookup($I->[POS], $key);

    return unless @el;

    my $rc;

    if( @el==1 and $el[0]>=$I->[PARENT]->mainidx ) {
      # another index
      tie %{$rc={}}, ref($I), $I->[PARENT], $el[0], $I->[DATAMODE];
    } else {
      tie @{$rc=[]}, 'MMapDB::Data', $I->[PARENT], \@el, $I->[DATAMODE];
    }

    return $rc;
  }

  sub EXISTS {
    my ($I, $key)=@_;
    return $I->[PARENT]->index_lookup($I->[POS], $key) ? 1 : undef;
  }

  sub FIRSTKEY {
    my ($I)=@_;
    my @el=($I->[ITERATOR]=$I->[PARENT]->index_iterator($I->[POS]))->();
    return @el ? $el[0] : ();
  }

  sub NEXTKEY {
    my ($I)=@_;
    my @el=$I->[ITERATOR]->();
    return @el ? $el[0] : ();
  }

  sub SCALAR {
    my ($I)=@_;
    my $pos=defined $I->[POS] ? $I->[POS] : $I->[PARENT]->_ididx;
    my $n=unpack 'x'.$pos.$I->[PARENT]->intfmt,${$I->[PARENT]->_data};
    return $n==0 ? $n : "$n/$n";
  }
}

#######################################################################
# ID Index Accessor
#######################################################################

{
  package MMapDB::IDIndex;

  use strict;
  BEGIN {MMapDB::_base->import}
  {our @ISA=qw/MMapDB::Index/}

  sub FETCH {
    {
      my $shel;
      $shel=$_[0]->[SHADOW] and
        keys %$shel and
          $shel=$shel->{$_[1]} and
            return $shel->[1];
    }

    if( $_[0]->[DATAMODE]==MMapDB::DATAMODE_SIMPLE ) {
      $_[0]->[PARENT]->data_value($_[0]->[PARENT]->id_index_lookup($_[1]));
    } else {
      $_[0]->[PARENT]->data_record($_[0]->[PARENT]->id_index_lookup($_[1]));
    }
  }

  sub EXISTS {
    my ($I, $key)=@_;
    return $I->[PARENT]->id_index_lookup($key) ? 1 : undef;
  }

  sub FIRSTKEY {
    my ($I)=@_;
    my @el=($I->[ITERATOR]=$I->[PARENT]->id_index_iterator)->();
    return @el ? $el[0] : ();
  }
}

#######################################################################
# Data Accessor
#######################################################################

{
  package MMapDB::Data;

  use strict;
  BEGIN {MMapDB::_base->import}
  {our @ISA=qw/MMapDB::_base/}

  sub FETCH {
    my ($I, $idx)=@_;

    {
      my $shel;
      $shel=$I->[SHADOW] and
        keys %$shel and
          $shel=$shel->{$idx} and
            return $shel->[1];
    }

    return unless @{$I->[POS]}>$idx;
    if( $I->[DATAMODE]==MMapDB::DATAMODE_SIMPLE ) {
      return $I->[PARENT]->data_value($I->[POS]->[$idx]);
    } else {
      return $I->[PARENT]->data_record($I->[POS]->[$idx]);
    }
  }

  sub FETCHSIZE {scalar @{$_[0]->[POS]}}

  sub EXISTS {@{$_[0]->[POS]}>$_[1]}
}

1;
__END__

=encoding utf-8

=head1 NAME

MMapDB - a simple database in shared memory

=head1 SYNOPSIS

  use MMapDB qw/:error/;

  # create a database
  my $db=MMapDB->new(filename=>$path, intfmt=>'J');
  $db->start;       # check if the database exists and connect
  $db->begin;       # begin a transaction

  # insert something
  ($id, $pos)=$db->insert([[qw/main_key subkey .../],
                           $sort, $data]);
  # or delete
  $success=$db->delete_by_id($id);
  $just_deleted=$db->delete_by_id($id, 1);

  # or forget everything
  $db->clear;

  # make changes visible
  $db->commit;

  # or forget the transaction
  $db->rollback;

  # use a database
  my $db=MMapDB->new(filename=>$path);
  $db->start;

  # tied interface
  ($keys, $sort, $data, $id)=@{$db->main_index->{main_key}->{subkey}};
  $subindex=$db->main_index->{main_key};
  @subkeys=keys %$subindex;
  @mainkeys=keys %{$db->main_index};

  # or even
  use Data::Dumper;
  print Dumper($db->main_index); # dumps the whole database

  tied(%{$db->main_index})->datamode=DATAMODE_SIMPLE;
  print Dumper($db->main_index); # dumps only values

  # access by ID
  ($keys, $sort, $data, $id)=@{$db->id_index->{$id}};

  # fast access
  @positions=$db->index_lookup($db->mainidx, $key);
  if( @positions==1 and $positions[0] >= $db->mainidx ) {
    # found another index
    @positions=$db->index_lookup($positions[0], ...);
  } elsif(@positions) {
    # found a data record
    for (@positions) {
      ($keys, $sort, $data, $id)=@{$db->data_record($_)};

      or

      $data=$db->data_value($_);

      or

      $sort=$db->data_sort($_);
    }
  } else {
    # not found
  }

  # access by ID
  $position=$db->id_index_lookup($id);
  ($keys, $sort, $data, $id)=@{$db->data_record($position)};

  # iterate over all valid data records
  for( $it=$db->iterator; $pos=$it->(); ) {
    ($keys, $sort, $data, $id)=@{$db->data_record($pos)};
  }

  # or all invalid data records
  for( $it=$db->iterator(1); $pos=$it->(); ) {
    ($keys, $sort, $data, $id)=@{$db->data_record($pos)};
  }

  # iterate over an index
  for( $it=$db->index_iterator($db->mainidx);
       ($partkey, @positions)=$it->(); ) {
    ...
  }

  # and over the ID index
  for( $it=$db->id_index_iterator;
       ($id, $position)=$it->(); ) {
    ...
  }

  # disconnect from a database
  $db->stop;

=head1 DESCRIPTION

C<MMapDB> implements a database similar to a hash of hashes
of hashes, ..., of arrays of data.

It's main design goals were:

=over 4

=item * very fast read access

=item * lock-free read access for massive parallelism

=item * minimal memory consumption per accessing process

=item * transaction based write access

=item * simple backup, compactness, one file

=back

The cost of write access was unimportant and the expected database size was
a few thousands to a few hundreds of thousands data records.

Hence come 2 major decisions. Firstly, the database is completely mapped
into each process's address space. And secondly, a transaction writes the
complete database anew.

Still interested?

=head1 CONCEPTS

=head2 The data record

A data record consists of 3-4 fields:

 [[KEY1, KEY2, ..., KEYn], ORDER, DATA, ID]   # ID is optional

All of the C<KEY1>, ..., C<KEYn>, C<SORT> and C<DATA> are arbitrary length
octet strings. The key itself is an array of strings showing the way to
the data item. The word I<key> in the rest of this text refers to such
an array of strings.

Multiple data records can be stored under the same key. So, there is
perhaps an less-greater relationship between the data records. That's why
there is the C<ORDER> field. If the order field of 2 or more data records
are equal (C<eq>, not C<==>), their order is defined by the stability of
perl's C<sort> operation. New data records are always appended to the set
of records. So, if C<sort> is stable they appear at the end of a range of
records with the same C<ORDER>.

The C<DATA> field contains the data itself.

A data record in the database further owns an ID. The ID uniquely identifies
the data record. It is assigned when the record is inserted.

An ID is a fixed size number (32 or 64 bits) except 0. They are allocated
from 1 upwards. When the upper boundary is reached the next ID becomes 1
if it is not currently used.

=head2 The index record

An index record consists of 2 or more fields:

 (PARTKEY, POS1, POS2, ..., POSn)

C<PARTKEY> is one of the C<KEYi> that form the key of a data record. The
C<POSi> are positions in the database file that point to other indices
or data records. Think of such a record as an array of data records or
the leafes in the hash of hashes tree.

If an index record contains more than 1 positions they must all point to
data records. This way an ordered array of data records is formed. The position
order is determined by the C<ORDER> fields of the data records involved.

If the index record contains only one position it can point to another
index or a data record. The distiction is made by the so called I<main index>
position. If the position is lower it points to a data record otherwise
to an index.

=head2 The index

An index is a list of index records ordered by their C<PARTKEY>
field. Think of an index as a hash or a twig in the hash of hashes tree.
When a key is looked up a binary search in the index is performed.

There are 2 special indices, the main index and the ID index. The positions
of both of them are part of the database header. This fact is the only
thing that makes the main index special. The ID index is special also
because it's keys are IDs rather than strings.

=head2 The hash of hashes

To summarize all of the above, the following data structure displays the
logical structure of the database:

 $main_index={
               KEY1=>{
                       KEY11=>[[DATAREC1],
                               [DATAREC2],
                               ...],
                       KEY12=>[[DATAREC1],
                               [DATAREC2],
                               ...],
                       KEY13=>{
                                KEY131=>[[DATAREC1],
                                         [DATAREC2],
                                         ...],
                                KEY132=>...
                              },
                     },
               KEY1=>[[DATAREC1],
                      [DATAREC2],
                      ...]
             }

What cannot be expressed is an index record containing a pointer
to a data record and to another subindex, somthing like this:

  KEY=>[[DATAREC],
        {                     # INVALID
          SUBKEY=>...
        },
        [DATAREC],
        ...]

Note also, the root element is always a hash. The following is invalid:

 $main_index=[[DATAREC1],
              [DATAREC2],
              ...]

=head2 Accessing a database

To use a database it must be connected. Once connected a database
is readonly. You will always read the same values regardless of other
transactions that may have written the database.

The database header contains a flag that says if it is still valid or
has been replaced by a transaction. There is a method that checks this
flag and reconnects to the new version if necessary. The points when
to call this method depend on your application logic.

=head2 Accessing data

To access data by a key first thing the main index position is read from
the database header. Then a binary search is performed to look up the
index record that matches the first partial key. If it could be found
and there is no more partial key the position list is returned. If there
is another partial key but the position list points to data records the
key is not found. If the position list contains another index position
and there is another partial key the lookup is repeated on this index
with the next partial key until either all partial keys have been found
or one of them could not be found.

A method is provided to read a single data record by its position.

The index lookup is written in C for speed. All other parts are perl.

=head2 Transaction

When a transaction is started a new private copy of the database is
created. Then new records can be inserted or existing ones deleted.
While a transaction is active it is not possible to reconnect to the
database. This ensures that the transaction derives only from the data
that was valid when the transaction has begun.

Newly written data cannot be read back within the transaction. It becomes
visible only when the transaction is committed. So, one will always read
the state from the beginning of the transaction.

When a transaction is committed the public version is replaced by the
private one. Thus, the old database is deleted. But other processes
including the one performing the commit still have the old version still
mapped in their address space. At this point in time new processes will
see the new version while existing see the old data. Therefore a flag
in the old memory mapped database is written signaling that is has become
invalid. The atomicity of this operation depends on the atomicity of
perls C<rename> operation. On Linux it is atomic in a sense that there is
no point in time when a new process won't find the database file.

A lock file can be used to serialize transactions.

=head2 The integer format

All numbers and offsets within the database are written in a certain
format (byte order plus size). When a database is created the format
is written to the database header and cannot be changed afterwards.

Perl's C<pack> command defines several ways of encoding integer numbers.
The database format is defined by one of these pack format letters:

=over 4

=item * L

32 bit in native byte order.

=item * N

32 bit in big endian order. This format should be portable.

=item * J

32 or 64 bit in native byte order.

=item * Q

64 bit in native byte order. But is not always implemented.

=back

=head2 Iterators

Some C<MMapDB> methods return iterators. An iterator is a blessed function
reference (also called closure) that if called returns one item at a time.
When there are no more items an empty list or C<undef> is returned.

If you haven't heard of this concept yet perl itself has an iterator
attached to each hash. The C<each> operation returns a key/value pair
until there is no more.

Iterators are mainly used this way:

  $it=$db->...;       # create an iterator
  while( @item=$it->() ) {
    # use @item
  }

As mentioned, iterators are also objects. They have methods to fetch the
number of elements they will traverse or to position the iterator to a
certain element.

=head2 Error Conditions

Some programmers believe exceptions are the right method of error reporting.
Other think it is the return value of a function or method.

This modules somehow divides errors in 2 categories. A key that could not
be found for example is a normal result not an error. However, a disk full
condition or insufficient permissions to create a file are errors. This
kind of errors are thrown as exceptions. Normal results are returned through
the return value.

If an exception is thrown in this module C<$@> will contain a scalar reference.
There are several errors defined that can be imported into the using
program:

  use MMapDB qw/:error/;  # or :all

The presence of an error is checked this way (after C<eval>):

  $@ == E_TRANSACTION

Human readable error messages are provided by the scalar C<$@> points to:

  warn ${$@}

=head3 List of error conditions

=over 4

=item * E_READONLY

database is read-only

=item * E_TWICE

attempt to insert the same ID twice

=item * E_TRANSACTION

attempt to begin a transaction while there is one active

=item * E_FULL

no more IDs

=item * E_DUPLICATE

data records cannot be mixed up with subindices

=item * E_OPEN

can't open file

=item * E_READ

can't read from file

=item * E_WRITE

can't write to file

=item * E_CLOSE

file could not be closed

=item * E_RENAME

can't rename file

=item * E_SEEK

can't move file pointer

=item * E_TRUNCATE

can't truncate file

=item * E_LOCK

can't lock or unlock

=item * E_RANGE

attempt move an iterator position out of its range

=item * E_NOT_IMPLEMENTED

function not implemented

=back

=head2 UTF8

As of version 0.07 C<MMapDB> supports UTF8 data. What does that mean?

For each string perl maintains a flag that says whether the string is stored
in UTF8 or not. C<MMapDB> stores and retrieves this flag along with the string
itself.

For example take the string C<"\320\263\321\200\321\203\321\210\320\260">.
With the UTF8 flag unset it is just a bunch of octets. But if the flag is
set the string suddenly becomes these characters
C<"\x{433}\x{440}\x{443}\x{448}\x{430}"> or C<груша> which means C<pear>
in Russian.

Note, with the flag unset the length of our string is 10 which is the number
of octets. But if the flag is set it is 5 which is the number of characters.

So, although the octet sequences representing both strings (with and
without the flag) equal the strings themselves differ.

With C<MMapDB>, if something is stored under an UTF8 key it can be retrieved
also only by the UTF8 key.

There is a subtle point here, what if the UTF8 flag is set for a string
consisting of ASCII-only characters? In Perl th following expression is true:

 'hello' eq Encode::decode_utf8('hello')

The first C<hello> is a string the the UTF8 flag unset. It is compared with
the same sequence of octets with the UTF8 flag set.

C<MMapDB> up to version 0.11 (including) considered those 2 strings different.
That bug has been fixed in version 0.12.

=head2 The database format

With version 0.07 UTF8 support was introduced into C<MMapDB>. This required
a slight change of the database on-disk format. Now the database format
is encoded in the magic number of the database file. By now there are 2
formats defined:

=over 4

=item * Format 0 --> magic number: MMDB

=item * Format 1 --> magic number: MMDC

=back

C<MMapDB> reads and writes both formats. By default new databases are written
in the most up-to-date format and the format of existing ones is not changed.

If you want to write a certain format for a new database or convert an
existing database to an other format specify it as parameter to the
C<begin()> method.

If you want to write the newest format use C<-1> as format specifier.

=head1 METHODS

=head2 $dh=MMapDB-E<gt>new( KEY=E<gt>VALUE, ... )

=head2 $new=$db-E<gt>new( KEY=E<gt>VALUE, ... )

=head2 $dh=MMapDB-E<gt>new( $filename )

=head2 $new=$db-E<gt>new( $filename )

creates or clones a database handle. If there is an active transaction
it is rolled back for the clone.

If only one parameter is passed it is taken as the database filename.

Otherwise parameters are passed as (KEY,VALUE) pairs:

=over 4

=item * filename

specifies the database file

=item * lockfile

specify a lockfile to serialize transactions. If given at start of a
transaction the file is locked using C<flock> and unlocked at commit
or rollback time. The lockfile is empty but must not be deleted. Best
if it is created before first use.

If C<lockfile> ommitted C<MMapDB> continues to work but it is possible
to begin a new transaction while another one is active in another process.

=item * intfmt

specifies the integer format. Valid values are C<N> (the default), C<L>,
C<J> and C<Q> (not always implemented). When opening an existing database
this value is overwritten by the database format.

=item * readonly

if passed a true value the database file is mapped read-only. That means
the accessing process will receive a SEGV signal (on UNIX) if some stray
pointer wants to write to this area. At perl level the variable is marked
read-only. So any read access at perl level will not generate a segmentation
fault but instead a perl exception.

=back

=head2 $success=$db-E<gt>set_intfmt(LETTER)

sets the integer format of an existing database handle. Do not call this
while the handle is connected to a database.

=head2 $db-E<gt>filename

=head2 $db-E<gt>readonly

=head2 $db-E<gt>intfmt

those are accessors for the attributes passed to the constructor. They can
also be assigned to (C<$db-E<gt>filename=$new_name>) but only before
a database is connected to. C<intfmt> must be set using C<set_intfmt()>.

=head2 $success=$db-E<gt>start

(re)connects to the database. This method maps the database file and checks
if it is still valid. This method cannot be called while a transaction
is active.

If the current database is still valid or the database has been successfully
connected or reconnected the database object is returned. C<undef> otherwise.

There are several conditions that make C<start> fail:

=over 4

=item * $db-E<gt>filename could not be opened

=item * the file could not be mapped into the address space

=item * the file is empty

=item * the magic number of the file does not match

=item * the integer format indentifier is not valid

=back

=head2 $success=$db-E<gt>stop

disconnects from a database.

=head2 $success=$db-E<gt>begin

=head2 $success=$db-E<gt>begin($dbformat)

begins a transaction. Returns the database object.

If the C<$dbformat> parameter is ommitted the database format is unchanged.

If C<0> is given the database is written in C<MMDB> format. If C<1> is given
C<MMDC> format is written.

If C<-1> is given always the newest format is written.

=head2 $db-E<gt>index_prealloc

=head2 $db-E<gt>stringmap_prealloc

When a transaction is begun 2 temporary files are created, one for the
index and data records the other for the string table. These files are
then mapped into the process' address space for faster access.

C<index_prealloc> and C<stringmap_prealloc> define the initial sizes of
these files. The files are created as sparse files. The actual space is
allocated on demand. By default both these values are set to C<10*1024*1024>
which is ten megabytes.

When the space in one of the areas becomes insufficient it is extented and
remapped in chunks of C<index_prealloc> and C<stringmap_prealloc> respectively.

You should change the default values only for really big databases:

 $db->index_prealloc=100*1024*1024;
 $db->stringmap_prealloc=100*1024*1024;

=head2 $success=$db-E<gt>commit

=head2 $success=$db-E<gt>commit(1)

commits a transaction and reconnects to the new version.

Returns the database object it the new version has been connected.

If a true value is passed to this message the old database version is
not invalidated. This makes it possible to safely create a copy for backup
this way:

  my $db=MMapDB->new(filename=>FILENAME);
  $db->start;
  $db->filename=BACKUPNAME;
  $db->begin;
  $db->commit(1);

or

  my $db=MMapDB->new(filename=>FILENAME);
  $db->start;
  my $backup=$db->new(filename=>BACKUP);
  $backup->begin;
  $backup->commit(1);

=head2 $success=$db-E<gt>rollback

forgets about the current transaction

=head2 $db-E<gt>is_valid

returns true if a database is connected an valid.

=head2 $db-E<gt>invalidate

invalidates the current version of the database. This is normally called
internally by C<commit> as the last step. Perhaps there are also other
uses.

=head2 $db-E<gt>backup(BACKUPNAME)

creates a backup of the current database version called C<BACKUPNAME>.
It works almost exactly as shown in L<commit|/$success=$db-E<gt>commit(1)>.
Note, C<backup> calls C<$db-E<gt>start>.

If the C<filename> parameter is ommitted the result of appending the
C<.BACKUP> extension to the object's C<filename> property is used.

=head2 $db-E<gt>restore(BACKUPNAME)

just the opposite of C<backup>. It renames C<BACKUPNAME> to
C<$db-E<gt>filename> and invalidates the current version. So, the backup
becomes the current version. For other processes running in parallel this
looks just like another transaction being committed.

=head2 $db->dbformat_in

=head2 $db->dbformat_out

when a database is newly created it is written in the format passed to
the C<begin()> method. When it is connected later via C<start()>
C<dbformat_in()> contains this format. So, a database user can check
if a database file meets his expectations.

Within a transaction C<dbformat_out()> contains the format of the database
currently being written.

=head2 $db->flags

contains a number in the range between 0 and 255 that represents the C<flags>
byte of the database.

It is written to the database file by the C<begin()> method and read by
C<start()>.

Using this field is not recommended. It is considered experimental and may
disappear in the future.

=head2 @positions=$db-E<gt>index_lookup(INDEXPOS, KEY1, KEY2, ...)

looks up the key C<[KEY1, KEY2, ...]> in the index given by its position
C<INDEXPOS>. Returns a list of positions or an empty list if the complete
key is not found.

If C<INDEXPOS> is C<0> or C<undef> C<< $db->mainidx >> is used.

To check if the result is a data record array or another index use this code:

  if( @positions==1 and $positions[0] >= $db->mainidx ) {
    # found another index
    # the position can be passed to another index_lookup()
  } elsif(@positions) {
    # found a data record
    # the positions can be passed to data_record()
  } else {
    # not found
  }

=head2 ($idxpos, $nth)=$db-E<gt>index_lookup_position(INDEXPOS, KEY1, ...)

This method behaves similar to
L<< index_lookup()|/@positions=$db->index_lookup(INDEXPOS, KEY1, KEY2, ...) >>
in that it looks up a key. It differs in

=over 4

=item *

It returns the position of the index containing the last key element
and the position of the found element within that index. These 2 numbers
can be used to create and position an
L<< iterator|/$it=$db->id_index_iterator >>.

=item *

The last key element may not exist. In this case the value returned as C<$nth>
points to the index element before which the key would appear.

=item *

If an intermediate key element does not exist or is not an index an empty
list is returned.

=back

Consider the following database:

 {
   key => {
            aa => ['1'],
            ab => ['2'],
            ad => ['3'],
          }
 }

Now let's define an accessor function:

 sub get {
   my ($subkey)=@_;

   $db->data_value
     ((
       $db->index_iterator
         ($db->index_lookup_position($db->mainidx, "key", $subkey))->()
      )[1])
 }

Then

 get "aa";    # returns '1'
 get "ab";    # returns '2'
 get "ac";    # returns '3' although key "ac" does not exist it would
              #             show up between "ab" and "ad". So, the iterator
              #             is positioned on "ad"
 get "aba";   # returns '3' for the same reason
 get "ad";    # returns '3'

 (undef, $nth)=$db->index_lookup_position($db->mainidx, "key", "az");
 # now $nth is 3 because "az" would be inserted after "ad" which is at
 # position 2 within the index.

If C<INDEXPOS> is C<0> or C<undef> C<< $db->mainidx >> is used.

=head2 $position=$db-E<gt>id_index_lookup(ID)

looks up a data record by its ID. Returns the data record's position.

=head2 $boolean=$db-E<gt>is_datapos(POS)

returns true if C<$pos> points to the data record space.

This method is simply a shortcut for

  $pos < $db->mainidx

A true result does not mean it is safe to use C<$pos> in C<data_record()>.

=head2 @recs=$db-E<gt>data_record(POS, ...)

given a list of positions fetches the data records. Each C<@recs> element is
an array reference with the following structure:

  [[KEY1, KEY2, ...], SORT, DATA, ID]

All of the C<KEYs>, C<SORT> and C<DATA> are read-only strings.

=head2 @values=$db-E<gt>data_value(POS, ...)

similar to L<data_record()|/@recs=$db-E<gt>data_record(POS, ...)> but returns
only the C<DATA> fields of the records. Faster than
L<data_record()|/@recs=$db-E<gt>data_record(POS, ...)>.

See L</The MMapDB::Data class> for an example.

=head2 @sorts=$db-E<gt>data_sort(POS, ...)

similar to L<data_record()|/@recs=$db-E<gt>data_record(POS, ...)> but returns
only the C<SORT> fields of the records. Faster than
L<data_record()|/@recs=$db-E<gt>data_record(POS, ...)>.

=head2 @records=$db-E<gt>index_lookup_records(INDEXPOS, KEY1, KEY2, ...)

a more effective shortcut of

 @records=$db->data_record($db->index_lookup((INDEXPOS, KEY1, KEY2, ...)))

=head2 @values=$db-E<gt>index_lookup_values(INDEXPOS, KEY1, KEY2, ...)

a more effective shortcut of

 @records=$db->data_value($db->index_lookup((INDEXPOS, KEY1, KEY2, ...)))

=head2 @sorts=$db-E<gt>index_lookup_sorts(INDEXPOS, KEY1, KEY2, ...)

a more effective shortcut of

 @records=$db->data_sort($db->index_lookup((INDEXPOS, KEY1, KEY2, ...)))

=head2 $it=$db-E<gt>iterator

=head2 $it=$db-E<gt>iterator(1)

perhaps you want to iterate over all data records in a database.
The iterator returns a data record position:

  $position=$it->()

If a true value is passed as parameter only deleted records are found
otherwise only valid ones.

C<$it> is an L<MMapDB::Iterator|/"The C<MMapDB::Iterator> class"> object.
Invoking any method on this iterator results in a C<E_NOT_IMPLEMENTED>
exception.

=head2 $it=$db-E<gt>index_iterator(POS, NTH)

=head2 ($it, $nitems)=$db-E<gt>index_iterator(POS, NTH)

iterate over an index given by its position. The iterator returns
a partial key and a position list:

  ($partkey, @positions)=$it->()

If called in array context the iterator and the number of items it will
iterate is returned.

The optional C<NTH> parameter initially positions the iterator within
the index as L<< MMapDB::Iterator->nth|/$it->nth($n) >> does.

C<index_iterator()> can be used in combination with
L<< index_lookup_position()|/($idxpos, $nth)=$db->index_lookup_position(INDEXPOS, KEY1, ...) >>
to create and position an iterator:

 $it=$db->index_iterator($db->index_lookup_position($db->mainidx, qw/key .../));

C<$it> is an L<MMapDB::Iterator|/"The C<MMapDB::Iterator> class"> object.

=head2 $it=$db-E<gt>id_index_iterator

=head2 ($it, $nitems)=$db-E<gt>id_index_iterator

iterate over the ID index. The iterator returns 2 elements, the ID
and the data record position:

  ($id, $position)=$it->()

If called in array context the iterator and the number of items it will
iterate is returned.

C<$it> is an L<MMapDB::Iterator|/"The C<MMapDB::Iterator> class"> object.

=head2 ($id, $pos)=$db-E<gt>insert([[KEY1, KEY2, ....], SORT, DATA])

=head2 ($id, $pos)=$db-E<gt>insert([[KEY1, KEY2, ....], SORT, DATA, ID])

insert a new data record into the database. The ID parameter is optional
and should be ommitted in most cases. If it is ommitted the next available
ID is allocated and bound to the record. The ID and the position in the
new database version are returned. Note, that the position cannot be used
as parameter to the C<data_record> method until the transaction is
committed.

=head2 $success=$db-E<gt>delete_by_id(ID)

=head2 ($keys, $sort, $data, $id)=@{$db-E<gt>delete_by_id(ID, 1)}

delete an data record by its ID. If the last parameter is true the
deleted record is returned if there is one. Otherwise only a status
is returned whether a record has been deleted by the ID or not.

=head2 $db-E<gt>clear

deletes all data records from the database.

=head2 $pos=$db-E<gt>mainidx

returns the main index position. You probably need this as parameter
to C<index_lookup()>.

=head2 $hashref=$db-E<gt>main_index

This is an alternative way to access the database via tied hashes.

  $db->main_index->{KEY1}->{KEY2}->[0]

returns almost the same as

  $db->data_record( ($db->index_lookup($db->mainidx, KEY1, KEY2))[0] )

provided C<[KEY1, KEY2]> point to an array of data records.

While it is easier to access the database this way it is also much slower.

See also L</The MMapDB::Index and MMapDB::IDIndex classes>

=head2 $db-E<gt>datamode=$mode or $mode=$db-E<gt>datamode

Set/Get the datamode for C<< %{$db->main_index} >>.

See also L</The MMapDB::Index and MMapDB::IDIndex classes>

=head2 $hashref=$db-E<gt>id_index

The same works for indices:

  $db->id_index->{42}

returns almost the same as

  $db->data_record( $db->id_index_lookup(42) )

See also L</The MMapDB::Index and MMapDB::IDIndex classes>

=head2 $db-E<gt>id_datamode=$mode or $mode=$db-E<gt>id_datamode

Set/Get the datamode for C<< %{$db->id_index} >>.

See also L</The MMapDB::Index and MMapDB::IDIndex classes>

=head1 The C<MMapDB::Index> and C<MMapDB::IDIndex> classes

C<< $db->main_index >> and C<< $db->id_index >> elements are initialized
when C<< $db->start >> is called. They simply point to empty anonymous hashes.
These hashes are then tied to these classes.

Now if a hash value is accessed the C<FETCH> function of the tied object
checks whether the element points to another index (that means another hash)
or to a list of data records.
The C<< $db->id_index >> hash elements are always data records. So, there is
nothing to decide here.

If an index is found the reference of another anonymous hash is returned.
This hash itself is again tied to a C<MMapDB::Index> object. If a
list of data records is found the reference of an anonymous array is
returned. The array itself is tied to  a C<MMapDB::Data> object.

All 3 classes, C<MMapDB::Index>, C<MMapDB::IDIndex> and C<MMapDB::Data>
have a property called C<datamode>. When a C<MMapDB::Index> object
creates a new C<MMapDB::Index> or C<MMapDB::Data> object it passes
its datamode on.

The datamode itself is either C<DATAMODE_NORMAL> or C<DATAMODE_SIMPLE>.
It affects only the behavior of a C<MMapDB::Data> object. But since it
is passed on setting it for say C<< tied(%{$db->main_index}) >>
affects all C<MMapDB::Data> leaves created afterwards.

=head1 The C<MMapDB::Data> class

When a list of data records is found by a C<MMapDB::Index> or
C<MMapDB::IDIndex> object it is tied to an instance of C<MMapDB::Data>.

The individual data records can be read in 2 modes C<DATAMODE_NORMAL>
and C<DATAMODE_SIMPLE>. In normal mode the record is read with
C<< $db->data_record >>, in simple mode with C<< $db->data_value >>.

The following example shows the difference:

Create a database with a few data items:

 my $db=MMapDB->new("mmdb");
 $db->start; $db->begin;
 $db->insert([["k1", "k2"], "0", "data1"]);
 $db->insert([["k1", "k2"], "1", "data2"]);
 $db->insert([["k2"], "0", "data3"]);
 $db->commit;

Now, in C<DATAMODE_NORMAL> it looks like:

 {
   k1 => {
	   k2 => [
		   [['k1', 'k2'], '0', 'data1', 1],
		   [['k1', 'k2'], '1', 'data2', 2],
		 ],
	 },
   k2 => [
	   [['k2'], '0', 'data3', 3],
	 ],
 }

Now, we set C<< $db->datamode=DATAMODE_SIMPLE >> and it looks like:

 {
   k1 => {
           k2 => ['data1', 'data2'],
         },
   k2 => ['data3'],
 }

=head1 The C<MMapDB::Iterator> class

To this class belong all iterators documented here. An iterator is mainly
simply called as function reference to fetch the next element:

 $it->();

But sometimes one wants to reposition an iterator or ask it a question. Here
this class comes into play.

Some iterators don't implement all of the methods. In this case an
C<E_NOT_IMPLEMENTED> exception is thrown.

The index and id-index iterators implement all methods.

=head2 $it-E<gt>nth($n)

=head2 @el=$it-E<gt>nth($n)

If called in void context the iterator position is moved to the C<$n>'th
element. The element read by the next C<< $it->() >> call will be this one.

If called in other context the iterator position is moved to the C<$n>'th
element which then is returned. The next C<< $it->() >>
call will return the C<($n+1)>'th element.

An attempt to move the position outside its boundaries causes an
C<E_RANGE> exception.

=head2 $it-E<gt>cur

returns the current iterator position as an integer starting at C<0> and
counting upwards by C<1> for each element.

=head2 $it-E<gt>nelem

returns the number of elements that the iterator will traverse.

=head1 INHERITING FROM THIS MODULE

An C<MMapDB> object is internally an array. If another module want to
inherit from C<MMapDB> and needs to add other member data it can add
elements to the array. C<@MMapDB::attributes> contains all attribute
names that C<MMapDB> uses.

To add to this list the following scheme is recommended:

 package MMapDB::XX;
 use MMapDB;
 our @ISA=('MMapDB');
 our @attributes;

 # add attribute accessors
 BEGIN {
   @attributes=(@MMapDB::attributes, qw/attribute1 attribute2 .../);
   for( my $i=@MMapDB::attributes; $i<@attributes; $i++ ) {
     my $method_num=$i;
     no strict 'refs';
     *{__PACKAGE__.'::'.$attributes[$method_num]}=
	sub : lvalue {$_[0]->[$method_num]};
   }
 }

Now an C<MMapDB::XX> object can call C<< $obj->filename >> to get the
C<MMapDB> filename attribute or C<< $obj->attribute1 >> to get its own
C<attribute1>.

If another module then wants to inherit from C<MMapDB::XX> it uses

   @attributes=(@MMapDB::XX::attributes, qw/attribute1 attribute2 .../);
   for( my $i=@MMapDB::XX::attributes; $i<@attributes; $i++ ) {
     ...
   }

Multiple inheritance is really tricky this way.

=head1 EXPORT

None by default.

Error constants are imported by the C<:error> tag.

C<DATAMODE_SIMPLE> is imported by the C<:mode> tag.

All constants are imported by the C<:all> tag.

=head1 READ PERFORMANCE

The C<t/002-benchmark.t> test as the name suggests is mainly about
benchmarking. It is run only if the C<BENCHMARK> environment
variable is set. E.g. on a C<bash> command line:

 BENCHMARK=1 make test

It creates a
database with 10000 data records in a 2-level hash of hashes structure.
Then it finds the 2nd level hash with the largest number of elements and
looks for one of the keys there.

This is done for each database format using both C<index_lookup> and
the tied interface. For comparison 2 perl hash lookups are also
measured:

 sub {(sub {scalar @{$c->{$_[0]}->{$_[1]}}})->($k1, $k2)};
 sub {scalar @{$c->{$k1}->{$k2}}};

As result you can expect something like this:

             Rate mmdb_L mmdb_N mmdb_Q mmdb_J hash1 idxl_N idxl_Q idxl_J idxl_L hash2
 mmdb_L   41489/s     --    -0%    -1%    -1%  -89%   -92%   -93%   -93%   -93%  -99%
 mmdb_N   41696/s     1%     --    -0%    -1%  -89%   -92%   -93%   -93%   -93%  -99%
 mmdb_Q   41755/s     1%     0%     --    -1%  -89%   -92%   -93%   -93%   -93%  -99%
 mmdb_J   42011/s     1%     1%     1%     --  -89%   -92%   -93%   -93%   -93%  -99%
 hash1   380075/s   816%   812%   810%   805%    --   -31%   -32%   -33%   -33%  -87%
 idxl_N  548741/s  1223%  1216%  1214%  1206%   44%     --    -2%    -3%    -4%  -81%
 idxl_Q  560469/s  1251%  1244%  1242%  1234%   47%     2%     --    -1%    -2%  -81%
 idxl_J  568030/s  1269%  1262%  1260%  1252%   49%     4%     1%     --    -0%  -81%
 idxl_L  570717/s  1276%  1269%  1267%  1258%   50%     4%     2%     0%     --  -81%
 hash2  2963100/s  7042%  7006%  6996%  6953%  680%   440%   429%   422%   419%    --

The C<mmdb> tests use the tied interface. C<idxl> means C<index_lookup>.
C<hash1> is the first of the 2 perl hash lookups above, C<hash2> the 2nd.

C<hash2> is naturally by far the fastest. But add one anonymous function level and
C<idxl> becomes similar. Further, the C<N> format on this machine requires
byte rearrangement. So, it is expected to be slower. But it differs only in
a few percents from the other C<idxl>.

=head1 BACKUP AND RESTORE

The database consists only of one file. So a backup is in principle a
simple copy operation. But there is a subtle pitfall.

If there are writers active while the copy is in progress it may become
invalid between the opening of the database file and the read of the first
block.

So, a better way is this:

 perl -MMMapDB -e 'MMapDB->new(filename=>shift)->backup' DATABASENAME

To restore a database use this one:

 perl -MMMapDB -e 'MMapDB->new(filename=>shift)->restore' DATABASENAME

See also L<< backup()|/$db->backup(BACKUPNAME) >> and
L<< restore()|/$db->restore(BACKUPNAME) >>

=head1 DISK LAYOUT

In this paragraph the letter I<S> is used to designate a number of 4 or 8
bytes according to the C<intfmt>. The letter I<F> is used as a variable
holding that format. So, when you see C<F/a*> think C<N/a*> or C<Q/a*>
etc. according to C<intfmt>.

If an integer is used somewhere in the database it is aligned correctly.
So, 4-byte integer values are located at positions divisible by 4 and
8-byte integers are at positions divisible by 8. This also requires strings
to be padded up to the next divisible by 4 or 8 position.

Strings are always packed as C<F/a*> and padded up to the next S byte
boundary. With C<pack> this can be achieved with C<F/a* x!S> where C<F>
is one of C<N>, C<L>, C<J> or C<Q> and C<S> either 4 or 8.

The database can be divided into a few major sections:

=over 4

=item * the database header

=item * the data records

=item * the indices

=item * the string table

=back

=head2 Differences between database format 0 and 1

Format 0 and 1 are in great parts equal. Only the database header and the
string table entry slightly differ.

=head2 The database header

=head3 Database Format 0

At start of each database comes a descriptor:

 +----------------------------------+
 | MAGIC NUMBER (4 bytes) == 'MMDB' |
 +----------------------------------+
 | FORMAT (1 byte) + 3 bytes resrvd |
 +----------------------------------+
 | MAIN INDEX POSITION (S bytes)    |
 +----------------------------------+
 | ID INDEX POSITION (S bytes)      |
 +----------------------------------+
 | NEXT AVAILABLE ID (S bytes)      |
 +----------------------------------+
 | STRING TABLE POSITION (S bytes)  |
 +----------------------------------+

The magic number always contains the string C<MMDB>. The C<FORMAT> byte
contains the C<pack> format letter that describes the integer format of the
database. It corresponds to the C<intfmt> property. When a database becomes
invalid a NULL byte is written at this location.

L<Main Index position|/The Index> is the file position just after all
data records where the main index resides.

L<ID Index|/The Index> is the last index written to the file. This field
contains its position.

The C<NEXT AVAILABLE ID> field contains the next ID to be allocated.

The C<STRING TABLE POSITION> keeps the offset of the string table at the end
of the file.

=head3 Database Format 1

At start of each database comes a descriptor:

 +----------------------------------+
 | MAGIC NUMBER (4 bytes) == 'MMDC' |
 +----------------------------------+
 | FORMAT (1 byte)                  |
 +----------------------------------+
 | FLAGS  (1 byte)                  |
 +----------------------------------+
 | 2 bytes reserved                 |
 +----------------------------------+
 | MAIN INDEX POSITION (S bytes)    |
 +----------------------------------+
 | ID INDEX POSITION (S bytes)      |
 +----------------------------------+
 | NEXT AVAILABLE ID (S bytes)      |
 +----------------------------------+
 | STRING TABLE POSITION (S bytes)  |
 +----------------------------------+

In format 1 the database header sightly differs. The magic number is now
C<MMDC> instead of C<MMDB>. One of the reserved bytes following the
format indicator is used as flags field.

All other fields remain the same.

=head2 Data Records

Just after the descriptor follows an arbitrary umber of data records.
In the following diagrams the C<pack> format is shown after most of the
fields. Each record is laid out this way:

 +----------------------------------+
 | VALID FLAG (S bytes)             |
 +----------------------------------+
 | ID (S bytes)                     |
 +----------------------------------+
 | NKEYS (S bytes)                  |
 +----------------------------------+
 ¦                                  ¦
 ¦ KEY POSITIONS (NKEYS * S bytes)  ¦
 ¦                                  ¦
 +----------------------------------+
 | SORT POSITION                    |
 +----------------------------------+
 | DATA POSITION                    |
 +----------------------------------+

A data record consists of a certain number of keys, an ID, a sorting field
and of course the data itself. The key, sort and data positions are offsets
from the start of the string table.

The C<valid> flag is 1 if the data is active or 0 if it has been deleted.
In the latter case the next transaction will purge the database.

=head2 The Index

Just after the data section follows the main index. Its starting position
is part of the header. After the main index an arbitrary number
of subindices may follow. The last index in the database is the ID
index.

An index is mainly an ordered list of strings each of which points to a
list of positions. If an index element points to another index this
list contains 1 element, the position of the index. If it points to
data records the position list is ordered according to the sorting
field of the data items.

An index starts with a short header consisting of 2 numbers followed by
constant length index records:

 +----------------------------------+
 | NRECORDS (S bytes)               |
 +----------------------------------+
 | RECORDLEN (S bytes)              |  in units of integers
 +----------------------------------+
 ¦                                  ¦
 ¦ constant length records          ¦
 ¦                                  ¦
 +----------------------------------+

The record length is a property of the index itself. It is the length of the
longest index record constituting the index. It is expressed in units of C<S>
bytes.

Each record looks like this:

 +----------------------------------+
 | KEY POSITION (S bytes)           |
 +----------------------------------+
 | NPOS (S bytes)                   |
 +----------------------------------+
 ¦                                  ¦
 ¦ POSITION LIST (NPOS * S bytes)   ¦
 ¦                                  ¦
 +----------------------------------+
 ¦                                  ¦
 ¦ padding up to RECORDLEN          ¦
 ¦                                  ¦
 +----------------------------------+

The C<KEY POSITION> contains the offset of the record's partial key from
the start of the string table. C<NPOS> is the number of elements of the
subsequent position list. Each position list element is the starting
point of a data record or another index relativ to the start of the file.

=head2 The string table

=head3 Database Format 0

The string table is located at the end of the database file that so far
consists only of integers. There is no structure in the string table. All
strings are simply padded to the next integer boundary and concatenated.

Each string is encoded with the C<F/a* x!S> pack-format:

 +----------------------------------+
 | LENGTH (S bytes)                 |
 +----------------------------------+
 ¦                                  ¦
 ¦ OCTETS (LENGTH bytes)            ¦
 ¦                                  ¦
 +----------------------------------+
 ¦                                  ¦
 ¦ padding                          ¦
 ¦                                  ¦
 +----------------------------------+

=head3 Database Format 1

In database format 1 a byte representing the utf8-ness is appended to
each string. The pack-format C<F/a*C x!S> is used:

 +----------------------------------+
 | LENGTH (S bytes)                 |
 +----------------------------------+
 ¦                                  ¦
 ¦ OCTETS (LENGTH bytes)            ¦
 ¦                                  ¦
 +----------------------------------+
 ¦ UTF8 INDICATOR (1 byte)          ¦
 +----------------------------------+
 ¦                                  ¦
 ¦ padding                          ¦
 ¦                                  ¦
 +----------------------------------+

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
