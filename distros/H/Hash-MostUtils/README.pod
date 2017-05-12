use strict;
use warnings;
package Hash::MostUtils;
use base qw(Exporter);

use Carp qw(confess);
use Hash::MostUtils::leach qw(n_each leach);

our $VERSION = 1.07;

our @EXPORT_OK = qw(
  lvalues
  lkeys
  leach
  hash_slice_of
  hash_slice_by
  hashmap
  hashgrep
  hashapply
  hashsort
  n_each
  n_map
  n_grep
  n_apply
  reindex
  rekey
  revalue
);

# decrementing $| flips it between 0 and 1
sub lkeys   { local $|; return grep { $|-- == 0 } @_ }
sub lvalues { local $|; return grep { $|-- == 1 } @_ }

# I would put leach() here, but it was imported above

*hashmap = sub(&@) { unshift @_, 2; goto &n_map };
*hashgrep = sub(&@) { unshift @_, 2; goto &n_grep };
*hashapply = sub (&@) { unshift @_, 2; goto &n_apply };

sub hashsort (&@) {
  my $sort = shift;

  my $caller = caller;
  no strict 'refs';

  return
    map { ($_->{key} => $_->{value}) }
    sort {
      local (${"$caller\::a"}, ${"$caller\::b"}) = ($a, $b);
      $sort->();
    }
    &hashmap(sub { +{key => $a, value => $b} }, @_);
}

# I would put n_each() here, but it was imported above

sub n_map ($&@) {
  # Usually I don't mutate @_. Here I deliberately modify @_ for the upcoming non-obvious goto-&NAME.
  my $n = shift;
  my $collector = sub { return $_[0]->() };
  unshift @_, $collector;

  # Using a "safe goto" allows n_map() to remove itself from the callstack, which allows _n_collect()
  # to see the correct caller.
  #
  # 'perldoc -f goto' for why this is a safe goto.
  goto &{_n_collect($n)};
}

sub n_grep ($&@) {
  my $n = shift;

  # the comments in n_map() apply here as well.

  my $collector = sub {
    my ($code, $vals, $aliases) = @_;
    return $code->() ? @$vals : ();
  };
  unshift @_, $collector;

  goto &{_n_collect($n)};
}

sub n_apply {
  my $n = shift;
  my $collector = sub {
    my ($code, $vals, $aliases) = @_;
    $code->();
    return map { $$_ } @$aliases;
  };
  unshift @_, $collector;

  goto &{_n_collect($n)};
}

sub _n_collect($) {
  my ($n) = @_;
  return sub(&@) {
    my $collector = shift;
    my $code = shift;
    if (@_ % $n != 0) {
      confess("your input is insane: can't evenly slice " . @_ . " elements into $n-sized chunks\n");
    }

    # these'll reserve some namespace back in the callpackage
    my @n = ('a' .. 'z');

    # stash old values back in callpackage *and* in main. If called from main::, this comes down to:
    #   local ${'main::a'}, ${'main::b'}, ${'main::c'}
    # when $n is 3.
    my $caller = caller;
    no strict 'refs';
    foreach ((@n[ 0 .. $n-1 ])) {
      local ${"::$_"};
    }

    my @out;
    while (my @chunk = splice @_, 0, $n) {  # build up each set...
      my @aliases;
      foreach (0 .. $#chunk) {
        # ...assign values from @_ back to localized variables in $caller *and* in 'main::'.
        # Aliasing in main::  allows you to refer to variables $c and onwards as $::c.
        # Aliasing in $caller allows you to refer to variables $c and onwards as $whatever::package::c.
        ${"::$n[$_]"} = ${"$caller\::$n[$_]"} = $chunk[$_];

        # Keep a reference to $::a (etc.) and pass them in to the $collector; this allows $code to mutate
        # $::a (etc) and signal the changed values back to $collector.
        push @aliases, \$ {"::$n[$_]"};
      }
      push @out, $collector->($code, \@chunk, \@aliases);             # ...and apply $code.
    }

    return @out;
  };
}

sub hash_slice_of {
  my ($ref, @keys) = @_;
  return map { ($_ => $ref->{$_}) } @keys;
}

sub hash_slice_by {
  my ($obj, @methods) = @_;
  return map { ($_ => scalar($obj->$_)) } @methods;
}

