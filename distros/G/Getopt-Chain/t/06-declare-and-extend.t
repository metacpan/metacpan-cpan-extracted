#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

our @did;

package My::Command;

use Getopt::Chain::Declare;

no Getopt::Chain::Declare;

package My::Command::Help;

use Getopt::Chain::Declare::under 'help';

on '' => undef, sub {
    push @did, [qw/ help /];
};

no Getopt::Chain::Declare::under;

package My::Command::Fruit;

use Getopt::Chain::Declare::under [ [qw/ apple banana /] ];

on '' => undef, sub {
    push @did, [qw/ fruit /];
};

no Getopt::Chain::Declare::under;

package main;

my $options;

sub run {
    undef @did;
    $options = My::Command->new->run( [ @_ ] );
}

run qw//;
cmp_deeply( \@did, [ ] );

run qw/help/;
cmp_deeply( \@did, [ [qw/ help /] ] );

run qw/apple/;
cmp_deeply( \@did, [ [qw/ fruit /] ] );

run qw/banana/;
cmp_deeply( \@did, [ [qw/ fruit /] ] );
