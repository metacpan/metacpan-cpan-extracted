package Devel::Size::Report;

require 5.006;

$VERSION = '0.13';

use Devel::Size qw(size total_size);
use Scalar::Util qw/reftype refaddr blessed dualvar isweak readonly isvstring/;
use Time::HiRes qw/time/;
use Array::RefElem qw/hv_store av_push/;
use Devel::Peek qw/SvREFCNT/;

require Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/
  report_size track_size element_type type entries_per_element track_sizes
  hide_tracks

  S_SCALAR
  S_HASH
  S_ARRAY
  S_GLOB
  S_UNKNOWN
  S_CODE
  S_LVALUE
  S_REGEXP
  S_CYCLE
  S_DOUBLE
  S_VSTRING
  
  SF_WEAK
  SF_KEY
  SF_REF
  SF_WEAK
  SF_RO
  SF_DUAL
  SF_MAGIC

  /;

use strict;

#############################################################################
# The following should not be global to be thread safe:

# If somebody used hv_store, we need also to enter hash key addresses into
# SEEN. Default is off, because this wastes memory.
my $TRACK_DOUBLES = 0;

# _track_size() stores it's result here:
my @sizes;

# for cycles in memory:
my %SEEN;

# count calls to track_size for statistics
my $CALLS;

#############################################################################
# The overhead for one ref. Used to correct the results from Devel::Size.
my $SIZE_OF_REF;

BEGIN
  {
  # disable any warnings Devel::Size might spill
  $Devel::Size::warn = 0;

  # Devel::Size will dereference arguments, so it misses the size of the
  # reference. Compute the size for \\0 and \0 and infer the overhead for
  # one reference from that. Thanx to SADAHIRO Tomoyuki.

  $SIZE_OF_REF = total_size(\\0) - total_size(\0);
  }

# scalar that can be entered into %SEEN many times:
my $UNDEF = undef;
# scalar that can be entered into @sizes many times:
my $ZERO = 0;

# the different types of elements
use constant {
  S_UNKNOWN	=> 0,
  S_CYCLE	=> 1,
  S_SCALAR	=> 2,
  S_ARRAY	=> 3,
  S_HASH	=> 4,
  S_GLOB	=> 5,
  S_CODE	=> 6,
  S_REGEXP	=> 7,
  S_LVALUE	=> 8,
  S_DOUBLE	=> 9,
  S_VSTRING	=> 10 };

# some flags (to be added to the types)
use constant {
  SF_KEY 	=> 0x0100,
  SF_REF	=> 0x0200,
  SF_BLESS	=> 0x0400,
  SF_WEAK	=> 0x0800,
  SF_RO		=> 0x1000,
  SF_DUAL	=> 0x2000,
  SF_MAGIC	=> 0x4000 };

sub entries_per_element () { 7; }

# default mapping for type output names (human readable)
my $TYPE = { 
  S_SCALAR() => 'Scalar', 
  S_UNKNOWN() => 'Unknown', 
  S_HASH() => 'Hash ref', 
  S_GLOB() => 'Glob', 
  S_ARRAY() => 'Array ref', 
  S_CODE() => 'Code', 
  S_REGEXP() => 'Regexp', 
  S_LVALUE() => 'Lvalue', 
  S_CYCLE() => 'Circular ref', 
  S_DOUBLE() => 'Double scalar ref', 
  S_VSTRING() => 'VString',

  SF_REF() => 'Ref', 
  SF_BLESS() => 'Blessed', 
  SF_WEAK() => 'Weak', 
  SF_RO() => 'Read-Only', 
  SF_DUAL() => 'Dual-Var', 
  SF_MAGIC() => 'Magical', 
  SF_KEY() => '', 
  };

# default mapping for type name (internal comparisation)
my $TYPE_CLASS = { 
  S_SCALAR() => 'SCALAR', 
  S_UNKNOWN() => 'UNKNOWN', 
  S_HASH() => 'HASH', 
  S_GLOB() => 'GLOB', 
  S_ARRAY() => 'ARRAY', 
  S_CODE() => 'CODE', 
  S_REGEXP() => 'REGEXP', 
  S_LVALUE() => 'LVALUE', 
  S_CYCLE() => 'CYCLE', 
  S_DOUBLE() => 'DOUBLE', 
  S_VSTRING() => 'VSTRING', 
  };

