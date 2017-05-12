#! /usr/bin/perl -w
# Basic test suite for the functional interface
# Copyright (c) 2003-2008 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 41 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
delete $ENV{$_}
    foreach qw(LANGUAGE LC_ALL LC_CTYPE LC_COLLATE LC_MESSAGES LC_NUMERIC
                LC_MONETARY LC_TIME LANG);

# Basic test suite
# bindtextdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    $_ = bindtextdomain("test", $LOCALEDIR);
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, $LOCALEDIR);

# textdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    $_ = textdomain("test");
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, "test");

# get_handle
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    return 1;
};
# 5
ok($r, 1);

# maketext
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = maketext("Hello, world!");
    return 1;
};
# 6
ok($r, 1);
# 7
ok($_, "Hiya :)");

# __ (shortcut to maketext)
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("Hello, world!");
    return 1;
};
# 8
ok($r, 1);
# 9
ok($_, "Hiya :)");

# N_ (do nothing)
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!");
    return 1;
};
# 10
ok($r, 1);
# 11
ok($_, "Hello, world!");

# N_ (do nothing)
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    # ゅ硂采﹁ナ :p From: 芖臨艵
    @_ = N_("Hello, world!", "Cool!", "Big watermelon");
    return 1;
};
# 12
ok($r, 1);
# 13
ok($_[0], "Hello, world!");
# 14
ok($_[1], "Cool!");
# 15
ok($_[2], "Big watermelon");

$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!");
    return 1;
};
# 16
ok($r, 1);
# 17
ok($_, "Hello, world!");

# maketext
# English
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_[0] = __("Hello, world!");
    $_[1] = pmaketext("Menu|File|", "Hello, world!");
    $_[2] = pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 18
ok($r, 1);
# 19
ok($_[0], "Hiya :)");
# 20
ok($_[1], "Hiya :) under the File menu");
# 21
ok($_[2], "Hiya :) under the View menu");

# Traditional Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    $_[0] = __("Hello, world!");
    $_[1] = pmaketext("Menu|File|", "Hello, world!");
    $_[2] = pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 22
ok($r, 1);
# 23
ok($_[0], "產");
# 24
ok($_[1], "郎匡虫產");
# 25
ok($_[2], "聅凝匡虫產");

# Simplified Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-cn");
    $_[0] = __("Hello, world!");
    $_[1] = pmaketext("Menu|File|", "Hello, world!");
    $_[2] = pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 26
ok($r, 1);
# 27
ok($_[0], "大家好。");
# 28
ok($_[1], "档案菜单下的大家好。");
# 29
ok($_[2], "浏览菜单下的大家好。");

# maketext - by environment
# English
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "en";
    get_handle();
    $_[0] = __("Hello, world!");
    $_[1] = pmaketext("Menu|File|", "Hello, world!");
    $_[2] = pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 30
ok($r, 1);
# 31
ok($_[0], "Hiya :)");
# 32
ok($_[1], "Hiya :) under the File menu");
# 33
ok($_[2], "Hiya :) under the View menu");

# Traditional Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "zh-tw";
    get_handle();
    $_[0] = __("Hello, world!");
    $_[1] = pmaketext("Menu|File|", "Hello, world!");
    $_[2] = pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 34
ok($r, 1);
# 35
ok($_[0], "產");
# 36
ok($_[1], "郎匡虫產");
# 37
ok($_[2], "聅凝匡虫產");

# Simplified Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "zh-cn";
    get_handle();
    $_[0] = __("Hello, world!");
    $_[1] = pmaketext("Menu|File|", "Hello, world!");
    $_[2] = pmaketext("Menu|View|", "Hello, world!");
    return 1;
};
# 38
ok($r, 1);
# 39
ok($_[0], "大家好。");
# 40
ok($_[1], "档案菜单下的大家好。");
# 41
ok($_[2], "浏览菜单下的大家好。");
