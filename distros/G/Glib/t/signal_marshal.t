#!perl
package MyClass;
use strict;
use warnings;
use Glib;

use Glib::Object::Subclass
  'Glib::Object',
  signals => { mysig => { param_types => [],
                          return_type => undef },
             };

sub INIT_INSTANCE {
  my ($self) = @_;
}

sub do_mysig {
  return 123;
}


package MySubClass;
use strict;
use warnings;
use Glib;

use Glib::Object::Subclass
  'MyClass',
  signals => { mysig => \&_do_mysubclass_mysig };

sub INIT_INSTANCE {
  my ($self) = @_;
}

our $MYSIG_RUNS = 0;

sub _do_mysubclass_mysig {
  my ($self) = @_;
  $self->signal_chain_from_overridden;
  $MYSIG_RUNS++;
}


package main;
use strict;
use warnings;
use Glib;
use Test::More tests => 1;

my $obj = MySubClass->new;
$obj->signal_emit ('mysig');

is($MySubClass::MYSIG_RUNS, 1,
   'marshaling a signal with no return type');