# map 'SCALAR' => S_SCALAR
my $NAME_MAP = { 
  SCALAR => S_SCALAR(),
  HASH => S_HASH(),
  GLOB => S_GLOB(),
  ARRAY => S_ARRAY(),
  CODE => S_CODE(),
  REGEXP => S_REGEXP(),
  LVALUE => S_LVALUE(),
  CYCLE => S_CYCLE(),
  DOUBLE => S_DOUBLE(),
  VSTRING => S_VSTRING(),

  REF => SF_REF(),
  KEY => SF_KEY(),
  WEAK => SF_WEAK(),
  DUAL => SF_DUAL(),
  RO => SF_RO(),
  MAGIC => SF_MAGIC(), 
  };

sub _default_options
  {
  # set the options to their default values
  my ($options) = @_;

  my $o = {};
  for my $k (keys %$options) { $o->{$k} = $options->{$k}; }
  
  $o->{indent} = '  ' if !defined $o->{indent};
  $o->{names} ||= $TYPE;

  $o->{bytes} = 'bytes' unless defined $o->{bytes};
  $o->{bytes} = ' ' . $o->{bytes} if $o->{bytes} ne '';

  $o->{left} = '' if !defined $o->{left};
  $o->{inner} = '  ' if !defined $o->{inner};
  
  $o->{total} = 1 if !defined $o->{total};

  $o->{head} = "Size report v$Devel::Size::Report::VERSION for" if !defined $o->{head};

  $o->{overhead} = " (overhead: %i%s, %0.2f%%)" if !defined $o->{overhead};

  # binary flags
  for my $k (qw/addr terse class/)
    {
    $o->{$k} ||= 0;
    }

  $o; 
  }

sub report_size
  {
  # walk the given reference recursively and return text describing the size
  # of each element
  my ($ref,$opt) = @_;
  
  $opt = {} unless defined $opt;
  if (ref($opt) ne 'HASH')
    {
    require Carp;
    Carp::confess ("report_size() needs a hash ref for options");
    }  
  
  my $options = _default_options($opt);

  $TRACK_DOUBLES = $options->{doubles} || 0;
  
  # DONT do "track_size($ref)" because $ref is a copy of $_[0], reusing some
  # pre-allocated slot and this can have a different total size than $_[0]!!

  # get the size for all elements so that we can generate a report on it
  track_sizes($_[0],$opt);

  my $text = '';
 
  my $indent = $options->{indent};
  my $names = $options->{names};
  my $bytes = $options->{bytes};
  my $left = $options->{left}; 
  my $inner = $options->{inner};
  $inner .= $left;
  
  my $total = $options->{total};
  my $head = $options->{head}; 
  my $terse = $options->{terse}; 
  # show summary?
  my $show_summary = $options->{summary};

  my $foverhead = $options->{overhead};
  
  # show class?
  my $class = $options->{class};
  
  # show addr?
  my $addr = $options->{addr};

  my $count = {};		# per class/element type counter
  my $sum = {};			# per class/element memory sum

  # XXX TODO: why not HASH here?
  my $r = ref($ref); $r = '' if $r =~ /^(ARRAY|SCALAR)$/;
  $r = " ($r)" if $r ne '';
  $text = "$left$head '$ref'$r:\n" if $head ne '';

  my $e = entries_per_element();
  
  for (my $i = 0; $i < @sizes; $i += $e)
    {
    # inline element_type for speed:
    # my $type = element_type( ($sizes[$i+1] & 0xFF),$names);
    my $type = $names->{ ($sizes[$i+1] & 0xFF) } || 'Unknown';

    if ($show_summary)
      {
      my $t = $sizes[$i+1] & 0xFF; $t = $TYPE_CLASS->{$t};
      $t = $sizes[$i+6] if $sizes[$i+6];
      print "# $t $sizes[$i+1]\n" if $t eq '_set';
      if ($t) 
        {
        $count->{$t} ++;
        $sum->{$t} += $sizes[$i+2];
        }
      # else { should not happen }
      }

    if (!$terse)
      {
      # include flags
      for my $flag (SF_WEAK, SF_RO, SF_DUAL)
        {
        if ( ($sizes[$i+1] & $flag) != 0)
          {
          $type = element_type($flag, $names) . ' ' . $type;
          }
        }
      if ( ($sizes[$i+1] & SF_REF) != 0)
        {
        $type .= " " . element_type(SF_REF, $names);
        }

      # add addr of element if wanted
      $type .= "(" . $sizes[$i+5] . ")" if $addr && $sizes[$i+5];

      # add class of element if wanted
      $type .= " (" . $sizes[$i+6] . ")" if $class && $sizes[$i+6];

      my $str = $type;
      if ( ($sizes[$i+1] & SF_KEY) != 0)
        {
        $str = "'$sizes[$i+4]' => " . $type;
        }
      $str .= " $sizes[$i+2]$bytes";
      if ($sizes[$i+3] != 0)
        {
        my $overhead = 
	  sprintf($foverhead, $sizes[$i+3], $bytes, 
	   100 * $sizes[$i+3] / $sizes[$i+2]); 
          $overhead = ' (overhead: unknown)' if $sizes[$i+3] < 0;
        $str .= $overhead;
        }
      $text .= $inner . ($indent x $sizes[$i]) . "$str\n";
      }
    } 

  if ($show_summary)
    {
    # default sort is by size
    my $sort = sub { $sum->{$b} <=> $sum->{$a} };

    $text .= "Total memory by class (inclusive contained elements):\n";
    foreach my $k (sort $sort keys %$count)
      {
      $text .= $indent . _right_align($sum->{$k},10) . " bytes in " . _right_align($count->{$k},6) . " $k\n";
      }
    }
  my $elements = scalar @sizes / $e;
  $text .= $left . "Total: $sizes[2]$bytes in $elements elements\n" if $total;

  hide_tracks();		# release memory

  $text;
  }

