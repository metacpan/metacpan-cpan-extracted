package Hash::AutoHash::Args;
our $VERSION='1.18';
$VERSION=eval $VERSION;		# I think this is the accepted idiom..

#################################################################################
#
# Author:  Nat Goodman
# Created: 09-03-05
# $Id: 
#
# Simplifies processing of keyward argument lists.
# Replaces Class::AutoClass::Args using Class::AutoClass:Hash and tied hash to 
# provide cleaner, more powerful interface.
# NOT completely compatible with Class::AutoClass::Args.
# Use Hash::AutoHash::Args::V0 if compatibility with Class::AutoClass::Args needed
#
#################################################################################
use strict;
use Carp;
use Hash::AutoHash;
use base qw(Hash::AutoHash);

our @NORMAL_EXPORT_OK=
  qw(get_args getall_args set_args fix_args fix_keyword fix_keywords is_keyword is_positional
     autoargs_get autoargs_set);
our @RENAME_EXPORT_OK=sub {s/^autohash/autoargs/; $_};
# our @EXPORT_OK=Hash::AutoHash::Args::helper->EXPORT_OK;
# our @SUBCLASS_EXPORT_OK=Hash::AutoHash::Args::helper->SUBCLASS_EXPORT_OK;
my $helper_class=__PACKAGE__.'::helper';
our @EXPORT_OK=$helper_class->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=$helper_class->SUBCLASS_EXPORT_OK;

# sub new {
#   my $class_or_self=@_>0 && shift;
#   # send to parent if called as object method. will access hash slot via AUTOLOAD
#   return $class_or_self->SUPER::new(@_) if ref $class_or_self;
#   # do regular 'new' via helper class if called as class method. 
#   my $helper_class=$class_or_self.'::helper';
#   $helper_class->_new($class_or_self,@_);
# }

#################################################################################
# helper package exists to avoid polluting Hash::AutoHash::Args namespace with
#   subs that would mask accessor/mutator AUTOLOADs
# functions herein (except _new) are exportable by Hash::AutoHash::Args
#################################################################################
package Hash::AutoHash::Args::helper;
our $VERSION=$Hash::AutoHash::Args::VERSION;
use strict;
use Carp;
use Scalar::Util qw(reftype);
BEGIN {
  our @ISA=qw(Hash::AutoHash::helper);
}
use Hash::AutoHash qw(autohash_tie);

sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie Hash::AutoHash::Args::tie,@args;
  bless $self,$class;
}

#################################################################################
# functions from Class::AutoClass::Args
# get_args, set_args are redundant w/ autoargs_get, autoargs_set 
# getall_args is trivial wrapper for %$args.... 
#################################################################################
sub get_args {
  my($self,@args)=@_;
  @args=@{$args[0]} if @args==1 && 'ARRAY' eq ref $args[0];
  @args=fix_keyword(@args);
  my @results=map {$self->{$_}} @args;
# NG 09-03-12: line below is ancient bug. see POD. scary it wasn't caught sooner
#   wantarray? @results: $results[0];
  wantarray? @results: \@results;
}
sub autoargs_get { get_args(@_); } # do it this way so defined at compile-time
# *autoargs_get=\&get_args;        # NOT this way!

sub getall_args {
  my $self = shift;
  wantarray? %$self: {%$self};
}
sub set_args {
  my $self=shift;
 if (@_==2 && 'ARRAY' eq ref $_[0] && 'ARRAY' eq ref $_[1]) { # separate arrays form
   my($keys,$values)=@_;
   my @keys=fix_keywords(@$keys);
   my @values=@$values;
   for (my $i=0; $i<@keys; $i++) {
     my($key,$value)=($keys[$i],$values[$i]);
     $self->{$key}=$value;
   }} else {
     my $args=fix_args(@_);
     while(my($key,$value)=each %$args) {
       $self->$key($value);
     }}
  $self;
}
sub autoargs_set { set_args(@_); } # do it this way so defined at compile-time
# *autoargs_set=\&set_args;        # NOT this way!

