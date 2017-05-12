package Hash::AutoHash;
our $VERSION='1.17';
$VERSION=eval $VERSION;		# I think this is the accepted idiom..

#################################################################################
#
# Author:  Nat Goodman
# Created: 09-02-24
# $Id: 
#
# Wrapper that provides accessor and mutator methods for hashes (real or tied)
#   Hash can be externally supplied or this object itself
#   Tying of hash can be done by application or by this class
#   Can also wrap object tied to hash 
#   (actually, any object with suitable FETCH and STORE methods)
#
#################################################################################

use strict;
use Carp;
use vars qw($AUTOLOAD);
our @CONSTRUCTORS_EXPORT_OK=
  qw(autohash_new autohash_hash autohash_tie autohash_wrap autohash_wrapobj autohash_wraptie);
our @SUBCLASS_EXPORT_OK=
  qw(autohash_clear autohash_delete autohash_each autohash_exists autohash_keys autohash_values 
     autohash_get autohash_set autohash_count autohash_empty autohash_notempty 
     autohash_alias autohash_tied
     autohash_destroy autohash_untie);
our @EXPORT_OK=(@CONSTRUCTORS_EXPORT_OK,@SUBCLASS_EXPORT_OK);

# following are used by subclasses
our @RENAME_EXPORT_OK=();
our %RENAME_EXPORT_OK=();

# our @EXPORT_OK=qw(autohash_new autohash_tie 
# 		  autohash_wraphash autohash_wraptie autohash_wrapobject
# 		  autohash2hash autohash2object
# 		  autohash_clear autohash_delete autohash_exists autohash_keys autohash_values 
# 		  autohash_count autohash_empty autohash_notempty
# 		  autohash_destroy autohash_untie
# 		  autohash_get autohash_set);

sub import {
  my $class_or_self=shift;
  if (ref $class_or_self) { 
    # called as object method. access hash slot via AUTOLOAD
    $AUTOLOAD='import';
    return $class_or_self->AUTOLOAD(@_);
  } 
  # called as class method. do regular 'import'
  my $caller=caller;
  my $helper_class=$class_or_self.'::helper';
  $helper_class->_import($class_or_self,$caller,@_);
}
sub new {
  my $class_or_self=shift;
  if (ref $class_or_self) { 
    # called as object method. access hash slot via AUTOLOAD
    $AUTOLOAD='new';
    return $class_or_self->AUTOLOAD(@_);
  }
  # called as class method. do regular 'new' via helper class
  my $helper_class=$class_or_self.'::helper';
  $helper_class->_new($class_or_self,@_);
}
# NG 12-09-02: no longer possible to use method notation for keys with same names as methods
#              inherited from UNIVERSAL. 'Cuz as of Perl 5.9.3, calling UNIVERSAL methods as
#              functions is deprecated and developers encouraged to use method form instead.
# sub can {
#   my $class_or_self=shift;
#   if (ref $class_or_self) { 
#     # called as object method. access hash slot via AUTOLOAD
#     $AUTOLOAD='can';
#     return $class_or_self->AUTOLOAD(@_);
#   }
#   # called as class method. do regular 'can' via base class
#   return $class_or_self->SUPER::can(@_);
# }
# sub isa {
#   my $class_or_self=shift;
#   if (ref $class_or_self) { 
#     # called as object method. access hash slot via AUTOLOAD
#     $AUTOLOAD='isa';
#     return $class_or_self->AUTOLOAD(@_);
#   }
#   # called as function or class method. do regular 'isa' via base class
#   return $class_or_self->SUPER::isa(@_);
# }
# sub DOES {			# in perl 5.10, UNIVERSAL provides this
#   my $class_or_self=shift;
#   if (ref $class_or_self) { 
#     # called as object method. access hash slot via AUTOLOAD
#     $AUTOLOAD='DOES';
#     return $class_or_self->AUTOLOAD(@_);
#   }
#   # called as function or class method. do regular 'DOES' via base class
#   # illegal and will die in perls < 5.10 
#   return $class_or_self->SUPER::DOES(@_);
# }
# sub VERSION {
#   my $class_or_self=shift;
#   if (ref $class_or_self) { 
#     # called as object method. access hash slot via AUTOLOAD
#     $AUTOLOAD='VERSION';
#     return $class_or_self->AUTOLOAD(@_);
#   }
#   # called as function or class method. do regular 'VERSION' via base class
#   return $class_or_self->SUPER::VERSION(@_);
# }
sub DESTROY  { 
  # CAUTION: do NOT shift - need $_[0] intact
  if (ref($_[0])) {
    # called as object method. inish up in helper class where namespace more complete
    my $helper_class=ref($_[0]).'::helper';
    my $helper_function=__PACKAGE__.'::helper::_destroy';
    return $helper_class->$helper_function(@_);
  }
  # called as class method. pass to base class. not sure this ever happens...
  my $class_or_self=shift;
  return $class_or_self->SUPER::DESTROY(@_);
}

#   my $self=$_[0];		# CAUTION: do NOT shift - need $_[0] intact
#   return unless ref $self;	# shouldn't happen, but...
#   if (@_==1) {			# called as destructor or accessor
#     # perlobj says that $_[0] is read-only when DESTROY called as destructor
#     local $@=undef;
#     eval { $_[0]=undef };
#     return if $@;		# eval failed, so it's destructor.
#      $_[0]=$self;		# not destructor. restore $_[0]
#   }
#   # not destructor. access hash slot via AUTOLOAD
#   shift;			# now shift $self out of @_
#   $AUTOLOAD='DESTROY';
#   $self->AUTOLOAD(@_)

sub AUTOLOAD {
  my $self=shift;
  $AUTOLOAD=~s/^.*:://;		               # strip class qualification
  # return if $AUTOLOAD eq 'DESTROY';            # the books say you should do this
  my $key=$AUTOLOAD;
  defined $key or $key='AUTOLOAD';
  $AUTOLOAD=undef;		# reset for next time
  # finish up in helper class where namespace more complete
  my $helper_function=__PACKAGE__.'::helper::_autoload';
  $self->$helper_function($key,@_);
}

#################################################################################
# helper package exists to avoid polluting Hash::AutoHash namespace with
#   subs that would mask accessor/mutator AUTOLOADs
# functions herein (except _new, _autoload) are exportable by Hash::AutoHash
#################################################################################
package Hash::AutoHash::helper;
our $VERSION=$Hash::AutoHash::VERSION;
use strict;
use Carp;
use Scalar::Util qw(blessed readonly reftype);
use List::MoreUtils qw(uniq);
use Tie::ToObject;
use vars qw(%SELF2HASH %SELF2OBJECT %SELF2EACH %CLASS2ANCESTORS %EXPORT_OK);

sub _import {
  my($helper_class,$class,$caller,@want)=@_;
  $helper_class->EXPORT_OK;	# initializes %EXPORT_OK if necessary
  no strict 'refs';
  my %caller2export=%{$class.'::EXPORT_OK'};
  #   my @export_ok=keys %caller2export;
  for my $want (@want) {
    confess("\"$want\" not exported by $class module") unless exists $caller2export{$want};
    confess("\"$want\" not defined by $class module") unless defined $caller2export{$want};
    my $caller_sym=$caller.'::'.$want;
    my $export_sym=$caller2export{$want};
    no strict 'refs';
    *{$caller_sym}=\&{$export_sym};
  }
}
    
