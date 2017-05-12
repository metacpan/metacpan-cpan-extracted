package Hash::AutoHash::AVPairsSingle;
our $VERSION='1.17';
$VERSION=eval $VERSION;		# I think this is the accepted idiom..

#################################################################################
#
# Author:  Nat Goodman
# Created: 09-03-05
# $Id: 
#
# AutoHash with single-valued, string or number elements. no references
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
package Hash::AutoHash::AVPairsSingle::helper;
our $VERSION=$Hash::AutoHash::AVPairsSingle::VERSION;
use strict;
use Carp;
BEGIN {
  our @ISA=qw(Hash::AutoHash::helper);
}
use Hash::AutoHash qw(autohash_tie);

sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie Hash::AutoHash::AVPairsSingle::tie,@args;
  bless $self,$class;
}

#################################################################################
# Tied hash which implements Hash::AutoHash::MultiValued
#################################################################################
package Hash::AutoHash::AVPairsSingle::tie;
our $VERSION=$Hash::AutoHash::AVPairsSingle::VERSION;
use strict;
use Carp;
use Tie::Hash;
our @ISA=qw(Tie::ExtraHash);
use constant STORAGE=>0;

sub TIEHASH {
  my($class,@hash)=@_;
  my $self=bless [{}],$class;
  if (@hash==1) {		# flatten if ARRAY or HASH
    my $hash=shift @hash;
    @hash=('ARRAY' eq ref $hash)? @$hash: ('HASH' eq ref $hash)? %$hash: ();
  }
  while (@hash>1) {		      # store initial values
    my($key,$value)=splice @hash,0,2; # shift 1st two elements
      $self->STORE($key,$value);
  }
  $self;
}
sub STORE {
  my($self,$key,$new)=@_;
  confess "Trying to store reference as value of attribute $key" if ref $new;
  $self->[STORAGE]->{$key}=$new;
}
1;

__END__

=head1 NAME

Hash::AutoHash::AVPairsSingle - Object-oriented access to hash with simple (non-reference) elements

=head1 VERSION

Version 1.17

=head1 SYNOPSIS

  use Hash::AutoHash::AVPairsSingle;

  # create object and set intial values
  my $avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',hobby=>'chess';

  # access or change hash elements via methods
  my $name=$avp->name;                        # 'Joe'
  $avp->name('Joey');                         # change name to 'Joey'
  $avp->pets({dog=>'Spot'});                  # illegal - reference

  # you can also use standard hash notation and functions
  my $name=$avp->{name};                      # 'Joey'
  $avp->{name}='Joe';                         # change name back to 'Joe'
  my($name,$hobby)=@$avp{qw(name hobby)};     # get 2 elements in one statement
  my @keys=keys %$avp;                        # ('name','hobby')
  my @values=values %$avp;                    # ('Joe','chess')

  while(my($key,$value)=each %$avp) {
     print "$key => @$value\n";               # prints each element as usual
  }
  delete $avp->{hobby};                       # no more hobby

  # alias $avp to regular hash for more concise hash notation
  use Hash::AutoHash::AVPairsSingle qw(autohash_alias);
  my %hash;
  autohash_alias($avp,%hash);
  # access or change hash elements without using ->
  $hash{hobby}='go';                          # change hobby to 'go'
  my $hobby=$hash{hobby};                     # 'go'
  my($name,$hobby)=@hash{qw(name hobby)};     # get 2 elements in one statement

=head1 DESCRIPTION

This is a subclass of L<Hash::AutoHash> which wraps a tied hash whose
elements are simple values like numbers and strings, not references.
"AVP" stands for "attribute-value pairs". L<Hash::AutoHash::Record>
uses this class to represent attribute-value pairs parsed from text
files.

Like L<Hash::AutoHash> itself, this class lets you get or set hash
elements using hash notation or by invoking a method with the same
name as the key.  See L<SYNOPSIS> for examples.  

Also like L<Hash::AutoHash>, this class provides a full plate of
functions for performing hash operations on
Hash::AutoHash::AVPairsSingle objects.  These are useful if you want to
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

=head2 new

 Title   : new 
 Usage   : $avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',hobby=>'chess'
           -- OR --
           $avp=new Hash::AutoHash::AVPairsSingle [name=>'Joe',hobby=>'chess']
           -- OR --
           $avp=new Hash::AutoHash::AVPairsSingle {name=>'Joe',hobby=>'chess'}
 Function: Create Hash::AutoHash::AVPairsSingle object and set elements.
 Returns : Hash::AutoHash::AVPairsSingle object
 Args    : Optional list of key=>value pairs which are used to set elements of
           the object. Args can also be passed as ARRAY or HASH

=head2 Functions inherited from Hash::AutoHash

The following functions are inherited from L<Hash::AutoHash> and
operate exactly as there. You must import them into your namespace
before use.

 use Hash::AutoHash::AVPairsSingle
    qw(autohash_alias autohash_tied autohash_get autohash_set
       autohash_clear autohash_delete autohash_each autohash_exists 
       autohash_keys autohash_values 
       autohash_count autohash_empty autohash_notempty)

=head3 autohash_alias

Aliasing a Hash::AutoHash::AVPairsSingle object to a regular hash avoids the need to
dereference the variable when using hash notation.  As a convenience,
the autoahash_alias functions can link in either direction depending
on whether the given object exists.

 Title   : autohash_alias
 Usage   : autohash_alias($avp,%hash)
 Function: Link $avp to %hash such that they will have exactly the same value.
 Args    : Hash::AutoHash::AVPairsSingle object and hash 
 Returns : Hash::AutoHash::AVPairsSingle object

