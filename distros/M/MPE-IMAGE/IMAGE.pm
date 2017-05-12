package MPE::IMAGE;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MPE::IMAGE ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   dset_info
   dset_name
   dset_num
   item_info
   item_name
   item_num
  $DbError 
  @DbStatus
   DbBegin
   DbClose 
   DbControl
   DbEnd
   DbExplain
   DbFind
   DbGet
   DbInfo
   DbMemo
   DbOpen 
   DbXBegin
   DbXEnd
   DbXUndo
   DbLock
   DbUnlock
   DbPut
   DbDelete
   DbUpdate
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.98a';
bootstrap MPE::IMAGE $VERSION;

use Config;

my %size_factor = (
  'E' => 2,
  'I' => 2,
  'J' => 2,
  'K' => 2,
  'R' => 2,
  'P' => 0.5,
  'U' => 1,
  'X' => 1,
  'Z' => 1
);

our @DbStatus;
our $DbError;

tie $DbError, 'MPE::IMAGE';

sub TIESCALAR {
  my $class = shift;
  my $var = 0;
  return bless \$var, $class;
}

sub FETCH { 
  my $self = shift;
  setDbError($self) unless
    defined(@DbStatus) and defined($DbStatus[0]) and
    $$self == $DbStatus[0];
  return $$self;
}

sub STORE {}

sub DbClose ($;$$) {
  my($db,$mode,$dataset) = @_;
  
  if (defined($dataset)) {
    if ($mode !~ /^\d+$/) {
      ($mode,$dataset) = ($dataset,$mode);
    }
    if ($dataset =~ /^-?\d+$/) {
      $dataset = abs($dataset);
    } else {
      $dataset = uc($dataset).';'; # Just in case
    }
  } else {
    $dataset = ';';
  }
  $mode = 1 unless defined($mode);
  _dbclose($db,$dataset,$mode);
}

sub dset_num ($$) {
  my($db,$dset) = @_;

  return $dset if $dset =~ /^-?\d+$/;
  ($dset = uc($dset)) =~ s/[ ;]$//;
  if (exists($db->{dset_nums}->{$dset})) {
    return $db->{dset_nums}->{$dset};
  } else {
    my $num = DbInfo($db,201,$dset);
    $db->{dset_names}->[abs($num)] = $dset;
    return $db->{dset_nums}->{$dset} = $num;
  }
}

sub dset_name ($$) {
  my($db,$dset) = @_;

  return $dset unless $dset =~ /^-?\d+$/;
  my $abs_dset = abs($dset);
  if (exists($db->{dset_names}->[$abs_dset])) {
    return $db->{dset_names}->[$abs_dset];
  } else {
    my $name = DbInfo($db,202,$dset);
    $db->{dset_nums}->{$name} = $dset;
    return $db->{dset_names}->[$abs_dset] = $name;
  }
}

sub item_num ($$) {
  my($db,$item) = @_;

  return $item if $item =~ /^-?\d+$/;
  ($item = uc($item)) =~ s/[ ;]$//;
  if (exists($db->{item_nums}->{$item})) {
    return $db->{item_nums}->{$item};
  } else {
    my $num = DbInfo($db,101,$item);
    return unless $DbStatus[0] == 0;
    $db->{item_names}->[abs($num)] = $item;
    return $db->{item_nums}->{$item} = $num;
  }
}

sub item_name ($$) {
  my($db,$item) = @_;
  
  return $item unless $item =~ /^-?\d+$/;
  my $abs_item = abs($item);
  if (defined($db->{item_names}->[$abs_item])) {
    return $db->{item_names}->[$abs_item];
  } else {
    my $name = DbInfo($db,102,$item);
    $db->{item_nums}->{$name} = $item;
    return $db->{item_names}->[$abs_item] = $name;
  }
}

sub dset_info ($$) {
  my($db,$dset) = @_;

  $dset = abs($dset);
  unless (defined($db->{dset_info}->[$dset])) {
    my %info = DbInfo($db,205,$dset);
    # Remove volatile entries 
    delete $info{entries};
    delete $info{capacity};
    delete $info{hwm};
    $db->{dset_info}->[$dset] = \%info;
  }
  return $db->{dset_info}->[$dset];
}

sub item_info ($$) {
  my($db,$item) = @_;

  $item = abs($item);
  unless (defined($db->{item_info}->[$item])) {
    my %info = DbInfo($db,102,$item);
    return unless $DbStatus[0] == 0;
    $db->{item_info}->[$item] = \%info;
  }
  return $db->{item_info}->[$item];
}

sub mult {
  # Multiply an arbitrarily long integer by a 32-bit or smaller integer,
  # returning the (arbitrarily long) product
  my($num,$factor,$add) = @_;
  return if ($factor > 238609294);  # That's just under (2**31)/9
  my $carry = (defined($add)) ? $add : 0;

  foreach my $idx (reverse(0..length($num)-1)) {
    my $product = ($factor * substr($num,$idx,1)) + $carry;
    substr($num,$idx,1) = chop($product);
    $carry = $product || 0;
  }
  $num = $carry.$num if $carry;
  return $num;
}

