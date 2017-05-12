package autohashUtil;
use lib qw(t);
use strict;
use Carp;
use List::MoreUtils qw(uniq);
#use Test::More qw/no_plan/;
use Test::More;
use Test::Deep;
use Exporter();
use Hash::AutoHash;

our @ISA=qw(Exporter);
our @EXPORT=qw(as_bool ordinal report _report
	       cmp_types cmp_autohash _cmp_autohash keys_obj values_obj each_obj
	       @KEYS @UNDEFS @VALUES_SV @VALUES_MV $VERBOSE
	       is_autohash is_hash is_object is_self is_tie 
	       is_autohash_hash is_autohash_object is_autohash_self is_autohash_tie
	       test_special_keys 
	       test_class_methods @COMMON_SPECIAL_KEYS
	       $autohash %hash %tie $object);

# globals used in all tests
our($autohash,%hash,%tie,$object);
our $VERBOSE=0;
our @KEYS=qw(key0 key1 key2);
our @UNDEFS=(undef) x @KEYS;
our @VALUES_SV=([undef,undef,undef],
		[undef,'value11','value21'],
		[undef,'value12','value22'],
		[undef,'value13','value23'],);
our @VALUES_MV=([undef,undef,undef],
		[undef,['value11'],['value21']],
		[undef,[qw(value11 value12)],[qw(value21 value22)]],
		[undef,[qw(value11 value12 value13)],[qw(value21 value22 value23)]]);

# sub report (*\@\@) {
#   my($label,$ok,$fail)=@_;
#   unless (@$fail) {
#     pass($label) if $VERBOSE;
#     return 1;
#   }
#   fail($label);
#   diag(scalar(@$ok)." cases have correct values: @$ok");
#   diag(scalar(@$fail)." cases have wrong values: @$fail");
# }

sub _report (*\@\@) {
  my($label,$ok,$fail)=@_;
  unless (@$fail) {
    pass($label) if $VERBOSE;
    return 1;
  }
  fail($label);
  diag(scalar(@$ok)." cases have correct values: @$ok");
  diag(scalar(@$fail)." cases have wrong values: @$fail");
  return 0;
}
sub report (*\@\@) {
  my($label,$ok,$fail)=@_;
  my $pass=_report($label,@$ok,@$fail);
  pass($_[0]) if $pass && !$VERBOSE; # print if all tests passed and tests didn't print passes
  $pass;
}

sub as_bool {$_[0]? 1: undef;}
sub ordinal {
  my $i=shift;
  return 'initial' unless $i--;
  return '1st' unless $i--;
  return '2nd' unless $i--;
  return '3rd' unless $i--;
  return $i.'-th';
}

