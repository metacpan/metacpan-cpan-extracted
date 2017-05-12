#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@serzik.com>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-apache2.t 224 2017-04-04 10:27:41Z minus $
#
#########################################################################
use Test::More tests => 5;

use CTK::TFVals;
BEGIN { 
    use_ok('MPMinus::Helper::Util');
}

my $apache = getApache();
my ($aroot, $aconfig, $sver, $aver) = (
        $apache->{HTTPD_ROOT},
        $apache->{SERVER_CONFIG_FILE},
        $apache->{SERVER_VERSION},
        $apache->{APACHE_VERSION},
    );

ok(($aroot && (-e $aroot) && ((-d $aroot) || (-l $aroot))), sprintf('Root Directory: %s', uv2null($aroot)));
ok(($aconfig && (-e $aconfig) && ((-f $aconfig) || (-l $aconfig))), sprintf('Server Config File: %s', uv2null($aconfig)));
ok($sver, sprintf('Server Version: %s', uv2null($sver)));
ok(($aver && $aver > 2), sprintf('Apache Version: %s', uv2zero($aver)));

1;