sub pack_item {
  my($item,$pic_array) = @_;
  my $value = 0;

  my($count,$type,$len) = @{$pic_array};

  carp("Item uninitialized") unless defined($item);
  carp("Count uninitialized") unless defined($count);
  carp("Type uninitialized") unless defined($type);
  carp("Len uninitialized") unless defined($len);
  if ($count eq '' or $count == 1) {
    return pack_subitem($item,$type,$len);
  } else {
    my $ret_val = '';
    for (1..$count) {
      $ret_val .= pack_subitem($item->[$_],$type,$len);
    }
    return $ret_val;
  }
}

sub pack_subitem {
  my ($item,$type,$length) = @_;

  if ($type eq 'P') {
    if ($item =~ /^\+(\d+)/) { # Marked positive
      $item = "$1c";
    } elsif ($item >= 0) { # No sign, nonnegative
      $item .= 'f';
    } else { # Negative
      $item .= 'd';
    }
    $item = ('0' x ($length - length($item))).$item;
    return pack("H$length",$item);
  } elsif ($type =~ /[UXZ]/) {
    return pack("A$length",$item);
  } elsif ($type =~ /[IJK]/) {
    if ($length >= 1 and $length <= 4) {
      my $value = pack('L L', int($item / 2**32), $item % 2**32);
      return substr($value,-$length*2);
    } 
    croak "MPE::IMAGE cannot pack I, J or K items above 8 bytes long";
  } else {  # E and R
    my $ret_val = pack(($length == 2) ? 'f' : 'd',$item);
    if ($type eq 'R') {
      $ret_val = _IEEE_real_to_HP_real($ret_val);
    }
    return $ret_val;
  }
}

sub unpack_item {
  my($item,$pic_array) = @_;
  my $value = 0;

  my($count,$type,$len) = @{$pic_array};

  if ($count == 1) {
    return unpack_subitem($item,$type,$len);
  } else {
    my @ret_array;
    for (1..$count) {
      push @ret_array,
        unpack_subitem(substr($item,0,$size_factor{$type}*$len,''),$type,$len);
    }
    return \@ret_array;
  }
}
  
sub unpack_subitem {
  my ($item,$type,$length) = @_;

  if ($type eq 'P') {
    my $cnv = unpack("H$length",$item);
    $cnv =~ s/^(\d+)([cdf])$/(($2 eq 'd')?'-':'').$1/e;
    return $cnv;
  } elsif ($type =~ /[UXZ]/) {
    return unpack("A$length",$item);
  } elsif ($type =~ /[IJK]/) {
    return unpack(($type eq 'K') ? 'S' : 's',$item) if $length == 1;
    my $value = unpack(($type eq 'K') ? 'L' : 'l',$item);
    return $value if $length == 2;
    return $value.unpack('S',$item) if $length == 3;
    return $value.unpack('L',$item) if $length == 4;

    # Handle longer than I4.  Why?  Who knows?
    for my $cnt (2..($length - 1)) {
      mult($value,2**16,unpack('S',substr($item,$cnt*2,2)));
    }
    return $value;
  } else {  # E and R
    if ($type eq 'R') {
      $item = _HP_real_to_IEEE_real($item);
    }
    return unpack(($length == 2) ? 'f' : 'd',$item);
  }
}

sub DbFind ($$$;$$$) {
  my($db,$dataset,$mode,$item,$argument,$type) = @_;
  my($dset_num,$item_num);

  if ($dataset =~ /^-?\d+$/) {
    $dataset = $dset_num = abs($dataset);
  } else {
    $dataset = uc($dataset);
    $dataset .= ';' unless $dataset =~ /[ ;]$/;
    $dset_num = abs(dset_num($db,$dataset));
  }

  unless ($mode =~ /^-?\d+$/ or defined($type)) {
    ($mode,$item,$argument,$type) = (1,$mode,$item,$argument);
  }

  unless (defined($argument)) {
    if (defined($item)) {
      ($mode,$item,$argument) = (1,$mode,$item);
    } else {
      unless (defined($db->{key_items}->[$dset_num])) {
        $db->{key_items}->[$dset_num] = (DbInfo($db,302,$dataset))[0];
      }
      ($mode,$item,$argument) = (1,$db->{key_items}->[$dset_num],$mode);
    }
  }

  $item = uc($item);
  $item .= ';' unless $item =~ /[ ;]$/;

  unless (defined($type)) {
    if ($item =~ /^-?\d+$/) {
      $item_num = $item = abs($item);
    } else {
      $item_num = item_num($db,$item);
      $item_num = abs($item_num) if defined($item_num);
    }
  }

  return unless defined($item_num) or defined($type);
  if (defined($type)) {
    my($c,$t,$l) = ($type =~ /(\d*)([EIJKPRUXZ])(\d+)/i) or return;
    $c = '' unless defined($c);
    $argument = pack_item($argument, [ $c,$t,$l ]);
  } else {
    my $info = item_info($db,$item_num);
    $argument = pack_item($argument, [ @{$info}{'count', 'type', 'length'} ]);
  }
  _dbfind($db,$dataset,$mode,$item,$argument);
}