# test type of $autohash, whatever $autohash is tied to, %hash, $object, whatever %hash is tied to
sub cmp_types {
  my($label,$correct_tied,$correct_object,$correct_tiedhash)=@_;
  my $correct_autohash='Hash::AutoHash';
  my $correct_hash='HASH';
  my(@ok,@fail);
  my $actual_autohash=ref $autohash;
  my $actual_tied=ref tied %$autohash;
  my $actual_hash=ref \%hash;
  my $actual_object=ref $object;
  my $actual_tiedhash=ref tied %hash;
  $actual_autohash eq $correct_autohash? push(@ok,'autohash'): push(@fail,'autohash');
  $actual_tied eq $correct_tied? push(@ok,'tied'): push(@fail,'tied');
  $actual_hash eq $correct_hash? push(@ok,'hash'): push(@fail,'hash');
  $actual_object eq $correct_object? push(@ok,'object'): push(@fail,'object');
  $actual_tiedhash eq $correct_tiedhash? push(@ok,'tiedhash'): push(@fail,'tiedhash');
  $label.=': types';
  pass($label),return unless @fail;
  fail($label);
  diag(scalar(@ok)." items have correct types: @ok");
  diag(scalar(@fail)." items have wrong types: @fail");
}
# test contents of wrapper and external hash or object
# NG 09-07-29: generalize to allow any actual autohash or correct value
sub cmp_autohash {
  my $pass=_cmp_autohash(@_);
  my $label=$_[0];
  pass($_[0]) if $pass && !$VERBOSE; # print if all tests passed and tests didn't print passes
  $pass;
}
# _cmp_autohash does the work but does not print passes
sub _cmp_autohash {
  my($label,$values,$actual,$correct,$ok_hash,$ok_object,$hash,$obj);
  if ('ARRAY' eq ref $_[1]) {	# old form
    ($label,$values,$ok_hash,$ok_object)=@_;
    my @values=@$values;

    # NG 09-07-29: added computation of %correct. added _cmp_contents.
    #              changed othered to use %correct
    $actual=$autohash;
    %$correct=map {defined($values[$_])? ($KEYS[$_]=>$values[$_]): ()} 0..$#values;
    $hash=\%hash;
    $obj=$object;
  } else {
    ($label,$actual,$correct,$ok_hash,$ok_object,$hash,$obj)=@_;
  }
  my $pass=1;			# assume success
  $pass&&=_cmp_contents($label,$actual,$correct);
  $pass&&=_cmp_autohash_methods($label,$actual,$correct);
  $pass&&=_cmp_autohash_hash($label,$actual,$correct);
  $pass&&=_cmp_hash($label,$ok_hash,$hash,$correct);
  $pass&&=_cmp_object($label,$ok_object,$obj,$correct);
  $pass;
#     _cmp_autohash_methods($label,@values);
#     _cmp_autohash_hash($label,@values);
#     _cmp_hash($label,$ok_hash,@values);
#     _cmp_object($label,$ok_object,@values);
#   } else {			# new form
#     ($label,$actual,$correct,$ok_hash,$ok_object,$hash,$object)=@_;
#     %correct=%$correct;
#     _cmp_contents($label,$actual,%correct);
#     _cmp_autohash_methods($label,$actual,%correct);
#     _cmp_autohash_hash($label,$actual,%correct);
#     _cmp_hash($label,$ok_hash,$hash,%correct);
#     _cmp_object($label,$ok_object,$object,%correct);
#   }
}
# NG 09-07-29: added _cmp_contents
sub _cmp_contents {
  my($label,$actual,$correct)=@_;
  $label.=' contents';
  my %actual=%$actual;
  return 1 if !$VERBOSE && eq_deeply(\%actual,$correct);
  # else let cmp_deeply print its results
  cmp_deeply(\%actual,$correct,$label);
}

