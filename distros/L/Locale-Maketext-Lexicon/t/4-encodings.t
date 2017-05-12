#! /usr/bin/perl -w
# Test suite for the different encodings
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use strict;
use Test;

BEGIN {
    %ENV = ();
    plan(tests => 0), exit
	unless eval { require Encode::compat; 1 }
	    or eval { require Encode; 1 }
}
BEGIN { plan tests => 22 }

use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Different encodings
# English
# Find the default encoding
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->encoding;
};
# 1
ok($@, "");
# 2
ok($_, "US-ASCII");

# Traditional Chinese
# Find the default encoding
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->encoding;
};
# 3
ok($@, "");
# 4
ok($_, "Big5");

# Turn to Big5
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("Big5");
    $_ = $_->maketext("Hello, world!");
};
# 5
ok($@, "");
# 6
ok($_, "¤j®a¦n¡C");

# Turn to UTF-8
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("UTF-8");
    $_ = $_->maketext("Hello, world!");
};
# 7
ok($@, "");
# 8
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to UTF-16LE
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->encoding("UTF-16LE");
    $_ = $_->maketext("Hello, world!");
};
# 9
ok($@, "");
# 10
ok($_, "'Y¶[}Y0");

# Find the default encoding, in UTF-8
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_ = $_->encoding;
};
# 11
ok($@, "");
# 12
ok($_, "UTF-8");

# Turn to UTF-8
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("UTF-8");
    $_ = $_->maketext("Hello, world!");
};
# 13
ok($@, "");
# 14
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to Big5
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("Big5");
    $_ = $_->maketext("Hello, world!");
};
# 15
ok($@, "");
# 16
ok($_, "¤j®a¦n¡C");

# Turn to UTF-16LE
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("UTF-16LE");
    $_ = $_->maketext("Hello, world!");
};
# 17
ok($@, "");
# 18
ok($_, "'Y¶[}Y0");

# Find the default encoding
# Simplified Chinese
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_ = $_->encoding;
};
# 19
ok($@, "");
# 20
ok($_, "UTF-8");

# Turn to GB2312
eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test_utf8", $LOCALEDIR);
    $_->textdomain("test_utf8");
    $_->encoding("GB2312");
    $_ = $_->maketext("Hello, world!");
};
# 21
ok($@, "");
# 22
ok($_, "´ó¼ÒºÃ¡£");