# front-end to autohash_new constructor function, which in turn is front-end
#   to other constructor functions.
sub _new {
  my($helper_class,$class)=splice @_,0,2;
  my $self=autohash_new(@_);
  bless $self,$class;		# re-bless in case called via subclass
}

sub _destroy {
  my $helper_class=shift;
  # $_[0] is now original object. 
  # CAUTION: do NOT shift further - need $_[0] intact
  # perlobj says that $_[0] is read-only when DESTROY called as destructor
  return if @_==1 && readonly($_[0]); # destructor. nothing to do.
  # not destructor. access hash slot via AUTOLOAD
  my $self=shift;
  my $helper_function=__PACKAGE__.'::_autoload';
  $self->$helper_function('DESTROY',@_)
}

sub _autoload {
  my($self,$key)=splice(@_,0,2);
  if (my $object=tied %$self) {	# tied hash, so invoke FETCH/STORE methods
    return @_==0? $object->FETCH($key): $object->STORE($key,@_);
  } else {			# regular hash
    return @_==0? ($self->{$key}): ($self->{$key}=$_[0]);
  }
}

# use vars qw(%CLASS2ANCESTORS);
sub _ancestors {
  my($class,$visited)=@_;
  my $ancestors=$CLASS2ANCESTORS{$class};
  defined $visited or $visited={};
  unless (defined($ancestors) || $visited->{$class}) {
    # first call, so compute it
    $ancestors=[$class];	# include self
    $visited->{$class}++;
    my @isa;
    {no strict "refs"; @isa = @{ $class . '::ISA' };}
    for my $super (@isa) {
      push(@$ancestors,_ancestors($super,$visited));
    }
    @$ancestors=uniq(@$ancestors);
    $CLASS2ANCESTORS{$class}=$ancestors
  }
  wantarray? @$ancestors: $ancestors;
}

sub EXPORT_OK {
  my $helper_class=shift;
  my($class)=$helper_class=~/^(.*)::helper$/;
  # for Hash::AutoHash::helper, @EXPORT_OK is given and function computes %EXPORT_OK
  if ($helper_class eq __PACKAGE__) { # NOTE: change this if you copy-and-paste into subclass
    no strict 'refs';
    my $export_ok_list=\@{$class.'::EXPORT_OK'};
    my $export_ok_hash=\%{$class.'::EXPORT_OK'};     
    unless(%$export_ok_hash) {
      my $ancestors=$helper_class->_ancestors;
      for my $func (@$export_ok_list) {
	$export_ok_hash->{$func}=_export_sym($func,$class,$ancestors);
      }}
    return @$export_ok_list;
  }
  # for subclasses, @EXPORT_OK and %EXPORT_OK must both be computed
  my($export_ok_list,$export_ok_hash,@isa,@normal_export_ok,@rename_export_ok,%rename_export_ok);
  {
    no strict 'refs';
    $export_ok_list=\@{$class.'::EXPORT_OK'};
    # NG 12-11-29: 'defined @array' deprecated in 5.16 or so
    # return @$export_ok_list if defined @$export_ok_list;
    return @$export_ok_list if @$export_ok_list;
    $export_ok_hash=\%{$class.'::EXPORT_OK'}; 
    @isa=@{$helper_class.'::ISA'};
    @normal_export_ok=@{$class.'::NORMAL_EXPORT_OK'};
    @rename_export_ok=@{$class.'::RENAME_EXPORT_OK'};
    %rename_export_ok=%{$class.'::RENAME_EXPORT_OK'};
  };
  map {$_->EXPORT_OK} @isa;  # mqke sure EXPORT_OK setup in ancestors
  my $ancestors=$helper_class->_ancestors;

  for my $func (@normal_export_ok) {
    $export_ok_hash->{$func}=_export_sym($func,$class,$ancestors);
  }
  while(my($caller_func,$our_func)=each %rename_export_ok) {
    $export_ok_hash->{$caller_func}=_export_sym($our_func,$class,$ancestors);
  }
  if (@rename_export_ok) {
    my($sub,@our_funcs)=@rename_export_ok;
    my %skip;
    unless (@our_funcs) {	# rename list empty, so use default
      # start with all subclass-exportable functions from base classes
      @our_funcs=uniq
	map {UNIVERSAL::can($_,'SUBCLASS_EXPORT_OK')? $_->SUBCLASS_EXPORT_OK: ()} @isa;
      # %skip contains ones dealt with in @NORMAL_EXPORT_OK or %RENAME_EXPORT_OK
      @skip{@normal_export_ok}=(1) x @normal_export_ok;
      @skip{keys %rename_export_ok}=(1) x keys %rename_export_ok;
      # @skip{values %rename_export_ok}=(1) x values %rename_export_ok;
    }
    for my $our_func (@our_funcs) {
      local $_=$our_func;
      my $caller_func=&$sub();	# sub operates on $_
      next if $skip{$caller_func};
      $export_ok_hash->{$caller_func}=_export_sym($our_func,$class,$ancestors);
    }
  }
  @$export_ok_list=keys %$export_ok_hash;
}
sub SUBCLASS_EXPORT_OK {
  my $helper_class=shift;
  my($class)=$helper_class=~/^(.*)::helper$/;
  no strict 'refs';
  # for Hash::AutoHash::helper, @SUBCLASS_EXPORT_OK is given
  if ($helper_class eq __PACKAGE__) { # NOTE: change this if you copy-and-paste into subclass
    return @{$class.'::SUBCLASS_EXPORT_OK'};
  } 
  # for subclasses, @SUBCLASS_EXPORT_OK must be computed
  my $subclass_export_ok=\@{$class.'::SUBCLASS_EXPORT_OK'};
  # NG 12-11-29: 'defined @array' deprecated in 5.16 or so
  # return @$subclass_export_ok if defined @$subclass_export_ok;
  return @$subclass_export_ok if @$subclass_export_ok;
  return @$subclass_export_ok=$helper_class->EXPORT_OK;
}

sub _export_sym {
  my($func,$class,$ancestors)=@_;
  for my $export_class (@$ancestors) { # @$ancestors includes self
    no strict 'refs';
    my $export_sym=$export_class.'::'.$func;
    return $export_sym if defined *{$export_sym}{CODE};
    # see if ancestor renames it
    my($class)=$export_class=~/^(.*)::helper$/;
    my $export_sym=${$class.'::EXPORT_OK'}{$func};
    return $export_sym if defined $export_sym;
  }
  undef;
}

