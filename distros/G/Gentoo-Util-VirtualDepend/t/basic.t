
use strict;
use warnings;

use Test::More;
use Test::File::ShareDir::Dist { 'Gentoo-Util-VirtualDepend' => 'share/' };
use Gentoo::Util::VirtualDepend;

# ABSTRACT: Test basic behaviour

my $v = Gentoo::Util::VirtualDepend->new();
ok( $v->has_module_override('ExtUtils::MakeMaker'), "Override found" );
ok( !$v->has_module_override('Moose'),        "No Override found" );
is( $v->get_module_override('ExtUtils::MakeMaker'), 'virtual/perl-ExtUtils-MakeMaker', "MAP OK" );

ok( $v->has_dist_override('ExtUtils-MakeMaker'), "Override found" );
ok( !$v->has_dist_override('Moose'),       "No Override found" );
is( $v->get_dist_override('ExtUtils-MakeMaker'), 'virtual/perl-ExtUtils-MakeMaker', "MAP OK" );

done_testing;

