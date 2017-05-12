#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

use Linux::Systemd::Journal::Write;

my $jnl = Linux::Systemd::Journal::Write->new;

$jnl->print('flarg');
$jnl->print('Hello world', 4);

my %hash =
  (DAY_ONE => 'Monday', DAY_TWO => 'Tuesday', DAY_THREE => 'Wednesday');
$jnl->send('Here is a message', \%hash);

open my $fh, '<', 'nosuchfile'
  or $jnl->perror('Failed to open some fake file');
