#!#!/usr/bin/perl
#
# Copyright (C) 2012 by Mark Hindess

use strict;
use Test::More tests => 10;

{
  package My::Onkyo;
  use base 'Device::Onkyo';
  sub write {
    my $self = shift;
    push @{$self->{_calls}}, \@_;
    1;
  }
  sub calls {
    my $self = shift;
    delete $self->{_calls};
  }
  1;
}

my $log = '/dev/null';
open my $fh, $log or die "Failed to open $log: $!\n";

my $onkyo = My::Onkyo->new(filehandle => $fh);
ok $onkyo, 'object created';

my $cb = sub {};
$onkyo->command('volume up' => $cb);
is_deeply $onkyo->calls, [['MVLUP', $cb]], '... volume up';

$onkyo->command('volume -' => $cb);
is_deeply $onkyo->calls, [['MVLDOWN', $cb]], '... volume down';

$onkyo->command('vol?' => $cb);
is_deeply $onkyo->calls, [['MVLQSTN', $cb]], '... volume query';

$onkyo->command('volume 100%' => $cb);
is_deeply $onkyo->calls, [['MVL64', $cb]], '... volume 100%';

$onkyo->command('vol10%' => $cb);
is_deeply $onkyo->calls, [['MVL0a', $cb]], '... volume 10%';

$onkyo->command('power on' => $cb);
is_deeply $onkyo->calls, [['PWR01', $cb]], '... power on';

$onkyo->command('poweroff' => $cb);
is_deeply $onkyo->calls, [['PWR00', $cb]], '... power off';

$onkyo->command('power query' => $cb);
is_deeply $onkyo->calls, [['PWRQSTN', $cb]], '... power query';

eval { $onkyo->command('power up') };
like $@, qr!^My::Onkyo->command: 'power up' does not match!, '... power error';
