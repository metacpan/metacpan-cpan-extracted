#!/usr/bin/perl

package main;
use strict;
use warnings;
use Test::More tests => 1;

#------------------------------------------------------------------------------

package MaiTai;
use strict;
use warnings;

sub TIESCALAR {
  my ($class) = @_;
  return bless {}, $class;
}

my $mai_tai_store_called;

sub STORE {
  my ($self) = @_;
  $mai_tai_store_called = 1;
}

#------------------------------------------------------------------------------

package MyObject;
use strict;
use warnings;
use Glib;

use Glib::Object::Subclass
  Glib::Object::,
  properties => [ Glib::ParamSpec->int ('myprop',
                                        'myprop',
                                        'Blurb',
                                        0, 100,
                                        0,
                                        [qw/writable readable/]),
                ];

sub INIT_INSTANCE {
  my $self = shift;
  tie $self->{'myprop'}, 'MaiTai';
}

#------------------------------------------------------------------------------

package main;
my $obj = MyObject->new;

$mai_tai_store_called = 0;
$obj->set (myprop => 50);
is ($mai_tai_store_called, 1,
    'MaiTai tied store function called');

exit 0;
