#! /usr/bin/perl -w
# Test suite on the functional interface for switching between different settings
# Copyright (c) 2003-2008 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 63 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
delete $ENV{$_}
    foreach qw(LANGUAGE LC_ALL LC_CTYPE LC_COLLATE LC_MESSAGES LC_NUMERIC
                LC_MONETARY LC_TIME LANG);

# Switching between different settings
use File::Copy qw(copy);
use vars qw($dir1 $dir2 $dir3 $f1 $f11 $f12 $f2 $f21 $f3 $f31 $class);

# dmaketext in the middle
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    get_handle("en");
    bindtextdomain("test", $LOCALEDIR);
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test");
    $_[0] = __("Hello, world!");
    $_[1] = pmaketext("Menu|File|", "Hello, world!");
    $_[2] = __("Every story has a happy ending.");
    $_[3] = pmaketext("Menu|File|", "Every story has a happy ending.");
    $_[4] = dmaketext("test2", "Hello, world!");
    $_[5] = dpmaketext("test2", "Menu|File|", "Hello, world!");
    $_[6] = dmaketext("test2", "Every story has a happy ending.");
    $_[7] = dpmaketext("test2", "Menu|File|", "Every story has a happy ending.");
    $_[8] = __("Hello, world!");
    $_[9] = pmaketext("Menu|File|", "Hello, world!");
    $_[10] = __("Every story has a happy ending.");
    $_[11] = pmaketext("Menu|File|", "Every story has a happy ending.");
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_[0], "Hiya :)");
# 3
ok($_[1], "Hiya :) under the File menu");
# 4
ok($_[2], "Every story has a happy ending.");
# 5
ok($_[3], "Every story has a happy ending.");
# 6
ok($_[4], "Hello, world!");
# 6
ok($_[5], "Hello, world!");
# 8
ok($_[6], "Pray it.");
# 9
ok($_[7], "Pray it under the File menu");
# 10
ok($_[8], "Hiya :)");
# 11
ok($_[9], "Hiya :) under the File menu");
# 12
ok($_[10], "Every story has a happy ending.");
# 13
ok($_[11], "Every story has a happy ending.");

# Switch between domains
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    bindtextdomain("test2", $LOCALEDIR);
    get_handle("en");
    textdomain("test");
    $_[0] = __("Hello, world!");
    $_[1] = __("Every story has a happy ending.");
    textdomain("test2");
    $_[2] = __("Hello, world!");
    $_[3] = __("Every story has a happy ending.");
    textdomain("test");
    $_[4] = __("Hello, world!");
    $_[5] = __("Every story has a happy ending.");
    return 1;
};
# 14
ok($r, 1);
# 15
ok($_[0], "Hiya :)");
# 16
ok($_[1], "Every story has a happy ending.");
# 17
ok($_[2], "Hello, world!");
# 18
ok($_[3], "Pray it.");
# 19
ok($_[4], "Hiya :)");
# 20
ok($_[5], "Every story has a happy ending.");

# Switch between languages
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_[0] = __("Hello, world!");
    get_handle("zh-tw");
    $_[1] = __("Hello, world!");
    get_handle("zh-cn");
    $_[2] = __("Hello, world!");
    return 1;
};
# 21
ok($r, 1);
# 22
ok($_[0], "Hiya :)");
# 23
ok($_[1], "產");
# 24
ok($_[2], "大家好。");

# Switch between languages - by environment
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $ENV{"LANG"} = "en";
    get_handle();
    $_[0] = __("Hello, world!");
    $ENV{"LANG"} = "zh-tw";
    get_handle();
    $_[1] = __("Hello, world!");
    $ENV{"LANG"} = "zh-cn";
    get_handle();
    $_[2] = __("Hello, world!");
    return 1;
};
# 25
ok($r, 1);
# 26
ok($_[0], "Hiya :)");
# 27
ok($_[1], "產");
# 28
ok($_[2], "大家好。");

