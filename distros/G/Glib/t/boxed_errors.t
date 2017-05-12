#!/usr/bin/perl

# Test the GBoxed wrapper for GError.

use strict;
use warnings;
use Test::More;
use Glib ':constants';

if (Glib->CHECK_VERSION (2, 26, 0)) {
  plan tests => 5;
} else {
  plan skip_all => 'new in 2.26';
}

Glib::Type->register_object (
  'Glib::Object',
  'Foo',
  signals => {
    throw => {
      param_types => [qw(Glib::Error)],
    },
  },
);

my $foo = Glib::Object::new ('Foo');
$foo->signal_connect (throw => \&throw_handler, 23);
$foo->signal_emit ('throw', Glib::File::Error->new ('io', 'End of file reached'));

sub throw_handler {
  my ($instance, $error, $data) = @_;
  is ($instance, $foo);
  is ($data, 23);

  isa_ok ($error, 'Glib::File::Error');
  is ($error->value, 'io');
  is ($error->message, 'End of file reached');
}
