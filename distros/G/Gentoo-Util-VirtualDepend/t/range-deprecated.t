
use strict;
use warnings;

use Test::More;
use Test::File::ShareDir::Dist { 'Gentoo-Util-VirtualDepend' => 'share/' };
use Gentoo::Util::VirtualDepend;

# ABSTRACT: Test basic behaviour

my $v = Gentoo::Util::VirtualDepend->new();

ok( !$v->has_module_override('Module::Pluggable'), "Module::Pluggable has no override" );

sub isperl {
  my ( $min, $max, $module, $version ) = @_;
  return $v->module_is_perl( { min_perl => $min, max_perl => $max }, $module, $version );
}

ok( isperl( '5.17.6', '5.17.7', 'Module::Pluggable' ), "Module::Pluggable is perl up to 5.17.7" );
ok( !isperl( '5.17.6', '5.17.9', 'Module::Pluggable' ), "Module::Pluggable is non-perl past 5.17.9" );
ok( !isperl( '5.17.9', '5.17.9', 'Module::Pluggable' ), "Module::Pluggable is non-perl exclusively on 5.17.9" );
ok( !isperl( '5.18.3', '5.18.4', 'Module::Pluggable' ), "Module::Pluggable is non-perl up to 5.18.4" );
ok( !isperl( '5.18.4', '5.19.0', 'Module::Pluggable' ), "Module::Pluggable is non-perl up to 5.19.0" );
ok( !isperl( '5.18.4', '5.19.1', 'Module::Pluggable' ), "Module::Pluggable is non-perl up to 5.19.1" );
ok( !isperl( '5.19.0', '5.19.1', 'Module::Pluggable' ), "Module::Pluggable is non-perl after 5.19.0" );

ok( !$v->has_module_override('strict'), "strict has no override" );
ok( isperl( '5.018000', '5.020002', 'strict' ), "strict is perl" );
ok( $v->module_is_perl('strict'), "strict is perl" );
ok( !$v->module_is_perl( 'strict', 9999.99 ), "strict 9999 triggers USE CPAN " );

done_testing;