# Switch between different language methods
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_[0] = __("Hello, world!");
    $ENV{"LANG"} = "zh-tw";
    get_handle();
    $_[1] = __("Hello, world!");
    get_handle("zh-cn");
    $_[2] = __("Hello, world!");
    $ENV{"LANG"} = "en";
    get_handle();
    $_[3] = __("Hello, world!");
    return 1;
};
# 29
ok($r, 1);
# 30
ok($_[0], "Hiya :)");
# 31
ok($_[1], "產");
# 32
ok($_[2], "大家好。");
# 33
ok($_[3], "Hiya :)");

# Reuse of a same text domain class
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    $ENV{"LANG"} = "en";
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle();
    $_[0] = __("Hello, world!");
    $_[1] = __("Every story has a happy ending.");
    $_[2] = ref($Locale::Maketext::Gettext::Functions::LH);
    $_[2] =~ s/^(.+)::.*?$/$1/;
    
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test2");
    get_handle("zh-tw");
    $_[3] = __("Hello, world!");
    $_[4] = __("Every story has a happy ending.");
    
    bindtextdomain("test", "/dev/null");
    textdomain("test");
    get_handle("en");
    $_[5] = __("Hello, world!");
    $_[6] = __("Every story has a happy ending.");
    
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-cn");
    $_[7] = __("Hello, world!");
    $_[8] = __("Every story has a happy ending.");
    $_[9] = ref($Locale::Maketext::Gettext::Functions::LH);
    $_[9] =~ s/^(.+)::.*?$/$1/;
    return 1;
};
# 34
ok($r, 1);
# 35
ok($_[0], "Hiya :)");
# 36
ok($_[1], "Every story has a happy ending.");
# 37
ok($_[3], "Hello, world!");
# 38
ok($_[4], "珿ㄆ常Τ腞挡Ы");
# 39
ok($_[5], "Hello, world!");
# 40
ok($_[6], "Every story has a happy ending.");
# 41
ok($_[7], "大家好。");
# 42
ok($_[8], "Every story has a happy ending.");
# 43
ok($_[2], $_[9]);

# Language addition/removal
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    $dir1 = catdir($LOCALEDIR, "en", "LC_MESSAGES");
    $dir2 = catdir($LOCALEDIR, "zh_TW", "LC_MESSAGES");
    $dir3 = catdir($LOCALEDIR, "zh_CN", "LC_MESSAGES");
    $f1 = catfile($dir1, "test_dyn.mo");
    $f11 = catfile($dir1, "test.mo");
    $f2 = catfile($dir2, "test_dyn.mo");
    $f21 = catfile($dir2, "test.mo");
    $f3 = catfile($dir3, "test_dyn.mo");
    $f31 = catfile($dir3, "test.mo");
    unlink $f1;
    unlink $f2;
    unlink $f3;
    
    bindtextdomain("test_dyn", $LOCALEDIR);
    textdomain("test_dyn");
    get_handle("zh-tw");
    $_[0] = __("Hello, world!");
    get_handle("zh-cn");
    $_[1] = __("Hello, world!");
    
    copy $f21, $f2  or die "ERROR: $f21 $f2: $!";
    textdomain("test_dyn");
    get_handle("zh-tw");
    $_[2] = __("Hello, world!");
    get_handle("zh-cn");
    $_[3] = __("Hello, world!");
    
    unlink $f2;
    copy $f31, $f3  or die "ERROR: $f31 $f3: $!";
    textdomain("test_dyn");
    get_handle("zh-tw");
    $_[4] = __("Hello, world!");
    get_handle("zh-cn");
    $_[5] = __("Hello, world!");
    
    copy $f21, $f2  or die "ERROR: $f21 $f2: $!";
    textdomain("test_dyn");
    get_handle("zh-tw");
    $_[6] = __("Hello, world!");
    get_handle("zh-cn");
    $_[7] = __("Hello, world!");
    
    unlink $f2;
    unlink $f3;
    textdomain("test_dyn");
    get_handle("zh-tw");
    $_[8] = __("Hello, world!");
    get_handle("zh-cn");
    $_[9] = __("Hello, world!");
    
    unlink $f1;
    unlink $f2;
    unlink $f3;
    return 1;
};
# 44
ok($r, 1);
# 45
ok($_[0], "Hello, world!");
# 46
ok($_[1], "Hello, world!");
# 47
ok($_[2], "產");
# 48
ok($_[3], "Hello, world!");
# 49
ok($_[4], "Hello, world!");
# 50
ok($_[5], "大家好。");
# 51
ok($_[6], "產");
# 52
ok($_[7], "大家好。");
# 53
ok($_[8], "Hello, world!");
# 54
ok($_[9], "Hello, world!");

