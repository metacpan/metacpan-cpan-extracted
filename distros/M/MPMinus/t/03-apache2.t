#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-apache2.t 281 2019-05-16 16:53:58Z minus $
#
#########################################################################
use Test::More;

use CTK::TFVals;
use MPMinus::Helper::Util;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 5;

my $apache = MPMinus::Helper::Util::getApache();
my ($aroot, $aconfig, $sver, $aver, $alogdir) = (
        $apache->{HTTPD_ROOT},
        $apache->{SERVER_CONFIG_FILE},
        $apache->{SERVER_VERSION},
        $apache->{APACHE_VERSION},
        $apache->{APACHE_LOG_DIR},
    );

ok(($aroot && (-e $aroot) && ((-d $aroot) || (-l $aroot))), sprintf('Root Directory: %s', uv2null($aroot)));
ok(($aconfig && (-e $aconfig) && ((-f $aconfig) || (-l $aconfig))), sprintf('Server Config File: %s', uv2null($aconfig)));
ok($sver, sprintf('Server Version: %s', uv2null($sver)));
ok(($aver && $aver > 2), sprintf('Apache Version: %s', uv2zero($aver)));
ok(($alogdir && (-e $alogdir) && ((-d $alogdir) || (-l $alogdir))), sprintf('Apache log directory: %s', uv2null($alogdir)));

#note(explain($apache));

1;
