package Linux::Smaps;

use 5.008;
use strict;
use warnings FATAL=>'all';
no warnings qw(uninitialized portable);
use Errno qw/EACCES/;

my $min_vma_off;

BEGIN {
  package Linux::Smaps::VMA;

  use strict;
  BEGIN {
    our @attributes=qw(vma_start vma_end r w x mayshare file_off
		       dev_major dev_minor inode file_name is_deleted _line);
    # it seems a bit faster (~4%) if _line is placed at the end of
    # @attributes.
    my $line_idx=$#attributes;
    our %attributes;
    for( my $i=0; $i<@attributes; $i++ ) {
      no strict 'refs';
      my $n=$i;
      *{__PACKAGE__.'::'.$attributes[$n]}=
	$attributes{$attributes[$n]}=
	  sub : lvalue {
	    my $I=$_[0];
	    if( @_>1 ) {
	      $I->[$n]=$_[1];
	    } elsif( defined($I->[$n]) || !defined($I->[$line_idx]) ) {
	      $I->[$n];
	    } else {
	      $I->_parse if defined $I->[$line_idx];
	      $I->[$n];
	    }
	  };
      my $const=sub () {$n};
      *{__PACKAGE__.'::V_'.$attributes[$n]}=$const;
      *{'Linux::Smaps::V_'.$attributes[$n]}=$const;
      $Linux::Smaps::VMA::attr_idx{$attributes[$n]}=$n;
    }
    $min_vma_off=@attributes;

    our %special=
      (
       vmflags=>sub {my @l=split /\s+/, $_[0]; shift @l; \@l},
      );
    our @special;
  }

  sub new {bless [@_[1..$#_]]=>(ref $_[0] ? ref $_[0] : $_[0])}

  sub _parse {
    my ($I)=@_;
    @{$I}[V_vma_start..V_is_deleted]=(hex($1), hex($2), ($3 eq 'r'),
				      ($4 eq 'w'), ($5 eq 'x'), ($6 eq 's'),
				      hex($7), hex($8), hex($9), $10, $11,
				      defined($12))
      if $I->[V__line]=~/^
			 ([\da-f]+)-([\da-f]+)\s	  # range
			 ([r\-])([w\-])([x\-])([sp])\s	  # access mode
			 ([\da-f]+)\s		          # page offset in file
			 ([\da-f]+):([\da-f]+)\s	  # device
			 (\d+)\s*			  # inode
			 (.*?)				  # file name
			 (\s\(deleted\))?		  # is deleted?
			 $
			/xi;
    undef $I->[V__line]; # eval it only once
    return;
  }
}

BEGIN {
  our @attributes=qw{pid lasterror filename procdir _elem};
  our %attributes;
  for( my $i=0; $i<@attributes; $i++ ) {
    my $n=$i;
    die "Internal Error"	# should not happen
      if exists $Linux::Smaps::VMA::attributes{$attributes[$n]};
    no strict 'refs';
    *{__PACKAGE__.'::'.$attributes[$n]}=
      $attributes{$attributes[$n]}=
	sub : lvalue {@_>1 ? $_[0]->[$n]=$_[1] : $_[0]->[$n]};
    *{__PACKAGE__.'::M_'.$attributes[$n]}=sub () {$n};
  }
}

our $VERSION = '0.13';

sub new {
  my $class=shift;
  $class=ref($class) if( ref($class) );
  my $I=bless []=>$class;
  my %h;

  $I->[M_procdir]='/proc';
  $I->[M_pid]='self';

  if( @_==1 ) {
    $I->[M_pid]=shift;
  } else {
    our @attributes;
    our %attributes;
    %h=@_;
    foreach my $k (@attributes) {
      $attributes{$k}->($I, $h{$k}) if exists $h{$k};
    }
  }

  return $I if( $h{uninitialized} );

  my $rc=$I->update;
  die __PACKAGE__.": ".$I->[M_lasterror]."\n" unless( $rc );

  return $rc;
}

sub clear_refs {
  my ($I)=@_;

  my $name=$I->[M_procdir].'/'.$I->[M_pid].'/clear_refs';

  open my $f, '>', $name or do {
    $I->[M_lasterror]="Cannot open $name: $!";
    return;
  };
  print $f "1\n";
  close $f;

  return $I;
}

my ($cnt1, $fmt1)=(0);

sub update {
  my ($I)=@_;

  my $name;

  # this way one can use one object to loop through a list of processes like:
  # foreach (@pids) {
  #   $smaps->pid=$_; $smaps->update;
  #   process($smaps);
  # }
  if( defined $I->[M_filename] ) {
    $name=$I->[M_filename];
  } else {
    $name=$I->[M_procdir].'/'.$I->[M_pid].'/smaps';
  }

  # Normally, access permissions for a file are checked when it is opened.
  # /proc/PID/smaps is different. Here permissions are checked by the read
  # syscall.
  open my $f, '<', $name or do {
    $I->[M_lasterror]="Cannot open $name: $!";
    return;
  };

  my $current;
  $I->[M__elem]=[];
  my %cache;
  my ($l, $tmp, $m);
  my $current_off=@Linux::Smaps::VMA::attributes;

  $!=0;
  while( defined($l=<$f>) ) {
    if( $current_off<@Linux::Smaps::VMA::attributes ) {
      if( $tmp=$Linux::Smaps::VMA::special[$current_off] ) {
        $current->[$current_off++]=$tmp->($l);
      } else {
        no warnings qw(numeric);
        $current->[$current_off++]=0+(unpack $fmt1, $l)[0];
      }
    } elsif( $l=~/^(\w+):\s*(\d+) kB$/ ) {
      $m=lc $1;

      if( exists $Linux::Smaps::VMA::attributes{$m} ) {
	$I->[M_lasterror]="Linux::Smaps::VMA::$m method is already defined";
	return;
      }
      if( exists $Linux::Smaps::attributes{$m} ) {
	$I->[M_lasterror]="Linux::Smaps::$m method is already defined";
	return;
      }

      $current->[$current_off++]=0+$2;

      push @Linux::Smaps::VMA::attributes, $m;
      {
	no strict 'refs';
	my $n=$#Linux::Smaps::VMA::attributes;
	*{'Linux::Smaps::VMA::'.$m}=
	  $Linux::Smaps::VMA::attributes{$m}=
	    sub : lvalue {@_>1 ? $_[0]->[$n]=$_[1] : $_[0]->[$n]};
	$Linux::Smaps::VMA::attr_idx{$m}=$n;
      }

      {
	no strict 'refs';
	my $attr_nr=$#Linux::Smaps::VMA::attributes;
	*{__PACKAGE__."::$m"}=$Linux::Smaps::attributes{$m}=sub {
	  my ($I, $n)=@_;
	  my $rc=0;
	  foreach my $el (length $n
			  ? grep(
				 {
				  $_->_parse if(!defined($_->[V_file_name]) and
						defined($_->[V__line]));
				  $_->[V_file_name] eq $n;
				 } @{$I->[M__elem]}
				)
			  : @{$I->[M__elem]}) {
	    $rc+=$el->[$attr_nr];
	  }
	  return $rc;
	};
      }

      if( length($m)>$cnt1 ) {
	$cnt1=length($m);
	$fmt1="x".($cnt1+1)."A*";
      }
    } elsif( $l=~/^(\w+):.+$/ and $tmp=$Linux::Smaps::VMA::special{$m=lc $1} ) {
      if( exists $Linux::Smaps::VMA::attributes{$m} ) {
	$I->[M_lasterror]="Linux::Smaps::VMA::$m method is already defined";
	return;
      }

      $Linux::Smaps::VMA::special[$current_off]=$tmp;
      $current->[$current_off++]=$tmp->($l);

      push @Linux::Smaps::VMA::attributes, $m;
      {
	no strict 'refs';
	my $n=$#Linux::Smaps::VMA::attributes;
	*{'Linux::Smaps::VMA::'.$m}=
	  $Linux::Smaps::VMA::attributes{$m}=
	    sub : lvalue {@_>1 ? $_[0]->[$n]=$_[1] : $_[0]->[$n]};
	$Linux::Smaps::VMA::attr_idx{$m}=$n;
      }
    } elsif( $l=~/^([\da-f]+-[\da-f]+)\s/i ) {
      # the rest of the line is lazily parsed
      @{$current=bless [], 'Linux::Smaps::VMA'}[V__line]=$l;

      # use %cache to work around a bug in some implementations,
      # VMAs may be reported twice.
      push @{$I->[M__elem]}, $current unless $cache{$1}++;
      $current_off=$min_vma_off;
    } else {
      $I->[M_lasterror]="$name($.): not parsed: $l";
      return;
    }
  }

  if( $.==0 ) {                 # nothing read
    $!||=EACCES;                # some kernels just report it as an empty file
    $I->[M_lasterror]="$name: read failed: $!";
    close $f;
    return;
  }

  close $f;

  return $I;
}

BEGIN {
  foreach my $n (qw{heap stack vdso vsyscall}) {
    no strict 'refs';
    my $name=$n;
    my $s="[$n]";
    *{__PACKAGE__.'::'.$name}=sub {
      foreach my $el (@{$_[0]->[M__elem]}) {
	$el->_parse if !defined($el->[V_file_name]) and defined($el->[V__line]);
	return $el if $s eq $el->[V_file_name];
      }
    };
  }
}

sub unnamed {
  my $I=shift;
  if( wantarray ) {
    return grep {
      $_->_parse if !defined($_->[V_file_name]) and defined($_->[V__line]);
      !length $_->[V_file_name];
    } @{$I->[M__elem]};
  } else {
    my @idx=@Linux::Smaps::VMA::attr_idx{qw/size rss shared_clean shared_dirty
					    private_clean private_dirty/};
    my $sum=Linux::Smaps::VMA->new((0)x@Linux::Smaps::VMA::attributes);
    foreach my $el (@{$I->[M__elem]}) {
      $el->_parse if !defined($el->[V_file_name]) and defined($el->[V__line]);
      next if( length $el->[V_file_name] );
      foreach my $idx (@idx) {$sum->[$idx]+=$el->[$idx]}
    }
    return $sum;
  }
}

sub named {
  my $I=shift;
  if( wantarray ) {
    return grep {
      $_->_parse if !defined($_->[V_file_name]) and defined($_->[V__line]);
      length $_->[V_file_name];
    } @{$I->[M__elem]};
  } else {
    my @idx=@Linux::Smaps::VMA::attr_idx{qw/size rss shared_clean shared_dirty
					    private_clean private_dirty/};
    my $sum=Linux::Smaps::VMA->new((0)x@Linux::Smaps::VMA::attributes);
    foreach my $el (@{$I->[M__elem]}) {
      $el->_parse if !defined($el->[V_file_name]) and defined($el->[V__line]);
      next if( !length $el->[V_file_name] );
      foreach my $idx (@idx) {$sum->[$idx]+=$el->[$idx]}
    }
    return $sum;
  }
}

sub all {
  my $I=shift;
  if( wantarray ) {
    return @{$I->[M__elem]};
  } else {
    my @idx=@Linux::Smaps::VMA::attr_idx{qw/size rss shared_clean shared_dirty
					    private_clean private_dirty/};
    my $sum=Linux::Smaps::VMA->new((0)x@Linux::Smaps::VMA::attributes);
    foreach my $el (@{$I->[M__elem]}) {
      foreach my $idx (@idx) {$sum->[$idx]+=$el->[$idx]}
    }
    return $sum;
  }
}

sub names {
  my $I=shift;
  local $_;
  my %h;
  undef @h{map {
    $_->_parse if !defined($_->[V_file_name]) and defined($_->[V__line]);
    $_->[V_file_name];
  } @{$I->[M__elem]}};
  delete @h{'',qw/[heap] [stack] [vdso] [vsyscall]/};
  return keys %h;
}

sub diff {
  my $I=shift;
  my @my_special;
  my @my=map {
    $_->_parse if !defined($_->[V_file_name]) and defined($_->[V__line]);
    if( $_->[V_file_name]=~/\[\w+\]/ ) {
      push @my_special, $_;
      ();
    } else {
      $_;
    }
  } @{$I->[M__elem]};
  my %other_special;
  my %other=map {
    $_->_parse if !defined($_->[V_file_name]) and defined($_->[V__line]);
    if( $_->[V_file_name]=~/^(\[\w+\])$/ ) {
      $other_special{$1}=$_;
      ();
    } else {
      ($_->[V_vma_start]=>$_);
    }
  } @{shift->[M__elem]};

  my @new;
  my @diff;
  my @old;

  foreach my $vma (@my_special) {
    if( exists $other_special{$vma->[V_file_name]} ) {
      my $x=delete $other_special{$vma->[V_file_name]};
      push @diff, [$vma, $x]
	if( $vma->[V_vma_start] != $x->[V_vma_start] or
	    $vma->[V_vma_end] != $x->[V_vma_end] or
	    $vma->shared_clean != $x->shared_clean or
	    $vma->shared_dirty != $x->shared_dirty or
	    $vma->private_clean != $x->private_clean or
	    $vma->private_dirty != $x->private_dirty or
	    $vma->[V_dev_major] != $x->[V_dev_major] or
	    $vma->[V_dev_minor] != $x->[V_dev_minor] or
	    $vma->[V_r] != $x->[V_r] or
	    $vma->[V_w] != $x->[V_w] or
	    $vma->[V_x] != $x->[V_x] or
	    $vma->[V_file_off] != $x->[V_file_off] or
	    $vma->[V_inode] != $x->[V_inode] or
	    $vma->[V_mayshare] != $x->[V_mayshare] );
    } else {
      push @new, $vma;
    }
  }
  @old=values %other_special;

  foreach my $vma (@my) {
    if( exists $other{$vma->[V_vma_start]} ) {
      my $x=delete $other{$vma->[V_vma_start]};
      push @diff, [$vma, $x]
	if( $vma->[V_vma_end] != $x->[V_vma_end] or
	    $vma->shared_clean != $x->shared_clean or
	    $vma->shared_dirty != $x->shared_dirty or
	    $vma->private_clean != $x->private_clean or
	    $vma->private_dirty != $x->private_dirty or
	    $vma->[V_dev_major] != $x->[V_dev_major] or
	    $vma->[V_dev_minor] != $x->[V_dev_minor] or
	    $vma->[V_r] != $x->[V_r] or
	    $vma->[V_w] != $x->[V_w] or
	    $vma->[V_x] != $x->[V_x] or
	    $vma->[V_file_off] != $x->[V_file_off] or
	    $vma->[V_inode] != $x->[V_inode] or
	    $vma->[V_mayshare] != $x->[V_mayshare] or
	    $vma->[V_file_name] ne $x->[V_file_name] );
    } else {
      push @new, $vma;
    }
  }
  push @old, sort {$a->[V_vma_start] <=> $b->[V_vma_start]} values %other;

  return \@new, \@diff, \@old;
}

sub vmas {return @{$_[0]->_elem};}

{
  my $once;
  sub import {
    my $class=shift;
    unless( $once ) {
      $once=1;
      eval {$class->new(@_)};
    }
  }
}

1;
__END__

=encoding utf8

=head1 NAME

Linux::Smaps - a Perl interface to /proc/PID/smaps

=head1 SYNOPSIS

  use Linux::Smaps;
  my $map=Linux::Smaps->new($pid);
  my @vmas=$map->vmas;
  my $private_dirty=$map->private_dirty;
  ...

=head1 DESCRIPTION

The F</proc/PID/smaps> files in modern linuxes provides very detailed
information about a processes memory consumption. It particularly includes
a way to estimate the effect of copy-on-write. This module implements a Perl
interface.

The content of the F<smaps> file is a set of blocks like this:

 0060a000-0060b000 r--p 0000a000 fd:01 531212       /bin/cat
 Size:                  4 kB
 Rss:                   4 kB
 Pss:                   4 kB
 Shared_Clean:          0 kB
 Shared_Dirty:          0 kB
 Private_Clean:         0 kB
 Private_Dirty:         4 kB
 Referenced:            4 kB
 Swap:                  0 kB
 KernelPageSize:        4 kB
 MMUPageSize:           4 kB

Each one describes a virtual memory area of a certain process. All those
areas together describe its complete address space. For the meaning of
the items refer to your Linux documentation.

The set of information announced by the kernel depends on its version. Early
versions (around Linux 2.6.14) lacked for example C<Pss>, C<Referenced>,
C<Swap>, C<KernelPageSize> and C<MMUPageSize>. C<Linux::Smaps> provides an
interface to all of the components. It creates accessor methods dynamically
depending on what the kernel reveals. The C<Shared_Clean> entry for example
mutates to the C<< Linux::Smaps::VMA->shared_clean >> accessor. Method
names are built by simply lowercasing them. The actual set of methods is
created when the first F<smaps> file is parsed. Subsequent C<update>
or C<< Linux::Smaps->new >> operations expect exactly the same file format.
That means you cannot parse F<smaps> files from different kernel versions
by the same perl interpreter.

=head2 Constructor, Object Initialization, etc.

=head3 Linux::Smaps-E<gt>new

=head3 Linux::Smaps-E<gt>new($pid)

=head3 Linux::Smaps-E<gt>new(pid=E<gt>$pid, procdir=E<gt>'/proc')

=head3 Linux::Smaps-E<gt>new(filename=E<gt>'/proc/self/smaps')

creates and initializes a C<Linux::Smaps> object. On error an exception is
thrown. C<new()> may fail if the smaps file is not readable or if the file
format is wrong.

C<new()> without parameter is equivalent to C<new('self')> or
C<< new(pid=>'self') >>. With the C<procdir> parameter the mount point of
the proc filesystem can be set if it differs from the standard C</proc>.

The C<filename> parameter sets the name of the smaps file directly. This way
also files outside the standard C</proc> tree can be analyzed.

=head3 Linux::Smaps-E<gt>new(uninitialized=E<gt>1)

returns an uninitialized object. This makes C<new()> simply skip the C<update()>
call after setting all parameters. Additional parameters like C<pid>,
C<procdir> or C<filename> can be passed.

=head3 $self-E<gt>pid($pid) or $self-E<gt>pid=$pid

=head3 $self-E<gt>procdir($dir) or $self-E<gt>procdir=$dir

=head3 $self-E<gt>filename($name) or $self-E<gt>filename=$name

get/set parameters.

If a filename is set C<update()> reads that file. Otherwize a file name is
constructed from C<< $self->procdir >>, C<< $self->pid >> and the name
C<smaps>. The constructed file name is not saved in the C<Linux::Smaps>
object to allow loops like this:

 foreach (@pids) {
     $smaps->pid=$_;
     $smaps->update;
     process $smaps;
 }

=head3 $self-E<gt>update

reinitializes the object; rereads the underlying file. Returns the object
or C<undef> on error. The actual reason can be obtained via C<lasterror()>.

=head3 $self-E<gt>clear_refs

writes to the corresponding F</proc/PID/clear_refs> file. Thus, the amount
of memory reported as C<Referenced> by the process is reset to C<0> for
all VMAs.

Returns the object or C<undef> on failure.

Example:

 # how much memory is referenced while updating the Linux::Smaps object?
 perl -MLinux::Smaps -le '
   my $s=Linux::Smaps->new;
   print $s->referenced;
   print $s->clear_refs->update->referenced
 '
 2556
 840

 # how much memory is used while the shell is inactive?
 perl -MLinux::Smaps -le '
   my $s=Linux::Smaps->new(shift);
   print $s->referenced;
   print $s->clear_refs->update->referenced
 ' $$
 1468
 0

=head3 $self-E<gt>lasterror

C<update()> and C<new()> return C<undef> on failure. C<lasterror()> returns
a more verbose reason. Also C<$!> can be checked.

=head2 Information Retrieval

=head3 $self-E<gt>vmas

returns a list of C<Linux::Smaps::VMA> objects each describing a vm area,
see below.

=head3 $self-E<gt>size

=head3 $self-E<gt>rss

=head3 $self-E<gt>shared_clean

=head3 $self-E<gt>shared_dirty

=head3 $self-E<gt>private_clean

=head3 $self-E<gt>private_dirty

these methods compute the sums of the corresponding values of all vmas.

C<size>, C<rss>, C<shared_clean>, C<shared_dirty>, C<private_clean> and
C<private_dirty> methods are unknown until the first call to
C<Linux::Smaps::update()>. They are created on the fly. This is to make
the module extendable as new features are added to the smaps file by the
kernel. As long as the corresponding smaps file lines match
C<^(\w+):\s*(\d+) kB$> new accessor methods are created.

At the time of this writing at least one new field (C<referenced>) is on
the way but all my kernels still lack it.

=head3 $self-E<gt>stack

=head3 $self-E<gt>heap

=head3 $self-E<gt>vdso

=head3 $self-E<gt>vsyscall

these are shortcuts to the corresponding C<Linux::Smaps::VMA> objects.

=head3 $self-E<gt>all

=head3 $self-E<gt>named

=head3 $self-E<gt>unnamed

In array context these functions return a list of C<Linux::Smaps::VMA>
objects representing named or unnamed VMAs or simply all VMAs. Thus, in
array context C<all()> is equivalent to C<vmas()>.

In scalar context these functions create a fake C<Linux::Smaps::VMA> object
containing the summaries of the C<size>, C<rss>, C<shared_clean>,
C<shared_dirty>, C<private_clean> and C<private_dirty> fields.

=head3 $self-E<gt>names

returns a list of vma names, i.e. the files that are mapped.

=head3 ($new, $diff, $old)=$self-E<gt>diff( $other )

$other is assumed to be also a C<Linux::Smaps> instance. 3 arrays are
returned. The first one ($new) is a list of vmas that are contained in
$self but not in $other. The second one ($diff) contains a list of pairs
(2-element arrays) of vmas that differ between $self and $other. The
3rd one ($old) is a list of vmas that are contained in $other but not in
$self.

Vmas are identified as corresponding if their C<vma_start> fields match.
They are considered different if they differ in one of the following fields:
C<vma_end>, C<r>, C<w>, C<x>, C<mayshare>, C<file_off>, C<dev_major>,
C<dev_minor>, C<inode>, C<file_name>, C<shared_clean>, C<shared_diry>,
C<private_clean> and C<private_dirty>.

=head2 C<Linux::Smaps::VMA> objects

normally these objects represent a single vm area:

=head3 $self-E<gt>vma_start

=head3 $self-E<gt>vma_end

start and end address

=head3 $self-E<gt>r

=head3 $self-E<gt>w

=head3 $self-E<gt>x

=head3 $self-E<gt>mayshare

these correspond to the VM_READ, VM_WRITE, VM_EXEC and VM_MAYSHARE flags.
see Linux kernel for more information.

=head3 $self-E<gt>file_off

=head3 $self-E<gt>dev_major

=head3 $self-E<gt>dev_minor

=head3 $self-E<gt>inode

=head3 $self-E<gt>file_name

describe the file area that is mapped.

=head3 $self-E<gt>size

the same as vma_end - vma_start but in kB.

=head3 $self-E<gt>rss

what part is resident.

=head3 $self-E<gt>shared_clean

=head3 $self-E<gt>shared_dirty

=head3 $self-E<gt>private_clean

=head3 $self-E<gt>private_dirty

C<shared> means C<< page_count(page)>=2 >> (see Linux kernel), i.e. the page
is shared between several processes. C<private> pages belong only to one
process.

C<dirty> pages are written to in RAM but not to the corresponding file.

=head2 Notes

C<size>, C<rss>, C<shared_clean>, C<shared_dirty>, C<private_clean> and
C<private_dirty> methods are unknown until the first call to
C<Linux::Smaps::update>. They are created on the fly. This is to make
the module extendable as new features are added to the smaps file by the
kernel. As long as the corresponding smaps file lines match
C<^(\w+):\s*(\d+) kB$> new accessor methods are created.

See also L</EXPORT> below.

=head1 Example: The copy-on-write effect

 use strict;
 use Linux::Smaps;

 my $x="a"x(1024*1024);		# a long string of "a"
 if( fork ) {
   my $s=Linux::Smaps->new($$);
   my $before=$s->all;
   $x=~tr/a/b/;			# change "a" to "b" in place
   #$x="b"x(1024*1024);		# assignment
   $s->update;
   my $after=$s->all;
   foreach my $n (qw{rss size shared_clean shared_dirty
                     private_clean private_dirty}) {
     print "$n: ",$before->$n," => ",$after->$n,": ",
            $after->$n-$before->$n,"\n";
   }
   wait;
 } else {
   sleep 1;
 }

This script may give the following output:

 rss: 4160 => 4252: 92
 size: 6916 => 7048: 132
 shared_clean: 1580 => 1596: 16
 shared_dirty: 2412 => 1312: -1100
 private_clean: 0 => 0: 0
 private_dirty: 168 => 1344: 1176

C<$x> is changed in place. Hence, the overall process size (size and rss)
would not grow much. But before the C<tr> operation C<$x> was shared by
copy-on-write between the 2 processes. Hence, we see a loss of C<shared_dirty>
(only a little more than our 1024 kB string) and almost the same growth of
C<private_dirty>.

Exchanging the C<tr>-operation to an assingment of a MB of "b" yields the
following figures:

 rss: 4160 => 5276: 1116
 size: 6916 => 8076: 1160
 shared_clean: 1580 => 1592: 12
 shared_dirty: 2432 => 1304: -1128
 private_clean: 0 => 0: 0
 private_dirty: 148 => 2380: 2232

Now we see the overall process size grows a little more than a MB.
C<shared_dirty> drops almost a MB and C<private_dirty> adds almost 2 MB.
That means perl first constructs a 1 MB string of C<b>. This adds 1 MB to
C<size>, C<rss> and C<private_dirty> and then copies it to C<$x>. This
takes another MB from C<shared_dirty> and adds it to C<private_dirty>.

=head1 A special note on copy on write measurements

The proc filesystem reports a page as shared if it belongs multiple
processes and as private if it belongs to only one process. But there
is an exception. If a page is currently paged out (that means it is not
in core) all its attributes including the reference count are paged out
as well. So the reference count cannot be read without paging in the page.
In this case a page is neither reported as private nor as shared. It is
only included in the process size.

Thus, to exaclty measure which pages are shared among N processes at least
one of them must be completely in core. This way all pages that can
possibly be shared are in core and their reference counts are accessible.

The L<mlockall(2)> syscall may help in this situation. It locks all pages
of a process to main memory:

 require 'syscall.ph';
 require 'sys/mmap.ph';

 0==syscall &SYS_mlockall, &MCL_CURRENT | &MCL_FUTURE or
     die "ERROR: mlockall failed: $!\n";

This snippet in one of the processes locks it to the main memory. If all
processes are created from the same parent it is executed best just before
the parent starts to fork off children. The memory lock is not inherited
by the children. So all private pages of the children are swappable.

=head1 EXPORT

The module's C<import()> method is implemented as follows:

 my $once;
 sub import {
   my $class=shift;
   unless( $once ) {
     $once=1;
     eval {$class->new(@_)};
   }
 }

Thus, the first

 use Linux::Smaps;

initializes all methods according to your current kernel.

To avoid that use

 use Linux::Smaps ();

If your C<proc> filesystem is mounted elsewhere or if you want to initialize
the methods according to a certain file you can achieve this by

 use Linux::Smaps (procdir=>'/procfs');

or

 use Linux::Smaps (filename=>'/path');

=head1 SEE ALSO

Linux Kernel.

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2011 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
