package Hash::AutoHash::AVPairsMulti;
our $VERSION='1.17';
$VERSION=eval $VERSION;		# I think this is the accepted idiom..

#################################################################################
#
# Author:  Nat Goodman
# Created: 09-03-05
# $Id: 
#
# AutoHash with multivalued string or number elements. no references
# Inspired by Tie::Hash::Multivalue
#
#################################################################################
use strict;
use Carp;
use Hash::AutoHash;
use base qw(Hash::AutoHash);

our @NORMAL_EXPORT_OK=@Hash::AutoHash::EXPORT_OK;
my $helper_class=__PACKAGE__.'::helper';
our @EXPORT_OK=$helper_class->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=$helper_class->SUBCLASS_EXPORT_OK;

#################################################################################
# helper package exists to avoid polluting Hash::AutoHash::Args namespace with
#   subs that would mask accessor/mutator AUTOLOADs
# functions herein (except _new) are exportable by Hash::AutoHash::Args
#################################################################################
package Hash::AutoHash::AVPairsMulti::helper;
our $VERSION=$Hash::AutoHash::AVPairsMulti::VERSION;
use strict;
use Carp;
BEGIN {
  our @ISA=qw(Hash::AutoHash::helper);
}
use Hash::AutoHash qw(autohash_tie);

sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie Hash::AutoHash::AVPairsMulti::tie,@args;
  bless $self,$class;
}

#################################################################################
# Tied hash which implements Hash::AutoHash::AVPairsMulti
#################################################################################
package Hash::AutoHash::AVPairsMulti::tie;
our $VERSION=$Hash::AutoHash::AVPairsMulti::VERSION;
use strict;
use Carp;
use Hash::AutoHash::MultiValued;
our @ISA=qw(Hash::AutoHash::MultiValued::tie);

sub STORE {
  my($self,$key,@new)=@_;
  # all values must be simple (non-reference)
  my $bad;
  if (@new==1 && 'ARRAY' eq ref $new[0]) { # if passed ARRAY, look inside
    $bad=1 if grep {ref($_)} @{$new[0]};
  } else {
    $bad=grep {ref($_)} @new;
  }
  confess "Trying to store reference as value of attribute $key" if $bad;
  $self->SUPER::STORE($key,@new);
}
1;

__END__

=head1 NAME

Hash::AutoHash::AVPairsMulti -  Object-oriented access to hash with multi-valued simple (non-reference) elements

=head1 VERSION

Version 1.17

=head1 SYNOPSIS

  use Hash::AutoHash::AVPairsMulti;

  # create object and set intial values
  my $avp=new Hash::AutoHash::AVPairsMulti
               pets=>'Spot',hobbies=>'chess',hobbies=>'cooking';

  # access or change hash elements via methods
  my $pets=$avp->pets;                   # ['Spot']
  my @pets=$avp->pets;                   # ('Spot')
  my $hobbies=$avp->hobbies;             # ['chess','cooking']
  my @hobbies=$avp->hobbies;             # ('chess','cooking')
  $avp->hobbies('go','rowing');          # new values added to existing ones
  my $hobbies=$avp->hobbies;             # ['chess','cooking','go','rowing']
  $avp->family({kids=>'Joey'});          # illegal - reference

  # you can also use standard hash notation and functions
  my($pets,$hobbies)= @$avp{qw(pets hobbies)};          
                                         # get 2 elements in one statement
  $avp->{pets}='Felix';                  # set pets to ['Spot','Felix']   
  my @keys=keys %$avp;                   # ('pets','hobbies')
  my @values=values %$avp;               # (['Spot','Felix'],
                                         #  ['chess','cooking','go','rowing'])
  while(my($key,$value)=each %$avp) {
     print "$key => @$value\n";          # prints each element as usual
  }
  delete $avp->{hobbies};                # no more hobbies

  # CAUTION: hash notation doesn't respect array context!
  $avp->{hobbies}=('go','rowing');    # sets hobbies to last value only
  my @hobbies=$avp->{hobbies};        # @hobbies is (['rowing'])
 
  # alias $avp to regular hash for more concise hash notation
  use Hash::AutoHash::AVPairsMulti qw(autohash_alias);
  my %hash;
  autohash_alias($avp,%hash);
  # access or change hash elements without using ->
  $hash{hobbies}=['chess','cooking'];    # append values to hobbies 
  my $pets=$hash{pets};                  # ['Spot','Felix']
  my $hobbies=$hash{hobbies};            # ['rowing','chess','cooking']
  # another way to do the same thing
  my($pets,$hobbies)=@hash{qw(pets hobbies)};

  # set 'unique' in tied object to eliminate duplicates
  use Hash::AutoHash::AVPairsMulti qw(autohash_tied);
  autohash_tied($avp)->unique(1);
  $avp->hobbies('cooking','baking');     # duplicate 'cooking' not added
  my @hobbies=$avp->hobbies;             # ('rowing','chess','cooking','baking')

