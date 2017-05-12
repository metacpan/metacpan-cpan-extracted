#! /usr/bin/perl -w
# Basic test suite
# Copyright (c) 2003-2008 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 22 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Basic test suite
use Encode qw(decode);
use vars qw($META $n $k1 $k2 $s1 $s2);

# bindtextdomain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_ = $_->bindtextdomain("test");
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, "$LOCALEDIR");

# textdomain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->textdomain;
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, "test");

# read_mo
$META = << "EOT";
Project-Id-Version: test 1.1
Report-Msgid-Bugs-To: 
POT-Creation-Date: 2008-02-19 12:31+0800
PO-Revision-Date: 2008-02-19 12:31+0800
Last-Translator: imacat <imacat\@mail.imacat.idv.tw>
Language-Team: English <imacat\@mail.imacat.idv.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: 7bit
Plural-Forms: nplurals=2; plural=n != 1;
EOT
$r = eval {
    use Locale::Maketext::Gettext;
    $_ = catfile($LOCALEDIR, "en", "LC_MESSAGES", "test.mo");
    %_ = read_mo($_);
    @_ = sort keys %_;
    $n = scalar(@_);
    $k1 = $_[0];
    $k2 = $_[1];
    $s1 = $_{$k1};
    $s2 = $_{$k2};
    return 1;
};
# 5
ok($r, 1);
# 6
ok($n, 4);
# 7
ok($k1, "");
# 8
ok($k2, "Hello, world!");
# 9
ok($s1, $META);
# 10
ok($s2, "Hiya :)");

# English
$r = eval {
    require T_L10N;
    @_ = qw();
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_[0] = $_->maketext("Hello, world!");
    $_[1] = $_->pmaketext("Menu|File|", "Hello, world!");
    $_[2] = $_->pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 11
ok($r, 1);
# 12
ok($_[0], "Hiya :)");
# 13
ok($_[1], "Hiya :) under the File menu");
# 14
ok($_[2], "Hiya :) under the View menu");

# Traditional Chinese
$r = eval {
    require T_L10N;
    @_ = qw();
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_[0] = $_->maketext("Hello, world!");
    $_[1] = $_->pmaketext("Menu|File|", "Hello, world!");
    $_[2] = $_->pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 15
ok($r, 1);
# 16
ok($_[0], "產");
# 17
ok($_[1], "郎匡虫產");
# 18
ok($_[2], "聅凝匡虫產");

# Simplified Chinese
$r = eval {
    require T_L10N;
    @_ = qw();
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_[0] = $_->maketext("Hello, world!");
    $_[1] = $_->pmaketext("Menu|File|", "Hello, world!");
    $_[2] = $_->pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 19
ok($r, 1);
# 20
ok($_[0], "大家好。");
# 21
ok($_[1], "档案菜单下的大家好。");
# 22
ok($_[2], "浏览菜单下的大家好。");
