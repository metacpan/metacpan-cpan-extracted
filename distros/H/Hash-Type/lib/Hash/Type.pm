package Hash::Type;

use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;
use List::Util   qw/max/;

our $VERSION = "2.00";

our $reserved_keys_field = "\0HTkeys\0"; # special reserved hash entry

#----------------------------------------------------------------------
# constructor
#----------------------------------------------------------------------
sub new { # this is a polymorphic 'new', creating either Hash::Type instances
          # from this class, or tied hashes from one of those instance
  my $obj_or_class = shift;

  if (ref($obj_or_class)) {
    # create a new tied hash from the Hash::Type instance
    my %h;
    tie %h, $obj_or_class , @_;
    return \%h;
  }
  else {
    # create a new Hash::Type instance
    my $self = {$reserved_keys_field => []};
    bless $self, $obj_or_class;
    $self->add(@_);  # add indices for fields given in @_
    return $self;
  }
}



#----------------------------------------------------------------------
# tied hash implementation
#----------------------------------------------------------------------
sub TIEHASH  { bless [@_], __PACKAGE__                                     }
sub STORE    { my $index = $_[0]->[0]{$_[1]} or
		 croak "can't STORE, key '$_[1]' was never added "
                     . "to this Hash::Type";
	       $_[0]->[$index] = $_[2];                                    }

# FETCH : must be an lvalue because it may be used in $h{field} =~ s/.../../;
# And since lvalues cannot use "return" (cf. L<perlsub>), we
# must write it with nested ternary ifs -- not nice to read :-(
sub FETCH : lvalue { 
  my $index = $_[0]->[0]{$_[1]};
  $index ? $_[0]->[$index]
         : $_[1] eq 'Hash::Type' ? $_[0]->[0]
                                 : undef;
}

sub FIRSTKEY { $_[0]->[0]{$reserved_keys_field}[0];                        }
sub NEXTKEY  { my ($h, $last_key) = @_;
               my $index_last = $h->[0]{$last_key};        # index on base 1..
               $h->[0]{$reserved_keys_field}[$index_last]; # .. used on base 0!
             }