# Garbage collection - drop abandoned language handles
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    $dir1 = catdir($LOCALEDIR, "en", "LC_MESSAGES");
    $dir2 = catdir($LOCALEDIR, "zh_TW", "LC_MESSAGES");
    $dir3 = catdir($LOCALEDIR, "zh_CN", "LC_MESSAGES");
    $f1 = catfile($dir1, "test_dyn.mo");
    $f11 = catfile($dir1, "test.mo");
    $f2 = catfile($dir2, "test_dyn.mo");
    $f21 = catfile($dir2, "test.mo");
    $f3 = catfile($dir3, "test_dyn.mo");
    $f31 = catfile($dir3, "test.mo");
    unlink $f1;
    unlink $f2;
    unlink $f3;
    
    copy $f11, $f1  or die "ERROR: $f11 $f1: $!";
    copy $f21, $f2  or die "ERROR: $f21 $f2: $!";
    textdomain("test_dyn");
    get_handle("en");
    get_handle("zh-tw");
    get_handle("zh-cn");
    $class = ref($Locale::Maketext::Gettext::Functions::LH);
    $class =~ s/^(.+)::.*?$/$1/;
    
    unlink $f2;
    copy $f31, $f3  or die "ERROR: $f31 $f3: $!";
    textdomain("test_dyn");
    get_handle("en");
    get_handle("zh-tw");
    get_handle("zh-cn");
    @_ = grep /^$class/, keys %Locale::Maketext::Gettext::Functions::LHS;
    return 1;
};
# 55
ok($r, 1);
# 56
ok(scalar(@_), 0);

# Reload the text
$r = eval {
    $dir1 = catdir($LOCALEDIR, "en", "LC_MESSAGES");
    $f1 = catfile($dir1, "test_reload.mo");
    $f11 = catfile($dir1, "test.mo");
    $f12 = catfile($dir1, "test2.mo");
    unlink $f1;
    copy $f11, $f1  or die "ERROR: $f11 $f1: $!";
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test_reload", $LOCALEDIR);
    textdomain("test_reload");
    get_handle("en");
    $_[0] = __("Hello, world!");
    $_[1] = __("Every story has a happy ending.");
    unlink $f1;
    copy $f12, $f1  or die "ERROR: $f12 $f1: $!";
    $_[2] = __("Hello, world!");
    $_[3] = __("Every story has a happy ending.");
    reload_text;
    $_[4] = __("Hello, world!");
    $_[5] = __("Every story has a happy ending.");
    unlink $f1;
    return 1;
};
# 57
ok($r, 1);
# 58
ok($_[0], "Hiya :)");
# 59
ok($_[1], "Every story has a happy ending.");
# 60
ok($_[2], "Hiya :)");
# 61
ok($_[3], "Every story has a happy ending.");
# 62
ok($_[4], "Hello, world!");
# 63
ok($_[5], "Pray it.");

# Garbage collection
unlink catfile($LOCALEDIR, "en", "LC_MESSAGES", "test_dyn.mo");
unlink catfile($LOCALEDIR, "zh_TW", "LC_MESSAGES", "test_dyn.mo");
unlink catfile($LOCALEDIR, "zh_CN", "LC_MESSAGES", "test_dyn.mo");
unlink catfile($LOCALEDIR, "en", "LC_MESSAGES", "test_reload.mo");