#
# Touchup the value passed (either numeric or alpha) and return it and the
# dataset number
#
sub touchup_dset ($$) {
  my($db,$dset) = @_;
  my $dnum; 

  if ($dset =~ /^-?\d+$/) {
    $dset = $dnum = abs($dset);
  } else {
    $dset = uc($dset);
    $dset .= ';' unless $dset =~ /[ ;]$/;
    $dnum = abs(dset_num($db,$dset));
  }
  return ($dset,$dnum);
}

#
# Take the list received and return the set list in both scalar and 
#   array forms.  If $list is undefined, return the current list if there
#   is one and the @-list otherwise.
#
sub touchup_list ($$$$) {
  my($db,$list,$dset_num,$dataset) = @_;
  my(@list) = ();

  unless (defined($list)) {
    if (defined($db->{default_lists}->[$dset_num])) {
      $list = '*;';
      @list = @{$db->{default_lists}->[$dset_num]};
    } else {
      $list = '@;';
      if (defined($db->{full_lists}->[$dset_num])) {
        @list = @{$db->{full_lists}->[$dset_num]};
      } else {
        @list = @{$db->{full_lists}->[$dset_num]} = DbInfo($db,104,$dataset);
      }
    }
  } else {
    if (UNIVERSAL::isa($list,'ARRAY')) {
      @list = @{$list};
      foreach (@list) {
        $_ = item_num($db,$_) unless /^\d+$/;
      }
      $list = '';
    } else {
      $list = '0;' if $list =~ /^\0$/;
      $list .= ';' unless $list =~ /[ ;]$/;
      if ($list =~ /^\*[ ;]$/) {
        $db->{default_lists}->[$dset_num] = []
          unless defined($db->{default_lists}->[$dset_num]);
        @list = @{$db->{default_lists}->[$dset_num]};
      } elsif ($list =~ /^@[ ;]$/) {
        @{$db->{full_lists}->[$dset_num]} = DbInfo($db,104,$dataset)
          unless defined($db->{full_lists}->[$dset_num]);
        @list = @{$db->{full_lists}->[$dset_num]};
      } elsif ($list =~ /^0?[ ;]$/) {
        @list = ();
      } else {
        foreach (split(/,\s*/,$list)) {
          my $item;
          ($item = $_) =~ s/[ ;]$//;
          push @list,item_num($db,$item);
        }
      }
    }
  }
  @list = map { abs($_) } @list;
  return($list,@list);
}
 
sub collect_items {
  my($db,$list,$list_arr,$dset_num,$schema) = @_;
  my @list = @{$list_arr};

  my(@name,@type,@size);
  my $size = 0;
  unless (defined($schema)) {
    if ($list =~ /^\*[ ;]$/) {
      unless (defined($db->{default_names}->[$dset_num])) {
        $db->{default_names}->[$dset_num] = [];
        $db->{default_types}->[$dset_num] = [];
        $db->{default_sizes}->[$dset_num] = [];
        $db->{default_size}->[$dset_num] = 0;
      }
      @name = @{$db->{default_names}->[$dset_num]};
      @type = @{$db->{default_types}->[$dset_num]};
      @size = @{$db->{default_sizes}->[$dset_num]};
      $size = $db->{default_size}->[$dset_num];
    } else {
      $size = 0;
      foreach (@list) {
        my $info = item_info($db,$_);
        my $item_size = 
             $size_factor{$info->{type}} * $info->{length} * $info->{count};
        push @size, $item_size;
        $size += $item_size;
        if (/^-?\d+$/) {
          push @name, item_name($db,$_);
        } else {
          push @name, $_;
        }
        push @type, [ @{$info}{'count', 'type', 'length'} ];
      }
    }
  } else {
    while (@{$schema}) {
      push @name,shift @{$schema};
      my $pic = shift @{$schema};
      croak "Invalid datatype in schema: $pic"
        unless $pic =~ /^(\d*)([eijkrpuxz])(\d+)$/i;
      my $count = (length($1)) ? $1 : '1';
      my $type = uc($2);
      push @type,[ $count, $type, $3 ];
      my $item_size = $size_factor{$type}*$3*$count;
      push @size,$item_size;
      $size += $item_size;
    }
  }
  return(\@name,\@type,\@size,$size);
}

sub DbDelete ($$) {
  my($db,$dset) = @_;
  my $dset_num;

  ($dset,$dset_num) = touchup_dset($db,$dset);
  _dbdelete($db,$dset);
}

