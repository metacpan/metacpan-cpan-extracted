package recordUtil;
use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Exporter();
use Hash::AutoHash::Record;
use Hash::AutoHash::AVPairsSingle;
use Hash::AutoHash::AVPairsMulti;
use autohashUtil;

our @ISA=qw(Exporter);
our @EXPORT=qw(cmp_record _cmp_record new_SV new_MV new_Nested 
	       test_class_methods @COMMON_SPECIAL_KEYS $VERBOSE);

# test contents of wrapper and external hash or object
sub cmp_record {
  my $pass=_cmp_record(@_);
  pass($_[0]) if $pass && !$VERBOSE; # print if all tests passed and tests didn't print passes
  $pass;
}

# based on _cmp_mvhash from mvhashUtil
sub _cmp_record {
  my($label,$actual,$correct,$hash,$object,$chk_defaults_types,$chk_defaults)=@_;
  my($ok_hash,$ok_object);           
  my $ok_hash=defined $hash;         # for _cmp_autohash
  $object or $object=tied %$actual;
  my $ok_object=defined $object;     # for _cmp_autohash. always true
  my $pass=_cmp_autohash($label,$actual,$correct,$ok_hash,$ok_object,$hash,$object);
  return unless $pass;		     # short circuit if already failed

  # tests not covered by cmp_autohash
  # (1) access of multi-valued fields via methods in array context
  # (2) types of defaults (for specially named fields only)
  # (3) defaults (for specially named fields only)
  $label.=' via methods in array context';
  my(@ok,@fail);
  for my $key (keys %$correct) {
    my @actual_val=$actual->$key;
    my $correct_val=$correct->{$key};
    next unless 'ARRAY' eq ref $correct_val;
    eq_deeply(\@actual_val,$correct_val)? push(@ok,$key): push(@fail,$key);
  }
  $pass&&=_report($label,@ok,@fail);
  if ($pass && $chk_defaults_types) {
    $label=' types of defaults';
    my %defaults=tied(%$actual)->defaults;
    my(@ok,@fail);
    while(my($key,$value)=each %defaults) {
      my $correct_type=$key=~/^single/ ? undef
	: $key=~/^multi/ ? 'ARRAY'
	  : $key=~/^avp_single/ ? 'Hash::AutoHash::AVPairsSingle'
	    : $key=~/^avp_multi/ ? 'Hash::AutoHash::AVPairsMulti'
	      : $key=~/^nested/ ? 'Hash::AutoHash::Record'
		: $key=~/^hash_normal/ ? 'HASH'
		  : $key=~/^hash_workaround/ ? 'main'
		    : $key=~/^refhash/ ? 'REF'
		      : next;
      my $actual_type=ref $value;
      $actual_type eq $correct_type? push(@ok,$key): push(@fail,$key);
    }
  $pass&&=_report($label,@ok,@fail);
  }
  if ($pass && $chk_defaults) {
    $label=' defaults';
    my %defaults=tied(%$actual)->defaults;
    my(@ok,@fail);
    while(my($key,$actual_default)=each %defaults) {
      my $correct_default=$key=~/^single/ ? ''
	: $key=~/^multi/ ? []
	  : $key=~/^avp_single/ ? new_SV()
	    : $key=~/^avp_multi/ ? new_MV()
	      : $key=~/^nested/ ? new_Nested()
		: $key=~/^hash_normal/ ? {}
		  : $key=~/^hash_workaround/ ? bless {}
		    : $key=~/^refhash/ ? \bless {}
		      : next;
      eq_deeply($actual_default,$correct_default)? push(@ok,$key): push(@fail,$key);
    }
    $pass&&=_report($label,@ok,@fail);
  }
  $pass;
}
sub new_SV {
  new Hash::AutoHash::AVPairsSingle @_;
}
sub new_MV {
  new Hash::AutoHash::AVPairsMulti @_;
}
sub new_Nested {
  new Hash::AutoHash::Record @_;
}
1;
