#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';

use Devel::TakeHashArgs;
use Carp;

sub foos {
    get_args_as_hash(\@_, \my %args, { foos => 'bars' } )
        or croak $@;

    use Data::Dumper;
    print Dumper \%args;
}
foos(1..4);

print "Now die!\n";
foos(1..3);