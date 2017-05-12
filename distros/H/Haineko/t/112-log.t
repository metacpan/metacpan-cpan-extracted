use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::Log;
use Test::More;

my $modulename = 'Haineko::Log';
my $pkgmethods = [ 'new' ];
my $objmethods = [ 'o', 'h', 'w' ];
my $testobject = Haineko::Log->new;

can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;
isa_ok $testobject, $modulename;

my $v = { 'queueid' => 'neko', 'remoteaddr' => '127.0.0.1' };
my $o = Haineko::Log->new( %$v );

is $o->queueid, 'neko', '->queueid => neko';
is $o->remoteaddr, '127.0.0.1', '->remoteaddr => 127.0.0.1';
is $o->remoteport, '', '->remoteport => ""';
is $o->useragent, '', '->useragent => ""';
is $o->facility, 'local2', '->facilicy => local2';
is $o->loglevel, 'info', '->loglevel => info';
is $o->identity, 'haineko', '->identity => haineko';

is $o->o, '', '->o => '.$o->o;
like $o->h, qr/queueid=neko, client=127/, '->h => '.$o->h;

done_testing;
__END__