sub rekey (&@) {
  my %map = shift()->();
  return n_map 2, sub { $map{$a} || $a => $b }, @_;
}

sub reindex (&@) {
  my %map = shift()->();
  @_[values %map] = delete @_[keys %map];
  return @_;
}

sub revalue (&@) {
  my %map = shift()->();
  return n_map 2, sub { $a => $map{$b} || $b }, @_;
}

1;

__END__

=head1 NAME

Hash::MostUtils - Yet another collection of tools for operating pairwise on lists.

=head1 DESCRIPTION

This module provides a number of functions for processing hashes as lists of key, value pairs.

=head1 SYNOPSIS

  my @found_and_transformed =
      hashmap { uc($b) => 100 + $a }
      hashgrep { $a < 100 && $b =~ /[aeiou]/i } (
          1 => 'cwm',
          2 => 'apple',
          100 => 'cherimoya',
      );

  my @keys = lkeys @found_and_transformed;
  my @vals = lvalues @found_and_transformed;
  foreach my $key (@keys) {
      my $value = shift @vals;
      print "$key => $val\n";
  }

  while (my ($key, $val) = leach @found_and_transformed) {
      print "$key => $val\n";
  }

  my $serialized = join ',', hashsort { $a->{key} cmp $b->{key} } %hash;

=head1 EXPORTS

By default, none. On request, any of the following:

=head1 FUNCTIONS TO MAKE ARRAYS ACT LIKE HASHES

=head2 lkeys LIST

Return the "keys" of LIST. Perl's C<keys()> keyword only operates on hashes; lkeys() offers
an approximation of the same functionality for lists.

    my @evens = lkeys 1..10;

    my @keys  =
        lkeys                                     # give me back those keys (i.e. the letters)
        hashgrep { $b > 100 }                     # find key/value pairs where the value is > 100
        map { $_ => int(rand(1000)) } 'a'..'z';   # turn 'a'..'z' into key/value pairs with random values

The "keys" of a list are the even-positioned items. Note that in the case of an C<E<gt>empty slotE<lt>>
in a sparse array, the key will be C<undef>.

=head2 lvalues LIST

Return the "values" of LIST. Perl's C<values()> keyword only operates on hashes; lvalues() offers
an approximation of the same functionality for lists.

    my @odds = lkeys 1..10;

    my @values =
        lvalues                                  # give me back those values (i.e. the letters)
        hashgrep { $a > 100 }                    # look for key/value pairs where the key is > 100
        map { int(rand(1000)) => $_ } 'a'..'z';  # make 26 random keys from 1-1000, with fixed keys

The "values" of a list are the odd-positioned items. Note that in the case of an C<E<gt>empty slotE<lt>>
in a sparse array, the value will be C<undef>.

=head2 leach [ ARRAY | HASH | ARRAYREF | HASHREF ]

Iterate over an ARRAY, HASH, ARRAYREF, or HASHREF, returning successive "key/value" pairs. This behaves
functionally identically to Perl's built-in C<each> keyword; however, it is useful for arrays and array-
and hash-references. This function handles objects which are built around blessed array- and hash-references.

    my @array = (1..4);

    while (my ($k, $v) = leach @array) {
        print "$k => $v\n";
    }

    print "$_\n" for @array;

    __END__
    1 => 2
    3 => 4
    1
    2
    3
    4

Using C<leach> to gather key/value pairs from a collection is guaranteed to be non-destructive to that
collection. One pattern that's useful for iterating arrays and arrary references in pairs is to use C<splice>,
which has the possibly unintended side effect of destroying the subject collection:

    my @array = (1..4);

    while (my ($k, $v) = splice @array, 0, 2) {
        print "$k => $v\n";
    }

    print "$_\n" for @array;

    __END__
    1 => 2
    3 => 4

Note the distinction between saying that this function is

    leach ARRAY

rather than

    leach LIST

Perl does not allow this behavior:

    while (my ($k, $v) = leach 1..10) {                   # can't leach a list, only an array
        # do something with this key/value tuple
    }

But don't worry, Perl also doesn't allow for this behavior:

    while (my ($k, $v) = splice 1..10, 0, 2) {            # can't splice a list, only an array
        # do something with this key/value tuple
    }

=head1 FUNCTIONS TO OPERATE ON LISTS, ARRAYS, AND HASHES AS TUPLES