=head1 DESCRIPTION

This is a subclass of L<Hash::AutoHash> which wraps a tied hash whose
elements contain multiple simple values like numbers and strings, not
references. L<Hash::AutoHash::Record> uses this class to represent
attribute-value pairs parsed from text files.  It is conceptually a
subclass of L<Hash::AutoHash::MultiValued> whose elements contain
values of all kinds.

Like L<Hash::AutoHash> itself, this class lets you get or set hash
elements using hash notation or by invoking a method with the same
name as the key.  See L<SYNOPSIS> for examples.  

Also like L<Hash::AutoHash>, this class provides a full plate of
functions for performing hash operations on
Hash::AutoHash::AVPairsMulti objects.  These are useful if you want to
avoid hash notation all together.

And also like L<Hash::AutoHash>, you can alias the object to a regular
hash for more concise hash notation. See L<SYNOPSIS> for examples.
Admittedly, this is a minor convenience, but the reduction in
verbosity can be useful in some cases.

As in L<Hash::AutoHash>, the namespace is "clean"; any method invoked
on an object is interpreted as a request to access or change an
element of the underlying hash.  The software accomplishes this by
providing all its capabilities through class methods (these are
methods, such as 'new', that are invoked on the class rather than on
individual objects), functions that must be imported into the caller's
namespace, and methods invoked on the tied object implementing the
hash.

CAUTION: As of version 1.12, it is not possible to use method
notation for keys with the same names as methods inherited from
UNIVERSAL (the base class of everything). These are 'can', 'isa',
'DOES', and 'VERSION'.  The reason is that as of Perl 5.9.3, calling
UNIVERSAL methods as functions is deprecated and developers are
encouraged to use method form instead. Previous versions of AutoHash
are incompatible with CPAN modules that adopt this style.

=head2 Duplicate elimination and filtering

By default, hash elements may contain duplicate values.

  my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
  my @hobbies=$avp->hobbies;             # ('go','go')

You can change this behavior by setting 'unique' in the B<tied object
implementing the hash> to a true value. 

 autohash_tied($avp)->unique(1);
 my @hobbies=$avp->hobbies;              # now ('go')

'unique' can be set to a boolean, as in the example, or to a
subroutine (technically, a CODE ref).  The subroutine should operate
on two values and return true if the values are considered to be
equal, and false otherwise.  

By default, 'unique' is sub {my($a,$b)=@_; $a eq $b}. The following example shows
how to set 'unique' to a subroutine that does case-insensitive
duplicate removal.

  my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>['GO','go'];
  autohash_tied($avp)->unique(sub {my($a,$b)=@_; lc($a) eq lc($b)});
  my @hobbies=$avp->hobbies;             # @hobbies is ('GO')

When 'unique' is given a true value, duplicate removal occurs
immediately by running all existing elements through the
duplicate-removal process. Thereafter, duplicate checking occurs on
every update.

