# perl-test
# $Id: 02-extmagic.t,v 1.3 2003/11/21 02:25:52 knok Exp $

use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("File::MMagic::XS", qw(:compat));
}

my $magic = File::MMagic::XS->new();
$magic->addMagicEntry("0\tstring\t#\\ perl-test\tapplication/x-perl-test");
my $ret = $magic->checktype_filename(__FILE__);
is($ret, 'application/x-perl-test');