#################################################################################
# constructor functions. recommended over 'new'
#################################################################################
# make real autohash
# any extra params are key=>value pairs stored in object
sub autohash_hash {
  my(@hash)=@_;
  # store params in self. can do in one step since no special semantics to worry about
  my $self=bless {@hash},'Hash::AutoHash';
  $self;
}
# tie autohash
# any extra params passed to tie
sub autohash_tie (*@) {
  my($hash_class,@hash_params)=@_;
  my $self=bless {},'Hash::AutoHash';
  tie %$self,$hash_class,@hash_params;
  $self;
}
# wrap pre-existing hash.
# any extra params are key=>value pairs passed to hash
sub autohash_wrap (\%@) {
  my($hash,@hash)=@_;
  # pass params to hash in loop in case it's tied hash with special semantics
  while (@hash>1) {
    my($key,$value)=splice @hash,0,2; # shift 1st two elements
    $hash->{$key}=$value;
  }
  my $self=bless {},'Hash::AutoHash';
  # if $hash is real, tie to 'alias', so autohash will alias hash
  if (my $object=tied(%$hash)) {
    tie %$self,'Tie::ToObject',$object;
  } else {
    tie %$self,'Hash::AutoHash::alias',$hash;
  }
  $self;
}
# wrap pre-existing tied object. (ie, object returned by tie),
# any extra params are key=>value pairs passed to object's STORE method
sub autohash_wrapobj {
  my($object,@hash)=@_;
  # pass params to hash in loop in case it's tied hash with special semantics
  while (@hash>1) {
    my($key,$value)=splice @hash,0,2; # shift 1st two elements
    $object->STORE($key,$value);
  }
  my $self=bless {},'Hash::AutoHash';
  tie %$self,'Tie::ToObject',$object;
  $self;
}
# tie and wrap hash in one step. any extra params passed to tie
# kinda silly, but oh well...
sub autohash_wraptie (\%*@) {
  my($hash,$hash_class,@hash_params)=@_;
  my $object=tie %$hash,$hash_class,@hash_params;
  my $self=bless {},'Hash::AutoHash';
  tie %$self,'Tie::ToObject',$object;
  $self;
}
# autohash_new - CAUTION: must come after other constructors because of prototypes
# front-end to other constructor functions
# cases:
# 1) 0 params - autohash_hash
# 2) >0 params - 1st param unblessed ARRAY - autohash_tie or autohash_wraptie
#     0th element scalar - autohash_tie
#     0th element HASH - autohash_wraptie
# 3) >0 params - 1st param unblessed HASH - autohash_wrap
# 4) >0 params - 1st param blessed HASH apparently not tied hash - autohash_wrap
# 5) >0 params - 1st param blessed and looks like tied hash object - autohash_wrapobj
# 6) other - autohash_hash
sub autohash_new {
  if (@_) {
    if ('ARRAY' eq ref $_[0]) {	# autohash_tie or autohash_wraptie
      my $autohash;
      my $params=shift;
      my $class_or_hash=shift @$params;
      unless (ref $class_or_hash) { # it's a class. so tie it
	$autohash=autohash_tie($class_or_hash,@$params);
      } else {			    # it's a hash. next param is class
	my $hash=$class_or_hash;
	my $class=shift @$params;
	$autohash=autohash_wraptie(%$hash,$class,@$params);
      }
      return autohash_set($autohash,@_);
    }
    if ('HASH' eq reftype($_[0]) && !_looks_wrappable($_[0])) { 
      my $hash=shift;
      return autohash_wrap(%$hash,@_);
    }
    if (_looks_wrappable($_[0])) {
      return autohash_wrapobj(@_);
    }}
  # none of the above, so must be real
  autohash_hash(@_);
}

# try to decide if object tied to hash. very approximate...
# say yes if blessed and has TIEHASH method
sub _looks_wrappable {blessed($_[0]) && UNIVERSAL::can($_[0],'TIEHASH');}
  
#################################################################################
# following functions provide standard hash operations on Hash::AutoHash
# objects. they delegate to wrapped goodie
#################################################################################
sub autohash_clear {%{$_[0]}=()}
sub autohash_delete {
  my $self=shift;
  delete @$self{@_};
}
sub autohash_each {each %{$_[0]}}
sub autohash_exists {exists $_[0]->{$_[1]}}
sub autohash_keys {keys %{$_[0]}}		  
sub autohash_values {values %{$_[0]}}

#################################################################################
# convenience methods easily be built on top of keys
#################################################################################
sub autohash_count {scalar(keys %{$_[0]}) || 0}
sub autohash_empty {scalar(%{$_[0]})? undef: 1}
sub autohash_notempty {scalar(%{$_[0]})? 1: undef}

################################################################################
# alias - connect autohash to hash - can be used to do the opposite of wrap
################################################################################
sub autohash_alias (\$\%@) {
  my($autohash_ref,$hash,@hash)=@_;
  if (!defined $$autohash_ref) { # no autohash, so create alias from hash to autohash
    return $$autohash_ref=autohash_wrap(%$hash,@hash);
  } else {		         # create alias from autohash to hash
    my $autohash=$$autohash_ref;
    autohash_set($autohash,@hash);
    tie %$hash,'Hash::AutoHash::alias',$autohash;
  }
}
################################################################################
# functional access to tied object. works on aliased hash, also
################################################################################
# sub autohash_options (\[$%]) {
#   my($ref)=@_;
#   my $autohash;
#   if ('REF' eq ref $ref) {	# it's autohash (we hope :)
#     $autohash=$$ref;		# dereference to get autohash
#     my $object=tied %$autohash;
#     return undef unless $object;                            # real hash
#     return undef if 'Hash::AutoHash::alias' eq ref $object; # aliased to real
#     return $object;                                         # tied or aliased to tied
#   } elsif ('HASH' eq ref $ref) { # HASH may be tied to 'real object or 'alias'
#     my $object=tied %$ref;
#     return undef unless $object; 
#     return $object unless 'Hash::AutoHash::alias' eq ref $object;
#     # hash aliased to autohash. recurse to get underlying tied object
#     $autohash=$object->[0];	          # extract autohash from alias
#     return &autohash_options(\$autohash); # use old-style call to turn off prototyping
#   }
#   undef;
# }
# sub autohash_options (\[$%]) {
#   my($ref)=@_;
#   my($autohash,$hash);
#   $autohash=$$ref if 'REF' eq ref $ref;	# it's autohash (we hope :)
#   $hash=$ref if 'HASH' eq ref $ref;
#   if ($hash) { # do hash case first. sometimes falls into autohash case
#     my $object=tied %$ref;
#     return undef unless $object; 
#     return $object unless 'Hash::AutoHash::alias' eq ref $object;
#     # hash aliased to autohash. extract autohash from alias and fall into authohash case
#     $autohash=$object->[0];
#   }
#   if ($autohash) {
#     my $object=tied %$autohash;
#     return undef unless $object;                            # real hash
#     return undef if 'Hash::AutoHash::alias' eq ref $object; # aliased to real
#     return $object;                                         # tied or aliased to tied
#   }
#   undef;
# }
# sub autohash_option (\[$%]@) {
#   my($ref,$option,@params)=@_;
#   my $object=&autohash_options($ref); # use old-style call to turn off prototyping
#   return undef unless $object;
#   $object->$option(@params);
# }
sub autohash_tied (\[$%]@) {
  my $ref=shift;
  my($autohash,$hash,$tied);
  $autohash=$$ref if 'REF' eq ref $ref;	# it's autohash (we hope :)
  $hash=$ref if 'HASH' eq ref $ref;
  if ($hash) { # do hash case first. sometimes falls into autohash case
    $tied=tied %$ref;
    # hash aliased to autohash. extract autohash from alias and fall into authohash case
    $autohash=$tied->[0] if 'Hash::AutoHash::alias' eq ref $tied;
  }
  if ($autohash) {
    $tied=tied %$autohash;
    $tied=undef if 'Hash::AutoHash::alias' eq ref $tied; # aliased to real
  }
  return $tied unless @_ && $tied;
  # have tied object and there are more params. this means 'run method on tied object'
  my($method,@params)=@_;
  $tied->$method(@params);
}

