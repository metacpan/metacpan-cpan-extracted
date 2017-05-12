#############################################################################
# Math/String/Sequence.pm -- defines a sequence or range of strings.
#
# Copyright (C) 2001 - 2005 by Tels.
#############################################################################

# the following hash values are used
# _first : first string
# _last	 : last string
# _set	 : charset for first/last
# _size	 : last-first
# _rev   : 1 if reversed sequence

package Math::String::Sequence;
use vars qw($VERSION);
$VERSION = '1.29';	# Current version of this package
require  5.005;		# requires this Perl version or later

use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(sequence);

use Math::String;
use Math::String::Charset;

use strict;
my $class = "Math::String::Sequence";

# some shortcuts for easier life
sub sequence
  {
  # exportable version of new
  $class->new(@_);
  }

###############################################################################
# constructor

sub new
  {
  # takes the following arguments:
  # first, last: Math:Strings or scalars
  # charset: optional, if you pass a scalar as first or last

  my $class = shift;
  $class = ref($class) || $class;

  my $args;
  if (ref $_[0] eq 'HASH')
    {
    $args = shift;
    }
  else
    {
    $args->{first} = shift;
    $args->{last} = shift;
    $args->{charset} = shift;
    }

  my $self = {};
  bless $self, $class;
  if (ref $args eq $class)
    {
    # make copy
    for (qw/_first _last/)
      {
      $self->{$_} = Math::String->new($args->{$_});
      }
    return $self;
    }
  my $first = $args->{first};
  my $last = $args->{last};
  my $set = $args->{charset};

  $first = Math::String->new($first,$set) unless ref $first;
  $last = Math::String->new($last,$set) unless ref $last;

  die ("first is NaN") if $first->is_nan();
  die ("last is NaN") if $last->is_nan();
  #die ("$first is not smaller than $last") if
  # adjustment by $self->_size(): $self->{_rev} = $first > $last ? 1 : 0;

  bless $self, $class;
  $self->{_first} = $first;
  $self->{_last} = $last;
  $self->_initialize();
  $self;
  }

#############################################################################
# private, initialize self

sub _initialize
  {
  # init sequence
  my $self = shift;

  $self->_size();
  $self->{_set} = $self->{_first}->{_set};
  $self;
  }

sub _size
  {
  # calculate new size and adjust _rev
  my $self = shift;

  $self->{_rev} = $self->{_first} < $self->{_last} ? 0 : 1;
  $self->{_size} = $self->{_last} - $self->{_first};
  $self->{_size} = $self->{_size}->babs()->as_number();
  $self->{_size}++;
  $self;
  }

#############################################################################
# public

sub charset
  {
  my $self = shift;
  $self->{_first}->{_set};
  }

sub length
  {
  my $self = shift;
  $self->{_size};
  }

sub is_reversed
  {
  # return true if the sequence is reversed, or false
  my $self = shift;
  $self->{_rev};
  }

sub first
  {
  my $self = shift;
  if (defined $_[0])
    {
    $self->{_first} = shift;
    $self->{_first} = Math::String->new($self->{_first},$self->{_set})
      unless ref $self->{_first};
    $self->_size();
    }
  $self->{_first};
  }

sub last
  {
  my $self = shift;
  if (defined $_[0])
    {
    $self->{_last} = shift;
    $self->{_last} = Math::String->new($self->{_last},$self->{_set})
      unless ref $self->{_last};
    $self->_size();
    }
  $self->{_last};
  }

sub string
  {
  # return the Nth string in sequence or undef for out-of-range
  my $self = shift;
  my $nr = shift; $nr = 0 if !defined $nr;

  $nr = Math::BigInt->new($nr) unless ref $nr;
  my $n;
  if ($self->{_rev})
    {
    if ($nr < 0)
      {
      $n = $self->{_last}-$nr; $n--;
      }
    else
      {
      $n = $self->{_first}-$nr;
      }
    return if $n > $self->{_first} || $n < $self->{_last};
    }
  else
    {
    if ($nr < 0)
      {
      $n = $self->{_last}+$nr; $n++;
      }
    else
      {
      $n = $self->{_first}+$nr;
      }
    return if $n > $self->{_last} || $n < $self->{_first};
    }
  $n;
  }

