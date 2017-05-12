package Hash::MultiKey;

use 5.006;
use strict;
use warnings;

use Carp;

use vars qw($VERSION);
$VERSION = '0.06';

# ---[ Implementation Overview ]----------------------------------------
#
# The first implementation of this module was based in an explicit tree.
# Right after its announcement in news:comp.lang.perl.modules Benjamin
# Goldberg suggested a radically different approach, far much simple and
# efficient. The current code is entirely based on his idea.
#
# Multi-key hashes are implemented now with a plain hash. There is no
# nesting involved.
#
# Lists of keys are converted to strings with pack():
#
#     $key = pack 'N' . ('w/a*' x @$keys), scalar(@$keys), @$keys;
#
# and that $key is what's used in the underlying hash. The first chunk
# stores the number of keys, to be used afterwards when we decode it.
# Then, pairs length_of_key/key follow.
#
# Conversely, to retrieve the original list of keys from a real key we
# use unpack():
#
#     $n = unpack 'N', $key;
#     [ unpack 'x4' . ('w/a*' x $n), $key ];
#
# Iteration is delegated to the iterator of the very hash.
#
# Knowing that the following code is crystal clear, so comments have
# been removed altogether.
#
# ----------------------------------------------------------------------


sub TIEHASH {
    bless {}, shift;
}

sub CLEAR {
    %{ shift() } = ();
}

sub FETCH {
    my ($self, $keys) = @_;
    $keys = [$keys eq '' ? ('') : split /$;/, $keys, -1] unless ref $keys eq 'ARRAY';
    @$keys or croak "Empty multi-key\n";
    $self->{pack 'N' . ('w/a*' x @$keys), scalar(@$keys), @$keys};
}

sub STORE {
    my ($self, $keys, $value) = @_;
    $keys = [$keys eq '' ? ('') : split /$;/, $keys, -1] unless ref $keys eq 'ARRAY';
    @$keys or croak "Empty multi-key\n";
    $self->{pack 'N' . ('w/a*' x @$keys), scalar(@$keys), @$keys} = $value;
}

sub DELETE {
    my ($self, $keys) = @_;
    $keys = [$keys eq '' ? ('') : split /$;/, $keys, -1] unless ref $keys eq 'ARRAY';
    @$keys or croak "Empty multi-key\n";
    delete $self->{pack 'N' . ('w/a*' x @$keys), scalar(@$keys), @$keys};
}

sub EXISTS {
    my ($self, $keys) = @_;
    $keys = [$keys eq '' ? ('') : split /$;/, $keys, -1] unless ref $keys eq 'ARRAY';
    @$keys or croak "Empty multi-key\n";
    exists $self->{pack 'N' . ('w/a*' x @$keys), scalar(@$keys), @$keys};
}

sub FIRSTKEY {
    my ($self) = @_;
    keys %$self; # reset iterator
    $self->NEXTKEY;
}

sub NEXTKEY {
    my ($self) = @_;
    defined(my $key = each %$self) or return;
    my $n = unpack 'N', $key;
    [ unpack 'x4' . ('w/a*' x $n), $key ];
}

sub SCALAR {
    my ($self) = @_;
    scalar %$self;
}

1;


__END__

=head1 NAME

Hash::MultiKey - hashes whose keys can be multiple

=head1 SYNOPSIS

  use Hash::MultiKey;

  # tie first
  tie %hmk, 'Hash::MultiKey';

  # store
  $hmk{['foo', 'bar', 'baz']} = 1;

  # fetch
  $v = $hmk{['foo', 'bar', 'baz']};

  # exists
  exists $hmk{['foo', 'bar', 'baz']}; # true

  # each
  while (($mk, $v) = each %hmk) {
      @keys = @$mk;
      # ...
  }

  # keys
  foreach $mk (keys %hmk) {
      @keys = @$mk;
      # ...
  }

  # values
  foreach $v (values %hmk) {
      $v =~ s/foo/bar/g; # alias, modifies value in %hmk
      # ...
  }

  # delete
  $rmed_value = delete $hmk{['foo', 'bar', 'baz']};

  # clear
  %hmk = ();

  # syntactic sugar, but see risks below
  $hmk{'foo', 'bar', 'baz', 'zoo'} = 2;

  # finally, untie
  untie %hmk;

=head1 DESCRIPTION

Hash::MultiKey provides hashes that accept arrayrefs of strings as keys.

Two multi-keys are regarded as being equal if their I<contents> are
equal, there is no need to use the same reference to refer to the same
hash entry:

    $hmk{['foo', 'bar', 'baz']} = 1;
    exists $hmk{['foo', 'bar', 'baz']}; # different arrayref, but true

A given hash can have multi-keys of different lengths:

    $hmk{['foo']}               = 1; # length 1
    $hmk{['foo', 'bar', 'baz']} = 3; # length 3, no problem

In addition, multi-keys cannot be empty:

    $hmk{[]} = 1; # ERROR

The next sections document how hash-related operations work in a
multi-key hash. Some parts have been copied from standard documentation,
since everything has standard semantics.

=head2 tie

Once you have tied a hash variable to Hash::MultiKey as in

    tie my (%hmk), 'Hash::MultiKey';

you've got a hash whose keys are arrayrefs of strings. Having that in
mind everything works as expected.

=head2 store

Assignment is this easy:

    $hmk{['foo', 'bar', 'baz']} = 1;

=head2 fetch

So is fetching:

    $v = $hmk{['foo', 'bar', 'baz']};

=head2 exists

Testing for existence works as usual:

    exists $hmk{['foo', 'bar', 'baz']}; # true

