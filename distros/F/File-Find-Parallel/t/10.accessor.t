#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;
use File::Find::Parallel;

ok my $ffp = File::Find::Parallel->new, 'created OK';
isa_ok $ffp, 'File::Find::Parallel';

my $any = $ffp->any_iterator;
is ref $any, 'CODE', 'iterator is code ref';
ok !$any->(), 'empty iterator';

my $all = $ffp->all_iterator;
is ref $all, 'CODE', 'iterator is code ref';
ok !$all->(), 'empty iterator';

my @dirs = ( 'a', 'b', 'c' );

$ffp->set_dirs( @dirs );
my @got = $ffp->get_dirs;
is_deeply \@got, \@dirs, 'getter, setter OK';

push @dirs, 'd';

$ffp->set_dirs( @dirs );
@got = $ffp->get_dirs;
is_deeply \@got, \@dirs, 'getter, setter OK';

my @extra  = ( 'e', 'f' );
push @dirs, @extra;
$ffp->add_dirs(@extra);
@got = $ffp->get_dirs;
is_deeply \@got, \@dirs, 'add_dirs OK';

ok my $nffp = File::Find::Parallel->new(@dirs), 'created OK';
@got = $ffp->get_dirs;
is_deeply \@got, \@dirs, 'pass dirs to constructor OK';
