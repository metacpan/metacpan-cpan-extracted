use strict;
use warnings;
use Test::More tests => 4;
use File::Spec;
use Devel::Unplug::OO;
use lib 't/lib';

my $unp = Devel::Unplug::OO->new( 'Some::Module' );
eval "use Some::Module";
like $@, qr{Can't\s+locate\s+Some/Module.pm}, "error message";

eval "use Some::Other::Module";
ok !$@, "no error";

my @unp = Devel::Unplug::unplugged();
is_deeply \@unp, ['Some::Module'], "unplugged";

undef $unp;
eval "use Some::Module";
ok !$@, "no error" or diag $@;