sub hide_tracks
  {
  @sizes = ();
  }

sub _right_align
  {
  my ($txt,$len) = @_;

  $txt = ' ' . $txt while (length($txt) < $len);
  $txt;
  }

sub element_type
  {
  my ($type,$TYPE) = @_;
  $TYPE->{$type} || 'Unknown';
  }

sub type
  {
  # map a typename to a type number
  $NAME_MAP->{$_[0]} || S_UNKNOWN;
  }

sub track_sizes
  {
  my $opt = $_[1];

  $TRACK_DOUBLES = $opt->{doubles} || 0;
  
  my $time = time();		# record start time
  undef %SEEN;			# reset cycle memory
  $CALLS = 0;
  @sizes = ();			# reset results array & stores result:
  _track_size($_[0]); 		# use $_[0] directly to avoid slot-reusing

  if ($opt->{debug})
    {
    $time = time() - $time; 
    print STDERR "\n DEBUG: Devel::Size::Report v$Devel::Size::Report::VERSION\n";
    my $size_seen = total_size(\%SEEN);
    my $size_sizes = total_size(\@sizes);

    print STDERR " DEBUG: \%SEEN : ", _right_align($size_seen,12), " bytes, ", scalar keys %SEEN, " elements\n";
    print STDERR " DEBUG: \@sizes: ", _right_align($size_sizes,12), " bytes, ", scalar @sizes, " elements\n";
    print STDERR " DEBUG: Total : ", _right_align($size_sizes + $size_seen,12), " bytes, ", scalar @sizes + scalar keys %SEEN, " elements\n";
    print STDERR " DEBUG: Calls to _track_size: $CALLS\n";
    print STDERR " DEBUG: took ", sprintf("%0.3f",$time), " seconds to gather data for report.\n\n";
    }
  undef %SEEN;		# save memory, throw away

  \@sizes;
  }

sub track_size
  {
  # fill the results into @sizes
  track_sizes($_[0], $_[1]);

  # return a copy (backwards compatibility)
  @sizes;		# return results
  }

sub _addr
  {
  # return address of an element as string
  my $adr;
  if (ref($_[0]) && $_[1] ne 'REF')
    {
    $adr = sprintf("0x%x", refaddr($_[0]));
    }
  else
    {
    $adr = sprintf("0x%x", refaddr(\($_[0])));
    }

  $adr;
  }

