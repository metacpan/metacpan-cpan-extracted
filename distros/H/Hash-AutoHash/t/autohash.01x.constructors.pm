use lib qw(t);
use strict;
use Carp;
use Test::More;
use Exporter();
use autohashUtil;
our @ISA=qw(Exporter);
our @EXPORT=qw(test_autohash test_autohash_more test_ashash test_ashash_more
	       test_exthash test_exthash_more
	     );

sub test_autohash {
  my($label,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  for($i++; $i<@values; $i++) {
    $autohash->key1('value1'.$i);
    $autohash->key2('value2'.$i);
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  }
}
sub test_autohash_more {
  my($label,$ok_hash,$ok_object,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  for($i++; $i<@values; $i++) {
    $autohash->key1('value1'.$i);
    $autohash->key2('value2'.$i);
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  }
}

sub test_ashash {
  my($label,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  for($i++; $i<@values; $i++) {
    $autohash->{key1}='value1'.$i;
    $autohash->{key2}='value2'.$i;
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  }
}
sub test_ashash_more {
  my($label,$ok_hash,$ok_object,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  for($i++; $i<@values; $i++) {
    $autohash->{key1}='value1'.$i;
    $autohash->{key2}='value2'.$i;
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  }
}

sub test_exthash {
  my($label,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  for($i++; $i<@values; $i++) {
    $hash{key1}='value1'.$i;
    $hash{key2}='value2'.$i;
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  }
}
sub test_exthash_more {
  my($label,$ok_hash,$ok_object,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  for($i++; $i<@values; $i++) {
    $hash{key1}='value1'.$i;
    $hash{key2}='value2'.$i;
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  }
}

sub test_extobj {
  my($label,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  for($i++; $i<@values; $i++) {
    $object->STORE('key1','value1'.$i);
    $object->STORE('key2','value2'.$i);
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i]);
  }
}
sub test_extobj_more {
  my($label,$ok_hash,$ok_object,$i,@values)=@_;
  cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  for($i++; $i<@values; $i++) {
    $object->STORE('key1','value1'.$i);
    $object->STORE('key2','value2'.$i);
    cmp_autohash("$label: ".ordinal($i).' values',$values[$i],$ok_hash,$ok_object);
  }
}
1;
