#!/usr/bin/perl
use strict;
use warnings;
use Glib;
use Tie::Hash;
use Test::More tests => 1;

tie my %hash, 'Tie::StdHash';

my $pspec = Glib::ParamSpec->boxed('t', 't', 't',
                                   'Glib::Scalar', [qw/writable readable/]);
$hash{flags} = $pspec->get_flags;
ok (eval {
      Glib::ParamSpec->boxed('t', 't', 't',
                             'Glib::Scalar', $hash{flags});
      1
    });