sub EXISTS   { exists $_[0]->[0]{$_[1]}                                    }
sub DELETE   { croak "DELETE is forbidden on hash tied to " . __PACKAGE__  }
sub CLEAR    { delete @{$_[0]}[1 .. $#{$_[0]}]                             }

#----------------------------------------------------------------------
# Object-oriented methods for dealing with names and values
#----------------------------------------------------------------------
sub add {
  my $self = shift;
  my $max  = @{$self->{$reserved_keys_field}};
  my $ix   = $max;
 NAME:
  foreach my $name (@_) {
    next NAME if exists $self->{$name};
    $self->{$name} = ++$ix;
    push @{$self->{$reserved_keys_field}}, $name;
  }

  # return the number of added names
  return $ix - $max;
}

sub names {
  my ($self) = @_;
  return @{$self->{$reserved_keys_field}};
}

sub values {
  my ($self, $tied_hash) = @_;
  my $tied = tied %$tied_hash;
  return @{$tied}[1 .. @{$self->{$reserved_keys_field}}];
}

sub each {
  my ($self, $tied_hash) = @_;
  my $tied = tied %$tied_hash;
  my $index = 0;
  my $max   = @{$self->{$reserved_keys_field}};
  return sub {
    $index += 1;
    return $index <= $max ? ($self->{$reserved_keys_field}[$index-1],
                             $tied->[$index])
                          : ();
    };
}

#----------------------------------------------------------------------
# compiling comparison functions
#----------------------------------------------------------------------
sub cmp {
  my $self = shift;

  @_ or croak "cmp : no cmp args";

  if (@_ == 1) {
    # parse first syntax, where all comparison fiels are in one string
    my @fields = split /,/, shift @_;
    foreach (@fields) {
      m[^\s*(\S.*?)\s*(?::([^:]+))?$] or croak "bad cmp op : $_";
      push @_, $1, $2; # feed back to @_ as arguments to second syntax
    }
  }

  # parse second syntax (pairs of field_name => comparison_instruction)

  # $a and $b are different in each package, so we must refer to the caller's
  my $caller = caller;
  my ($a, $b) = ("\$${caller}::a", "\$${caller}::b");

  my @cmp;         # holds code for each comparison to perform
  my @caller_sub;  # references to comparison subs given by caller
                   # (must copy them from @_ into a lexical variable
                   #  in order to build a proper closure)
  my $regex;       # used only for date comparisons, see below

  for (my $i = 0; $i < @_; $i += 2) {
    my $ix = $self->{$_[$i]} or croak "can't do cmp on absent field : $_[$i]";

    if (ref $_[$i+1] eq 'CODE') { # ref. to cmp function supplied by caller
      push @caller_sub, $_[$i+1];
      push @cmp, "do {local ($a, $b) = (tied(%$a)->[$ix], tied(%$b)->[$ix]);".
	             "&{\$caller_sub[$#caller_sub]}}";
    }
    else { # builtin comparison operator
      my ($sign, $op) = ("", "cmp");
      my $str;
      if (defined $_[$i+1]) {
	($sign, $op) = ($_[$i+1] =~ /^\s*([-+]?)\s*(.+)/);
      }

      for ($op) {
	/^(alpha|cmp)\s*$/   and do {$str = "%s cmp %s"; last};
	/^(num|<=>)\s*$/     and do {$str = "%s <=> %s"; last};
	/^d(\W+)m(\W+)y\s*$/ and do {$regex=qr{(\d+)\Q$1\E(\d+)\Q$2\E(\d+)};
				     $str = "_date_cmp(\$regex, 0, 1, 2, %s, %s)";
				     last};
	/^m(\W+)d(\W+)y\s*$/ and do {$regex=qr{(\d+)\Q$1\E(\d+)\Q$2\E(\d+)};
				     $str = "_date_cmp(\$regex, 1, 0, 2, %s, %s)";
				     last};
	/^y(\W+)m(\W+)d\s*$/ and do {$regex=qr{(\d+)\Q$1\E(\d+)\Q$2\E(\d+)};
				     $str = "_date_cmp(\$regex, 2, 1, 0, %s, %s)";
				     last};
	croak "bad operator for Hash::Type::cmp : $_[$i+1]";
      }
      $str = sprintf("$sign($str)", "tied(%$a)->[$ix]", "tied(%$b)->[$ix]");
      push @cmp, $str;
    }
  }

  local $@;
  my $sub = eval "sub {" . join(" || ", @cmp) . "}"
    or croak $@;
  return $sub;
}


sub _date_cmp {
  my ($regex, $d, $m, $y, $date1, $date2) = @_;

  return  0 if not $date1 and not $date2;
  return  1 if not $date1;  # null date is treated as bigger than any other
  return -1 if not $date2;

  for my $date ($date1, $date2) {
    $date =~ s[<.*?>][]g;   # remove any markup
    $date =~ tr/{}[]()//d;  # remove any {}[]() chars
  }; 

  my @d1 = ($date1 =~ $regex) or croak "invalid date '$date1' for regex $regex";
  my @d2 = ($date2 =~ $regex) or croak "invalid date '$date2' for regex $regex";

  $d1[$y] += ($d1[$y] < 33) ? 2000 : 1900 if $d1[$y] < 100;
  $d2[$y] += ($d2[$y] < 33) ? 2000 : 1900 if $d2[$y] < 100;

  return ($d1[$y]<=>$d2[$y]) || ($d1[$m]<=>$d2[$m]) || ($d1[$d]<=>$d2[$d]);
}


1;

__END__

=head1 NAME

Hash::Type - restricted, ordered hashes as arrays tied to a "type" (shared list of keys)

=head1 SYNOPSIS

  use Hash::Type;

  # create a Hash::Type
  my $person_type = Hash::Type->new(qw/firstname lastname city/);

  # create and populate some hashes tied to $person_type
  tie my(%wolfgang), $person_type, "wolfgang amadeus", "mozart", "salzburg";
  my $ludwig = $person_type->new("ludwig", "van beethoven", "vienna");
  my $jsb    = $person_type->new;
  $jsb->{city} = "leipzig";
  @{$jsb}{qw/firstname lastname/} = ("johann sebastian", "bach");

  # add fields dynamically
  $person_type->add("birth", "death") or die "fields not added";
  $wolfgang{birth} = 1750;

  # get back ordered names or values
  my @fields = $person_type->names;              # same as: keys %wolfgang
  my @vals   = $person_type->values(\%wolfgang); # same as: values %wolfgang

  # More complete example : read a flat file with headers on first line
  my ($headerline, @datalines) = map {chomp; $_} <F>;
  my $ht = Hash::Type->new(split /\t/, $headerline);
  foreach my $line (@datalines) {
    my $data = $ht->new(split /\t/, $line);
    work_with($data->{some_field}, $data->{some_other_field});
  }

  # get many lines from a DBI database
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  my $ht = Hash::Type->new(@{$sth->{NAME}});
  while (my $r = $sth->fetchrow_arrayref) {
    my $row = $ht->new(@$r);
    work_with($row);
  }

  # an alternative to Time::gmtime and Time::localtime
  my $time_type  = Hash::Type->new(qw/sec min hour mday mon year wday yday/);
  my $localtime  = $time_type->new(localtime);
  my $gmtime     = $time_type->new(gmtime);
  print $localtime->{hour} - $gmtime->{hour}, " hours difference to GMT";

  # an alternative to File::Stat or File::stat or File::Stat::OO
  my $stat_type  = Hash::Type->new(qw/dev ino mode nlink uid gid rdev
                                      size atime mtime ctime blksize blocks/);
  my $stat       = $stat_type->new(stat $my_file);
  print "$my_file has $stat->{size} bytes and $stat->{blocks} blocks";


  # comparison functions
  my $by_age         = $person_type->cmp("birth : -num, lastname, firstname");
  my $by_name_length = $person_type->cmp(
    lastname  => {length($b) <=> length($a)},
    lastname  => 'alpha',
    firstname => 'alpha',
  );
  show_person($_) foreach (sort $by_age         @people);
  show_person($_) foreach (sort $by_name_length @people);

  # special comparisons : dates
  my $US_date_cmp         = $my_hash_type->cmp("some_date_field : m/d/y");
  my $FR_inverse_date_cmp = $my_hash_type->cmp("some_date_field : -d.m.y");

=head1 DESCRIPTION

An instance of C<Hash::Type>  encapsulates a collection of field names,
and is used to generate tied hashes, implemented internally as arrayrefs,
and sharing the common list of fields.

The original motivation for this design was to spare memory, since the
field names are shared. As it turns out, benchmarks show that this
goal is not attained : memory usage is about 35% higher than Perl
native hashes.  However, this module also implements B<restricted
hashes> (hashes with a fixed set of keys that cannot be expanded) and
of B<ordered hashes> (the list of keys or list values are returned in
a fixed order); and for those two functionalities, the performances of
C<Hash::Type> are very competitive with respect to those of other
similar modules, both in terms of CPU and memory usage (see the
L</"BENCHMARKS"> section at the end of the documentation). In
addition, C<Hash::Type> offers an API for B<convenient and very
efficient sorting> of lists of tied hashes, and alternative
methods for C<keys>, C<values> and C<each>, faster than the L</perltie>
API.

In conclusion, this module is well suited for any need of restricted
and/or ordered hashes, and for situations dealing with large
collections of homogeneous hashes, like for example data rows coming from
spreadsheets or databases.

=head1 METHODS

=head2 new

The C<new()> method is polymorphic : it can be used
both as a class and as an instance method.

=head3 C<new()> as a class method

  my $h_type = Hash::Type->new(@names);

Creates a new instance which holds a collection of names and
associated indices (technically, this is a hash reference blessed in
package C<Hash::Type>).  This instance can then be used to generate tied
hashes.  The list of C<@names> is optional ; names can be added later
through the C<add> method.

=head3 C<new()> as an instance method

  my $tied_hashref = $h_type->new(@vals);

Creates a new tied hash associated to the C<Hash::Type> class and
containing a reference to the C<$h_type> instance.
Internally, the tied hash is implemented as an array reference.

=head2 TIE interface

=head3 Tied hash creation

The C<tie> syntax is an alternative to the C<new()> method seen above :

  tie my(%hash), $h_type, @vals;

This is a bit unusual since the official syntax for the L<tie> function
is C<tie VARIABLE, CLASSNAME, LIST>; here the second argument is not
a classname, but an object. It works well, however, because the
C<TIEHASH> call merely passes the second argument to the implementation,
without any check that this is a real scalar classname.

=head3 Accessing names in tied hashes

Access to C<$hash{name}> works like for a regular Perl hash.
It is equivalent to writing

  tied(%hash)->[$h_type->{name}]

where C<$h_type> is the C<Hash::Type> instance. That instance
can be retrieved through the special, reserved name
C<$hash{'Hash::Type'}>; you may need it for example to
generate a comparison function, as explained below.
The reserved name C<$hash{'Hash::Type'}> can be read but it does
not belong to  C<keys %hash>.

The operation C<delete $hash{name}> is forbidden since it would
break the consistency of the internal arrayref. Any attempt to
delete a name will generate an exception. Of course it is always
possible to set a field to C<undef>.

=head3 Iterating on keys

Standard Perl operations C<keys>, C<values> and C<each> on tied
hashes preserve the order in which names were added to the
C<Hash::Type> instance.

The same behavior can be obtained through object-oriented method
calls, described below.


=head2 add

  $h_type->add(@new_names);

Adds C<@new_names> in C<$h_type> and gives them new indices.
Does nothing for names that were already present.
Returns the number of names actually added.

Existing hashes already tied to C<$h_type> are not touched; their
internal arrayrefs are not expanded, but the new fields will spring
into existence as soon as they are assigned a value,
thanks to Perl's auto-vivification mechanism.

=head2 names

  my @headers = $h_type->names;

Returns the list of defined names, in index order.
This is the same list as C<keys %hash>, but computed faster
because it directly returns a copy of the underlying name array
instead of having to iterate through the keys.

=head2 values

  my @vals = $h_type->values(\%hash);

Returns the list of values in C<%hash>, in index order.
This is the same list as C<values %hash>, but computed faster.

=head2 each

  my $iterator = $h_type->each(\%hash);
  while (my ($key, $value) = $iterator->()) {
    # ...
  }

Returns an iterator function that yields pairs of
($key, $value) at each call, until reaching an empty list
at the end of the tied hash.
This is the same as calling C<each %hash>, but works faster.

=head2 cmp

=head3 first syntax : one single argument

  my $cmp = $h_type->cmp("f1 : cmp1, f2 : cmp2 , ...")

Returns a reference to an anonymous sub which successively compares
the given field names, applying the given operators,
and returns a positive, negative or zero value.
This sub can then be fed to C<sort>. 'f1', 'f2', etc are field names,
'cmp1', 'cmp2' are comparison operators written as :

  [+|-] [alpha|num|cmp|<=>|d.m.y|d/m/y|y-m-d|...]

The sign is '+' for ascending order, '-' for descending; default is '+'.
Operator 'alpha' is synonym to 'cmp' and 'num' is synonym to '<=>';
operators 'd.m.y', 'd/m/y', etc. are for dates in various
formats; default is 'alpha'. So for example

  my $cmp = $h_type->cmp("foo : -alpha, bar : num");

will sort alphabetically on C<foo> in descending order; in case of identical
values for the C<foo> field, it will sort numerically on the C<bar> field.

If all you want is alphabetic ascending order, 
just write the field names :

  my $cmp = $person_type->cmp('lastname, firstname');

B<Note> : C<sort> will not accept something like

  sort $person_type->cmp('lastname, firstname') @people;

so you B<have to> store it in a variable first :

  my $cmp = $person_type->cmp('lastname', 'firstname');
  sort $cmp @people;

For date comparisons, values are parsed into day/month/year, according
to the shape specified (for example 'd.m.y') will take '.' as
a separator. Day, month or year need not be several digits,
so '1.1.1' will be interpreted as '01.01.2001'. Years of 2 or 1 digits
are mapped to 2000 or 1900, with pivot at 33 (so 32 becomes 2032 and
33 becomes 1933).

=head3 second syntax : pairs of (field_name => comparison_specification)

  my $cmp = $h_type->cmp(f1 => cmp1, f2 => cmp2, ...);

This second syntax, with pairs of field names and operators,
is a bit more verbose but gives you more flexibility, 
as you can write your own comparison functions using C<$a> and C<$b> :

  my $by_name_length = $person_type->cmp(
    lastname  => {length($b) <=> length($a)},
    lastname  => 'alpha',
    firstname => 'alpha',
  );

B<Note> : the resulting closure is bound to
the special variables C<$a> and C<$b>. Since those
are different in each package, you cannot
pass the comparison function to another
package : the call to C<sort> has to be done in the package where the 
comparison function was compiled.


=head1 INTERNALS

A C<Hash::Type> instance is a blessed hashref, in which
each declared name is associated with a corresponding index
(starting at 1).

In addition, the hashref contains a private key C<\0HTkeys\0> holding
an arrayref to the ordered list of names, in order to provide a fast
implementation for the C<NEXTKEY> operation. In the unlikely case
that this private key would cause a conflict, it can be changed
by setting C<$Hash::Type::reserved_keys_field> to a different value.

Tied hashes are implemented as arrayrefs, in which slot 0 points
to the C<Hash::Type> instance, and slots 1 to I<n> are the values
for the named fields.

The particular thing about this module is that it has two different
families of instances blessed into the same class :

=over

=item *

blessed hashrefs are "types", holding a collection of field names,
answering to object-oriented methods of the public interface 
(i.e. methods L</add>, L</names>, etc.)

=item *

blessed arrayrefs are implementations of tied hashes, answering
to implicit method calls of the L</perltie> API
(i.e methods C<FIRSTKEY>, C<NEXTKEY>, C<EXISTS>, etc.).

=back


=head1 SEE ALSO

The 'pseudo-hashes' documented in L<perlref> were very similar,
but were deprecated since Perl 5.8.0.

For other ways to restrict the keys of a hash to a fixed set, see
L<Hash::Util/lock_keys>, L<Tie::Hash::FixedKeys>, L<Tie::StrictHash>.

For other ways to implement ordered hashes, see
L<Tie::IxHash>, L<Hash::Ordered>, L<Tie::Hash::Indexed>, and many
others.

The L<Sort::Fields> module in CPAN uses techniques similar to
the present L</cmp> method for
dynamically building sorting criterias according to field
positions; but it is intended for numbered fields, not
for named fields, and has no support for caller-supplied
comparison operators. The design is also a bit different :
C<fieldsort> does everything at once (splitting, comparing
and sorting), whereas C<Hash::Type::cmp> only compares, and
leaves it to the caller to do the rest.

C<Hash::Type> was primarily designed as a core element
for implementing rows of data in L<File::Tabular>.

=head1 BENCHMARKS

A benchmark program is supplied within the distribution to compare
performances of C<Hash::Type> to some other solutions. Compared
operations were hash creation, data access, data update, sorting,
and deletion, varying the number of tied hashes, the number of keys,
and also the length of hash keys (surprisingly, this can make a difference!).

To give an idea, here are just a few results :

  200000 records with 10 keys of  1 chars
   create  update  access    sort  delete   memory
  ======= ======= ======= ======= ======= ========
    4.181   2.246   0.812   0.062   0.016  132.5MB (perl core hashes)
    2.683   5.366   1.357   0.110   0.078  227.4MB (Hash::Type v2.00)
    3.386   5.740   1.358   5.194   0.110  524.0MB (Hash::Ordered v0.010)
    5.756   7.005   1.451   5.818   0.109  539.8MB (Tie::IxHash v1.23)
    3.167   4.196   1.279   5.258   0.171  508.2MB (Tie::Hash::Indexed v0.05)

  200000 records with  5 keys of 20 chars
   create  update  access    sort  delete   memory
  ======= ======= ======= ======= ======= ========
    1.482   1.201   0.811   0.078   0.031  132.5MB (perl core hashes)
    1.669   2.933   1.326   0.125   0.063  180.0MB (Hash::Type v2.00)
    2.200   3.120   1.341   5.148   0.109  524.0MB (Hash::Ordered v0.010)
    3.541   3.744   1.498   5.257   0.141  539.8MB (Tie::IxHash v1.23)
    1.826   2.215   1.279   5.164   0.172  506.2MB (Tie::Hash::Indexed v0.05)

  100000 records with 50 keys of  2 chars
   create  update  access    sort  delete   memory
  ======= ======= ======= ======= ======= ========
    6.349   5.382   0.406   0.062   0.171  384.5MB (perl core hashes)
    5.429  13.384   0.702   0.063   0.110  432.0MB (Hash::Type v2.00)
    9.048  14.211   0.687   1.232   0.577 1180.7MB (Hash::Ordered v0.010)
   14.508  17.113   0.765   1.513   0.702 1354.6MB (Tie::IxHash v1.23)
    7.893  11.997   0.670   1.358   1.107 1542.4MB (Tie::Hash::Indexed v0.05)

The conclusions (confirmed by other results not displayed here) are
that C<Hash::Type> is quite reasonable in CPU and memory usage, with
respect to other modules implementing ordered hashes. It even
sometimes outperforms perl core hashes on creation time. It is
especially good at sorting, but this due to its API allowing to
I<compile> a sorting function before applying it to a list of hashes.

Among the competitors L<Tie::Hash::Indexed> is the fastest, which is
not suprising as it is implemented in XS, while all other are
implemented in pure Perl; notice however that this module is quite
costly in terms of memory.

L<Tie::IxHash>, which was among the first modules on CPAN for
ordered hashes, is definitely the slowest and is quite greedy for memory.

L<Hash::Ordered>, a more recent proposal, sits in the middle; however, it
should be noted that the benchmark was based on its L</perltie> API, which
is probably not the most efficient way to use this module.


=head1 AUTHOR

Laurent Dami, C<< <laurent.dami AT cpan dot org>  >>

=head1 COPYRIGHT AND LICENSE

Copyright 2005, 2016 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