Only whole multi-keys as they were used in assigments have entries.
Sub-chains do not exist unless they were assigned some value.

For instance, C<['foo']> is a sub-chain of C<['foo', 'bar', 'baz']>, but
if it has no entry in %hmk so far

    exists $hmk{['foo']}; # false

=head2 each

As with everyday C<each()>, when called in list context returns a
2-element list consisting of the key and value for the next element of
the hash, so that you can iterate over it. When called in scalar
context, returns only the key for the next element in the hash.

Remember keys are arrayrefs of strings here:

    while (($mk, $v) = each %hmk) {
        @keys = @$mk;
        # ...
    }

The order in which entries are returned is guaranteed to be the same one
as either the C<keys()> or C<values()> function would produce on the
same (unmodified) hash.

When the hash is entirely read, a null array is returned in list context
(which when assigned produces a false (0) value), and C<undef> in scalar
context. The next call to C<each()> after that will start iterating
again.

There is a single iterator for each hash, shared by all C<each()>,
C<keys()>, and C<values()> function calls in the program.

Adding or deleting entries while we're iterating over the hash results
in undefined behaviour. Nevertheless, it is always safe to delete the
item most recently returned by C<each()>, which means that the following
code will work:

    while (($mk, $v) = each %hmk) {
        print "@$mk\n";
        delete $hmk{$mk}; # this is safe
    }

=head2 keys

Returns a list consisting of all the keys of the named hash. (In scalar
context, returns the number of keys.) The keys are returned in an
apparently random order. The actual random order is subject to change in
future versions of perl, but it is guaranteed to be the same order as
either the C<values()> or C<each()> function produces (given that the
hash has not been modified). As a side effect, it resets hash's
iterator.

Remember keys are arrayrefs of strings here:

    foreach $mk (keys %hmk) {
        @keys = @$mk;
        # ...
    }

There is a single iterator for each hash, shared by all C<each()>,
C<keys()>, and C<values()> function calls in the program.

The returned values are copies of the original keys in the hash, so
modifying them will not affect the original hash. Compare C<values()>.

=head2 values

Returns a list consisting of all the values of the named hash. (In a
scalar context, returns the number of values.) The values are returned
in an apparently random order. The actual random order is subject to
change in future versions of perl, but it is guaranteed to be the same
order as either the C<keys()> or C<each()> function would produce on the
same (unmodified) hash.

Note that the values are not copied, which means modifying them will
modify the contents of the hash:

   s/foo/bar/g foreach values %hmk;       # modifies %hmk's values
   s/foo/bar/g foreach @hash{keys %hash}; # same

As a side effect, calling C<values()> resets hash's internal iterator.

There is a single iterator for each hash, shared by all C<each()>,
C<keys()>, and C<values()> function calls in the program.


=head2 delete

Deletes the specified element(s) from the hash. Returns each element so
deleted or the undefined value if there was no such element.

The following (inefficiently) deletes all the values of %hmk:

    foreach $mk (keys %hmk) {
        delete $hmk{$mk};
    }

And so do this:

    delete @hmk{keys %hmk};

But both methods are slower than just assigning the empty list to %hmk:

    %hmk = (); # clear %hmk, the efficient way

=head2 untie

Untie the variable when you're done:

    untie %hmk;

=head1 SYNTACTIC SUGAR

Hash::MultiKey supports also this syntax:

    $hash{'see', '$;', 'in', 'perldoc', 'perlvar'} = 1;

If the key is a string instead of an arrayref the underlying code splits
it using C<$;> (see why in L<MOTIVATION>) and from then on the key is an
arrayref as any true multi-key. Thus, the assigment above is equivalent
to

    $hash{['see', '$;', 'in', 'perldoc', 'perlvar']} = 1;

once it has been processed.

You I<don't> need to split the string back while iterating with
C<each()> or C<keys()>, it already comes as an arrayref of strings.

Nevertheless take into account that this is B<slower>, and B<broken> if
any of the components contains C<$;>. It is supported just for
consistency's sake.


=head1 MOTIVATION

Perl comes already with some support for hashes with multi-keys. As you
surely know, if perl sees

    $hash{'foo', 'bar', 'baz'} = 1;

it joins C<('foo', 'bar', 'baz')> with C<$;> to obtain the actual key,
thus resulting in a string. Then you retrieve the components of the
multi-key like this:

    while (($k, $v) = each %hash) {
        @keys = $k eq '' ? ('') : split /$;/, $k, -1;
        # ...
    }

Since C<$;> is C<\034> by default, a non-printable character, this is
often enough.

Sometimes, however, that's not the most convenient way to work with
multi-keys. For instance, that magic join doesn't work with arrays:

    @array = ('foo', 'bar', 'baz');
    $hash{@array} = 1; # WARNING, @array evaluated in scalar context!

You could be dealing with binary data. Or you could be writing a public
module that uses user input in such a hash and don't want to rely on
input not coming with C<$;>, or don't want to document such an obscure,
gratuitous, and implementation dependent constraint.

In such cases, Hash::MultiKey can help.

=head1 AUTHORS

Xavier Noria (FXN), Benjamin Goldberg (GOLDBB).

=head1 THANKS

Iain Truskett (SPOON) kindly checked whether this module works in perl
5.005 and found out the use of "/" in C<pack()>, introduced in perl
5.006, prevents that.

Philip Monsen reported some tests of Hash::MultiKey 0.05 failed with
perl 5.8.4.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2003, Xavier Noria E<lt>fxn@cpan.orgE<gt>. All rights
reserved. This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perlvar>, L<perltie>

=cut
