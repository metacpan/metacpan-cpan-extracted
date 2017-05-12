#!/usr/bin/perl -w

use strict;

=head1 NAME

Maptastic - all map, all the time.  Maperiffic baby, yeah!

=head1 SYNOPSIS

 use Maptastic qw(:perly);

 @a = (1, 2, 3);
 @b = qw(Mary Jane);
 @c = ('A' .. 'E');
 %d = ( smokey => 1,
        cheese => 6,
        fire   => 7,
        plant  => 3.5 );

 @spliced = map_shift { [ @_ ] } (\@a, \@b, \@c);

 @mixed  = map_for { [ @_ ] } (\@a, \@b, \@c);

 %hashed = map_each { ( $_[0] > 4 ? @_ : () ) } \%d;

=head2 Results after the above

 # map_shift / mapcaru
 @spliced = ([1,     "Mary", "A"],
             [2,     "Jane", "B"],
             [3,     undef,  "C"],
             [undef, undef,  "D"],
             [undef, undef,  "E"]);

 # map_for / mapcar
 @mixed   = ([1,     "Mary", "A"],
             [2,     "Jane", "B"], # some LISPs stop here
             [3,             "C"],
             [               "D"],
             [               "E"]);

 # map_each
 %hashed = ( cheese => 6,
             fire   => 7 );

=head1 DESCRIPTION

This module defines two maptabulous new varieties of that
long-favourite map (see L<perlfunc/map>).  Two of these maps are more
maplicious than map itself - because unlike vanilla map, it maps more
than a single list!  Mapendous!

But the mappy feast does not stop there!  No, to satisfy your
ever-growing map cravings, there's a mapdiddlyumtious version of the
original map that iterates over hashes!  Mapnificent!

=head2 Iterator versions

Despite just how mapfect code looks with the flexmapible mapower of
map, sometimes, you don't want to process amapn entire list via map at
once.

To cater for these specialist map tastes, our maxperts have come up
with a great new flavour for all map-like functions: iterators.

An iterator is an object that returns the next item from its list when
asked.  There are many ways of `asking' an iterator for it's next
value, as well as different semantics for `rewinding' the iterator to
the beginning, if possible.

But don't worry, Maptastic is so mapscendant that it's looked at
all[*] of the modules on that mapreme Perl source repository, CPAN,
and therefore accepts the following semantics for iterators:

=over

=item B<Object::Iterate style>

If the object to be mapped over understands the method __next__, then
Object::Iterate style iteration is performed.

=item B<ref CODE style>

If the object to be mapped is a CODE reference (even blessed), then it
is assumed that calling the code reference will perform the iteration.
With these semantics, if I<undef> is ever returned, the iterator is
assumed to be `spent', and is unlinked; just in case subsequent calls
re-start the iterator.

=item B<SPOPS style>

Iterator function: get_next

=item B<misc. styles>

Other styles of iteration are automatically detected: is the object
implements a ->NEXT() or ->next() method, these are used as the
iterator method.

=item B<filehandles>

A filehandle is a type of iterator - so the "readline" method is
accepted too.

=back

=cut

package Maptastic;
require Exporter;
use Carp;
use Scalar::Util qw(reftype blessed);
use vars qw( $VERSION @EXPORT @ISA %EXPORT_TAGS);

BEGIN {
    $VERSION= "1.01";
    @EXPORT= qw( mapcar mapcaru map_each map_shift map_for
		 map_foreach filter

		 imap iter slurp igrep
		 imapcar imapcaru imap_each imap_shift imap_for
		 imap_foreach ifilter
	       );
    %EXPORT_TAGS = ( lisp => [ qw(mapcar mapcaru imapcar imapcaru) ],
		     (map { $_ => [ qw(map_each map_for map_foreach
				       map_shift filter) ] }
		      qw(perly perlish perl)),

		     iter => [ qw(iter slurp igrep imap imap_each
				  imap_shift imap_for imap_foreach
				  ifilter) ],

		   );
    @ISA= qw( Exporter );
}

# Adapt all of the different iterator styles to the ->() style
sub _adapt_iter {
    my $iter = shift;

    return unless ref $iter;

    if (blessed $iter) {

	# FIXME - is this a good idea?  This will probably catch all
	# sorts of objects that we don't want to.
	for my $method (qw(__next__ get_next NEXT next readline)) {
	    if ($iter->can($method)) {
		return sub { $iter->$method };  # see, isn't it tidy?
	    }
	}
	# no, blessed code refs must export a sensible method
	# return $iter if reftype $iter eq "CODE";

    } elsif ( ref $iter eq "CODE" ) {
	return $iter;
    } elsif ( ref $iter eq "ARRAY" ) {
	my $i = 0;
	return sub {
	    return if ($i > $#$iter);
	    return $iter->[$i++]
	};
    } elsif ( ref $iter eq "GLOB" ) {
	return sub { <$iter> };
    }

    return undef;
}

=head1 FUNCTIONS

=head2 map and friends

=over

=item mapcar { code } \@list, \@list, \@list...

=item map_for { code } \@list, \@list, \@list...

=item map_foreach { code } \@list, \@list, \@list...

"mapcar" originated in LISP (the LISt Processing language).  So did
the Perl built-in function "map".  "car" is an old term coming from
the term "Contents of the Address part of the Register", so there.
This function is also available as `map_for' or `map_foreach' (because
with for, you stop at the end of the list).