sub _type
  {
  # find the type of an element and return as string
  my $type = uc(reftype($_[0]) || '');
  my $class = blessed($_[0]); $class = '' unless defined $class;

  # blessed "Regexp" and ref to scalar?
  $type ='REGEXP' if $class eq 'Regexp';

  # refs to scalars are tricky
  $type ='REF' 
    if ref($_[0]) && UNIVERSAL::isa($_[0],'SCALAR') && $type ne 'REGEXP';
  ($type,$class);
  }

sub _track_size
  {
  # Walk the given reference recursively and store the size, type etc of each
  # element
  my ($ref, $level) = @_;

  $level ||= 0;

  $CALLS++;
  
  no warnings 'recursion';

  # DO NOT use "total_size($ref)" because $ref is a copy of $_[0], reusing some
  # pre-allocated slot and this can have a different total size than $_[0]!!
  my $total_size = size($_[0]);
  my ($type,$blessed) = _type($_[0]);
 
  my $adr = _addr($_[0],$type);

  if (exists $SEEN{$adr})
    {
    # already seen this part of the world, so return
    if (ref($ref))
      {
      push @sizes, $level, S_CYCLE, $SIZE_OF_REF, 0, undef, $adr, $blessed;
      return; 
      }
    # a scalar seen twice
    push @sizes, $level, S_DOUBLE, 0, 0;
    av_push (@sizes, $UNDEF);
    push @sizes, $adr;
    av_push (@sizes, $UNDEF);
    return;
    }

  # put in the address of $ref in the %SEEN hash (things with a refcnt of 1
  # cannot be part of a cycle, since only one thing is pointing at them)
  hv_store (%SEEN, $adr , $UNDEF) if ref($_[0]) || SvREFCNT($_[0]) > 1;

  # not a reference, but a plain scalar?
  if (!ref($ref))
    {
    my $type = S_SCALAR;
    $type = S_VSTRING if isvstring($_[0]);

    push @sizes, $level, _flags($_[0]) + $type, $total_size;
    av_push (@sizes, $ZERO);
    av_push (@sizes, $UNDEF);
    push @sizes, $adr, $blessed;
    return;
    }

  my $index = scalar @sizes + 2;		# idx of "total_size" entry

  if ($type eq 'ARRAY')
    {
    push @sizes, $level, S_ARRAY, $total_size + $SIZE_OF_REF, 0, undef, $adr, $blessed;

    my $sum = 0;
    for (my $i = 0; $i < scalar @$ref; $i++)
      {
      my $adr = _addr($ref->[$i], _type($ref->[$i]));

      if (exists $SEEN{$adr} || ref($ref->[$i]))
	{
        my $index = scalar @sizes;
        _track_size($ref->[$i], $level+1);
        $sum += $sizes[$index+2];
        }
      else
	{
	# Put in the address of $ref in the %SEEN hash.
        # If TRACK_DOUBLES is set, we also need to store scalars with
	# REFCNT == 1 because somebody might have used hv_store() to make all
	# keys point to the same scalar and these "shared" scalars have
	# unfortunately a REFCNT of 1.
	hv_store (%SEEN, $adr , $UNDEF) if $TRACK_DOUBLES || SvREFCNT($_[0]) > 1;
	my $size = size($ref->[$i]);
	push @sizes, $level+1, S_SCALAR, $size;
	av_push (@sizes, $ZERO);
	av_push (@sizes, $UNDEF);
	push @sizes, $adr;
	av_push (@sizes, $UNDEF);
        $sum += $size;
        }
      }
    $sizes[$index] += $sum;
    $sizes[$index+1] = $sizes[$index] - $sum;
    }
  elsif ($type eq 'HASH')
    {
    push @sizes, $level, S_HASH, $total_size + $SIZE_OF_REF, 0, undef, $adr, $blessed;

    my $sum = 0;
    foreach my $elem ( keys %$ref )
      {
      my $adr = _addr($ref->{$elem}, _type($ref->{$elem}));
      if (exists $SEEN{$adr} || ref($ref->{$elem}))
        {
        my $index = scalar @sizes;
        _track_size($ref->{$elem},$level+1);

	$sizes[$index+1] += SF_KEY;
	$sizes[$index+4] = $elem;
	$sum += $sizes[$index+2];
        }
      else
        {
        # Put in the address of $ref in the %SEEN hash.
        # If TRACK_DOUBLES is set, we also need to store scalars with
	# REFCNT == 1 because somebody might have used hv_store() to make all
	# keys point to the same scalar and these "shared" scalars have
	# unfortunately a REFCNT of 1.
        hv_store (%SEEN, $adr , $UNDEF) if $TRACK_DOUBLES || SvREFCNT($_[0]) > 1;
        my $size = size($ref->{$elem});
	push @sizes, $level+1, SF_KEY + S_SCALAR, $size, 0, $elem, $adr, undef;
        $sum += $size;
        }
      }
    $sizes[$index] += $sum;
    $sizes[$index+1] = $sizes[$index] - $sum;
    }
  elsif ($type eq 'REGEXP')
    {
    push @sizes, $level, type($type), $total_size;
    av_push (@sizes, $ZERO);
    av_push (@sizes, $UNDEF);
    push @sizes, $adr, $blessed;
    }
  elsif ($type eq 'REF')
    {
    my $type = uc(reftype(${$_[0]}) || '');
    $type ='REGEXP' if $blessed eq 'Regexp';
    $type ='SCALAR' if !ref(${$_[0]});
    my $flags = SF_REF;
    $flags += SF_WEAK if isweak($_[0]);

    push @sizes, 
     ($level, $flags + type($type), $total_size, 0, undef, $adr, $blessed);
    _track_size($$ref,$level+1);
    $sizes[$index] += $SIZE_OF_REF;			# account for wrong \"" sizes
    $sizes[$index+1] = $sizes[$index] - total_size($$ref);
    }
  # SCALAR reference must come after Regexp, because these are also SCALAR !?
  elsif ($type eq 'SCALAR')
    {
    push @sizes, ($level, SF_REF, $total_size, 0, undef, $adr, $blessed);
    }
  else
    {
    my $overhead = 0;
    $overhead = -1 if type($type) == S_UNKNOWN;
    push @sizes, ($level, type($type), $total_size, $overhead, undef, $adr, $blessed);
    }
  }