In many cases, it works fine and is more efficient to perform
duplicate removal on-demand rather than on every update.  You can
accomplish this by setting 'filter' in the B<tied object implementing
the hash> to a true value. By default, the filter function is 'uniq'
from L<List::MoreUtils>. You can change this by setting 'filter' to a
subroutine reference which takes a list of values as input and returns
a list of values as output. Though motivated by duplicate removal, the
'filter' function can transform the list in any way you choose.

The following contrived example shows sets 'filter' to a subroutine
that performs case-independent duplicate removal and sorts the
resulting values.

  sub uniq_nocase_sort {
    my %uniq;
    my @values_lc=map { lc($_) } @_;
    @uniq{@values_lc}=@_;
    sort values %uniq;  
  }

  my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>['GO','go','dance'];
  autohash_tied($avp)->filter(\&uniq_nocase_sort);
  my @hobbies=$avp->hobbies;             # @hobbies is ('dance','go')

You can do the same thing more concisely with this cryptic one-liner.

  autohash_tied($avp)->filter(sub {my %u; @u{map {lc $_} @_}=@_; sort values %u}); 

Filtering occurs when you run the 'filter' method. It does not occur on every update.

=head2 new

 Title   : new 
 Usage   : $avp=new Hash::AutoHash::AVPairsMulti
                       pets=>'Spot',hobbies=>'chess',hobbies=>'cooking'
           -- OR --
           $avp=new Hash::AutoHash::AVPairsMulti
                       [pets=>'Spot',hobbies=>'chess',hobbies=>'cooking']
           -- OR --
           $avp=new Hash::AutoHash::AVPairsMulti
                       {pets=>'Spot',hobbies=>['chess','cooking']}
 Function: Create Hash::AutoHash::AVPairsMulti object and set elements.
 Returns : Hash::AutoHash::AVPairsMulti object
 Args    : Optional list of key=>value pairs which are used to set elements of
           the object. Args can also be passed as ARRAY or HASH
 Notes   : Be aware when passing args as HASH that Perl does NOT preserve
           duplicate keys.

=head2 unique

This method must be invoked on the B<tied object implementing the hash>.

 Title   : unique 
 Usage   : $unique=tied(%$avp)->unique
           -- OR --
           tied(%$avp)->unique($boolean)
           -- OR --
           tied(%$avp)->unique(\&function)
           -- OR --
           $unique=autohash_tied($avp)->unique
           -- OR --
           autohash_tied($avp)->unique($boolean)
           -- OR --
           autohash_tied($avp)->unique(\&function)
 Function: Get or set option that controls duplicate elimination.  
           Form 1 gets the current value of the control.  
           Form 2. If the argument is true, duplicate-removal is turned on using 
           'eq' to determine which values are equal. 
           If the argument is false, duplicate-removal is turned off.  
           Form 3 turns on duplicate removal using the given function. 
           Forms 4-6 are functionally equivalent to the first three but use the
           autohash_tied function to get the tied object instead of Perl's
           built-in tied function.
           Note the '%' in front of $record in the first three forms and its
           absence in the next three forms.
 Returns : value of the control 
 Args    : Forms 2&5. Usually a boolean value, but can be any value which is not
           a CODE reference.  
           Forms 3&6. CODE reference for a function that takes two values and 
           returns true or false.
 Notes   : When unique is given a true value (including a CODE ref in forms 3&6)
           duplicate removal occurs immediately by running all existing elements
           through the duplicate-removal process. Thereafter, duplicate checking
           occurs on every update.

=head2 filter

This method must be invoked on the B<tied object implementing the hash>.

 Title   : filter 
 Usage   : $filter=tied(%$avp)->filter
           -- OR --
           tied(%$avp)->filter($boolean)
           -- OR --
           tied(%$avp)->filter(\&function)
            -- OR --
           $filter=autohash_tied($avp)->filter
           -- OR --
           autohash_tied($avp)->filter($boolean)
           -- OR --
           autohash_tied($avp)->filter(\&function)
