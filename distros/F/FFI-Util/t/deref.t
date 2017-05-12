use strict;
use warnings;
use Test::More tests => 2;
use FFI::Util qw( deref_ptr_set deref_ptr_get );
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc );
use Config;

subtest 'FFI::Raw' => sub {
  plan skip_all => 'subtest requires FFI::Raw' unless eval q{ use FFI::Raw; 1 };
  plan tests => 1;

  my $ptr = FFI::Raw::MemPtr->new($Config{ivsize});
  deref_ptr_set $ptr, 42;
  is deref_ptr_get($ptr), 42;

};

subtest 'FFI::Platypus' => sub {
  plan tests => 1;

  my $ffi = FFI::Platypus->new;
  my $ptr = malloc $ffi->sizeof('opaque');
  deref_ptr_set $ptr, 42;
  is deref_ptr_get($ptr), 42;

};