sub DbGet ($$$;$$$) {
  my($db,$mode,$dataset,$list,$argument,$schema) = @_;
  my(@list) = ();
  my $dset_num;

  unless ($mode =~ /^\d/) { # Assume that they put the dataset first
    ($mode,$dataset) = ($dataset,$mode);
  }

  ($dataset, $dset_num) = touchup_dset($db,$dataset);

  if ($mode == 4 or $mode == 7 or $mode == 8) {
    if (@_ == 4) {
      $argument = $list;
      undef $list;
    } 
  }

  ($list,@list) = touchup_list($db,$list,$dset_num,$dataset);
    
  my($name_arr,$type_arr,$size_arr,$size) = 
    collect_items($db,$list,\@list,$dset_num,$schema);
  
  $argument = '' unless defined $argument;
  if ($mode == 7 or $mode == 8) {
    unless (defined($db->{key_items}->[$dset_num])) {
      $db->{key_items}->[$dset_num] = (DbInfo($db,302,$dataset))[0];
    }
    my $info = item_info($db,$db->{key_items}->[$dset_num]);
    $argument = pack_item($argument, [ @{$info}{'count', 'type', 'length'} ]);
  } elsif ($mode == 4) {
    $argument = pack('N',$argument);
  }
  $list = \@list unless $list =~ /^[0*@][ ;]$/;

  $db->{default_lists}->[$dset_num] = \@list;
  $db->{default_names}->[$dset_num] = $name_arr;
  $db->{default_types}->[$dset_num] = $type_arr;
  $db->{default_sizes}->[$dset_num] = $size_arr;
  $db->{default_size}->[$dset_num] = $size;

  my $gotten = _dbget($db,$dataset,$mode,$list,$argument,$size);

  return $gotten unless wantarray;

  my %return_hash;
  foreach (0..$#{$name_arr}) {
    my $unpack_val = substr($gotten,0,${$size_arr}[$_],'');
    $return_hash{${$name_arr}[$_]} = unpack_item($unpack_val,${$type_arr}[$_]);
  }
  
  return %return_hash;
}

sub DbInfo ($$;$) {
  my($db,$mode,$qualifier) = @_;

  if (defined($qualifier)) {
    if ($mode !~ /^\d+$/) {
      ($mode,$qualifier) = ($qualifier,$mode);
    }
    if ($qualifier =~ /^-?\d+$/) {
      $qualifier = abs($qualifier);
    } else {
      $qualifier = uc($qualifier).';'; # Just in case
    }
  } else {
    $qualifier = ';';
  }
  my $ret_data = _dbinfo($db->{handle},$qualifier,$mode);
  return $ret_data unless ref($ret_data);
  if (UNIVERSAL::isa($ret_data,"ARRAY")) {
    return @{$ret_data};
  } else {
    return %{$ret_data} if wantarray;
    return $ret_data->{name};
  }
}

sub DbLock ($$;@) {
  my($db,$mode,@descr) = @_;
  
  if ($mode == 1 or $mode == 2) {
    _dblock($db,$mode,0);
  } elsif ($mode == 3 or $mode == 4) {
    _dblock($db,$mode,dset_name($db,$descr[0]).';');
  } else {
    my($descr) = pack('S',scalar(@descr));
    foreach my $d (@descr) {
      croak "Descriptor passed to DbLock is neither Array nor Hash"
        unless UNIVERSAL::isa($d,'ARRAY') or UNIVERSAL::isa($d,'HASH');
      my(@vals);
      if (UNIVERSAL::isa($d,'ARRAY')) {
        @vals = @{$d};
      } else {
        croak "Missing 'set' in descriptor passed to DbLock"
          unless defined(${$d}{'set'});
        @vals = grep { defined } @{$d}{'set','cond'};
      }
      if (@vals == 1) {
        $descr .= pack('S A16',10,dset_name($db,$vals[0]).';').'@ ';
      } else {
        my($item,$relop,$value) = split(/([<>= ]?=)/,$vals[1]);
        $relop = '=' if $relop eq '==';
        my $item_name;
        croak "Unknown item '$item' in DbLock" 
          unless $item_name = item_name($db,$item);
        my $info = item_info($db,item_num($db,$item));
        $value = pack_item($value, [ @{$info}{'count', 'type', 'length'} ]);
        my $len = $info->{'count'} * $size_factor{$info->{'type'}} *  
                  $info->{'length'};
        $descr .= pack('S A16 A16 A2',int($len/2)+18,
                       uc(dset_name($db,$vals[0])).';',
                       $item_name,$relop).$value;
      }
    }
    _dblock($db,$mode,$descr);
  }
}