#################################################################################
# get and set offer extended functionality for users of this interface.
# 'set' is the useful one. 'get' provided for symmetry
#################################################################################
# get values for one or more keys.
sub autohash_get  {
 my $self=shift;
 @$self{@_};
}
# set one or more key=>value pairs in hash
sub autohash_set {
 my $self=shift;
 if (@_==2 && 'ARRAY' eq ref $_[0] && 'ARRAY' eq ref $_[1]) { # separate arrays form
   my($keys,$values)=@_;
   for (my $i=0; $i<@$keys; $i++) {
     my($key,$value)=($keys->[$i],$values->[$i]);
     $self->{$key}=$value;
   }} else {			# key=>value form
   while (@_>1) {
     my($key,$value)=splice @_,0,2; # shift 1st two elements
     $self->{$key}=$value;
   }}
 $self;
}

#################################################################################
# destroy and untie rarely used but needed for full tied hash functionality.
# destroy nop. untie calls tied object's untie method
#################################################################################
sub autohash_destroy {}
sub autohash_untie {
  my $object=tied(%{$_[0]});
  $object->UNTIE() if $object;
}

# #################################################################################
# # this package used to 'dup' autohash to externally supplied real hash
# #   amazing that nothing in CPAN does this! I found several 'alias' packages but
# #   none could connect new variable to old one without changing the type of old
# #################################################################################
# package Hash::AutoHash::dup;
# use strict;
# use Tie::Hash;
# our @ISA=qw(Tie::ExtraHash);

# sub TIEHASH  { 
#   my($class,$existing_hash)=@_;
#   bless [$existing_hash],$class;
# }
#################################################################################
# this package used to 'alias' hash to externally supplied hash
#   amazing that nothing in CPAN does this! I found several 'alias' packages but
#   none could connect new variable to old one without changing the type of old
#################################################################################
package Hash::AutoHash::alias;
our $VERSION=$Hash::AutoHash::VERSION;
use strict;
use Tie::Hash;
our @ISA=qw(Tie::ExtraHash);

sub TIEHASH  { 
  my($class,$existing_autohash)=@_;
  bless [$existing_autohash],$class;
}
1;

__END__

=head1 NAME

Hash::AutoHash - Object-oriented access to real and tied hashes

=head1 VERSION

Version 1.17

=head1 SYNOPSIS

  use Hash::AutoHash;

  # real hash
  my $autohash=new Hash::AutoHash name=>'Joe', hobbies=>['hiking','cooking'];

  # access or change hash elements via methods
  my $name=$autohash->name;           # 'Joe'
  my $hobbies=$autohash->hobbies;     # ['hiking','cooking']
  $autohash->hobbies(['go','chess']); # hobbies now ['go','chess']

  # you can also use standard hash notation and functions
  my($name,$hobbies)=@$autohash{qw(name hobbies)};
  $autohash->{name}='Moe';            # name now 'Moe'
  my @values=values %$autohash;       # ('Moe',['go','chess'])

  # tied hash. 
  use Hash::AutoHash qw(autohash_tie);
  use Tie::Hash::MultiValue;          # from CPAN. each hash element is ARRAY
  my $autohash=autohash_tie Tie::Hash::MultiValue;
  $autohash->name('Joe');
  $autohash->hobbies('hiking','cooking');
  my $name=$autohash->name;           # ['Joe']
  my $hobbies=$autohash->hobbies;     # ['hiking','cooking']
  
  # real hash via constructor function. analogous to autohash_tied
  use Hash::AutoHash qw(autohash_hash);
  my $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking'];
  my $name=$autohash->name;           # 'Joe'
  my $hobbies=$autohash->hobbies;     # ['hiking','cooking']

  # autohash_set is easy way to set multiple elements at once
  # it has two forms
  autohash_set($autohash,name=>'Moe',hobbies=>['go','chess']);
  autohash_set($autohash,['name','hobbies'],['Moe',['go','chess']]);

  # alias $autohash to regular hash for more concise hash notation
  use Hash::AutoHash qw(autohash_alias);
  my %hash;
  autohash_alias($autohash,%hash);
  # access or change hash elements without using ->
  $hash{name}='Joe';                     # changes $autohash and %hash
  my $name_via_hash=$hash{name};         # 'Joe'
  my $name_via_autohash=$autohash->name; # 'Joe'
  # get two elements in one statement
  my($name,$hobbies)=@hash{qw(name hobbies)};

  # nested structures work, too, of course
  my $name=autohash_hash first=>'Joe',last=>'Doe';
  my $person=autohash_hash name=>$name,hobbies=>['hiking','cooking'];
  my $first=$person->name->first;    # 'Joe'

=head1 DESCRIPTION

This is yet another module that lets you access or change the elements
of a hash using methods with the same name as the element's key.  It
follows in the footsteps of L<Hash::AsObject>, L<Hash::Inflator>,
L<Data::OpenStruct::Deep>, L<Object::AutoAccessor>, and probably
others. The main difference between this module and its forebears is
that it supports tied hashes, in addition to regular hashes. This
allows a modular division of labor: this class is generic and treats
all hashes the same; any special semantics come from the tied hash.

The class has a 'new' method but also supplies several functions for
constructing new Hash::AutoHash objects.

The constructor functions shown in the SYNOPSIS are all you need for
typical uses.  autohash_hash creates a new 'real' (ie, not tied)
Hash::AutoHash object; autohash_tie creates a new tied Hash::AutoHash
object. Once the objects are constructed, the class treats them the
same way.

You can get the value of a hash element using hash notation or by
invoking a method with the same name as the key. For example, the
following are equivalent.

  my $name=$autohash->{name};
  my $name=$autohash->name;

You can also change the value of an element using either notation:

  $autohash->{name}='Jonathan';
  $autohash->name('Jonathan');

And you can add new elements using either notation:

  $autohash->{first_name}='Joe';
  $autohash->last_name('Plumber');

CAUTIONS

=over 2

=item * When using method notation, keys must be
syntactically legal method names and cannot include 'funny' characters.

=item * INCOMPATIBLE CHANGE: As of version 1.14, it is no longer
possible to use method notation for keys with the same names
as methods inherited from UNIVERSAL (the base class of
everything). These are 'can', 'isa', 'DOES', and 'VERSION'.
The reason is that as of Perl 5.9.3, calling UNIVERSAL
methods as functions is deprecated and developers are
encouraged to use method form instead. Previous versions of
AutoHash are incompatible with CPAN modules that adopt this
style.

=back

Nested structures work straightforwardly. If a value is a
Hash::AutoHash object, you can use a series of '->' operators
to get to its elements.

  my $name=autohash_hash first=>'Joe',last=>'Doe';
  my $person=autohash_hash name=>$name,hobbies=>['hiking','cooking'];
  my $first=$person->name->first;    # $name is 'Joe'

The class provides a full plate of functions for performing hash
operations on Hash::AutoHash objects.  These are useful if you
want to avoid hash notation all together.  The following example uses
these functions to removes hash elements whose values are undefined:

  use Hash::AutoHash qw(autohash_keys autohash_delete);
  my @keys=autohash_keys($autohash);
  for my $key (@keys) {
    autohash_delete($autohash,$key) unless defined $autohash->$key;
  }

The autohash_set function is an easy way to set multiple elements at
once. This is especially handy for setting the initial value of a tied
Hash::AutoHash object, in cases where the tied hash cannot do
this directly.

  use Hash::AutoHash qw(autohash_set);
  my $autohash=autohash_tie Tie::Hash::MultiValue;
  autohash_set($autohash,name=>'Joe',hobbies=>'hiking',hobbies=>'cooking');

