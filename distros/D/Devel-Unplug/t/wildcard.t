use strict;
use warnings;
use Test::More tests => 5;
use File::Spec;
use Devel::Unplug;
use lib 't/lib';

# Wildcard

my $match = qr{^Some:: (?: Other:: )? Module$}x;

Devel::Unplug::unplug( $match );
eval "use Some::Module";
like $@, qr{Can't\s+locate\s+Some/Module.pm}, "error message";
eval "use Some::Other::Module";
like $@, qr{Can't\s+locate\s+Some/Other/Module.pm}, "error message";

my @unp = Devel::Unplug::unplugged();
is_deeply \@unp, [ $match ], "unplugged OK";

Devel::Unplug::insert( $match );
eval "use Some::Module";
ok !$@, "no error";
eval "use Some::Other::Module";
ok !$@, "no error";