sub DbOpen ($$$) {
  my($base,$pass,$mode) = @_;
  # make sure we start with blanks
  unless ($base =~ /^  \S/) {
    $base =~ s/^\s+//;
    $base = "  $base";
  }
  # and end with a blank or a semicolon
  $base .= ';' unless $base =~ /[; ]$/;
  # make sure that the password and user are either at least eight characters
  # or else blank/semicolon-terminated
  $pass =~ s!((?:^|/)          # beginning of line or a slash
              [^\r/; ]*        # 0 or more valid password/user chars
              [ ;]?)           # possibly followed by a blank or semicolon
             (?=/|$)           # followed either by a slash or end of line
            !my($ret) = $1;
             $ret .= ';' unless length($1) > 7 or $1 =~ /[ ;]$/;
             $ret;
            !exg;              # e - execute replacemnt portion
                               # x - allow comments and suchlike
                               # g - do it multiple times if necessary
  my $db = _dbopen($base,$pass,$mode);
  return bless $db, "MPE::IMAGE";
}

sub DbPut ($$@) {
  my($db,$dset) = splice(@_,0,2);
  my(@list) = ();;
  my $dset_num;
  my $schema = undef;

  my($list,$data);
  if (@_ == 1) {
    $list = undef;
    $data = $_[0];
  } elsif (@_ == 2) {
    if ($_[0] =~ /[,; ]/ or
        ref($_[1])) { # This is a list, the rest is data
      ($list,$data) = @_;
    } else {
      $list = undef;
      $data = { @_ }
    }
  } elsif (@_ % 2 == 0) {
    $list = undef;
    $data = { @_ };
  } else {
    $list = shift @_;
    $data = { @_ };
  }
 
  ($dset,$dset_num) = touchup_dset($db,$dset);
  
  if (UNIVERSAL::isa($data,'HASH')) {
    $list = join(',',keys %{$data});
    ($list,@list) = touchup_list($db,$list,$dset_num,$dset);
    my @vals = @{$data}{map { item_name($db,$_) } @list};

    my($name_arr,$type_arr,$size_arr,$size) =
      collect_items($db,$list,\@list,$dset_num,$schema);

    my $packed_val = '';
    my $total_size = 0;
    foreach my $idx (0..$#{$name_arr}) {
      $packed_val .= pack_item($vals[$idx],$type_arr->[$idx]);
      $total_size += $size_arr->[$idx];
    }

    $list = \@list unless $list =~ /^[0*@][ ;]$/;

    $db->{default_lists}->[$dset_num] = \@list;
    $db->{default_names}->[$dset_num] = $name_arr;
    $db->{default_types}->[$dset_num] = $type_arr;
    $db->{default_sizes}->[$dset_num] = $size_arr;
    $db->{default_size}->[$dset_num]  = $total_size;
    
    _dbput($db,$dset,$list,$packed_val);

  } else { # $data is a scalar
  
    ($list,@list) = touchup_list($db,$list,$dset_num,$dset);

    my($name_arr,$type_arr,$size_arr,$size) =
      collect_items($db,$list,\@list,$dset_num,$schema);

    $list = \@list unless $list =~ /^[0*@][ ;]$/;

    $db->{default_lists}->[$dset_num] = \@list;
    $db->{default_names}->[$dset_num] = $name_arr;
    $db->{default_types}->[$dset_num] = $type_arr;
    $db->{default_sizes}->[$dset_num] = $size_arr;
    $db->{default_size}->[$dset_num] = $size;
    
    _dbput($db,$dset,$list,$data);

  }
}

sub DbUpdate ($$@) {
  my($db,$dset) = splice(@_,0,2);
  my(@list) = ();
  my $dset_num;
  my $schema = undef;
 
  my($list,$data);
  if (@_ == 1) {
    $list = undef;
    $data = $_[0];
  } elsif (@_ == 2) {
    if ($_[0] =~ /[,; ]/ or
        ref($_[1])) { # This is a list, the rest is data
      ($list,$data) = @_;
    } else {
      $list = undef;
      $data = { @_ }
    }
  } elsif (@_ % 2 == 0) {
    $list = undef;
    $data = { @_ };
  } else {
    $list = shift @_;
    $data = { @_ };
  }
 
  ($dset,$dset_num) = touchup_dset($db,$dset);
  
  if (UNIVERSAL::isa($data,'HASH')) {
    $list = join(',',keys %{$data});
    ($list,@list) = touchup_list($db,$list,$dset_num,$dset);
    my @vals = @{$data}{map { item_name($db,$_) } @list};

    my($name_arr,$type_arr,$size_arr,$size) =
      collect_items($db,$list,\@list,$dset_num,$schema);

    my $packed_val = '';
    my $total_size = 0;
    foreach (0..$#{$name_arr}) {
      $packed_val .= pack_item($vals[$_],$type_arr->[$_]);
      $size += $size_arr->[$_];
    }

    $list = \@list unless $list =~ /^[0*@][ ;]$/;

    $db->{default_lists}->[$dset_num] = \@list;
    $db->{default_names}->[$dset_num] = $name_arr;
    $db->{default_types}->[$dset_num] = $type_arr;
    $db->{default_sizes}->[$dset_num] = $size_arr;
    $db->{default_size}->[$dset_num] = $size;
    
    _dbupdate($db,$dset,$list,$packed_val);

  } else { # $data is a scalar
  
    ($list,@list) = touchup_list($db,$list,$dset_num,$dset);

    my($name_arr,$type_arr,$size_arr,$size) =
      collect_items($db,$list,\@list,$dset_num,$schema);

    $list = \@list unless $list =~ /^[0*@][ ;]$/;

    $db->{default_lists}->[$dset_num] = \@list;
    $db->{default_names}->[$dset_num] = $name_arr;
    $db->{default_types}->[$dset_num] = $type_arr;
    $db->{default_sizes}->[$dset_num] = $size_arr;
    $db->{default_size}->[$dset_num] = $size;
    
    _dbupdate($db,$dset,$list,$data);

  }
}