=head3 autohash_tied

You can access the object implementing the tied hash using Perl's
built-in tied function or the autohash_tied function inherited from
L<Hash::AutoHash>.  Advantages of autohash_tied are (1) it operates
directly on the Hash::AutoHash::AVPairsSingle object without requiring a
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
           Hash::AutoHash::AVPairsSingle object.
           In forms 2 and 4, the first argument is a hash to which a 
           Hash::AutoHash::AVPairsSingle object has been aliased
 Returns : In forms 1 and 2, object implementing tied hash or undef.
           In forms 3 and 4, result of invoking method (which can be anything or
           nothing), or undef.
 Args    : Form 1. Hash::AutoHash::AVPairsSingle object
           Form 2. hash to which Hash::AutoHash::AVPairsSingle object is aliased
           Form 3. Hash::AutoHash::AVPairsSingle object, method name, optional 
             list of parameters for method
           Form 4. hash to which Hash::AutoHash::AVPairsSingle object is aliased, 
             method name, optional list of parameters for method

=head3 autohash_get

 Title   : autohash_get
 Usage   : ($name,$hobby)=autohash_get($avp,qw(name hobby))
 Function: Get values for multiple keys.
 Args    : Hash::AutoHash::AVPairsSingle object and list of keys
 Returns : list of argument values

=head3 autohash_set

 Title   : autohash_set
 Usage   : autohash_set($avp,name=>'Joe Plumber',first_name=>'Joe')
           -- OR --
           autohash_set($avp,['name','first_name'],['Joe Plumber','Joe'])
 Function: Set multiple arguments in existing object.
 Args    : Form 1. Hash::AutoHash::AVPairsSingle object and list of key=>value pairs
           Form 2. Hash::AutoHash::MultiValue object, ARRAY of keys, ARRAY of 
           values
 Returns : Hash::AutoHash::AVPairsSingle object

=head3 Functions for hash-like operations

The remaining functions provide hash-like operations on
Hash::AutoHash::AVPairsSingle objects. These are useful if you want to
avoid hash notation all together.

=head4 autohash_clear

 Title   : autohash_clear
 Usage   : autohash_clear($avp)
 Function: Delete entire contents of $avp
 Args    : Hash::AutoHash::AVPairsSingle object
 Returns : nothing

=head4 autohash_delete

 Title   : autohash_delete
 Usage   : autohash_delete($avp,@keys)
 Function: Delete keys and their values from $avp.
 Args    : Hash::AutoHash::AVPairsSingle object, list of keys
 Returns : nothing

=head4 autohash_exists

 Title   : autohash_exists
 Usage   : if (autohash_exists($avp,$key)) { ... }
 Function: Test whether key is present in $avp.
 Args    : Hash::AutoHash::AVPairsSingle object, key
 Returns : boolean

=head4 autohash_each

 Title   : autohash_each
 Usage   : while (my($key,$value)=autohash_each($avp)) { ... }
           -- OR --
           while (my $key=autohash_each($avp)) { ... }
 Function: Iterate over all key=>value pairs or all keys present in $avp
 Args    : Hash::AutoHash::AVPairsSingle object
 Returns : list context: next key=>value pair in $avp or empty list at end
           scalar context: next key in $avp or undef at end

=head4 autohash_keys

 Title   : autohash_keys
 Usage   : @keys=autohash_keys($avp)
 Function: Get all keys that are present in $avp
 Args    : Hash::AutoHash::AVPairsSingle object
 Returns : list of keys

=head4 autohash_values

 Title   : autohash_values
 Usage   : @values=autohash_values($avp)
 Function: Get the values of all keys that are present in $avp
 Args    : Hash::AutoHash::AVPairsSingle object
 Returns : list of values

=head4 autohash_count

 Title   : autohash_count
 Usage   : $count=autohash_count($avp)
 Function: Get the number keys that are present in $avp
 Args    : Hash::AutoHash::AVPairsSingle object
 Returns : number

=head4 autohash_empty

 Title   : autohash_empty
 Usage   : if (autohash_empty($avp)) { ... }
 Function: Test whether $avp is empty
 Args    : Hash::AutoHash::AVPairsSingle object
 Returns : boolean

=head4 autohash_notempty

 Title   : autohash_notempty
 Usage   : if (autohash_notempty($avp)) { ... }
 Function: Test whether $avp is not empty. Complement of autohash_empty
 Args    : Hash::AutoHash::AVPairsSingle object
 Returns : boolean

=head1 SEE ALSO

L<perltie> and L<Tie::Hash> present background on tied hashes.

L<Hash::AutoHash> provides the object wrapping machinery. The
documentation of that class includes a detailed list of caveats and
cautions. L<Hash::AutoHash::Args>, L<Hash::AutoHash::MultiValued>,
L<Hash::AutoHash::AVPairsMulti>, L<Hash::AutoHash::Record> are other
subclasses of L<Hash::AutoHash>.

L<Hash::AutoHash::AVPairsMulti> is similar but allows each attribute to
have multiple values. 

L<Hash::AutoHash::Record> uses this class to to represent
attribute-value pairs parsed from text files.

=head1 AUTHOR

Nat Goodman, C<< <natg at shore.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-autohash-avpairssingle at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-AutoHash-AVPairsSingle>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::AutoHash::AVPairsSingle


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-AutoHash-AVPairsSingle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-AutoHash-AVPairsSingle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-AutoHash-AVPairsSingle>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-AutoHash-AVPairsSingle/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nat Goodman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Hash::AutoHash::AVPairsSingle