In the example above, 'hobbies' is set twice, because that's how
Tie::Hash::MultiValue lets you set a multi-valued element. Setting the
element to an ARRAY of values doesn't do it.

You can also feed autohash_set separate ARRAYs of keys and
values.

  my $autohash=autohash_tie Tie::Hash::MultiValue;
  autohash_set($autohash,['name','hobbies'],['Joe','hiking']);

You can alias the object to a regular hash for more concise hash
notation. 

  use Hash::AutoHash qw(autohash_alias);
  my $autohash=autohash_tie Tie::Hash::MultiValue;
  autohash_alias($autohash,%hash);
  $hash{name}='Joe';                  # changes both $autohash and %hash
  $autohash->hobbies('kayaking');     # changes both $autohash and %hash
  my($name,$hobbies)=@hash{qw(name hobbies)};

By aliasing $autohash to %hash, you avoid the need to dereference the
variable when using hash notation.  Admittedly, this is a minor
convenience, but the reduction in verbosity can be useful in some
cases.

It is also possible to link a Hash::AutoHash object to an
existing hash which may be real or tied, a process we call wrapping.
The effect is similar to aliasing. The difference is that with
aliasing, the object exists first whereas with wrapping, the hash
exists first.

  # wrap existing hash - can be real or tied.
  use Hash::AutoHash qw(autohash_wrap);
  my %hash=(name=>'Moe',hobbies=>['running','rowing']);
  my $autohash=autohash_wrap %hash;
  my($name,$hobbies)=@hash{qw(name hobbies)};
  $hash{name}='Joe';                  # changes both $autohash and %hash
  $autohash->hobbies('kayaking');     # changes both $autohash and %hash

If the Hash::AutoHash object is tied, the autohash_tied function
returns the object implementing the tied hash. If the Hash::AutoHash
object is aliased to a hash, the function also works on the
hash. autohash_tied is almost equivalent to Perl's built-in tied
function; see L<Accessing the tied object> for details.

  use Hash::AutoHash qw(autohash_tied);
  my $autohash=autohash_tie Tie::Hash::MultiValue;
  my $tied=autohash_tied($autohash);  # Tie::Hash::MultiValue object 
  autohash_alias($autohash,%hash);
  my $tied=autohash_tied(%hash);      # same object as above

If you're certain the Hash::AutoHash object is tied, you can invoke
methods on the tied object as follows. CAUTION: this will generate an
error if the object is not tied.

  my $result=autohash_tied($autohash)->some_method(@parameters);

A safer way is to supply the method name and parameters as additional
arguments to the autohash_tied function. This will return undef if the
object is not tied.

  my $result=autohash_tied($autohash,'some_method',@parameters);

=head2 Keeping the namespace clean

Hash::AutoHash provides all of its capabilities through class
methods (these are methods, such as 'new', that are invoked on the
class rather than on individual objects) or through functions that
must be imported into the caller's namespace.  In most cases, a method invoked on
an object is interpreted as a request to access or change an element
of the underlying hash. 

CAUTION: As of version 1.14, it is not possible to use method
notation for keys with the same names as methods inherited from
UNIVERSAL (the base class of everything). These are 'can', 'isa',
'DOES', and 'VERSION'.  The reason is that as of Perl 5.9.3, calling
UNIVERSAL methods as functions is deprecated and developers are
encouraged to use method form instead. Previous versions of AutoHash
are incompatible with CPAN modules that adopt this style.

Special care is needed with methods used implicitly by Perl to
implement common features ('import', 'AUTOLOAD', 'DESTROY'). 

'import' is usually invoked by Perl as a class method when processing
'use' statements to import functions into the caller's namespace. We
preserve this behavior but when invoked on an object, we interpret the
call as a request to access or change the element of the underlying
hash whose kye is 'import'.

'AUTOLOAD' and 'DESTROY' pose different problems, since they are
logically object methods.  Fortunately, Perl leaves enough clues to
let us tell whether these methods were called by Perl or directly
by the application.  When called by Perl, they operate as Perl
expects; when called by the application, they access the underlying
hash.

The 'new' method warrants special mention.  In normal use, 'new' is
almost always invoked as a class method, eg, 

  new Hash::AutoHash(name=>'Joe')

This invokes the 'new' method on Hash::AutoHash which
constructs a new object as expected.  If, however, 'new' is invoked on
an object, eg,

  $autohash->new

the code accesses the hash element named 'new'.

=head2 Constructors

Hash::AutoHash provides a number of constructor functions as well as a
'new' method which is simply a front-end for the constructor
functions. To use the constructor functions, you must import them into
the caller's namespace using the common Perl idiom of listing the
desired functions in a 'use' statement.

 use Hash::AutoHash qw(autohash_hash autohash_tie autohash_wrap autohash_wrapobj
                       autohash_wraptie autohash_new);

=head3 autohash_hash

 Title   : autohash_hash
 Usage   : $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking']
 Function: Create a real (ie, not tied) Hash::AutoHash object and 
           optionally set its initial value
 Returns : Hash::AutoHash object
 Args    : Optional list of key=>value pairs

=head3 autohash_tie

 Title   : autohash_tie
 Usage   : $autohash=autohash_tie Tie::Hash::MultiValue
 Function: Create a tied Hash::AutoHash object
 Returns : Hash::AutoHash object tied to the given class
 Args    : The class implementing the tied hash; quotes are optional. Any 
           additional parameters are passed to the TIEHASH constructor.

The object returned by autohash_tie is simultaneously a
Hash::AutoHash object and a tied hash.  To get the object
implementing the tied hash (ie, the object returned by Perl's tie
function), do either of the following.

  my $tied=tied %$autohash;            # note '%' before '$'
  my $tied=autohash_tied($autohash);   # note no '%' before '$'

The autohash_set function is a convenient way to set the initial value
of a tied Hash::AutoHash object in cases where the tied hash
cannot do this directly.

  use Hash::AutoHash qw(autohash_set);
  my $autohash=autohash_tie Tie::Hash::MultiValue;
  autohash_set ($autohash,name=>'Joe',hobbies=>'hiking',hobbies=>'cooking');

In the example above, 'hobbies' is set twice, because that's how
Tie::Hash::MultiValue lets you set a multi-valued element. Setting the
element to an ARRAY of values doesn't do it.

You can also provide autohash_set with separate ARRAYs of keys and values.

  my $autohash=autohash_tie Tie::Hash::MultiValue;
  autohash_set($autohash,['name','hobbies'],['Joe','hiking']);

=head3 Wrapping an existing hash or tied object

The constructor functions described in this section let you create a
Hash::AutoHash object that is linked to an existing hash or
tied object, a process we call wrapping. Once the linkage is made, the
contents of the object and hash will be identical; any changes made to
one will be reflected in the other.

=head4 autohash_wrap

 Title   : autohash_wrap
 Usage   : $autohash=autohash_wrap %hash,name=>'Joe',hobbies=>['hiking','cooking']
 Function: Create a Hash::AutoHash object linked to the hash. The initial
           value of the object is whatever value the hash currently has. Any
           additional parameters are key=>value pairs which are used to set
           further elements of the object (and hash)
 Returns : Hash::AutoHash object linked to the hash
 Args    : Hash and optional list of key=>value pairs. The hash can be real or
           tied. The key=>value pairs set further elements of the object (and 
           hash).
 Notes   : If the hash is tied, the constructed object will be tied to the 
           object implementing the tied hash.  If the hash is not tied, the 
           constructed object will be tied to an object of type 
           Hash::AutoHash::dup which implements the linking.