sub fix_args {
  no warnings;
  my(@args)=@_;
  @args=@{$args[0]} if @args==1 && 'ARRAY' eq ref $args[0];
  @args=%{$args[0]} if @args==1 && 'HASH' eq reftype $args[0];
  confess("Malformed keyword argument list (odd number of elements): @args") if @args%2;
  my $args={};
  while(@args) {
    my($keyword,$value)=(fix_keyword(shift @args),shift @args);
    $args->{$keyword}=$value,next unless exists $args->{$keyword};
    my $old=$args->{$keyword};
    # NG 09-12-31: breaks if $old is object. 
    # $args->{$keyword}=[$old,$value],next unless ref $old; # grow scalar slot into ARRAY
    $args->{$keyword}=[$old,$value],next unless 'ARRAY' eq ref $old; # grow scalar slot into ARRAY
    push(@$old,$value);					  # else add new value to ARRAY slot
  }
  $args;
}
sub fix_keyword {
  my @keywords=@_;		# copies input, so update-in-place doesn't munge it
  for my $keyword (@keywords) {
    next unless defined $keyword;
    $keyword=~s/^-*(.*)$/\L$1/ unless ref $keyword; # updates in place
  }
  wantarray? @keywords: $keywords[0];
}
sub fix_keywords {fix_keyword(@_);}
sub is_keyword {!(@_%2) && $_[0]=~/^-/;}
sub is_positional {@_%2 || $_[0]!~/^-/;}

#################################################################################
# Tied hash which provides the core capabilities of Hash::AutoHash::Args
#################################################################################
package Hash::AutoHash::Args::tie;
our $VERSION=$Hash::AutoHash::Args::VERSION;
use strict;
use Carp;
use Tie::Hash;
our @ISA=qw(Tie::StdHash);
*fix_args=\&Hash::AutoHash::Args::helper::fix_args;
*fix_keyword=\&Hash::AutoHash::Args::helper::fix_keyword;

sub TIEHASH {
  my($class,@args)=@_;
  $class=(ref $class)||$class;
  bless Hash::AutoHash::Args::helper::fix_args(@args), $class;
}
# following code adapted from Tie::StdHash
# sub TIEHASH  { bless {}, $_[0] }
# sub STORE    { $_[0]->{fix_keyword($_[1])} = $_[2] }
sub STORE    { 
  my $self=shift;
  my $keyword=fix_keyword(shift);
  my $value=@_==1? $_[0]: [@_];
  $self->{$keyword}=$value;
}
sub FETCH    { 
  my $self=shift;
  my $keyword=fix_keyword(shift);
  # non-existent arg should return nothing. not undef! this works when accessing the 
  #  object directly or using autoloaded methods from the main class. when accessing  
  #  via the tied hash interface, Perl converts the result to undef anyway :(
  return unless exists $self->{$keyword}; 
  return $self->{$keyword};
}
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{fix_keyword($_[1])} }
sub DELETE   { delete $_[0]->{fix_keyword($_[1])} }
sub CLEAR    { %{$_[0]} = () }
sub SCALAR   { scalar %{$_[0]} }

1;

__END__

=head1 NAME

Hash::AutoHash::Args - Object-oriented processing of keyword-based argument lists

=head1 VERSION

Version 1.18

=head1 SYNOPSIS

  use Hash::AutoHash::Args;
  my $args=new Hash::AutoHash::Args(name=>'Joe',
                                    HOBBIES=>'hiking',hobbies=>'cooking');

  # access argument values as HASH elements
  my $name=$args->{name};
  my $hobbies=$args->{hobbies};

  # access argument values via methods
  my $name=$args->name;
  my $hobbies=$args->hobbies;

  # set local variables from argument values -- two equivalent ways
  use Hash::AutoHash::Args qw(autoargs_get);
  my($name,$hobbies)=@$args{qw(name hobbies)};
  my($name,$hobbies)=autoargs_get($args,qw(name hobbies));

  # alias $args to regular hash for more concise hash notation
  use Hash::AutoHash::Args qw(autoargs_alias);
  autoargs_alias($args,%args);
  my($name,$hobbies)=@args{qw(name hobbies)}; # get argument values
  $args{name}='Joseph';                       # set argument value

=head1 DESCRIPTION

This class simplifies the handling of keyword argument lists. It
replaces L<Class::AutoClass::Args>.  See L<DIFFERENCES FROM
Class::AutoClass::Args> for a discussion of what's new. See
L<Hash::AutoHash::Args::V0> for a subclass which is more compatible
with the original.