Function: Set function used for filtering and perform filtering if true.
           Form 1 filters elements using filter function previously set.
           Form 2. If true, sets the filter function to its default, which is 
           'uniq' from L<List::MoreUtils> and performs filtering.
           If false, turns filtering off.  
           Form 3 sets the filter function to the given function and performs
           filtering.
           Forms 4-6 are functionally equivalent to the first three but use the 
           autohash_tied function to get the tied object instead of Perl's 
           built-in tied function.
           Note the '%' in front of $record in the first three forms and its
           absence in the last three forms.
 Returns : value of the control 
 Args    : Forms 2&5. Usually a boolean value, but can be any value which is not 
           a CODE reference.  
           Forms 3&6. CODE reference for a function that takes a list and 
           returns a list. The input list is passed in @_.
 Notes   : When filter is given a true value (including a CODE ref in forms 3&6)
           filtering occurs immediately by running all existing elements through
           the filter function.

=head2 Functions inherited from Hash::AutoHash

The following functions are inherited from L<Hash::AutoHash> and
operate exactly as there. You must import them into your namespace
before use.

 use Hash::AutoHash::AVPairsMulti
    qw(autohash_alias autohash_tied autohash_get autohash_set
       autohash_clear autohash_delete autohash_each autohash_exists 
       autohash_keys autohash_values 
       autohash_count autohash_empty autohash_notempty)

=head3 autohash_alias

Aliasing a Hash::AutoHash object to a regular hash avoids the need to
dereference the variable when using hash notation.  As a convenience,
the autoahash_alias functions can link in either direction depending
on whether the given object exists.

 Title   : autohash_alias
 Usage   : autohash_alias($avp,%hash)
 Function: Link $avp to %hash such that they will have exactly the same value.
 Args    : Hash::AutoHash::AVPairsMulti object and hash 
 Returns : Hash::AutoHash::AVPairsMulti object

=head3 autohash_tied

You can access the object implementing the tied hash using Perl's
built-in tied function or the autohash_tied function inherited from
L<Hash::AutoHash>.  Advantages of autohash_tied are (1) it operates
directly on the Hash::AutoHash::AVPairsMulti object without requiring a
leading '%', and (2) it provide an arguably simpler syntax for
invoking methods on the tied object.

 Title   : autohash_tied 
 Usage   : $tied=autohash_tied($avp)
           -- OR --
           $tied=autohash_tied(%hash)
           -- OR --
           $result=autohash_tied($avp,'some_method',@parameters)
           -- OR --
           $result=autohash_tied(%hash,'some_method',@parameters)
 Function: The first two forms return the object implementing the tied hash. The
           latter two forms invoke a method on the tied object. 
           In forms 1 and 3, the first argument is the 
           Hash::AutoHash::AVPairsMulti object.
           In forms 2 and 4, the first argument is a hash to which a 
           Hash::AutoHash::AVPairsMulti object has been aliased
 Returns : In forms 1 and 2, object implementing tied hash or undef.
           In forms 3 and 4, result of invoking method (which can be anything or
           nothing), or undef.
 Args    : Form 1. Hash::AutoHash::AVPairsMulti object
           Form 2. hash to which Hash::AutoHash::AVPairsMulti object is aliased
           Form 3. Hash::AutoHash::AVPairsMulti object, method name, optional 
             list of parameters for method
           Form 4. hash to which Hash::AutoHash::AVPairsMulti object is aliased, 
             method name, optional list of parameters for method

=head3 autohash_get

 Title   : autohash_get
 Usage   : ($pets,$hobbies)=autohash_get($avp,qw(pets hobbies))
 Function: Get values for multiple keys.
 Args    : Hash::AutoHash::AVPairsMulti object and list of keys
 Returns : list of argument values

=head3 autohash_set

 Title   : autohash_set
 Usage   : autohash_set($avp,pets=>'Felix',kids=>'Joe')
           -- OR --
           autohash_set($avp,['pets','kids'],['Felix','Joe'])
 Function: Set multiple arguments in existing object.
 Args    : Form 1. Hash::AutoHash::AVPairsMulti object and list of key=>value pairs
           Form 2. Hash::AutoHash::MultiValue object, ARRAY of keys, ARRAY of 
           values
 Returns : Hash::AutoHash::AVPairsMulti object

