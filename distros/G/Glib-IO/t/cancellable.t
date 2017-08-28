#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Glib::IO;

my $cancellable = Glib::IO::Cancellable->new ();
$cancellable->connect (\&callback, [ 23, 'bla' ]);
sub callback {
  my ($data) = @_;
  local $TODO = 'FIXME: user data does not get through in this case';
  is_deeply ($data, [ 23, 'bla' ]);
}
$cancellable->cancel ();

eval { $cancellable->set_error_if_cancelled (); };
isa_ok ($@, 'Glib::IO::IOErrorEnum');
is ($@->value, 'cancelled');