The 'new' method accepts a list, ARRAY, or HASH of keyword=>value
pairs, another Hash::AutoHash::Args object, or any object that can
be coerced into a HASH . It normalizes the keywords to ignore case and
leading dashes ('-').  The following keywords are all equivalent:

  name, -name, -NAME, --NAME, Name, -Name

Arguments can be accessed using HASH or method notation; the following
are equivalent (assuming the keyword 'name' exists in $args).

  my $name=$args->{name};
  my $name=$args->name;

Arguments values can also be changed using either notation:

  $args->{name}='Jonathan';
  $args->name('Jonathan');

Keywords are normalized automatically; the following are all equivalent.

  my $name=$args->{name};		# lower case HASH key
  my $name=$args->{Name};		# capitalized HASH key
  my $name=$args->{NAME};		# upper case HASH key
  my $name=$args->{NaMe};		# mixed case HASH key
  my $name=$args->{-name};		# leading - in HASH key

The following are also all equivalent, and are equivalent to the ones above assuming the keyword 'name' exists in $args.

  my $name=$args->name;			# lower case method
  my $name=$args->Name;			# capitalized method
  my $name=$args->NAME;			# upper case method
  my $name=$args->NaMe;			# mixed case method

One caution is that when using method notation, keywords must be
syntactically legal method names and cannot include leading dashes. The
following is NOT legal.

  my $name=$args->-name;		# leading dash in method - ILLEGAL

Repeated keyword arguments are converted into an ARRAY of the values.

  new Hash::AutoHash::Args(hobbies=>'hiking', hobbies=>'cooking')

is equivalent to

  new Hash::AutoHash::Args(hobbies=>['hiking', 'cooking'])

Caution: when setting values using HASH or method notation,
the grouping of repeated arguments does NOT occur. Thus,

  @$args{qw(hobbies hobbies)}=qw(running rowing);

leaves 'hobbies' set to the last value presented, namely 'rowing', as does

  $args->hobbies('running');
  $args->hobbies('rowing');

New keywords can be added using either notation.  For example,

  $args->{first_name}='Joe';
  $args->last_name('Plumber');

If a keyword does not exist, the method notation returns nothing,
while the HASH notation returns undef. This difference matters in
array context (including when passing the result as a parameter).

  my @list=$args->non_existent;   # @list will contain 0 elements
  my @list=$args->{non_existent}; # @list will contain 1 element

We find the method behavior (returning nothing) to be more natural and
is the behavior in Class::AutoClass::Args. Unfortunately, Perl does
not support this behavior with HASH notation; if the tied hash code
returns nothing, Perl converts this into undef before passing the
result to the caller.  Too bad.

You can alias the object to a regular hash for more concise hash
notation.

  use Hash::AutoHash::Args qw(autoargs_alias);
  autoargs_alias($args,%args);
  my($name,$hobbies)=@args{qw(name hobbies)};
  $args{name}='Joseph';

By aliasing $args to %args, you avoid the need to dereference the
variable when using hash notation.  Admittedly, this is a minor
convenience, but then again, this entire class is about convenience.