Note that the exact behvaviour of `mapcar' apparently varied from LISP
to LISP, so the version given here is the one that was widely
publicised on PerlMonks.

=cut

# This function has been updated to include support for certain types
# of iterators
sub mapcar(&@)
{
    my $sub= shift;
    if(  ! @_  ) {
        croak( "mapcar: Nothing to map" );
    }

    my @which;

    for my $av (  @_  ) {
	if (ref $av eq "ARRAY") {
	    push @which, undef;
	} elsif ( my $coderef = _adapt_iter ($av) ) {
	    push @which, $coderef;
	} else {
	    push @which, undef;
        }
    }

    my (@ret, $x);
    my $all_done = 0;

    for(  my $i= 0;  !$all_done;  $i++  ) {
	my $c = -1;
	$all_done = 1;
	my @next = (map {
	    $c++;
	    ( $which[$c]
	      ? ( defined($x = $which[$c]->())
		  ? do { $all_done = 0; $x }
		  : do { $which[$c] = sub{()}; () }
		)
	      : ( $i < @$_
		  ? do { $all_done = 0;
			 $_->[$i] }
		  : ()
		) )
	} @_);

	push @ret, &$sub(@next) if @next;
    }
    return wantarray ? @ret : \@ret;
}
sub map_for (&@) { goto \&mapcar }
sub map_foreach (&@) { goto \&mapcar }

=item mapcaru { code } \@list, \@list, \@list...

=item map_shift { code } \@list, \@list, \@list...

"mapcaru" is a version that works similarly to `mapcar', but puts
I<undef> (hence the u) into locations in the input array where the
input list has no elements.  This function is also available as
`map_shift' (because with `shift', you get undef out if there was
nothing in the list).

=cut

sub mapcaru(&@)
{
    my $sub= shift;
    if(  ! @_  ) {
        croak( "mapcaru: nothing to map" );
    }
    my $max= 0;
    for my $av (  @_  ) {
        if(  ! UNIVERSAL::isa( $av, "ARRAY" )  ) {
            croak( "mapcaru: `$av' is not an array reference" );
        }
        $max = @$av if $max < @$av;
    }
    my @ret;
    for(  my $i= 0;  $i < $max;  $i++  ) {
        push @ret, &$sub( map { $_->[$i] } @_ );
    }
    return wantarray ? @ret : \@ret;
}
sub map_shift(&@) { goto \&mapcaru }

=item map_each { code } \%hash, \%hash, ...

"map_each" is a version of `map' that works on hashes.  B<It does not
work like mapcar or mapcaru, it is a simple map for hashes>.
Supplying multiple hashes iterates over all of the hashes in sequence.

=cut

sub map_each(&@)
{
    my $sub = shift;
    if(  ! @_  ) {
        croak( "mapeach: Nothing to map" );
    }
    map { UNIVERSAL::isa($_, "HASH") or do {
        croak( "mapeach: `$_' is not a hash reference" );
    }; } @_;

    my @results;
    while ( my @a = each %{$_[0]}) {
	push @results, $sub->(@a);
    }
    return @results;
}

=item imapcar [TODO] ...

=item imap_for ...

=item imap_foreach ...

Returns an iterator version of mapcar (a CODE reference)

=back

=cut

sub imapcar(&@) {
    die "imapcar not yet implemented";
}

sub imap_for (&@) { goto \&imapcar };
sub imap_foreach (&@) { goto \&imapcar };

=head2 map's cousins

While not as mapxy as our star, this group of functions will be found
alongside map and imap in many a code fragment.

=over

=item iter($iter, [ ], ...)

This function simply returns an iterator that iterates over the input
list; it is exactly the same as:

   imap { $_ } (...)

=cut

