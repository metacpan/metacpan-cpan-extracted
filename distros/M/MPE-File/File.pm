package MPE::File;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( 'all' => [ qw(
mpefopen openfile readrec writerec hpfopen hperrmsg fread ccode
fcheck fwrite fclose flock funlock fpoint fcontrol fdelete ferrmsg
printfileinfo iowait iodontwait flabelinfo $MPE_error freadlabel
fwritelabel mpe_fileno lastwaitfilenum mpeprint printop printopreply
@itemerror
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
  $MPE_error flabelinfo lastwaitfilenum iowait iodontwait
  printop printopreply mpeprint
);
our $VERSION = '0.06';
our @flabeltypes = qw( x
  A8 A8 A8 A8    L S S S s S
  S l S s s      s s s L L
  S l A8 L a256  x a20 L L L
  L L A8 A34 A32 L S z L l
  l S A32 l A32  l L L q l
  l l s l l      l l l l l
  l q q l
);

our @ffileinfotypes = qw( x
  A28 S S s s S S s l l
  l l l s s S s A18 l s
  s s s s s A32 A32 S s s
  s S s s s S l S x l
  s s A36 s A18 s s s S S
  s l S S S l s s s s
  A52 A8 a20 q x L L L L x
  x x x q A64 A34 L L s z
  L l l S A32 l A32 l L L
  q l L l l l l l l l
  l l l l l l l l q l
);

our @itemerror;

sub new {
  my $class = shift;
  my $self = mpehpfopen(52, @_);

  if (defined($self) && $self) {
     bless \$self, $class;
  } else {
    return undef;
  }
  return \$self;
}

sub fopen {
  my $class = shift;
  my $self = mpefopen(@_);
  if (defined($self) && $self) {
     bless \$self, $class;
  } else {
    return undef;
  }
  return \$self;
}

sub hpfopen {
  my $class = shift;
  my $self = mpehpfopen(@_);
  if (defined($self) && $self) {
     bless \$self, $class;
  } else {
    return undef;
  }
  return \$self;
}

sub print {
  my $self = shift;
  my $sep = defined($,)?$,:'';
  my $eol = defined($\)?$\:'';
  $self->writerec(join($sep , @_) . $eol);
}

sub printf {
  my $self = shift;
  my $fmt = shift;
  $self->writerec(sprintf $fmt, @_);
}


# flabelinfo($filename, $mode, item, ...)
sub flabelinfo {
   my $itemsout = "";
   my $itemcount = 0;
   my $unpack = "";
   my @itemsin;
   my $items;
   my @quaditems;
   my @pathitems;
   my $fserr = 0;
   my $itemerror;
   my $itemnum;
   my $name = shift;
   my $mode = shift;
   while ($itemnum = shift) {
     my $type;
     if (defined($type = $flabeltypes[$itemnum]) && $type ne 'x') {
       push @itemsin, $itemnum;
       if ($type eq 'q') {
         push @quaditems, $itemcount;
	 $itemsout .= "\0" x 8;
	 $unpack .= "a8";
       } elsif ($type eq 'z') {
         push @pathitems, $itemcount;
	 $itemsout .= pack "Na1024", 1024, "";
	 $unpack .= "a1028";
       } elsif ($type =~ /^[SL]/i) {
	 $itemsout .= pack $type, 0;
	 $unpack .= $type;
       } else {
	 $itemsout .= pack $type, "";
	 $unpack .= $type;
       }
       ++$itemcount;
     }
   }


   $itemerror = "\0\0" x scalar(@itemsin);
   push @itemsin, 0;
   $items = pack "s*", @itemsin;
   @itemerror = ();
   if (!mpeflabelinfo($name, $mode, $items, $itemsout, $itemerror)) {
     @itemerror = unpack "s*", $itemerror;
     return ();
   }

   my @arrayout = unpack $unpack, $itemsout;

   for (@quaditems) {
     $arrayout[$_] = quadunpack($arrayout[$_]);
   }
   for (@pathitems) {
     ($arrayout[$_]) = unpack("N/a", $arrayout[$_]);
   }
   return @arrayout;
}

sub ffileinfo {
  my $self = shift;
  my @return = ();
  my $nextitem;

  while ($nextitem = shift) {
    my @items  = (0,0,0,0,0,0,0,0,0,0);
    my @types  = qw(a b c d e);
    my $i = 0;
    my $j = 0;
    do {
      my $type;
      if (defined($type = $ffileinfotypes[$nextitem]) && $type ne 'x') {
	 $items[$i] = $nextitem;
	 $i++;
	 $types[$j] = $type;
	 if ($type eq 'q') {
	   $items[$i] = "\0" x 8;
	 } elsif ($type eq 'z') {
	   $items[$i] = pack "Na1024", 1024, "";
	 } elsif ($type =~ /^[SL]/i) {
	   $items[$i] = pack $type, 0;
	 } else {
	   $items[$i] = pack $type, "";
	 }
	 $i++;
	 $j++;
      }
    } while ($i < 10 && ($nextitem = shift));

    mpeffileinfo($self, @items);
    $j = 0;
    for (my $k = 1; $k < $i; $k += 2, $j++) {
      my $type = $types[$j];
      if ($type eq 'q') {
	push @return, quadunpack($items[$k]);
      } elsif ($type eq 'z') {
        push @return, unpack("N/a", $items[$k]);
      } else {
        push @return, unpack($type, $items[$k]);
      }
    }
  }
  return @return;
}

sub quadunpack {
  my ($high, $out) = unpack("NN", $_[0]);
  $out += $high * (2 ** 32) if $high;
  return $out;
}

bootstrap MPE::File $VERSION;

1;
__END__

=head1 NAME

MPE::File - Perl extension for accessing MPE File intrinsics

=head1 SYNOPSIS

  use MPE::File;
  $file = MPE::File->new("FRED.PUB,old;acc=in")
    or die "Cannot open FRED.PUB: $MPE_error\n";
  OR
  $file = MPE::File->hpfopen(2, "FRED.PUB", 3, 1, 11, 0)
    or die "Cannot open FRED.PUB: $MPE_error\n";
  OR
  $file = MPE::File->fopen("FRED.PUB", 1, 0)
    or die "Cannot open FRED.PUB: $MPE_error\n";

  $rec = $file->readrec();   # use this instead of fread

  $rec = $file->freadbykey($key, $keyloc);
  $rec = $file->freadlabel( [$labelid] );
  $rec = $file->freaddir($lrecnum);
  $rec = $file->freadc();
  $file->fread($buffer, $bufsize);


  $file->writerec($buffer, [$controlcode] )   # use this instead of fwrite
  # (do not include '\n' at end of rec)

  $file->print($a, $b, $c);
  $file->printf($fmt, $a, $b, $c);
  # (do not include '\n' at end of rec)
 

  $file->fupdate($buffer);
  $file->fwritedir($buffer, $lrecnum);
  $file->fwritelabel ($buffer, [$labelid] )
  $file->fwrite($buffer, $length, $controlcode)

  $file->fpoint($lrecnum);
  $file->fcontrol($itemnum, $item);
  $file->fdelete( [$lrecnum] );
  $file->fsetmode($modeflags);
  $file->fremove();
  $file->fgetkeyinfo($param, $control);
  $file->ffindbykey($value, $location, $length, $relop);
  $file->printfileinfo();

  $rec = $file->iowait();
    or
  $rec =iowait(0);
   then call lastwaitfilenum() to get file number

  $rec->mpe_fileno
    You'll need this to compare with lastwaitfilenum()

  mpeprint("rec");
    Calls MPE intrinsic PRINT()
    (Perl print does not work right if stdout is circular file, msg file, ...)

  printop($msg);
  $rec = printopreply($msg);

  @info = $file->ffileinfo(1, 3, 7, 9);

  @info = flabelinfo("FRED.PUB", $mode, 1, 3, 7, 9);
    If there is an error, an empty list is returned and you can check
    $MPE_error and @MPE::File::itemerror for the error

  $errmsg = ferrmsg($fserrcode);
  hperrmsg($displaycode,...)

=head1 DESCRIPTION

  The primary reference should be the MPE/iX Intrinsic Reference Manual
  (available at http://docs.hp.com/mpeix/all/index.html)

  Notice that there are some difference in parameters.
  For example, I take care of all the delimited strings in HPFOPEN

  Subroutines return 0 or undef on failure; check $MPE_error for
  the error number and/or string (both should be valid).
  For example:
    if ($MPE_error == 52) {
      print 0+$MPE_error, " ", $MPE_error, "\n";
    }
  Will print
   52 NONEXISTENT PERMANENT FILE  (FSERR 52)
  (if that is the error).

  MPE::File->new($x) is the same as MPE::File->hpfopen(52, $x)
  which, to quote the Intrinsic manual:
    "Passes a character string that matches the file equation
    specification syntax exactly."

  You can pass other HPFOPEN parameter pairs after the first
  one, although almost all can be specified in the file equation.
  
  One that can't be is to save a file right away, on HPFOPEN, instead
  of waiting until FCLOSE.  You can do that like this:
  $file = MPE::File->new("FRED,new;rec=-80,,f,ascii;msg;acc=in", 3, 4)
     or die "Cannot open FRED: $MPE_error\n";
  (Notice the 3, 4 pair at the end.)

  If you use FFREADBYKEY, remember to pad out your keys to the full
  length.  Also, if they are binary keys, you'll need to use pack,
  otherwise a number will be converted to its string equivalent.

  This documentation will be expanded at some point; feel free to
  send me suggestions (or completed paragraphs).


=head2 EXPORT

flabelinfo $MPE_error

=head1 AUTHOR

Ken Hirsch E<lt>F<kenhirsch@myself.com>E<gt>

This module may be used and distributed on the same terms as Perl.

=head1 SEE ALSO

perl(1).

=cut