=head2 new

 Title   : new
 Usage   : $args=new Hash::AutoHash::Args
              (name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking')
           -- OR --
           $args=new Hash::AutoHash::Args($another_args_object)
           -- OR --
           $args=new Hash::AutoHash::Args
              ([name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking'])
           -- OR --
           $args=new Hash::AutoHash::Args
              ({name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking'})
 Function: Create a normalized argument list
 Returns : Hash::AutoHash::Args object that represents the given arguments
 Args    : Argument list in keyword=>value form
           The usual case is a list (as in form 1 above).  It can also be 
           another Hash::AutoHash::Args object (as in form 2 above), any object  
           that can be coerced into a HASH (form not illustrated), an ARRAY (form
           3 above), or HASH (form 4)
 Caution : In form 4, the order in which the two 'hobbies' arguments are 
           processed is arbitrary. This means that the value of $args->hobbies
           could have 'hiking' and 'cooking' in either order.

=head2 Getting and setting argument values

One way to get and set argument values is to treat the object
as a HASH and access the arguments as hash elements, eg,

  my $args=new Hash::AutoHash::Args
                (name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking');
  my $name=$args->{name};
  my($name,$hobbies)=@$args{qw(name hobbies)};
  $args->{name}='Jonathan';
  @$args{qw(name hobbies)}=('Joseph',['running','rowing']);

The HASH keys are normalized automatically exactly as in 'new'.

A second approach is to invoke a method with the name of the
keyword.  Eg,

  $args->name;
  $args->name('Joseph');                # sets name to 'Joseph'
  $args->hobbies('running','rowing');   # sets hobbies to ['running','rowing']

The method name is normalized exactly as in 'new'.

New keywords can be added using either notation.  For example,

  $args->{first_name}='Joe';
  $args->last_name('Plumber');

If a keyword does not exist, the method notation returns nothing,
while the HASH notation returns undef. This difference matters in
array context (including when passing the result as a parameter).

  my @list=$args->non_existent;   # @list will contain 0 elements
  my @list=$args->{non_existent}; # @list will contain 1 element

We find the method behavior (returning nothing) to be more natural and
is the behavior in Class::AutoClass::Args. Unfortunately, Perl does not support
this behavior with HASH notation.

You can alias the object to a regular hash to avoid the need to dereference the
variable when using hash notation. 

  use Hash::AutoHash::Args qw(autoargs_alias);
  autoargs_alias($args,%args);
  my($name,$hobbies)=@args{qw(name hobbies)};
  $args{name}='Joseph';

=head3 Caveats

=over 4

=item * Illegal method names

When using method notation, keywords must be syntactically legal method
names and cannot include leading dashes. The following is NOT legal.

  my $name=$args->-name;		# leading dash in method name - ILLEGAL

=item * Setting individual keywords does not preserve multiple values

When arguments are set via 'new', 'set_args', 'autoargs_set', or
method notation repeated keyword arguments are converted into an ARRAY
of the values.  When setting individual keywords using either HASH or
notation, this does NOT occur. Thus,

  $args=new Hash::AutoHash::Args(hobbies=>'hiking',hobbies=>'cooking');

sets 'hobbies' to an ARRAY of the two hobbies, but 

  @$args{qw(hobbies hobbies)}=qw(running rowing);

leaves 'hobbies' set to the last value presented, namely 'rowing'. 

When arguments are set via any mechanism, the new value or values
replace the existing value(s); the new values are NOT added to the
existing value(s).  Thus

  $args->hobbies('running');
  $args->hobbies('rowing');

leaves 'hobbies' set to the last value presented, namely 'rowing'.

This is a semantic oddity from Class::AutoClass::Args that we have kept for
compatibility reasons.  It seems not to cause problems in practice,
because this class is mostly used in a "write-once" pattern.

=item * Non-existent keywords

If a keyword does not exist, the method notation returns nothing,
while the HASH notation returns undef. This difference matters in
array context (including when passing the result as a parameter).

  my @list=$args->non_existent;   # @list will contain 0 elements
  my @list=$args->{non_existent}; # @list will contain 1 element

We find the method behavior (returning nothing) to be more natural;  
unfortunately, Perl does not support this behavior with HASH notation.

=back

=head2 Wholesale manipulation of arguments

The class also provides several functions for wholesale manipulation of
arguments. To use these functions, you must import them into the
caller's namespace using the common Perl idiom of listing the desired
functions in a 'use' statement.  For example,

 use Hash::AutoHash::Args
    qw(get_args getall_args set_args autoargs_get autoargs_set);
 
=head3 get_args

 Title   : get_args
 Usage   : ($name,$hobbies)=get_args($args,qw(-name hobbies))
 Function: Get values for multiple keywords
 Args    : Hash::AutoHash::Args object and array or ARRAY of keywords
 Returns : array or ARRAY of argument values

=head3 autoargs_get

 Title   : autoargs_get
 Usage   : ($name,$hobbies)=autoargs_get($args,qw(name -hobbies))
 Function: Get values for multiple keywords. Synonym for 'get_args' provided 
           for stylistic consistency with Hash::AutoHash
 Args    : Hash::AutoHash::Args object and array or ARRAY of keywords
 Returns : array or ARRAY of argument values

=head3 getall_args

 Title   : getall_args
 Usage   : %args=getall_args($args);
 Function: Get all keyword, value pairs
 Args    : Hash::AutoHash::Args object
 Returns : hash or HASH of key=>value pairs.

=head3 set_args

 Title   : set_args
 Usage   : set_args($args,
                    name=>'Joe the Plumber',-first_name=>'Joe',-last_name=>'Plumber')
           -- OR -- 
           set_args($args,['name','-first_name','-last_name'],
                          ['Joe the Plumber','Joe','Plumber'])
 Function: Set multiple arguments in existing object
 Args    : Form 1. Hash::AutoHash::Args object and parameter list in same format  
           as for 'new'
           Form 2. Hash::AutoHash::Args object and separate ARRAYs of keywords 
           and values
 Returns : nothing

=head3 autoargs_set

 Title   : autoargs_set
 Usage   : autoargs_set($args,
                        name=>'Joe the Plumber',-first_name=>'Joe',-last_name=>'Plumber')
           -- OR -- 
           autoargs_set($args,['name','-first_name','-last_name'],
                              ['Joe the Plumber','Joe','Plumber'])
 Function: Set multiple arguments in existing object. 
           Synonym for 'set_args' provided for stylistic consistency with 
           Hash::AutoHash
 Args    : Form 1. Hash::AutoHash::Args object and parameter list in same format  
           as for 'new'
           Form 2. Hash::AutoHash::Args object and separate ARRAYs of keywords 
           and values
 Returns : Hash::AutoHash::Args object

=head2 Aliasing object to hash: autoargs_alias

You can alias a Hash::AutoHash::Args object to a regular hash to
avoid the need to dereference the variable when using hash
notation. Before using this function, you must import it into the
caller's namespace using the common Perl idiom of listing the function
in a 'use' statement.

 use Hash::AutoHash::Args qw(autoargs_alias);
  
 Title   : autoargs_alias
 Usage   : autoargs_alias($args,%args)
 Function: Link $args to %args such that they will have exactly the same value.
 Args    : Hash::AutoHash::Args object and hash 
 Returns : Hash::AutoHash::Args object

=head2 Functions to normalize keywords

These functions normalize keywords as explained in L<DESCRIPTION>.  To
use these functions, they must be imported into the caller's namespace
using the common Perl idiom of listing the desired functions in a
'use' statement.

 use Hash::AutoHash::Args qw(fix_args fix_keyword fix_keywords);

=head3 fix_args
 
 Title   : fix_args
 Usage   : $hash=fix_args(-name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking')
 Function: Normalize each keyword to lowercase with no leading dashes and gather
           the values of repeated keywords into ARRAYs. 
 Args    : Argument list in keyword=>value form exactly as for 'new', 'set_args', and
           'autoargs_set'.  
 Returns : HASH of normalized keyword=>value pairs

=head3 fix_keyword
 
 Title   : fix_keyword
 Usage   : $keyword=fix_keyword('-NaMe')
           -- OR --
           @keywords=fix_keyword('-NaMe','---hobbies');
 Function: Normalize each keyword to lowercase with no leading dashes.
 Args    : array of one or more strings
 Returns : array of normalized strings

=head3 fix_keywords
 
 Title   : fix_keywords
 Usage   : $keyword=fix_keywords('-NaMe')
           -- OR --
           @keywords=fix_keywords('-NaMe','---hobbies');
 Function: Synonym for fix_keyword
 Args    : array of one or more strings
 Returns : array of normalized strings

=head2 Functions to check format of argument list

These functions can be used in a class (typically its 'new' method)
that wishes to support both keyword and positional argument lists.  We
strongly discourage this practice for reasons discussed later.

To use these functions, they must be imported into the caller's namespace.

 use Hash::AutoHash::Args qw(is_keyword is_positional);

=head3 is_keyword

 Title   : is_keyword
 Usage   : if (is_keyword(@args)) {
             $args=new Hash::AutoHash::Args (@args);
	   }
 Function: Checks whether an argument list looks like it is in keyword form.
           The function returns true if 
           (1) the argument list has an even number of elements, and
           (2) the first argument starts with a dash ('-').
           Obviously, this is not fully general.
 Returns : boolean
 Args    : argument list as given

=head3 is_positional

 Title   : is_positional
 Usage  : if (is_positional(@args)) {
             ($arg1,$arg2,$arg3)=@args; 
	   }
 Function: Checks whether an argument list looks like it is in positional form.
           The function returns true if 
           (1) the argument list has an odd number of elements, or
           (2) the first argument does not start with a dash ('-').
           Obviously, this is not fully general.
 Returns : boolean
 Args    : argument list as given

=head3 Why the Combination of Positional and Keyword Forms is Ambiguous

The keyword => value notation is just a Perl shorthand for stating two
list members with the first one quoted.  Thus,

  @list=(first_name=>'John', last_name=>'Doe')

is completely equivalent to 

  @list=('first_name', 'John', 'last_name', 'Doe')

The ambiguity of allowing both positional and keyword forms should now
be apparent. In this example,

  new Hash::AutoHash::Args ('first_name', 'John')

there is s no way to tell whether the program is specifying a keyword
argument list with the parameter 'first_name' set to the value "John'
or a positional argument list with the values ''first_name' and 'John'
being passed to the first two parameters.

If a program wishes to permit both forms, we suggest the convention
used in BioPerl that keywords be required to start with '-' (and that
values do not start with '-').  Obviously, this is not fully general.

The methods 'is_keyword' and 'is_positional' check this convention.

=head2 Functions for hash-like operations

These functions provide hash-like operations on Hash::AutoHash::Args objects.   

To use these functions, you must imported then into the caller's namespace, eg, as follows.

 use Hash::AutoHash::Args qw(autoargs_clear autoargs_delete autoargs_each autoargs_exists 
                               autoargs_keys autoargs_values 
                               autoargs_count autoargs_empty autoargs_notempty);

=head3 autoargs_clear

 Title   : autoargs_clear
 Usage   : autoargs_clear($args)
 Function: Delete entire contents of $args
 Args    : Hash::AutoHash::Args object
 Returns : nothing

=head3 autoargs_delete

 Title   : autoargs_delete
 Usage   : autoargs_delete($args,@keywords)
 Function: Delete keywords and their values from $args. The keywords are
           automatically normalized
 Args    : Hash::AutoHash::Args object, list of keywords
 Returns : nothing

=head3 autoargs_exists

 Title   : autoargs_exists
 Usage   : if (autoargs_exists($args,$keyword)) { ... }
 Function: Test whether keyword is present in $args.  The keyword is
           automatically normalized
 Args    : Hash::AutoHash::Args object, keyword
 Returns : boolean

=head3 autoargs_each

 Title   : autoargs_each
 Usage   : while (my($keyword,$value)=autoargs_each($args)) { ... }
           -- OR --
           while (my $keyword=autoargs_each($args)) { ... }
 Function: Iterate over all keyword=>value pairs or all keywords present in $args
 Args    : Hash::AutoHash::Args object
 Returns : list context: next keyword=>value pair in $args or empty list at end
           scalar context: next keyword in $args or undef at end

=head3 autoargs_keys

 Title   : autoargs_keys
 Usage   : @keys=autoargs_keys($args)
 Function: Get all keywords that are present in $args
 Args    : Hash::AutoHash::Args object
 Returns : list of keywords

=head3 autoargs_values

 Title   : autoargs_values
 Usage   : @values=autoargs_values($args)
 Function: Get the values of all keywords that are present in $args
 Args    : Hash::AutoHash::Args object
 Returns : list of values

=head3 autoargs_count

 Title   : autoargs_count
 Usage   : $count=autoargs_count($args)
 Function: Get the number keywords that are present in $args
 Args    : Hash::AutoHash::Args object
 Returns : number

=head3 autoargs_empty

 Title   : autoargs_empty
 Usage   : if (autoargs_empty($args) { ... }
 Function: Test whether $args is empty
 Args    : Hash::AutoHash::Args object
 Returns : boolean

=head3 autoargs_notempty

 Title   : autoargs_notempty
 Usage   : if (autoargs_notempty($args) { ... }
 Function: Test whether $args is not empty. Complement of autoargs_empty
 Args    : Hash::AutoHash::Args object
 Returns : boolean

=head1 DIFFERENCES FROM Class::AutoClass::Args

This class differs from its precursor, L<Class::AutoClass::Args>, in the
following major ways:

=over 2

=item * Masked keywords

In Class::AutoClass::Args, numerous methods and functions were defined in the
Class::AutoClass::Args namespace.  These methods and functions
"masked" keywords with the same names and made it impossible to use
method notation to access arguments with these names.  Examples
include 'new', 'get_args', 'can', 'isa', 'import', and 'AUTOLOAD'
among others.

Some of the offending methods and functions were defined explicitly by
Class::AutoClass::Args (eg, 'new', 'get_args'), while others
were inherited from UNIVERSAL (the base class of everything, e.g,
'can', 'isa') or used implicitly by Perl to implement common features
(eg, 'import', 'AUTOLOAD').

Hash::AutoHash::Args has a cleaner namespace: B<no keywords are masked>.

CAUTION: As of version 1.13, it is not possible to use method
notation for keys with the same names as methods inherited from
UNIVERSAL (the base class of everything). These are 'can', 'isa',
'DOES', and 'VERSION'.  The reason is that as of Perl 5.9.3, calling
UNIVERSAL methods as functions is deprecated and developers are
encouraged to use method form instead. Previous versions of AutoHash
are incompatible with CPAN modules that adopt this style.

=item * Object vs. class methods

Some of the methods that remain in the Hash::AutoHash::Args namespace
are logically object-methods (ie, logically apply to individual
Hash::AutoHash::Args objects, eg, 'AUTOLOAD'), while others are
logically class-methods (ie, apply to the entire class, eg, 'import').

For methods that are logically class methods, the code checks whether
the method was invoked on a class or an object and "does the right
thing".  

The 'new' method warrants special mention.  In normal use, 'new' is
almost always invoked as a class method, eg, 

  new Hash::AutoHash::Args(name=>'Joe')

This invokes the 'new' method on Hash::AutoHash::Args which constructs
a new object as expected.  If, however, 'new' is invoked on an object,
eg,

  $args->new

the code accesses the keyword named 'new'.


=item * Methods vs. functions

Functions are subs that do not operate on objects or classes.
Class::AutoClass::Args provided the following functions in its
namespace:

_fix_args, fix_keyword, fix_keywords, is_keyword, is_positional

With Hash::AutoHash::Args, the caller must import these functions into
its own namespace using the common Perl idiom of listing the desired
functions when 'using' Hash::AutoHash::Args.

=item * New hash-like functions

This class provides additional functions that perform hash-like
operations, for example testing whether a keyword exists, getting the
values of all keywords, or clearing all arguments.  You can import any
of these functions into your code.

=item * Bug fix: get_args in scalar context

In scalar context, get_args is supposed to return an ARRAY of argument
values. Instead, in Class::AutoClass::Args, it returned the value of the first
argument.

  my $values=$args->get_args(qw(name hobbies)); # old bug: gets value of 'name'

get_args now returns an ARRAY of the requested argument values.

  my $values=get_args($args,qw(name hobbies));  # now: gets ARRAY of both values

=item * Tied HASH

In Class::AutoClass::Args, the HASH underlying the object was an
ordinary Perl HASH.  In this class, it's a tied HASH (see L<perltie>,
L<Tie::Hash>).  The key difference is that keywords are normalized
even when HASH notation is used.

Thus, in Class::AutoClass::Args, the following two statements had different effects,
whereas in this class they are equivalent.

  $args->{name}='Joe';		# old & new: sets 'name' keyword
  $args->{NAME}='Joe';		# old: sets 'NAME' HASH element
                                # new: sets 'name' keyword

=item * Implementation using Hash::AutoHash

Hash::AutoHash::Args is implemented as a subclass of L<Hash::AutoHash>.

=back

=head1 SEE ALSO

L<Hash::AutoHash> is the base class of this one.
L<Class::AutoClass::Args> is replaced by this
class. L<Hash::AutoHash::Args::V0> is a subclass which is more
compatible with Class::AutoClass::Args.

L<Hash::AutoHash::MultiValued>, L<Hash::AutoHash::AVPairsSingle>,
L<Hash::AutoHash::AVPairsMulti>, L<Hash::AutoHash::Record> are other
subclasses of L<Hash::AutoHash>.

L<perltie> and L<Tie::Hash> present background on tied hashes.

=head1 AUTHOR

Nat Goodman, C<< <natg at shore.net> >>

=head1 BUGS AND CAVEATS

Please report any bugs or feature requests to C<bug-hash-autohash at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-AutoHash>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head2 Known Bugs and Caveats

CPAN reports that "Make test fails under Perl 5.6.2, FreeBSD 5.2.1."
for the predecessor to this class, L<Class::AutoClass::Args>.  We are
not aware of any bugs in this class.

See caveats about accessing arguments via method notation.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::AutoHash::Args

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-AutoHash-Args>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-AutoHash-Args>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-AutoHash-Args>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-AutoHash-Args/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2009 Institute for Systems Biology (ISB). All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