C<hashmap>, C<hashgrep>, and C<hashapply> all act like their corresponding C<map>, C<grep>, and
C<List::Utils::apply> but for one notable exception: whereas C<map>, C<grep>, and C<apply> all
eat items from the given list one-by-one and assign that current value to $_, C<hashmap>, C<hashgrep>,
and C<hashapply> all eat items from the given list two-by-two, and assigns them to $a and $b.

The names $a and $b were chosen because they're already in lexical scope in Perl due to C<sort>'s need
for them.

If you have a singular occurance of $a and $b within your program, you will probably see this warning
from Perl:

    Name 'main::a' used only once: possible typo at ...
    Name 'main::b' used only once: possible typo at ...

I've just gotten in the habit of adding:

    use strict;
    use warnings; no warnings 'once';

when I see that message.

=head2 hashmap BLOCK LIST

This acts similar to

    map BLOCK LIST

with the exception that C<map> eats items off of LIST one at a time, assigning the current value to $_;
whereas C<hashmap> eats items off of LIST two at a time, assigning the first value to $a and the second
value to $b.

    # naive transformation of this hash into (101 => 'A', 102 => 'B')
    my %hash = (
        a => 1,
        b => 2,
    );

    my %transformed =
        hashmap { $b + 100 => uc($a) }
        %hash;


Just like C<map>, your BLOCK will be called without any arguments. Like perl's keyword C<map>, this
function maintains the order of LIST.

C<hashmap> is simply a prototyped alias for n_map(2, CODEREF, LIST), so all of the documentation to
C<n_map> applies here.

=head2 hashgrep BLOCK LIST

This acts similar to

    grep BLOCK LIST

with the exception that C<grep> eats items off of LIST one at a time, assigning the current value to $_;
whereas C<hashgrep> eats items off of LIST two at a time, assigning the first value to $a and the second
value to $b.

    # lame object dumper
    my $object = Some::Class->new(...);

    my %dump =
        hashgrep { $a !~ /^_/ && ! ref($b) }   # hide private fields and internal data structures
        %$object;

Just like C<grep>, your BLOCK will be called without any arguments. Like perl's keyword C<grep>,
this function maintains the order of LIST.

C<hashgrep> is simply a prototyped alias for n_grep(2, CODEREF, LIST), so all of the documentation
to C<n_grep> applies here.

=head2 hashapply BLOCK LIST

This is similar to C<List::MoreUtils::apply>:

    apply BLOCK LIST

with the usual exception: C<apply> eats items off of LIST one at a time, assigning to $_; whereas
C<hashapply> eats items off of LIST two at a time, assigning the first value to $a and the second
value to $b.

Normal C<apply> can be written as map:

=over 4

