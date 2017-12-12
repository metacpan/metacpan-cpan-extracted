use strict;
use Test::Lib;
use Test::More tests => 6;
use Example::LoadImp::Set;
use Mic ();

my $HashSetClass = Mic->load_class({
    interface      => 'Example::LoadImp::Set',
    implementation => 'Example::LoadImp::HashSet',
});

Mic->load_class({
    interface      => 'Example::LoadImp::Set',
    implementation => 'Example::LoadImp::ArraySet',
    name           => 'ArraySet',
});

my $a_set = 'ArraySet'->new;
ok ! $a_set->has(1);
$a_set->add(1);
ok $a_set->has(1);
is ref $a_set->[ $Example::LoadImp::ArraySet::SET ] => 'ARRAY', 'array imp';

my $h_set = $HashSetClass->new;
ok ! $h_set->has(1);
$h_set->add(1);
ok $h_set->has(1);
is ref $h_set->[ $Example::LoadImp::HashSet::SET ] => 'HASH', 'hash imp';