sub DESTROY {
  if (eval { my $handle = $_[0]->{handle}; } and
      not exists $_[0]->{closed}) {
    DbClose($_[0]);
  }
}

1;
__END__

=head1 NAME

MPE::IMAGE - Access MPEs TurboIMAGE/XL databases from within Perl

=head1 SYNOPSIS

  use MPE::IMAGE ':all';

  my $db = DbOpen('Dbase.Group.Account','Password',5);
  die "DbOpen Error: $DbError" unless $DbStatus[0] == 0;

  my %record = DbGet($db,2,'dataset','items');
  DbExplain unless $DbStatus[0] == 0;

  $db->DbClose(1);
  DbExplain unless $DbStatus[0] == 0;

=head1 DESCRIPTION

MPE::IMAGE is designed to make access to TurboIMAGE/XL databases fairly 
comfortable to the Perl programmer.  Please note that the calls differ in 
certain ways from the native intrinsic calls.  In specific:

=over 4

=item * 
Anywhere a "number of elements" was given, it is no longer necessary.
Perl knows how many elements are in an array and passes that information to
the appropriate intrinsic.  An example of this is in passing an item-number
list to C<DbGet>.

=item *
The status array is a globally defined perl array and so does not get passed
to any of the routines.

=item *
The data returned from C<DbGet> and passed to C<DbPut> and C<DbUpdate> can
be either a single scalar value containing the entire buffer exactly as it
is gotten or put, or a hash mapping item names to their values.

=item *
MPE::IMAGE will handle all the translation to and from the various IMAGE
datatypes transparently.

=item *
C<DbGet>, C<DbPut> and C<DbUpdate> can each take a schema hash, allowing 
fields to be redefined.

=item *
Dataset and item names can be given in any case.  They will be passed to the
intrinsics uppercase.

=back

The following are provided by MPE::IMAGE.  Note that for each call which
expects a database argument, that argument should be a database object as
returned by C<DbOpen>.

=head2 C<@DbStatus>

The array C<@DbStatus> contains the status values from the most recent
intrinsic call.  

=head2 C<$DbError>

C<DBERROR> is implemented as a readonly variable called C<$DbError>.  
When used in a string context, C<$DbError> gives the text returned by a call 
to C<DBERROR>.

When used in a numeric context, it contains the same value as C<$DbStatus[0]>.
However, it is somewhat more expensive to use than C<$DbStatus[0]> as using it 
includes the overhead of using a tied variable and, possibly, a call to 
C<DBERROR>.

In any of the following usages, the overhead should be negligible

  die "DbOpen Error: $DbError" unless $DbStatus[0] == 0;
  die "DbOpen Error: $DbError" if $DbError;
  dbfail($DbError) if $DbError != 0 and $DbError != 15;

I would be much less likely to use it in this fashion:

  while ($DbError == 0) {
    %data = DbGet($db,5,'dataset');
    . . . 
  }

because it makes a "method" call on every iteration and in the final pass, 
when the status comes up 15, it performs a C<DBERROR> call to get an 
explanation for an expected condition, both problems which are avoided by
using $DbStatus[0] instead:

  while ($DbStatus[0] == 0) {
    %data = DbGet($db,5,'dataset');
    . . . 
  }

=head2 C<DbBegin>

  DbBegin(Database,1);
  DbBegin(Database,1,text);
  $transid = DbBegin(Array of bases,3 or 4);
  $transid = DbBegin(Array of bases,3 or 4,text);

Note that the $transid is more than just a number.  It is the array, in binary
form, containing not only the transaction id but all the base ids as well.
Its only intended purpose is for passing to DbEnd.

=head2 C<DbClose>

  DbClose(Database);
  DbClose(Database,mode);
  DbClose(Database,mode,dataset);

If mode is omitted, it defaults to 1.

=head2 C<DbControl>

  DbControl(Database,mode);
  $status = DbControl(Database,13,0);
  $status = DbControl(Database,13,function,set);
  $status = DbControl(Database,13,function,set,flags);
  $status = DbControl(Database,14,function);
  $status = DbControl(Database,14,7,wildcard);
  DbControl(Database,15);
  DbControl(Database,15,wildcard);
  DbControl(Database,16);

=head2 C<DbDelete>

  DbDelete(Database,Dataset);