=head4 autohash_wrapobj

 Title   : autohash_wrapobj
 Usage   : $autohash=autohash_wrapobj $tied_object,name=>'Joe',hobbies=>'hiking'
 Function: Create a Hash::AutoHash object linked to a tied hash given 
           the object implementing the tie (in other words, the object returned
           by Perl's tie function). The initial value of the constructed object
           is whatever value the hash currently has. Any additional parameters 
           are key=>value pairs which are used to set further elements of the 
           object (and hash).
 Returns : Hash::AutoHash object linked to the hash
 Args    : Object implementing a tied hash and optional list of key=>value 
           pairs. The key=>value pairs set further elements of the object (and 
           hash).

Here is another, perhaps more typical, illustration of autohash_wrapobj.

  $autohash=autohash_wrapobj tie %hash,'Tie::Hash::MultiValue'

You can set initial values in the constructed object by including them
as parameters to the function, using parentheses to keep them separate
from the parameters to 'tie'.  All the parentheses in the example
below are necessary.

  $autohash=autohash_wrapobj ((tie %hash,'Tie::Hash::MultiValue'),
                              name=>'Joe',hobbies=>'hiking',hobbies=>'cooking')

=head4 autohash_wraptie

 Title   : autohash_wraptie
 Usage   : $autohash=autohash_wraptie %hash,Tie::Hash::MultiValue
 Function: Create a Hash::AutoHash object linked to a tied hash and do 
           the tying in one step.
 Returns : Hash::AutoHash object linked to the hash. As a side effect,
           the hash will be tied to the given class.
 Args    : Hash and the class implementing the tied hash (quotes are optional).
           Any additional parameters are passed to the TIEHASH constructor.
 Notes   : This is equivalent to
           $autohash=autohash_wrapobj tie %hash,'Tie::Hash::MultiValue'

=head3 new

'new' and L<autohash_new> are front-ends to the other constructor
functions. To accommodate the diversity of the other functions, the
parameter syntax makes some assumptions and is not completely general.

 Title   : new 
 Usage   : $autohash=new Hash::AutoHash 
                         name=>'Joe',hobbies=>['hiking','cooking']
           -- OR --
           $autohash=new Hash::AutoHash ['Tie::Hash::MultiValue'],
                         name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
           -- OR --
           $autohash=new Hash::AutoHash \%hash,
                         name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
           -- OR --
           $autohash=new Hash::AutoHash $tied_object,
                         name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
           -- OR --
           $autohash=new Hash::AutoHash [\%hash,'Tie::Hash::MultiValue'],
                         name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
 Function: Create a Hash::AutoHash object and optionally set elements.
           Form 1, like autohash_hash, creates a real (ie, not tied) object.
           Form 2, like autohash_tie, creates a tied object,
           Form 3, like autohash_wrap, creates an object linked to a hash.
           Form 4, like autohash_wrapobj, creates an object linked to a tied 
             hash given the object implementing the tie
           Form 5, like autohash_wraptie, creates an object linked to a tied 
             hash and does the tie in one step 
 Returns : Hash::AutoHash object
 Args    : The first argument determines the form. The remaining arguments are
           an optional list of key=>value pairs which are used to set elements
           of the object
           Form 1. first argument is a scalar (eg, a string)
           Form 2. first argument is an ARRAY whose elements are the class
             implementing the tied hash (quotes are required) followed by
             additional parameters for the the TIEHASH constructor.
           Form 3. first argument is a HASH that doesn't look like a tied 
             object.  See form 4.
           Form 4. first argument is a HASH that looks like a tied object; this
             is any blessed HASH that provides a TIEHASH method.
           Form 5. first argument is an ARRAY whose elements are a HASH and the 
             class implementing the tied hash (quotes are required) followed by
             additional parameters for the the TIEHASH constructor.

=head3 autohash_new

Like L<new>, autohash_new is a front-end to the other constructor
functions. We provide it for stylistic consistency. To accommodate the
diversity of the other functions, the parameter syntax makes some
assumptions and is not completely general.

 Title   : autohash_new 
 Usage   : $autohash=autohash_new name=>'Joe',hobbies=>['hiking','cooking']
           -- OR --
           $autohash=autohash_new ['Tie::Hash::MultiValue'],
                                  name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
           -- OR --
           $autohash=autohash_new \%hash,
                                  name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
           -- OR --
           $autohash=autohash_new $tied_object,
                                  name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
            -- OR --
           $autohash=autohash_new [\%hash,'Tie::Hash::MultiValue'],
                                  name=>'Joe',hobbies=>'hiking',hobbies=>'cooking'
Function: same as 'new'
 Returns : Hash::AutoHash object
 Args    : same as 'new'

=head2 Aliasing: autohash_alias

You can alias a Hash::AutoHash object to a regular hash to
avoid the need to dereference the variable when using hash
notation. The effect is similar to wrapping an existing hash via the
autohash_wrap function. The difference is that with aliasing, the
Hash::AutoHash object exists first and you are linking a hash
to it, whereas with wrapping, the hash exists first.

Once the linkage is made, the contents of the object and hash will be
identical; any changes made to one will be reflected in the other.

As a convenience, the autoahash_alias functions can link in either
direction depending on whether the given object exists.

 Title   : autohash_alias
 Usage   : autohash_alias($autohash,%hash)
 Function: If $autohash is defined and is a Hash::AutoHash object, link
           $autohash to %hash. If $autohash is not defined, create a new 
           Hash::AutoHash object that wraps %hash
 Args    : Hash::AutoHash object or undef and hash 
 Returns : Hash::AutoHash object

=head2 Getting and setting hash elements

One way to get and set hash elements is to treat the object
as a HASH and use standard hash notation, eg,

  my $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking'];
  my $name=$autohash->{name};
  my($name,$hobbies)=@$autohash{qw(name hobbies)};
  $autohash->{name}='Moe';
  @$autohash{qw(name hobbies)}=('Joe',['running','rowing']);

A second approach is to invoke a method with the name of the
key.  Eg,

  $autohash->name;
  $autohash->name('Moe');                   # sets name to 'Moe'
  $autohash->hobbies(['blading','rowing']); # sets hobbies to ['blading','rowing']

New hash elements can be added using either notation.  For example,

  $autohash->{first_name}='Joe';
  $autohash->last_name('Plumber');

If the object wraps or aliases a hash, you can operate on the hash
instead of the Hash::AutoHash object. This may allow more
concise notation by avoiding the need to dereference the object
repeatedly.

  use Hash::AutoHash qw(autohash_alias);
  autohash_alias($autohash,%hash);
  my $name=$hash{name};		# instead of $autohash->{name}
  my @keys=keys %hash;          # instead of keys %$autohash

The class also provides two functions for wholesale manipulation of
arguments.  To use these functions, you must import them into the
caller's namespace using the common Perl idiom of listing the desired
functions in a 'use' statement.

 use Hash::AutoHash qw(autohash_get autohash_set);

=head3 autohash_get
 
 Title   : autohash_get
 Usage   : ($name,$hobbies)=autohash_get($autohash,qw(name hobbies))
 Function: Get values for multiple keys.
 Args    : Hash::AutoHash object and list of keys
 Returns : list of argument values

=head3 autohash_set

 Title   : autohash_set
 Usage   : autohash_set($autohash,name=>'Joe Plumber',first_name=>'Joe')
           -- OR --
           autohash_set($autohash,['name','first_name'],['Joe Plumber','Joe'])
 Function: Set multiple arguments in existing object.
 Args    : Form 1. Hash::AutoHash object and list of key=>value pairs
           Form 2. Hash::AutoHash object, ARRAY of keys, ARRAY of values
 Returns : Hash::AutoHash object

=head2 Functions for hash-like operations

These functions provide hash-like operations on Hash::AutoHash
objects. These are useful if you want to avoid hash notation all
together. To use these functions, you must import them into the
caller's namespace using the common Perl idiom of listing the desired
functions in a 'use' statement.

 use Hash::AutoHash 
    qw(autohash_clear autohash_delete autohash_each autohash_exists 
       autohash_keys autohash_values 
       autohash_count autohash_empty autohash_notempty);

=head3 autohash_clear

 Title   : autohash_clear
 Usage   : autohash_clear($autohash)
 Function: Delete entire contents of $autohash
 Args    : Hash::AutoHash object
 Returns : nothing

=head3 autohash_delete

 Title   : autohash_delete
 Usage   : autohash_delete($autohash,@keys)
 Function: Delete keys and their values from $autohash.
 Args    : Hash::AutoHash object, list of keys
 Returns : nothing

=head3 autohash_exists

 Title   : autohash_exists
 Usage   : if (autohash_exists($autohash,$key)) { ... }
 Function: Test whether key is present in $autohash.
 Args    : Hash::AutoHash object, key
 Returns : boolean

=head3 autohash_each

 Title   : autohash_each
 Usage   : while (my($key,$value)=autohash_each($autohash)) { ... }
           -- OR --
           while (my $key=autohash_each($autohash)) { ... }
 Function: Iterate over all key=>value pairs or all keys present in $autohash
 Args    : Hash::AutoHash object
 Returns : list context: next key=>value pair in $autohash or empty list at end
           scalar context: next key in $autohash or undef at end

=head3 autohash_keys

 Title   : autohash_keys
 Usage   : @keys=autohash_keys($autohash)
 Function: Get all keys that are present in $autohash
 Args    : Hash::AutoHash object
 Returns : list of keys

=head3 autohash_values

 Title   : autohash_values
 Usage   : @values=autohash_values($autohash)
 Function: Get the values of all keys that are present in $autohash
 Args    : Hash::AutoHash object
 Returns : list of values

=head3 autohash_count

 Title   : autohash_count
 Usage   : $count=autohash_count($autohash)
 Function: Get the number keys that are present in $autohash
 Args    : Hash::AutoHash object
 Returns : number

=head3 autohash_empty

 Title   : autohash_empty
 Usage   : if (autohash_empty($autohash)) { ... }
 Function: Test whether $autohash is empty
 Args    : Hash::AutoHash object
 Returns : boolean

=head3 autohash_notempty

 Title   : autohash_notempty
 Usage   : if (autohash_notempty($autohash)) { ... }
 Function: Test whether $autohash is not empty. Complement of autohash_empty
 Args    : Hash::AutoHash object
 Returns : boolean

=head2 Accessing the tied object: autohash_tied

If a Hash::AutoHash object is tied, the application sometimes needs to
access the object implementing the underlying tied hash.  The term
'tied object' refers to this object.  This is necessary, for example,
if the tied object provides options that affect the operation of the
tied hash.

In many cases, you can access the tied object using Perl's built-in tied function.

  my $autohash=autohash_tie Tie::Hash::MultiValue;
  my $tied=tied %$autohash;             # note leading '%'

However Perl's built-in tied function doesn't do the right thing when
the Hash::AutoHash object wraps or is aliased to a regular (not tied)
hash. In these cases, the code uses an internal tied hash to implement
the connection between the Hash::AutoHash object and the hash. (The
internal tied hash is currently named Hash::AutoHash::alias, but this
is subject to change).

The autohash_tied function is a safer way to get the tied object. In
most cases, it is equivalent to Perl's built-in tied function, but it
reaches through the internal Hash::AutoHash::alias object when one is
present.

If the Hash::AutoHash object is aliased to a hash, the function also
works on the hash.

  use Hash::AutoHash qw(autohash_tied);
  my $autohash=autohash_tie Tie::Hash::MultiValue;
  my $tied=autohash_tied($autohash);  # Tie::Hash::MultiValue object 
  autohash_alias($autohash,%hash);
  my $tied=autohash_tied(%hash);      # same object as above

If you're certain the Hash::AutoHash object is tied, you can invoke
methods on the result of autohash_tied. This will generate an error if
the object is not tied. A safer way is to supply the method name and
parameters as additional arguments to the autohash_tied function. This
will return undef if the object is not tied.

  # two ways to invoke method on tied object
  # 1st generates error if $autohash not tied
  # 2nd returns undef if $autohash not tied
  my $result=autohash_tied($autohash)->some_method(@parameters);
  my $result=autohash_tied($autohash,'some_method',@parameters);

 use Hash::AutoHash qw(autohash_tied);

 Title   : autohash_tied 
 Usage   : $tied=autohash_tied($autohash)
           -- OR --
           $tied=autohash_tied(%hash)
           -- OR --
           $result=autohash_tied($autohash,'some_method',@parameters)
           -- OR --
           $result=autohash_tied(%hash,'some_method',@parameters)
 Function: The first two forms return the object implementing the tied hash that
           underlies a Hash::AutoHash object if it is tied, or undef if it isn't
           tied.  The latter two forms invoke a method on the tied object if the
           Hash::AutoHash object is tied, or undef if it isn't tied. 
           In forms 1 and 3, the first argument is the Hash::AutoHash object.
           In forms 2 and 4, the first argument is a hash to which a 
           Hash::AutoHash object has been aliased
 Returns : In forms 1 and 2, object implementing tied hash or undef.
           In forms 3 and 4, result of invoking method (which can be anything or
           nothing), or undef.
 Args    : Form 1. Hash::AutoHash object
           Form 2. hash to which Hash::AutoHash object is aliased
           Form 3. Hash::AutoHash object, method name, optional list of
             parameters for method
           Form 4. hash to which Hash::AutoHash object is aliased, method name,
             optional list of parameters for method

=head2 Subclassing

Special considerations apply when subclassing Hash::AutoHash
due to its goal of keeping the namespace clean and its heavy use of
functions instead of methods.

A common use-case is a subclass that provides an object interface to a
specific tied hash class.  In such cases, the subclass would probably
provide a 'new' method that constructs objects tied to that class and
would probably want to hide the other constructor functions. The
subclass might also want to provide the other functions from
Hash::AutoHash (why not?) but might want to change their names to be
consistent with the subclass's name.

Here is an example subclass, TypicalChild, illustrating this use-case.
TypicalChild provides a 'new' method that creates objects tied to
Tie::Hash::MultiValue. The 'new' method can also set the object's
initial value (the TIEHASH method of Tie::Hash::MultiValue does not
support this directly). The subclass provides the other functions from
Hash::AutoHash but renames each from autohash_XXX to
typicalchild_XXX.

  package TypicalChild;
  use Hash::AutoHash;
  our @ISA=qw(Hash::AutoHash);
  our @NORMAL_EXPORT_OK=();
  our %RENAME_EXPORT_OK=();
  our @RENAME_EXPORT_OK=sub {s/^autohash/typicalchild/; $_};
  our @EXPORT_OK=TypicalChild::helper->EXPORT_OK;
  our @SUBCLASS_EXPORT_OK=TypicalChild::helper->SUBCLASS_EXPORT_OK;

  #############################################################
  # helper package to avoid polluting TypicalChild namespace
  #############################################################
  package TypicalChild::helper;
  use Hash::AutoHash qw(autohash_tie autohash_set);
  use Tie::Hash::MultiValue;
  BEGIN {
    our @ISA=qw(Hash::AutoHash::helper);
  }
  sub _new {
    my($helper_class,$class,@args)=@_;
    my $self=autohash_tie Tie::Hash::MultiValue;
    autohash_set($self,@args);
    bless $self,$class;
  }
  1;

The subclass consists of two packages: TypicalChild and
TypicalChild::helper. The helper package is where all the real code
goes to avoid polluting TypicalChild's namespace. TypicalChild must be
a subclass of Hash::AutoHash (ie, Hash::AutoHash must
be in its @ISA array); TypicalChild::helper must be a subclass of
Hash::AutoHash::helper (ie, Hash::AutoHash::helper
must be in its @ISA array).

The 'new' method of Hash::AutoHash dispatches to the '_new'
method in the helper class after making sure the method was invoked on
a class.  That's why the code has a '_new' method in
TypicalChild::helper rather than 'new' method in TypicalChild.

The BEGIN block is needed to make sure @ISA is set at compile-time
before @EXPORT_OK is calculated.

The code in TypicalChild dealing with the various EXPORT_OK arrays
handles the renaming of functions from Hash::AutoHash (or,
more generally, any ancestor class), the exporting of additional
functions defined by the subclass, and sets the stage for subclasses
of the subclass to do the same thing.

 Variable: @NORMAL_EXPORT_OK
 Usage   : @NORMAL_EXPORT_OK=qw(autohash_set typicalchild_function)
 Function: Functions that will be exported 'normally', in other words with no 
           change of name. The functions can be defined here (in the helper 
           class, not the main class!!) or in any ancestor class

 Variable: %NORMAL_EXPORT_OK
 Usage   : %NORMAL_EXPORT_OK=(learn=>'autohash_set',forget=>'autohash_delete')
 Function: Functions that will be exported with a different name. The left-hand 
           side of each pair is the new name; the right-hand side is the name of
           a function defined here (in the helper class, not the main class!!) 
           or in any ancestor class

 Variable: @RENAME_EXPORT_OK
 Usage   : @RENAME_EXPORT_OK=sub {s/^autohash/typicalchild/; $_}
           -- OR --
           @RENAME_EXPORT_OK=(sub {s/^autohash/typicalchild/; $_},
                              qw(autohash_exists autohash_get))
 Function: Functions that will be exported with a different name. This provides
           an easy way to rename many functions at once. The first element of 
           the list is a subroutine that will be applied to each other element
           of the list to generate the new names. The functions in the list can 
           be defined here (in the helper class, not the main class!!) or in any
           ancestor class

           If the list of functions is empty, the subroutine is applied to 
           everything in its parent classes' @SUBCLASS_EXPORT_OK array.

           The form of the subroutine is exactly as for Perl's grep and map 
           functions. 

 Variable: @EXPORT_OK
 Usage   : @EXPORT_OK=TypicalChild::helper->EXPORT_OK
           -- OR --
           @EXPORT_OK=qw(learn forget)
 Function: Complete list of functions that the subclass is willing to export. 
           The EXPORT_OK method computes this from the other variables. You can
           also set it explicitly.

 Variable: @SUBCLASS_EXPORT_OK
 Usage   : @SUBCLASS_EXPORT_OK=TypicalChild::helper->SUBCLASS_EXPORT_OK
           -- OR --
           @SUBCLASS_EXPORT_OK=qw(learn forget)
 Function: Functions that subclasses of this class might want to export. This 
           provides the default list of functions for @RENAME_EXPORT_OK in these
           subclasses. The SUBCLASS_EXPORT_OK method simply sets this to 
           @EXPORT_OK which is tantamount to assuming that subclasses may want 
           to export everything this class exports.  You can also set it 
           explicitly.

=head1 SEE ALSO

L<perltie> and L<Tie::Hash> present background on tied hashes.

L<Hash::AsObject>, L<Hash::Inflator>, L<Data::OpenStruct::Deep>, and
L<Object::AutoAccessor> are similar classes and may be better choices
if you don't need or want to used tied hashes.  The source code of
L<Hash::AsObject> alerted us to the danger of methods inherited from
UNIVERSAL.

L<Hash::AutoHash::Args>, L<Hash::AutoHash::MultiValued>,
L<Hash::AutoHash::AVPairsSingle>, L<Hash::AutoHash::AVPairsMulti>,
L<Hash::AutoHash::Record> are subclasses each of which provides an
object interface to a specific tied hash class.

L<Tie::Hash::MultiValue> is a nice tied hash class used as an example
throughout this POD.

Many interesting tied hash classes are available on CPAN and can be
found by searching for 'Tie::Hash'.

=head1 AUTHOR

Nat Goodman, C<< <natg at shore.net> >>

=head1 BUGS AND CAVEATS

Please report any bugs or feature requests to C<bug-hash-autohash at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-AutoHash>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head2 Known Bugs and Caveats

=over 4

=item * Overridden UNIVERSAL methods no longer supported

INCOMPATIBLE CHANGE: As of version 1.14, it is no longer
possible to use method notation for keys with the same names
as methods inherited from UNIVERSAL (the base class of
everything). These are 'can', 'isa', 'DOES', and 'VERSION'.
The reason is that as of Perl 5.9.3, calling UNIVERSAL
methods as functions is deprecated and developers are
encouraged to use method form instead. Previous versions of
AutoHash are incompatible with CPAN modules that adopt this
style.

=item * Tied hashes and serialization

Many serialization modules do not handle tied variables properly, and
will not give correct results when applied to Hash::AutoHash
objects that use tied hashes. In this context, "serialization" refers
to the process of converting Perl data structures into strings that
can be saved in files or elsewhere and later restored.

L<Storable> handles tied hashes correctly and can be used to serialize
all kinds of Hash::AutoHash objects.

L<Data::Dumper>, L<YAML>,and L<Data::Dump::Streamer> do not handle
tied hashes correctly and cannot be used to serialize
Hash::AutoHash objects that use tied hashes. This includes
objects created by the autohash_tie, autohash_wrap, and
autohash_wrapobj functions (or by equivalent calls to 'new' or
autohash_new).  It also includes objects that have been aliased.  The
only Hash::AutoHash objects that can be serialized by these
packages are real ones (ie, objects created by autohash_hash or
equivalent calls to 'new' or autohash_new) that have not been aliased.

If you want to print Hash::AutoHash objects for debugging or
testing purposes, L<Data::Dump> works fine. However there is no way to
recreate the objects from the printed form.

=item * Tied hashes and prototypes considered harmful (by some)

This class uses tied hashes and subroutine prototypes, Perl features
that Damian Conway urges programmers to avoid. Obviously, we disagree
with Damian on this point, but we acknowledge the weight of his
argument.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::AutoHash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-AutoHash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-AutoHash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-AutoHash>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-AutoHash/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2009 Institute for Systems Biology (ISB). All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