=head3 Functions for hash-like operations

The remaining functions provide hash-like operations on
Hash::AutoHash::AVPairsMulti objects. These are useful if you want to
avoid hash notation all together.

=head4 autohash_clear

 Title   : autohash_clear
 Usage   : autohash_clear($avp)
 Function: Delete entire contents of $avp
 Args    : Hash::AutoHash::AVPairsMulti object
 Returns : nothing

=head4 autohash_delete

 Title   : autohash_delete
 Usage   : autohash_delete($avp,@keys)
 Function: Delete keys and their values from $avp.
 Args    : Hash::AutoHash::AVPairsMulti object, list of keys
 Returns : nothing

=head4 autohash_exists

 Title   : autohash_exists
 Usage   : if (autohash_exists($avp,$key)) { ... }
 Function: Test whether key is present in $avp.
 Args    : Hash::AutoHash::AVPairsMulti object, key
 Returns : boolean

=head4 autohash_each

 Title   : autohash_each
 Usage   : while (my($key,$value)=autohash_each($avp)) { ... }
           -- OR --
           while (my $key=autohash_each($avp)) { ... }
 Function: Iterate over all key=>value pairs or all keys present in $avp
 Args    : Hash::AutoHash::AVPairsMulti object
 Returns : list context: next key=>value pair in $avp or empty list at end
           scalar context: next key in $avp or undef at end

=head4 autohash_keys

 Title   : autohash_keys
 Usage   : @keys=autohash_keys($avp)
 Function: Get all keys that are present in $avp
 Args    : Hash::AutoHash::AVPairsMulti object
 Returns : list of keys

=head4 autohash_values

 Title   : autohash_values
 Usage   : @values=autohash_values($avp)
 Function: Get the values of all keys that are present in $avp
 Args    : Hash::AutoHash::AVPairsMulti object
 Returns : list of values

=head4 autohash_count

 Title   : autohash_count
 Usage   : $count=autohash_count($avp)
 Function: Get the number keys that are present in $avp
 Args    : Hash::AutoHash::AVPairsMulti object
 Returns : number

=head4 autohash_empty

 Title   : autohash_empty
 Usage   : if (autohash_empty($avp)) { ... }
 Function: Test whether $avp is empty
 Args    : Hash::AutoHash::AVPairsMulti object
 Returns : boolean

=head4 autohash_notempty

 Title   : autohash_notempty
 Usage   : if (autohash_notempty($avp)) { ... }
 Function: Test whether $avp is not empty. Complement of autohash_empty
 Args    : Hash::AutoHash::AVPairsMulti object
 Returns : boolean

=head1 SEE ALSO

L<perltie> and L<Tie::Hash> present background on tied hashes.

L<Hash::AutoHash> provides the object wrapping machinery. The
documentation of that class includes a detailed list of caveats and
cautions. L<Hash::AutoHash::Args>, L<Hash::AutoHash::MultiValued>,
L<Hash::AutoHash::AVPairsSingle>, L<Hash::AutoHash::Record> are other
subclasses of L<Hash::AutoHash>.

L<Hash::AutoHash::AVPairsSingle> is similar but requires each
attribute to have a single value. L<Hash::AutoHash::MultiValued> is
similar, but permits values to be non-simple, ie, references.  Most of
the implementation comes from the tied hash class of
L<Hash::AutoHash::MultiValued>.

L<Hash::AutoHash::Record> uses this class to represent
attribute-value pairs parsed from text files.

=head1 AUTHOR

Nat Goodman, C<< <natg at shore.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-autohash-avpairsmulti at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-AutoHash-AVPairsMulti>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::AutoHash::AVPairsMulti


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-AutoHash-AVPairsMulti>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-AutoHash-AVPairsMulti>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-AutoHash-AVPairsMulti>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-AutoHash-AVPairsMulti/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nat Goodman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hash::AutoHash::AVPairsMulti