=head2 C<DbEnd>

  DbEnd(Database,1 or 2);
  DbEnd(Database,1 or 2,text);
  DbEnd(Array of bases,3 or 4);
  DbEnd(Array of bases,3 or 4,text);
  DbEnd($transid,3 or 4);
  DbEnd($transid,3 or 4,text);

=head2 C<DbExplain>

  DbExplain;

=head2 C<DbFind>

  DbFind(Database,dataset,argument);  # Assumed find mode 1 on key item
  DbFind(Database,dataset,item,argument);  # Assumed mode 1
  DbFind(Database,dataset,mode,item,argument);
  DbFind(Database,dataset,argument,type);  # Assumed find mode 1 on key item
  DbFind(Database,dataset,item,argument,type);  # Assumed mode 1
  DbFind(Database,dataset,mode,item,argument,type);

C<type> is a string containing an IMAGE type (such as "2X10") and is 
necessary only when searching on a TPI index (for which MPE::IMAGE cannot
look up the type).

=head2 C<DbGet>

  DbGet(Database,mode,dataset);
  DbGet(Database,mode,dataset,list);
  DbGet(Database,mode,dataset,undef,undef,schema);
  DbGet(Database,mode,dataset,list,undef,schema);

If mode is 4, 7 or 8:

  DbGet(Database,mode,dataset,argument);
  DbGet(Database,mode,dataset,list,argument);
  DbGet(Database,mode,dataset,undef,argument,schema);
  DbGet(Database,mode,dataset,list,argument,schema);

C<list> can be either an array of or a comma-separated list of item names or 
numbers (or a mixture of both).  It can also be "0", "*" or "@" and can be 
semicolon/space-terminated or not as preferred.  If C<list> is omitted, it is
assumed to be "*;" if the dataset has previously be used and "@;" if not.

C<schema> is the description of the fields and must describe a space of
exactly the same size as the fields in C<list>.  There will be a helper
function to allow a schema to be checked prior to use and this is highly
recommended.  If the schema is omitted, a schema derived from the IMAGE
item descriptions is used instead.  See the section on schemata for more 
information.

When used in scalar context, DbGet returns the retrieved values as a single
block.  Otherwise it returns a hash where the keys are the item names (or
the fields described in the schema) and the values are the values of those
items/fields.

=head2 C<DbInfo>

Since the return values from DbInfo must be parsed, and since the necessary
buffer size varies widely depending on the mode, only the modes listed in
the August 1997 (sixth) edition of the Image manual are supported 
(third-party indexing modes are not currently supported).

  $item_num = DbInfo(Database,101,item name or number);

  %item_info = DbInfo(Database,102,item name or number);

C<%item_info> will have elements with the following keys: "name", "type",
"length", "count".

  @item_nums = DbInfo(Database,103);

C<@item_nums> will contain the item numbers (positive and negative).  As with 
other modes which return arrays, the first element is *not* the number of
items.  Rather, the number of items is reflected in the size of the array.

  @item_nums = DbInfo(Database,104,set name or number);

  @btree_info = DbInfo(Database,113);

C<@btree_info> will be a six-element array, the 2nd and 6th elements of which
contain the respective wild-card characters (see Image documentation).

  $set_num = DbInfo(Database,201,set name or number);

  %set_info = DbInfo(Database,202,set name or number);

C<%set_info> will have elements with the following keys: "name", "type",
"length", "block fact", "entries", "capacity".

  @set_nums = DbInfo(Database,203);

  @set_nums = DbInfo(Database,204,item name or number);

  %set_info = DbInfo(Database,205,set name or number);

C<%set_info> will have elements with the following keys: "name", "type",
"length", "block fact", "entries", "capacity", "hwm", "max cap", "init cap",
"increment", "inc percent", "dynamic cap".

  $num_chunks = DbInfo(Database,206,set name or number);

  @chunk_sizes = DbInfo(Database,207,set name or number);

  @set_info = DbInfo(Database,208,set name or number);

C<@set_info> will be a seven-element array.

  @btree_info = DbInfo(Database,209,set name or number);

C<@btree_info> will be a two-element array.

  @path_array = DbInfo(Database,301,set name or number);

C<@path_array> will be an n-element array, where n is the number of paths for
the specified dataset.  Each element will be a reference to a hash containing
elements with the following keys: "set", "search", and "sort".  To report 
which sets are connected by paths to MYDETAIL, you could do something like 
this:
  
  my @path_array = DbInfo($db,301,'MYDETAIL');
  foreach (@path_array) {
    print $_->{'set'},"\n";
  }
  # end of example

  @key_array = DbInfo(Database,302,set name or number);

C<@key_array> will be a two-element array.

  %log_info = DbInfo(Database,401);

C<%log_info> will have elements with the following keys: "logid",
"base log flag", "user log flag", "trans flag", "user trans num".

  %ILR_info = DbInfo(Database,402);

C<%ILR_info> will have elements with the following keys: "ILR log flag",
"ILR date", "ILR time".

  %log_info = DbInfo(Database,403);

