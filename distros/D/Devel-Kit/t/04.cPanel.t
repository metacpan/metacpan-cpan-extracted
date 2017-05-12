use Test::More;

use vars qw($orig_o $orig_a);
use Devel::Kit;
BEGIN { $orig_o = \&Devel::Kit::o; $orig_a = \&Devel::Kit::a }
BEGIN { eval "require Cpanel::Logger;"; plan skip_all => "tests irrelevant on non-cPanel environment" if $@; }
use Devel::Kit::cPanel;

plan tests => 4;
isnt( \&Devel::Kit::o, $orig_o, 'Devel::Kit::o() is replaced' );
isnt( \&Devel::Kit::a, $orig_a, 'Devel::Kit::a() is replaced' );
my $ak = a;
isa_ok( $ak, 'App::Kit::cPanel', 'a() returns App-Kit-cPanel obj' );
is( a, $ak, 'a() returns same obj' );
