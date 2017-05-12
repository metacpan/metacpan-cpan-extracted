use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::RFC5321;
use Test::More;

my $modulename = 'Haineko::SMTPD::RFC5321';
my $pkgmethods = [ 'is8bit', 'check_ehlo' ];
my $objmethods = [ '' ];
my $doublebyte = <DATA>; chomp $doublebyte;

CLASS_METHODS: {
    can_ok $modulename, @$pkgmethods;
    is $modulename->is8bit( \$doublebyte ), 1, '->is8bit('.$doublebyte.')';
    is $modulename->is8bit( \'stray cat' ), 0, '->is8bit(stray cat)';
    is $modulename->check_ehlo( 'neko.example.jp' ), 1, '->check_ehlo(neko.example.jp)';
    is $modulename->check_ehlo( '[127.0.0.1]' ), 1, '->check_ehlo([127.0.0.1])';
    is $modulename->check_ehlo( '' ), 0, '->check_ehlo()';
    is $modulename->check_ehlo( 'にゃんこ' ), 0, '->check_ehlo(にゃんこ)';
}

done_testing;
__DATA__
仲良しの地域猫、二日酔いで何かをぶちまけているわけではない。
