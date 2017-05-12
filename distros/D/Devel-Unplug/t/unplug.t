use strict;
use warnings;
use Test::More tests => 5;
use File::Spec;
use Devel::Unplug;
use lib 't/lib';

Devel::Unplug::unplug( 'Some::Module' );
eval "use Some::Module";
like $@, qr{Can't\s+locate\s+Some/Module.pm}, "error message";

eval "use Some::Other::Module";
ok !$@, "no error";

my @unp = Devel::Unplug::unplugged();
is_deeply \@unp, ['Some::Module'], "unplugged";

Devel::Unplug::insert( 'Some::Module::That::Was::Not::Unplugged' );
is_deeply \@unp, ['Some::Module'], "unplugged";

Devel::Unplug::insert( 'Some::Module' );
eval "use Some::Module";
ok !$@, "no error" or diag $@;