sub _flags
  {
  my $flags = 0;

  $flags += SF_RO if readonly($_[0]);
  $flags += SF_WEAK if isweak($_[0]);

  # XXX TODO: how to find out if something is:
  # an LVALUE
  # a DUALVAR
  # a STASH

  $flags;
  }

1;
__END__

=pod

=head1 NAME

Devel::Size::Report - generate a size report for all elements in a structure

=head1 SYNOPSIS

        use Devel::Size::Report qw/report_size/;

        my $a = [ \8, \*STDIN, 7,
                  [ 1, 2, 3,
                    { a => 'b',
                      size => 12.2,
                      h => ['a']
                    },
                  'rrr'
                  ]
                ];
        print report_size($a, { indent => "  " } );

This will print something like this:

	Size report v0.08 for 'ARRAY(0x8145e6c)':
	  Array 886 bytes (overhead: 100 bytes, 11.29%)
	    Scalar Ref 32 bytes (overhead: 16 bytes, 50.00%)
	      Read-Only Scalar 16 bytes
	    Glob 266 bytes
	    Scalar 16 bytes
	    Array 472 bytes (overhead: 88 bytes, 18.64%)
	      Scalar 16 bytes
	      Scalar 16 bytes
	      Scalar 16 bytes
	      Hash 308 bytes (overhead: 180 bytes, 58.44%)
	        'h' => Array 82 bytes (overhead: 56 bytes, 68.29%)
	          Scalar 26 bytes
	        'a' => Scalar 26 bytes
	        'size' => Scalar 20 bytes
	      Scalar 28 bytes
	Total: 886 bytes in 15 elements

=head1 EXPORTS

Nothing per default, but can export the following per request:
  
	report_size
	track_size
	track_sizes
	hide_tracks
	element_type
	entries_per_element

	S_SCALAR
	S_HASH
	S_ARRAY
	S_GLOB
	S_UNKNOWN
	S_CODE
	S_LVALUE
	S_REGEXP
  	S_CYCLE
	S_DOUBLE

	SF_KEY
	SF_REF
	SF_REF
	SF_WEAK
	SF_RO
	SF_VSTRING
	SF_DUAL

