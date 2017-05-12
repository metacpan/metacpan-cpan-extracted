# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 11 };
use strict;
use Devel::Malloc;

sub malloc_free_test {
  my ($size) = @_;

  my $address = _malloc($size);
  if ($address)
  {
        _free($address);
        return 1;
  } else {
        return 0; 
  }
}

sub malloc_memset_test {
  my ($str) = @_;

  my $address = _malloc(length($str));
  if ($address)
  {
        my $address2 = _memset($address, $str, length($str));
        _free($address);
        return $address == $address2;
  } else {
        return 0;
  }
}

sub malloc_memget_test {
  my ($str) = @_;

  my $address = _malloc(length($str));
  if ($address)
  {
        _memset($address, $str, length($str));
        my $str2 = _memget($address, length($str));
        _free($address);
        return $str eq $str2;
  } else {
        return 0;
  }
}

sub malloc_memget_nolen_test {
  my ($str) = @_;

  my $address = _malloc(length($str));
  if ($address)
  {
        _memset($address, $str);
        my $str2 = _memget($address, length($str));
        _free($address);
        return $str eq $str2;
  } else {
        return 0;
  }
}

sub sync_load_store_sv_test {
  my ($str) = @_;
  
  my $address = _malloc(8);
  if ($address)
  {
	__sync_store_sv($address, $str, 8);
	my $str2 = __sync_load_sv($address, 8);
	_free($address);
	return $str eq $str2;
  } else {
	return 0;
  }
}

sub sync_load_store_less_sv_test {
  my ($str) = @_;
  
  my $address = _malloc(8);
  if ($address)
  {
	__sync_store_sv($address, $str, 8);
	my $str2 = __sync_load_sv($address, 8);
	_free($address);
	return $str eq substr($str2, 0, length($str));
  } else {
	return 0;
  }
}


sub sync_load_store_sv_test2 {
  my ($wrong, $well) = @_;
  
  my $address = _malloc(8);
  if ($address)
  {
	__sync_store_sv($address, $wrong, 8);
	__sync_store_sv($address, $well, 8);
	my $str2 = __sync_load_sv($address, 8);
	_free($address);
	return $well eq $str2;
  } else {
	return 0;
  }
}

sub sync_load_store_less_sv_test2 {
  my ($str) = @_;
  
  my $address = _malloc(8);
  if ($address)
  {
	__sync_store_sv($address, $str, length($str));
	my $str2 = __sync_load_sv($address, length($str));
	_free($address);
	return $str eq $str2;
  } else {
	return 0;
  }
}


sub sync_load_store_less_sv_nosize_test3 {
  my ($str) = @_;
  
  my $address = _malloc(8);
  if ($address)
  {
	__sync_store_sv($address, $str);
	my $str2 = __sync_load_sv($address, length($str));
	_free($address);
	return $str eq $str2;
  } else {
	return 0;
  }
}

sub sync_add_and_fetch {
 my ($val) = @_;
 
 my $address = _malloc(4);
 if ($address)
 {
	__sync_and_and_fetch($address, 0, 4);
	__sync_or_and_fetch($address, $val, 4);
	my $val2 = __sync_add_and_fetch($address, 1, 4);
	_free($address);
	return $val+1 == $val2;
 } else {
	return 0;
 }
} 

sub mutex_test {
 my $loops = @_;
 
 my $address = _malloc(1);
 if ($address)
 {
	# mutex init
	__sync_and_and_fetch($address, 0, 1);
	
	for (1..$loops)
	{
	    # lock
	    while (__sync_lock_test_and_set($address, 1, 1) == 1) { }
	
	    # critical section here
	
	    # unlock
	    __sync_lock_release($address, 1);
	}
	
	# free
	_free($address);
	return 1;
 } else {
	return 0;
 }
}

# 1
ok(malloc_free_test(1024));
ok(malloc_memset_test("test"));
ok(malloc_memget_test("test2"));
ok(malloc_memget_nolen_test("test3"));
ok(sync_load_store_sv_test("12345678"));
ok(sync_load_store_less_sv_test("12345"));
ok(sync_load_store_less_sv_test2("12345"));
ok(sync_load_store_less_sv_nosize_test3("12345"));
ok(sync_load_store_sv_test2("11111111","12345678"));
ok(sync_add_and_fetch(12345678));
ok(mutex_test(10));