my @words = qw(apple banana cherimoya);
my @clean1 = map { tr/aeiou//d; $_ } @words;  # @clean1 = @words = qw(ppl bnn chrmy);

@words = qw(apple banana cherimoya);
my @clean2 = apply { tr/aeiou//d } @words;    # @clean2 = qw(ppl bnn chrmy); @words = qw(apple banana cherimoya);

=back

Note that C<apply> does not transform the original data, whereas C<map> does. Similarly, C<hashapply> does
not transform the original data, whereas C<hashmap> might.

Note that C<apply> does not need to explicitly return $_, whereas C<map> does. Similarly, C<hashapply> does
not need to explicitly return a key/value tuple ($a, $b), whereas C<hashmap> does need to return something.

Like C<apply>, C<hashapply> will not transform the original LIST.

=head2 hashsort BLOCK LIST

Sort LIST by BLOCK, handling two tuples at a time. $a and $b will each have the form:

    $a = +{key => ..., value => ...};
    $b = +{key => ..., value => ...};

This call:

    my %hash = (a => 1, n => 14, m => 13, b => 2, z => 26);
    my @sorted =
      hashsort { $b->{key} cmp $a->{key} }
      %hash;

Is equivalent to this:

    my %hash = (a => 1, n => 14, m => 13, b => 2, z => 26);

    my @sorted =
      map { ($_->{key} => $_->{value}) }
      sort { $b->{key} cmp $a->{key} }
      map { +{key => $_, value => $hash{$_} }
      keys %hash;

C<hashsort> is the C<sort>-body of a Schwartzian transform over a list of tuples.

=head1 GENERIC N-ARY FORMS OF VARIOUS LIST-WISE FUNCTIONS

With the exception of C<hashsort>, each of the pairwise functions mentioned so far - C<leach>,
C<hashmap>, C<hashgrep>, C<hashapply> - are actually implemented in terms of more generic N-ary
forms. This means that if you need to process a list in sets of N, where N is E<gt> 2, you may
use the n_* forms of these functions.

Variable naming becomes more interesting when moving beyond 2 items. Whereas $a and $b are always in
lexical scope, once you go to N of 3, you need to agree on some variable naming convention.

$a and $b work nicely for the first two elements of a list; so $c is the third, and $d the fourth, and
so on. One limitation of this naming scheme is that you may not easily go beyond N of 26 - but if you
find yourself needing that, you'll find the code simple to extend.

In order to prevent 'strict refs' from complaining about $c..$z, you'll need to address those variables a
bit differently:

    my @sets =
        n_map   6, sub { [$a, $b, $::c, $::d, $::e, $::f] },
        n_apply 3, sub { $_ *= 3 for $a, $b, $::c },
        n_grep  3, sub { $::c > 4 },
        (1..9);                             # @sets = ([12, 15, 18, 21, 24, 27]);

I personally find the transition between C<$b> and C<$::c> to be a bit jarring visually, so the one
time I wrote a line like the above I chose to write it as C<$::a> and C<$::b>.

    my @sets =
        n_map   6, sub { [$::a, $::b, $::c, $::d, $::e, $::f] },
        n_apply 3, sub { $_ *= 3 for $::a, $::b, $::c },
        n_grep  3, sub { $::c > 4 },
        (1..9);                             # @sets = ([12, 15, 18, 21, 24, 27]);

=head2 n_each N, LIST

Iterate over LIST, returning successive "key/values" sets.

    my @list = (1..9);

    while (my ($k, @v) = n_each 3, @list) {
        # do something with this $k and @v
    }

There's nothing that says your N needs to remain constant:

    my @list = (
        a => 1,
        b => 1, 2,
        c => 1, 2, 3,
        d => 1, 2, 3, 4,
    );

    my $n = 2;

    my %triangle;
    while (my ($k, @v) = n_each $n++, @list) {
        $triangle{$k} = \@v;
    }

    __END__
    %triangle = (
        a => [1],
        b => [1, 2],
        c => [1, 2, 3],
        d => [1, 2, 3, 4],
    );

There's probably something clever that you can do with this that I just don't understand. Please drop me
a line if you know what it is.

=head2 n_map N, CODEREF, LIST

C<map> CODEREF over LIST, operating in N-sized chunks. Within the context of CODEREF, values of LIST
will be selected and aliased. LIST must be evenly divisible by N.

See L<GENERIC N-ARY FORMS OF VARIOUS LIST-WISE FUNCTIONS> for a discussion of variable names.

    my @transformed = n_map(
        3,
        sub { "$a, $b $::c!\n" },
        qw(goodnight sweet prince goodbye cruel world),
    );

    # @transformed = ("goodnight, sweet prince!\n", "goodbye, cruel world!");


If you are consistently n_map'ping by some N, then you might consider wrapping n_map so the call
syntax looks more like one of Perl's functional keywords:

    sub tri_map (&@) { unshift @_, 3; goto &n_map }

    my @transformed =
        tri_map { "$::a, $::b $::c!\n" }
        qw(goodnight sweet prince goodbye cruel world);

    # @transformed = ("goodnight, sweet prince!\n", "goodbye, cruel world!");

=head2 n_grep N, CODEREF, LIST

C<grep> for CODEREF over LIST, operating in N-sized chunks. Within the context of CODEREF, values
of LIST will be selected and aliased. LIST must be evenly divisible by N.

See L<GENERIC N-ARY FORMS OF VARIOUS LIST-WISE FUNCTIONS> for a discussion of variable names.

    my @found = n_grep(
        3,
        sub { $a =~ /good/ && $::c =~ /prince/ },
        qw(goodnight sweet prince goodbye cruel world),
    );

    # @found = qw(goodnight sweet prince);

Just as with C<n_map>, writing a small bit of gloss to make your N of n_grep work in a functional
manner is simple, and makes your code more readable:

    sub tri_grep (&@) { unshift @_, 3; goto &n_grep }

    my @found =
        tri_grep { $::a =~ /good/ && $::c =~ /prince/ }
        qw(goodnight sweet prince goodbye cruel world);

    # @found = qw(goodnight sweet prince);

=head2 n_apply N, CODEREF, LIST

C<List::Utils::apply> CODEREF to LIST, operating in N-sized chunks. LIST must be evenly divisible by N.

See L<GENERIC N-ARY FORMS OF VARIOUS LIST-WISE FUNCTIONS> for a discussion of variable names.

    my @uppercase = n_apply(
        3,
        sub { uc $::c }
        qw(goodnight sweet prince goodbye cruel world),
    );

    # @uppercase = qw(goodnight sweet PRINCE goodbye cruel WORLD);

Just as with C<n_map>, writing a small bit of gloss to make your N of n_apply work in a functional
manner is simple, and makes your code more readable:

    sub tri_apply (&@) { unshift @_, 3; goto &n_apply }

    my @uppercase =
        tri_apply { uc $::c }
        qw(goodnight sweet prince goodbye cruel world);

    # @uppercase = qw(goodnight sweet PRINCE goodbye cruel WORLD);

=head1 GRAB BAG

I like these functions, but they're decidedly different from everything up to this point. They
are mostly used to turn an existing hash reference or object into a smaller representation of
itself.

=head2 hash_slice_of HASHREF, LIST

Looks into HASHREF and extracts the key/value pairs of the keys named in LIST.
If a key in LIST is not present in HASHREF, returns undefined.

    my %hash = (1..10);

    my %slice = hash_slice_of \%hash, qw(5, 7, 9, 11);

    __END__
    %slice = (
        5 => 6,
        7 => 8,
        9 => 10,
        11 => undef,
    );

If you only want to get back key/value pairs for keys in LIST that exist in
HASHREF, just add a C<hashgrep>:

    my %hash = (1..10);

    my %slice =
        hashgrep { exists $hash{$a} }
        hash_slice_of \%hash, qw(5, 7, 9, 11);

    __END__
    %slice = (
        5 => 6,
        7 => 8,
        9 => 10,
    );

=head2 hash_slice_by OBJECT, LIST

Calls the methods named in LIST on OBJECT and returns a hash of the results.
If a method in LIST can not be performed on OBJECT, you will get the standard
"Can't call method ->... on object" error that Perl throws in this circumstance.

    my $object = ...;
    my %out = hash_slice_by $object, qw(foo bar baz);

    __END__
    %out = (
        foo => 'output of foo',
        bar => 'output of bar',
        baz => 'output of baz',
    );

Note that you may not use C<hash_slice_by> to pass arguments to the methods given
in LIST. Note too that your methods are invoked in scalar context.

=head2 rekey BLOCK HASH

Rename the keys in HASH by the mapping table provided by BLOCK. HASH may be a real
hash, or it may be an array that you are treating like a key/value store.

    my %hash = (crow => 'black', snow => 'white', libro => 'read all over');
    my %spanish = rekey { crow => 'corvino', snow => 'nieve' } %hash;

    __END__
    %spanish = (
        corvino => 'black',
        nieve   => 'white',
        libro   => 'read all over',
    );

=head2 revalue BLOCK HASH

Rename the values in HASH to the mapping table provided by BLOCK. HASH may be a real
hash, or it may be an array that you are treating like a key/value store.

    my @start = (apple => 'red', apple => 'green');
    my @translated = revalue { red => 'rojo', green => 'verde' } @start;

    __END__
    @translated = (
        apple => 'rojo',
        apple => 'verde',
    );

=head2 reindex BLOCK LIST

Reorder the values in LIST by the mapping table provided by BLOCK. LIST may be
either an array or a list. In general this function will not work on hashes.

    my @array = (1..5);
    my @reindexed = reindex { map { $_ => $_ + 1 } 0..$#array } @array;

    __END__
    @reindexed = (undef, 1..5);

=head1 ACKNOWLEDGEMENTS

The names and behaviors of most of these functions were initially developed at
AirWave Wireless, Inc. I've re-implemented them here.

This software would be trapped on my hard drive were it not for Logan Bell's encouragement to
release it. Separating the personal time I have put into this from the professional time afforded
by my employer, Shutterstock, Inc. would be very difficult. Thankfully I haven't needed to; when
I asked to share this, Dan McCormick simply said, "Go for it! Thanks for hacking."

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.