C<%log_info> will have elements with the following keys: "logid",
"base log flag", "user log flag", "trans flag", "user trans num",
"log set size", "log set type", "base attached", "dynamic trans",
"log set name".

  %log_info = DbInfo(Database,404);

C<%log_info> will have elements with the following keys: "base log flag",
"user log flag", "rollback flag", "ILR log flag", "mustrecover",
"base remote", "trans flag", "logid", "log index", "trans id", "trans bases",
"base ids".  "base ids" will be a reference to an array containing the ids
of the bases being used in a multiple-base transaction.

  %db_info = DbInfo(Database,406);

C<%db_info> will have elements with the following keys: "name", "mode",
"version"

  $subsys_access = DbInfo(Database,501);

  @ci_update = DbInfo(Database,502);

C<@ci_update> will be a two-element array.

  $language_id = DbInfo(Database,901);

=head2 C<DbLock>

  DbLock(Database,1 or 2);
  DbLock(Database,3 or 4,Dataset);
  DbLock(Database,5 or 6,Desc1,Desc2,...);

The Descriptors are either hashes or arrays.  If they are hashes, they must
contain a 'set' key and may optionally contain a 'cond' key.  The value for
the 'set' key should be the dataset, either numeric or alphabetic.  The 
condition should be given as item, relop and value value in a single string.  
For example, 'ID=12345' would be a valid condition.  If the descriptor is
an array, it should contain the dataset in slot 0 and the conditional, if any,
in slot 1.

=head2 C<DbMemo>

  DbMemo(Database);
  DbMemo(Database,text);

=head2 C<DbOpen>

  $db = DbOpen(BaseName,Password,Mode);

DbOpen returns a database object which can be passed to the other calls.

=head2 C<DbPut>

  DbPut(Database,Dataset,Data);
  DbPut(Database,Dataset,List,Data);

Data may either be a hash or a scalar.  If it is a hash, the keys of the
hash will be used to construct the list.  If it is a scalar and no list is
specified, the current list will be used.

=head2 C<DbUnlock>

  DbUnlock(Database);

=head2 C<DbUpdate>

  DbUpdate(Database,Dataset,Data);
  DbUpdate(Database,Dataset,List,Data);

Data may either be a hash or a scalar.  If it is a hash, the keys of the
hash will be used to construct the list.  If it is a scalar and no list is
specified, the current list will be used.

=head2 C<DbXBegin>

  DbXBegin(Database,1);
  DbXBegin(Database,1,text);
  $transid = DbXBegin(Array of bases,3);
  $transid = DbXBegin(Array of bases,3,text);

Note that the $transid is more than just a number.  It is the array, in binary
form, containing not only the transaction id but all the base ids as well.
Its only intended purpose is for passing to DbXEnd or DbXUndo.

=head2 C<DbXEnd>

  DbXEnd(Database,1 or 2);
  DbXEnd(Database,1 or 2,text);
  DbXEnd($transid,3);
  DbXEnd($transid,3,text);

=head2 C<DbXUndo>

  DbXUndo(Database,1);
  DbXUndo(Database,1,text);
  DbXUndo($transid,3);
  DbXUndo($transid,3,text);

=head1 HELPER FUNCTIONS

MPE::IMAGE also provides a set of helper functions

=over 4

=item *
dset_info(Database,Dataset Num)

=item *
dset_name(Database,Dataset)

=item *
dset_num(Database,Dataset)

=item *
item_info(Database,Item Num)

=item *
item_name(Database,Item)

=item *
item_num(Database,Item)

=back

These functions return information about datasets or items either by making
the necessary DbInfo calls or from cache, so they can be considerably faster
that making a DbInfo call.  C<dset_info> returns all of the mode 205
information except number of entries, capacity and high-water mark--those
things which cannot be safely cached.  C<item_info> returns the mode 102 
information.  The *_name and *_num calls can take either a dataset/item name or
number.  That way, one can use, for example, C<item_num> passing it whatever 
item identification one currently has and receive back an item number.

=head1 SCHEMAS

Yet to be written.  Note that schemas do NOT yet work for DbPut or DbUpdate,
only DbGet (and in a small way for DbFind).

=head1 NOTES

=over 4

=item *
ONLY those calls/modes which are in the test suite are guaranteed to be
tested.  There are some things, such as Priv Mode DbControl calls and things
relating to B-Trees and Jumbo sets which I couldn't very well test.

=item *
MPE::IMAGE can handle packed-decimal fields of any length, but as a P28, for
example, can hold a larger number than a 64-bit integer, P fields are always
translated into strings.  If the number is within range, Perl will translate
it into binary format when necessary.

=item *
IMAGE allows the definition of I, J and K types greater than 64 bits.  
MPE::IMAGE, however, gets very confused by such things.  

=back

=head1 AUTHORS

Ted Ashton, ashted@southern.edu (original author).

Dave Oksner, dave@case.net (maintainer).

=head1 SEE ALSO

perl(1).

=cut