sub _cmp_autohash_methods {
  my($label,$actual,$correct)=@_;
  $label.=' via methods';
  my(@ok,@fail);
  for my $key (keys %$correct) {
    my $actual_val=$actual->$key;
    my $correct_val=$correct->{$key};
    eq_deeply($actual_val,$correct_val)? push(@ok,$key): push(@fail,$key);
  }
  _report($label,@ok,@fail);
}
sub _cmp_autohash_hash {
  my($label,$actual,$correct)=@_;
  $label.=' as hash';
  my(@ok,@fail);
  for my $key (keys %$correct) {
    my $actual_val=$actual->{$key};
    my $correct_val=$correct->{$key};
    eq_deeply($actual_val,$correct_val)? push(@ok,$key): push(@fail,$key);
  }
  _report($label,@ok,@fail);
}
sub _cmp_hash {
  my($label,$ok_hash,$actual,$correct)=@_;
  my %actual=defined $actual? %$actual: ();
  $label.=' external hash';
  unless ($ok_hash) {		# %actual (aka %hash) should be empty
    $label.=' empty';
    fail($label), return if %actual;
    pass($label) if $VERBOSE;
    return 1;
  }
  my(@ok,@fail);
  for my $key (keys %$correct) {
    my $actual_val=$actual{$key};
    my $correct_val=$correct->{$key};
    eq_deeply($actual_val,$correct_val)? push(@ok,$key): push(@fail,$key);
  }
  _report($label,@ok,@fail);
}
sub _cmp_object {
  my($label,$ok_object,$actual,$correct)=@_;
  $label.=' tied object';
  unless ($ok_object) {		# $object should be undef
    $label.=' empty';
    fail($label), return if defined $object;
    pass($label) if $VERBOSE;
    return 1;
  }  
  my(@ok,@fail);
  for my $key (keys %$correct) {
    my $actual_val=$actual->FETCH($key);
    my $correct_val=$correct->{$key};
    eq_deeply($actual_val,$correct_val)? push(@ok,$key): push(@fail,$key);
  }
  _report($label,@ok,@fail);
}
# sub _cmp_autohash_methods {
#   my($label,@values)=@_;
#   $label.=' via methods';
#   my(@ok,@fail);
#   for my $key (@KEYS) {
#     my $actual=$autohash->$key;
#     my $correct=shift @values;
#     eq_deeply($actual,$correct)? push(@ok,$key): push(@fail,$key);
#   }
#   report($label,@ok,@fail);
# }
# sub _cmp_autohash_hash {
#   my($label,@values)=@_;
#   $label.=' as hash';
#   my(@ok,@fail);
#   for my $key (@KEYS) {
#     my $value=shift @values;
#     eq_deeply($autohash->{$key},$value)? push(@ok,$key): push(@fail,$key);
#   }
#   report($label,@ok,@fail);
# }
# sub _cmp_hash {
#   my($label,$ok_hash,@values)=@_;
#   $label.=' external hash';
#   unless ($ok_hash) {		# %hash should be empty
#     ok(!%hash,"$label empty");
#     return;
#   }
#   my(@ok,@fail);
#   for my $key (@KEYS) {
#     my $value=shift @values;
#     eq_deeply($hash{$key},$value)? push(@ok,$key): push(@fail,$key);
#   }
#   report($label,@ok,@fail);
# }
# sub _cmp_object {
#   my($label,$ok_object,@values)=@_;
#   $label.=' external object';
#   unless ($ok_object) {		# $object should be undef
#     is($object,undef,"$label empty");
#     return;
#   }  
#   my(@ok,@fail);
#   for my $key (@KEYS) {
#     my $actual=$object->FETCH($key);
#     my $correct=shift @values;
#     eq_deeply($actual,$correct)? push(@ok,$key): push(@fail,$key);
#   }
#   report($label,@ok,@fail);
# }
sub keys_obj {			# based on code from now-obsolete version of Hash
  my $obj=@_? shift: $object;
  my($key,$value)=$obj->FIRSTKEY() or return ();
  my @keys=($key);
  while(($key,$value)=$obj->NEXTKEY()) {
    push(@keys,$key);
  }
  @keys;
}
sub values_obj {			# based on code from now-obsolete version of Hash
  my $obj=@_? shift: $object;
  my($key,$value)=$obj->FIRSTKEY() or return ();
  my @values=($value);
  while(($key,$value)=$obj->NEXTKEY()) {
    push(@values,$value);
  }
  @values;
}
my $each;			# controls iterator
sub each_obj {
  my $obj=@_? shift: $object;
  if (wantarray) {
    my @result=!$each? $object->FIRSTKEY(): $object->NEXTKEY();
    $each=scalar @result;
    return @result;
  } else {
    my $result=!$each? $object->FIRSTKEY(): $object->NEXTKEY();
    return $each=$result;
  }
}
# sub is_object (*@) {
#   my($label,@values)=@_;
#   my(@ok,@fail);
#   for my $key (@KEYS) {
#     my $value=shift @values;
#     eq_deeply($object->FETCH($key),$value)? push(@ok,$key): push(@fail,$key);
#   }
#   $label.=": object";
#   report($label,@ok,@fail);
# }
# sub is_self (*@) {
#   my($label,@values)=@_;
#   my(@ok,@fail);
#   for my $key (@KEYS) {
#     my $value=shift @values;
#     eq_deeply($autohash->{$key},$value)? push(@ok,$key): push(@fail,$key);
#   }
#   $label.=": self";
#   report($label,@ok,@fail);
# }
# sub is_tie (*@) {
#   my($label,@values)=@_;
#   my(@ok,@fail);
#   for my $key (@KEYS) {
#     my $value=shift @values;
#     eq_deeply($tie{$key},$value)? push(@ok,$key): push(@fail,$key);
#   }
#   $label.=": tie";
#   report($label,@ok,@fail);
# }
# sub is_autohash_hash (*@) {
#   my($label,@values)=@_;
#   is_autohash($label,@values);
#   is_hash($label,@values);
# }
# sub is_autohash_object (*@) {
#   my($label,@values)=@_;
#   is_autohash($label,@values);
#   is_object($label,@values);
#   is_tie($label,@values);
# }
# sub is_autohash_self (*@) {
#   my($label,@values)=@_;
#   is_autohash($label,@values);
#   is_self($label,@values);
# }
# sub is_autohash_tie (*@) {
#   my($label,@values)=@_;
#   is_autohash($label,@values);
#   is_tie($label,@values);
# }

# NG 12-09-02: no longer possible to override methods inheritted from UNIVERSAL
# used by xxx.020.special_keys.t for many (probably all) subclasses 
our @COMMON_SPECIAL_KEYS=qw(import new AUTOLOAD DESTROY);
our @FORMER_SPECIAL_KEYS=qw(can isa DOES VERSION);