=head1 DESCRIPTION

Devel::Size can only report the size of a single element or the total size of
a structure (array, hash etc). This module enhances Devel::Size by giving you
the ability to generate a full size report for each element in a structure.

You have full control over how the generated text report looks like, and where
you want to output it. In addition, the method C<track_size> allows you to get
at the raw data that is used to generate the report for even more flexibility.

=head1 METHODS

=head2 report_size

	my $record = report_size( $reference, $options ) . "\n";
	print $record;

Walks the given reference recursively and returns text tree describing
the size of each element.  C<$options> is a hash, containing the following
optional keys:

	names	  ref to HASH mapping the types to names
		  This should map S_Scalar to something like "Scalar" etc
	indent	  string to indent different levels with, default is '  '
	left	  indent all text with this at the left side, default is ''
	inner	  indent inner text with this at the left side, default is '  '
	total	  if true, a total size will be printed as last line
	bytes	  name of the size unit, defaults to 'bytes'
	head	  header string, default 'Size report for'
		  Set to '' to supress header completely	
  	overhead  Format string for the overhead, first size in bytes, then
		  the bytes string (see above) and then the percentage.
		  The default is:
		  " (overhead: %i%s, %0.2f%%)"
	addr 	  if true, for each element the memory address will be output
	class	  if true, show the class each element was blessed in
	terse	  if true, details for elements will be supressed, e.g. you
		  will only get the header, total and summary (if requested)
	summary   if true, print a table summing up the memory details on a
		  per-class basis
	doubles	  If true, hash keys and array elemts that point to the same
		  thing in memory will be reported. Default is off, since it
		  saves memory. Note that you will usually only get double
		  entries in hashes and array by using Array::RefElem's methods
		  or similiar hacks/tricks.

=head2 entries_per_element

	my $entries = entries_per_element();

Returns the number of entries per element that L<track_size()> will generate.

=head2 track_sizes

	$elements = track_sizes( $reference, $level);

Walk the given scalar or reference recursively and returns a ref to an array,
containing L<entries_per_element> entries for each element in the structure
pointed to by C<$reference>. C<$reference> can also be a plain scalar.  

The entries for each element are currently:

	level	  the indent level
	type	  the type of the element, S_SCALAR, S_HASH, S_ARRAY etc
		  if (type & SF_KEY) != 0, the element is a member of a hash
	size	  size in bytes of the element
	overhead  if the element is an ARRAY or HASH, contains the overhead
		  in bytes (size - sum(size of all elements)).
	name	  if type & SF_KEY != 0, this contains the name of the hash key
	addr	  memory address of the element
	class	  classname that the element was blessed into, or ''

=head2 track_size

	@elements = track_size( $reference, $level);

Works just like L<track_sizes>, but for backward compatibility reasons
returns an array with the results.

=head2 hide_tracks

	hide_tracks();

Releases the memory consumed by a call to L<track_size> or L<track_sizes>.

=head2 type

	$type_number = type($type_name);

Maps a type name (like 'SCALAR') to a type number (lilke S_SCALAR).

=head2 element_type

	$type_name = element_type($type_nr);

Maps a type number (like S_SCALAR) to a type name (lilke 'SCALAR').

=head1 WRAP YOUR OWN

If you want to create your own report with different formattings, please
use L<track_size> and create a report out of the data you get back from it.
Look at the source code for L<report_size> how to do this - it is easy!

=head1 CAVEATS

=over 2

=item *

The limitations of Devel::Size also apply to this module. This means that
CODE refs and other "obscure" things might show wrong sizes, or unknown
overhead. In addition, some sizes might be reported wrong.

=item *

A string representation of the passed argument will be inserted when generating
a report with a header.
 
If the passed argument is an object with overloaded magic, then the routine for
stringification will be triggered. If this routine does actually modify the
object (for instance, Math::String objects cache their string form upon first
call to stringification, thus modifying themselves), the reported size will be
different from a first report without a header.

=back

=head1 BUGS 

=over 4

=item threads

The results are currently stored in a global package var, so this is probably
not threadsafe.

=back

=head1 AUTHOR

(c) 2004, 2005, 2006, 2008 by Tels http://bloodgate.com

=cut