sub error
  {
  my $self = shift;
  $self->{_set}->error();
  }

sub as_array
  {
  # return the sequence as array of strings
  my $x = shift;

  my @a;
  my $f = $x->{_first}; my $l = $x->{_last};
  if ($x->{_rev})
    {
    while ($f >= $l) { push @a,$f->copy(); $f->bdec(); }
    }
  else
    {
    while ($f <= $l) { push @a,$f->copy(); $f->binc(); }
    }
  @a;
  }

__END__

#############################################################################

=pod

=head1 NAME

Math::String::Sequence - defines a sequence (range) of Math::String(s)

=head1 SYNOPSIS

	use Math::String::Sequence;
	use Math::String::Charset;

	$seq = Math::String::Sequence->new( a, zzz );		   # set a-z
	$seq = Math::String::Sequence->new( a, zzz, ['z'..'a'] );  # set z..a
	$seq = Math::String::Sequence->new(
          { first => 'a', last => 'zzz', charset => ['z'..'a']
          } ); 							   # same
        $x = Math::String->new('a');
        $y = Math::String->new('zz');
	$seq = Math::String::Sequence->new( {
          first => $x, last => $y, } );  			   # same

	print "length: ",$seq->length(),"\n";
	print "first: ",$seq->first(),"\n";
	print "last: ",$seq->last(),"\n";
	print "5th: ",$seq->string(5),"\n";
	print "out-of-range: ",$seq->string(10000000),"\n"; 	   # undef

	print "as array:: ",$seq->as_array(),"\n"; 	   	   # as array

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt, Math::String, Math::String::Charset

=head1 EXPORTS

Exports nothing on default, but can export C<sequence()>.

=head1 DESCRIPTION

This module creates a sequence, or range of Math::Strings. Given a B<first> and
B<last> string it represents all strings in between, including B<first> and
B<last>. The sequence can be reversed, unlike 'A'..'Z', which needs the first
argument be smaller than the second.

=over 1

=item Default charset

The default charset is the set containing "abcdefghijklmnopqrstuvwxyz"
(thus producing always lower case output). If either C<first> or C<last> is
not an Math::String, they will get the given charset or this default.

=back

=head1 USEFULL METHODS

=over

=item new()

            new();

Create a new Math::String::Sequence object. Arguments are the
first and last string, and optional charset. You can give a hash ref, that must
then contain the keys C<first>, C<last> and C<charset>.

=item length()

            $sequence->length();

Returns the amount of strings this sequence contains, aka (last-first)+1.

=item is_reversed()

            $sequence->is_reversed();

Returns true or false, depending wether the first string in the sequence
is smaller than the last.

=item first()

            $sequence->first($length);

Return the first string in the sequence. The optional argument becomes the
new first string.

=item last()

            $sequence->last($length);

Return the last string in the sequence. The optional argument becomes the
new last string.

=item charset()

            $sequence->charset();

Return a reference to the charset of the Math::String::Sequence object.

=item string()

            $sequence->string($n);

Returns the Nth string in the sequence, 0 beeing the C<first>. Negative
arguments count backward from C<last>, just like with arrays.

=item as_array()

            @array = $sequence->as_array();

Returns the sequence as array of strings. Usefull for emulating things like

	foreach ('a'..'z')
	  {
          print "$_\n";
          }

via

	my $sequence = Math::String::Sequence->new('foo','bar');

	foreach ($sequence->as_array())
	  {
	  print "$_\n";
          }

Beware, might create HUGE arrays!

=back

=head1 BUGS

None discovered yet.

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

This module is (C) Tels http://bloodgate.com 2001 - 2005.

=cut
