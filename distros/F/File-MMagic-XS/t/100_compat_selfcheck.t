# perl-test
# $Id: 01-selfcheck.t,v 1.2 2003/11/21 02:25:52 knok Exp $

use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("File::MMagic::XS", qw(:compat));
}

my $magic = File::MMagic::XS->new();
my $ret = $magic->checktype_filename(__FILE__);
is($ret, 'text/plain', "mime should be 'text/plain'. got $ret");