sub iter {
    (my @__, @_) = @_;
    my ($n, $i) = (0, undef);

    return bless sub {
	my $rv;
	while (!defined $rv) { 
	    # set up the `next' iterator
	    unless (defined $i) {
		return if $n > $#__;
		$i = _adapt_iter($__[$n]) || sub {
		    $i = undef;
		    $__[$n++];
		};
	    }
	    # iterate
	    $rv = ($i->());
	    if (defined $rv) {
		return $rv;
	    } else {
		$n++;
		$i = undef;
	    }
	}
    }, __PACKAGE__;
}

sub NEXT { $_[0]->() }
sub __next__ { $_[0]->() }
sub get_next { $_[0]->() }
sub next { $_[0]->() }
sub readline { $_[0]->() }

=item slurp($iter, [ ], ...)

This function is the opposite of iter; it takes iterators, gets them
to spit values out until they are finished (or all of VM runs out,
your machine starts swapping and eventually crashes, esp. on Linux).
See L<bash/ulimit>.

=cut

sub slurp {
    my @rv;

    for (my $n = 0; $n <= $#_; $n++) {
	if (my $i = _adapt_iter($_[$n])) {
	    while (defined(my $item = $i->())) {
		push @rv, $item;
	    }
	} else {
	    push @rv, $_[$n];
	}
    }

    @rv;
}

=item filter

To save you from having to put unsightly `$_' at the end of your map
blocks, eg

   @a = ( filter { s{.*/(.*)}{} }
          split /\0/,
          `find . -type f -print0` );

   for (@a) {
       # do something with each filename
   }

=cut

sub filter(&@) {
    my $sub = shift;
    my @rv;
    my @input = slurp @_;
    while (@input) {
	local($_) = shift @input;
	$sub->();
	push @rv, $_;
    }
    @rv;
}

=item ifilter

Of course the above is much better written iteratively:

   use IO::Handle;

   open FIND, "find . -type f -print0 |";
   FIND->input_record_seperator("\0");

   $iter = ifilter { s{.*/(.*)}{} } \*FIND;

   while ( my $filename = $iter->() ) {
       # do something with each filename
   }

=cut

sub ifilter(&@) {
    my $sub = shift;
    my $iter = iter(@_);

    return bless sub {
	my $val = $iter->();
	if (defined($val)) {
	    local($_) = $val;
	    $sub->();
	    return $_;
	} else {
	    return;
	}
    }, __PACKAGE__;
}

=item igrep { BLOCK }, [...]

Iterative `grep'

=cut

sub igrep(&@) {
    my $sub = shift;
    my $iter = iter @_;

    return bless sub {
	my $ok = 0;
	while (1) {
	    local($_) = $iter->();
	    return unless defined $_;
	    if ($sub->()) {
		return $_;
	    }
	}
    }, __PACKAGE__;
}

=for thought; isplit

A version of `split' that uses a scalar context C<m//g> loop to return
an iterator over a string.

eg, here is a tokeniser that tokenizes a moronically small sub-set of
XML:

   my $iter = isplit qr/<[^>]*>|[^<]*/, $string;

Each call to $iter->() would return the next tag or CDATA section of
the string, assuming that the input didn't come from the real world.
$1, $2, etc are available as per normal with this function; though if
the iterator is called in list context, they are returned as a list
(yay!).

sub isplit($@) {
    my $regex = shift;
    my $iter = iter @_;
    my ($string, $pos);
    my $result = bless sub {
	while (1) {
	    unless (defined $string) {
		defined($string = $iter->()) or return;
	    }
	    if (defined (my $ok = ($string =~ m/$regex/g))) {
		if (wantarray) {
		    # nasty! but only way to be sure...
		    return ($& =~ m/$regex/);
		} else {
		    return $ok;
		}
	    }
	}
    }, __PACKAGE__;

    return $result;
}

=cut



1;

__END__

=back

=head1 EXPORTS

Everything in the module is exported by default.  If you prefer, you
can get just `mapcar' and `mapcaru' using the import tag :lisp;

   use Maptastic ':lisp';

   my @a = mapcar { do_this(@_) } \@b, \@c;

The other functions (`map_shift', etc) may be imported using the
import tags :perly (or :perl or :perlish);

   use Maptastic ':perly';

   my @b = map_for { do_that(@_) } \@b, \@c;

=head1 SEE ALSO

L<perlfunc/map>, L<perldata>, L<Object::Iterate>, L<Maptastic::DBI>

=head1 AUTHOR

Original implementation of mapcar by tye.  See
L<http://www.perlmonks.org/index.pl?node_id=22609>

Packaged for CPAN by The Map Junky <samv@cpan.org>

This module was somewhat inspired by an MJD talk at YAPC::Europe.

=cut
