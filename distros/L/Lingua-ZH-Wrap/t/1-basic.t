#!/usr/bin/perl
# $File: //member/autrijus/Lingua-ZH-Wrap/t/1-basic.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 3684 $ $DateTime: 2003/01/20 07:15:04 $

use Test;

BEGIN { plan tests => 5 }

require Lingua::ZH::Wrap;
ok($Lingua::ZH::Wrap::VERSION) if $Lingua::ZH::Wrap::VERSION or 1;

Lingua::ZH::Wrap->import(qw(wrap $columns $overflow));
$columns = 4;
ok(wrap('', '', '進世進士盡是近視'), join("\n", qw(進世 進士 盡是 近視)));

$columns  = 3;
ok(wrap('', '', '進世進士盡是近視'), join("\n", qw(進 世 進 士 盡 是 近 視)));

$overflow = 1;
ok(wrap('', '', '進世進士盡是近視'), join("\n", qw(進世 進士 盡是 近視)));

$overflow = 0;
ok(wrap('', '', '進世進士盡是近視'), join("\n", qw(進 世 進 士 盡 是 近 視)));

1;
