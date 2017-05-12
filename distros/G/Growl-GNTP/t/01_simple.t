#!perl -w

use strict;
use Test::More tests => 1;

use Growl::GNTP;

SKIP: {
  eval {
    my $g = Growl::GNTP->new( AppName => 'growl-gntp' );
    $g->register([{Name => 'foo'}, {Name => 'bar'}]);
    $g->notify(Title => 'bar', Message => 'タイトル2');
  } or warn $@;
};

pass;
