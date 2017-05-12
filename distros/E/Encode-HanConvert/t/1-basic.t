#!/usr/bin/perl -w
# $File: //member/autrijus/Encode-HanConvert/t/1-basic.t $ $Author: autrijus $
# $Revision: #4 $ $Change: 3944 $ $DateTime: 2003/01/27 23:40:39 $

use strict;
use Test;
use File::Spec;
use File::Basename;

BEGIN { plan tests => 10 }

my $path = dirname($0);

$SIG{__WARN__} = sub {};

ok(require('Encode/HanConvert.pm'));
Encode::HanConvert->import;

ok(big5_to_gb(_('daode.b5')), _('daode.gbk'));   # "big5_to_gb (function)"
ok(gb_to_big5(_('daode.gbk')), _('daode_g.b5')); # "gb_to_big5 (function)"

gb_to_big5($_ = _('zhengqi.gbk'));
ok($_, _('zhengqi.b5')); # "gb_to_big5 (inplace)"

big5_to_gb($_ = _('zhengqi.b5'));
ok($_, _('zhengqi_b.gbk')); # "big5_to_gb (inplace)"

ok(require('Encode/HanConvert/Perl.pm'));
{ local $^W; Encode::HanConvert::Perl->import }

ok(big5_to_gb(_('daode.b5')), _('daode.gbk'));   # "big5_to_gb (function)"
ok(gb_to_big5(_('daode.gbk')), _('daode_g.b5')); # "gb_to_big5 (function)"

gb_to_big5($_ = _('zhengqi.gbk'));
ok($_, _('zhengqi.b5')); # "gb_to_big5 (inplace)"

big5_to_gb($_ = _('zhengqi.b5'));
ok($_, _('zhengqi_b.gbk')); # "big5_to_gb (inplace)"

exit;
exit unless $] >= 5.006;

ok(trad_to_simp(_('daode.b5u')), _('daode.gbku'));   # "trad_to_simp (function)"
ok(simp_to_trad(_('daode.gbku')), _('daode_g.b5u')); # "simp_to_trad (function)"

simp_to_trad($_ = _('zhengqi.gbku'));
ok($_, _('zhengqi.b5u')); # "simp_to_trad (inplace)"

trad_to_simp($_ = _('zhengqi.b5u'));
ok($_, _('zhengqi_b.gbku')); # "trad_to_simp (inplace)"

sub _ { local $/; open _, File::Spec->catfile($path, $_[0]); return <_> }
