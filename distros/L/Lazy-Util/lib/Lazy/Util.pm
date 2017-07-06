use strict;
use warnings;

package Lazy::Util;
$Lazy::Util::VERSION = '0.004';
#ABSTRACT: Perl utilities for lazy evaluation


use Carp qw/ croak /;
use Exporter qw/ import /;
use Lazy::Iterator;
use Scalar::Util qw/ blessed /;

use constant SCALAR_DEFER => eval { require Scalar::Defer; 1 };

our @EXPORT_OK = qw/
  l_concat l_first l_grep l_map l_until g_count g_first g_join g_last g_max
  g_min g_prod g_sum
  /;

our %EXPORT_TAGS = (all => [@EXPORT_OK],);

sub _isa { defined blessed $_[0] and $_[0]->isa($_[1]); }


sub l_concat {
  my (@vals) = grep defined, @_;

  return Lazy::Iterator->new(sub {undef}) if @vals == 0;

  return $vals[0] if @vals == 1 and _isa($vals[0], 'Lazy::Iterator');

  return Lazy::Iterator->new(
    sub {
      while (@vals) {

        # if it's a Scalar::Defer or a CODE reference, coerce into a
        # Lazy::Iterator object
        $vals[0] = Lazy::Iterator->new($vals[0])
          if SCALAR_DEFER && _isa($vals[0], 0)
          or ref $vals[0] eq 'CODE';

        # if by this point it's not a Lazy::Iterator object, simply return it
        # and remove from @vals
        return shift @vals if not _isa($vals[0], 'Lazy::Iterator');

        # ->get the next value from the Lazy::Iterator object and return it if
        # it's defined
        if   (defined(my $get = $vals[0]->get())) { return $get; }
        else                                      { shift @vals; }
      }
      return undef;
    }
  );
}


sub l_first {
  my ($n, @vals) = @_;

  my $vals = l_concat @vals;

  return Lazy::Iterator->new(
    sub {
      return $vals->get() if $n-- > 0;
      return undef;
    }
  );
}


sub l_grep (&@) {
  my ($grep, @vals) = @_;

  my $vals = l_concat @vals;

  return Lazy::Iterator->new(
    sub {
      while (defined(my $get = $vals->get())) {
        for ($get) {
          if ($grep->($get)) { return $get }
        }
      }

      return undef;
    }
  );
}


sub l_map (&@) {
  my ($map, @vals) = @_;

  my $vals = l_concat @vals;

  my @subvals = ();
  return Lazy::Iterator->new(
    sub {
      return shift @subvals if @subvals;

      while (not @subvals) {
        my $get = $vals->get();
        return undef if not defined $get;

        @subvals = $map->($get) for $get;
      }

      return shift @subvals;
    }
  );
}


sub l_until (&@) {
  my ($until, @vals) = @_;

  my $vals = l_concat @vals;

  my $found = 0;
  return Lazy::Iterator->new(
    sub {
      return undef if $found;

      my $get = $vals->get();
      $found = $until->($get) for $get;

      return $get;
    }
  );
}


sub g_count {
  my (@vals) = @_;

  my $vals = l_concat @vals;

  my $n = 0;
  while (defined $vals->get()) { $n++; }

  return $n;
}


sub g_first {
  my (@vals) = @_;

  my $vals = l_concat @vals;

  return $vals->get();
}


sub g_join {
  my ($sep, @vals) = @_;

  my $vals = l_concat @vals;

  my $ret = $vals->get();
  while (defined(my $get = $vals->get())) { $ret .= $sep . $get; }

  return $ret;
}


sub g_last {
  my @vals = @_;

  my $vals = l_concat @vals;

  my $ret = undef;
  while (defined(my $get = $vals->get())) { $ret = $get; }

  return $ret;
}


sub g_max {
  my @vals = @_;

  my $vals = l_concat @vals;

  my $ret = $vals->get();
  while (defined(my $get = $vals->get())) { $ret = $get if $get > $ret; }

  return $ret;
}


sub g_min {
  my @vals = @_;

  my $vals = l_concat @vals;

  my $ret = $vals->get();
  while (defined(my $get = $vals->get())) { $ret = $get if $get < $ret; }

  return $ret;
}


sub g_prod {
  my @vals = @_;

  my $vals = l_concat @vals;

  my $ret = 1;
  while (defined(my $get = $vals->get())) {
    $ret *= $get;
    return 0 if $ret == 0;
  }

  return $ret;
}


sub g_sum {
  my @vals = @_;

  my $vals = l_concat @vals;

  my $ret = 0;
  while (defined(my $get = $vals->get())) { $ret += $get; }

  return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lazy::Util - Perl utilities for lazy evaluation

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Lazy::Util qw/ l_grep l_map /;
  
  my $lazy = l_map { $_ * 2 } l_grep { /^[0-9]+$/ } 3, 4, 5, sub {
    print "Enter a number: ";
    return scalar readline(STDIN);
  };

  while (defined(my $answer = $lazy->get())) { 
    print "Double your number: $answer\n";
  }

=head1 DESCRIPTION

Perl utility functions for lazy evaluation.

=head1 FUNCTIONS

This module has two sets of functions, the C<l_*> functions and the C<g_*>
functions. The C<l_*> functions are designed to return a L<Lazy::Iterator>
object which you can get values from, the C<g_*> functions are designed to get
a value out of a L<Lazy::Iterator> object. Some of the C<g_*> functions may
never return if the source of values is infinite, but they are for the most
part designed to not eat up all of your memory at least ;).