sub test_special_keys {
  my($autohash,$repeat,$fixer,$case)=@_;
  my $class=ref $autohash;
  defined($repeat) or $repeat=1;
  defined($fixer) or $fixer=sub {$_[0]};
  my $label=length($case)? "$class $case special keys": "$class special keys";
  my @keys;
  {
    no strict 'refs';
    @keys=uniq(@COMMON_SPECIAL_KEYS,
	       # qw(import new can isa DOES VERSION AUTOLOAD DESTROY),
	       @Hash::AutoHash::EXPORT_OK,@{$class.'::EXPORT_OK'});  
  }
  my(@ok,@fail);
  for my $key (@keys) {
    my $value="value_$key";
    for(my $i=0; $i<$repeat; $i++) {$autohash->$key($value);} # set value
    my $actual=$autohash->$key;	# get value
    my $correct=&$fixer($value);
    eq_deeply($actual,$correct)? push(@ok,$key): push(@fail,$key);
    # $actual eq $correct? push(@ok,$key): push(@fail,$key);
  }
  # like '_report'
#  my $label="$class special keys";
#   pass("$label. keys=@keys"),return unless @fail;
  pass($label),return unless @fail;
  fail($label);
  diag(scalar(@ok)." keys have correct values: @ok");
  diag(scalar(@fail)." keys have wrong values: @fail");
}

# # used for Child, Grandchild tests.  not for main special_keys test
# sub test_subclass_special_keys (*) {
#   my($class)=@_;
#   my @keys;
#   {
#     no strict 'refs';
#     @keys=uniq(@COMMON_SPECIAL_KEYS,
# 	       # qw(import new can isa DOES VERSION AUTOLOAD DESTROY),
# 	       @Hash::AutoHash::EXPORT_OK,@{$class.'::EXPORT_OK'});  
#   }
#   $autohash=new $class;
#   my(@ok,@fail);
#   for my $key (@keys) {
#     my $value="value_$key";
#     $autohash->$key($value);	# set value
#     my $actual=$autohash->$key;	# get value
#     my $correct=$value;
#     # eq_deeply($actual,$correct)? push(@ok,$key): push(@fail,$key);
#     $actual eq $correct? push(@ok,$key): push(@fail,$key);
#   }
#   # like '_report'
#   my $label="$class special keys";
# #   pass("$label. keys=@keys"),return unless @fail;
#   pass($label),return unless @fail;
#   fail($label);
#   diag(scalar(@ok)." keys have correct values: @ok");
#   diag(scalar(@fail)." keys have wrong values: @fail");
# }
# used by xxx.020.class_methods.t for many (probably all) subclasses 
sub test_class_methods {
  my $class=shift;
  my $import=@_? shift: undef;	# an importable function
  # It's kinda silly to test new and import, since we'd have failed miserably long ago
  #   if these were broken :) Included here for completeness.
  $autohash=new $class;
  ok($autohash,'new');
  is(ref $autohash,$class,"new returned $class object - sanity check");

  if ($import) {
    eval {import $class ($import)};
    ok(!$@,'import: success');
  }
  eval {import $class qw(import);};
  ok($@=~/not exported/,'import: not exported');
  eval {import $class qw(not_defined);};
  ok($@=~/not exported/,'import: not defined');

  my $can=can $class('can');
  is(ref $can,'CODE','can: can');
  my $can=can $class('not_defined');
  ok(!$can,'can: can\'t');

  if ($class ne 'Hash::AutoHash') {
    my $isa=$class->isa($class);
    is($isa,1,"isa: is $class");
  }
  my $isa=$class->isa('Hash::AutoHash');
  is($isa,1,'isa: is Hash::AutoHash');
  my $isa=$class->isa('UNIVERSAL');
  is($isa,1,'isa: is UNIVERSAL');
  my $isa=$class->isa('not_defined');
  ok(!$isa,'isa: isn\'t');

  # Test DOES in perls > 5.10. 
  # Note: $^V returns real string in perls > 5.10, and v-string in earlier perls
  #   regexp below fails in earlier perls. this is okay
  my($perl_main,$perl_minor)=$^V=~/^v(\d+)\.(\d+)/; # perl version
  if ($perl_main==5 && $perl_minor>=10) {
    my $does=DOES $class('Hash::AutoHash');
    is($does,1,'DOES: is Hash::AutoHash');
    my $does=DOES $class('UNIVERSAL');
    is($does,1,'DOES: is UNIVERSAL');
    my $does=DOES $class('not_defined');
    ok(!$does,'DOES: doesn\'t');
  }

  my $version=VERSION $class;
  my $correct=eval "\$$class"."::VERSION";
  is($version,$correct,'VERSION');

  my @imports=eval "\@$class"."::EXPORT_OK";
  import $class (@imports);
  pass('import all functions');
}

1;