All these functions can be exported, but none are exported by default. You can
use the C<:all> export tag to export all of them.

=head1 l_* functions

The C<l_*> functions are:

=head2 l_concat

  my $lazy = l_concat @sources;

C<l_concat> returns a L<Lazy::Iterator> object which will simply return each
subsequent value from the list of sources it's given.

=head2 l_first

  my $lazy = l_first $n, @sources;

C<l_first> will return a L<Lazy::Iterator> object which will only get the
first C<$n> values from the subsequent arguments. This can be used the 'break'
an otherwise infinite list to only return a certain number of results.

=head2 l_grep

  my $lazy = l_grep { ... } @sources;

C<l_grep> will return a L<Lazy::Iterator> object which will filter out any
value which doesn't return true from the C<$code> block in the first argument.

=head2 l_map

  my $lazy = l_map { ... } @sources;

C<l_map> will return a L<Lazy::Iterator> object which will transform any
value using the C<$code> block in the first argument.

The C<$code> block is evaluated in list context, and each scalar it returns
will be returned by each subsequent ->get(), not poking the C<@sources> again
until the list is exhausted. If an empty list is returned, the C<@sources> will
be poked again until a list of at least one element is returned, or the source
returns C<undef>.

=head2 l_until

  my $lazy = l_until { ... } @sources;

C<l_until> will return a L<Lazy::Iterator> object which will return values
from the C<@sources> until the C<$code> block returns true, after which it will
be exhausted.

=head1 g_* functions

The C<g_*> functions are:

=head2 g_count

  my $count = g_count @sources;

C<g_count> counts the number of values from the C<@sources> and returns how
many there were. B<This has the potential to never return> if given a source of
infinite values.

=head2 g_first

  my $val = g_first @sources;

C<g_first> returns the first value from the list of arguments, lazily
evaluating them. Equivalent to C<< l_concat(...)->get(); >>.
If C<@sources> is empty, it will return C<undef>.

=head2 g_join

  my $lines = g_join $str, @sources;

C<g_join> evaluates all the values it's given and returns them joined into a
string. B<This has the potential to never return as well as running out of
memory> if given a source of infinite values.
If C<@sources> is empty, it will return C<undef>.

=head2 g_last

  my $val = g_last @sources;

C<g_last> evaluates all the values it's given and returns the last value.
B<This has the potential to never return> if given a source of infinite values.
If C<@sources> is empty, it will return C<undef>.

=head2 g_max

  my $val = g_max @sources;

C<g_max> evaluates all the values it's given and returns the highest one.
B<This has the potential to never return> if given a source of infinite values.
If C<@sources> is empty, it will return C<undef>.

=head2 g_min

  my $val = g_min @sources;

C<g_min> evaluates all the values it's given and returns the lowest one. B<This
has the potential to never return> if given a source of infinite values.
If C<@sources> is empty, it will return C<undef>.

=head2 g_prod

  my $val = g_prod @sources;

C<g_prod> evaluates all the values it's given and returns the product of all of
them. B<This has the potential to never return> if given a source of infinite
values. Unless one of them is 0. If so, it will short-circuit and return 0.
If C<@sources> is empty, it will return C<1>.

=head2 g_sum

  my $val = g_sum @sources;

C<g_sum> evaluates all the values it's given and returns the sum of all of
them. B<This has the potential to never return> if given a source of infinite
values.
If C<@sources> is empty, it will return C<0>.

=head1 @sources

The C<@sources> array that most (all?) of these functions take can be any
combination of regular scalar values, L<Lazy::Iterator> objects,
L<Scalar::Defer> variables (see L</"NOTES">), or subroutine references. Each of
these will be iterated through from start to finish, and if one of them returns
C<undef>, the next one will be used instead, until the last one returns
C<undef>.

For instance, in the following scenario:

  my @values = qw/ a b c /;
  my $source = sub { shift @values };
  my $lazy = l_concat $source, 1;

  my @results = ($lazy->get(), $lazy->get(), $lazy->get(), $lazy->get());

What happens when you run C<< $lazy->get() >> the first time is that the
subroutine in C<$source> will be executed, and so C<@values> will change to
only contain C<qw/ b c />, and C<a> will be returned. The next time C<@values>
will be changed to only contain C<qw/ c />, and C<b> will be returned. The
third C<< $lazy->get() >> will change C<@values> to C<qw//> (an empty array),
and return the C<c>.

So far so good.

What happens with the next C<< $lazy->get() >> is that the subroutine in
C<$source> will be executed one last time, and it will run C<shift @values>,
but C<@values> is empty, so it will return C<undef>, which will signal that
C<$source> is exhausted, and so it will be discarded. The next value will be
taken from the next element in C<@sources>, which is the single scalar C<1>.

This means that at the end, C<@results> will contain C<qw/ a b c 1 />, and any
subsequent call to C<< $lazy->get() >> will return C<undef>.

=head1 NOTES

If L<Scalar::Defer> is installed, it will assume that any variable of type C<0>
is a L<Scalar::Defer> variable and will treat it as a source of values.

Not to be confused with L<Lazy::Utils>.

=head1 SEE ALSO

=over 4

=item L<Lazy::Iterator>

=item L<Scalar::Defer>

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
