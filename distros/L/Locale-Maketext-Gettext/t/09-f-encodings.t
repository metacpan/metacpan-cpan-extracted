#! /usr/bin/perl -w
# Test suite on the functional interface for different encodings
# Copyright (c) 2003-2007 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 34 }

use Encode qw();
use FindBin;
use File::Spec::Functions qw(catdir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Different encodings
# English
# Find the default encoding
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = encoding();
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, "US-ASCII");

# Traditional Chinese
# Find the default encoding
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    $_ = encoding();
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, "Big5");

# Turn to Big5
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding("Big5");
    $_ = maketext("Hello, world!");
    return 1;
};
# 5
ok($r, 1);
# 6
ok($_, "¤j®a¦n¡C");

# Turn to UTF-8
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding("UTF-8");
    $_ = maketext("Hello, world!");
    return 1;
};
# 7
ok($r, 1);
# 8
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to UTF-16LE
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding("UTF-16LE");
    $_ = maketext("Hello, world!");
    return 1;
};
# 9
ok($r, 1);
# 10
ok($_, "'Y¶[}Y0");

# Find the default encoding, in UTF-8
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    $_ = encoding();
    return 1;
};
# 11
ok($r, 1);
# 12
ok($_, "UTF-8");

# Turn to UTF-8
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    encoding("UTF-8");
    $_ = maketext("Hello, world!");
    return 1;
};
# 13
ok($r, 1);
# 14
ok($_, "å¤§å®¶å¥½ã€‚");

# Turn to Big5
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    encoding("Big5");
    $_ = maketext("Hello, world!");
    return 1;
};
# 15
ok($r, 1);
# 16
ok($_, "¤j®a¦n¡C");

# Turn to UTF-16LE
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-tw");
    encoding("UTF-16LE");
    $_ = maketext("Hello, world!");
    return 1;
};
# 17
ok($r, 1);
# 18
ok($_, "'Y¶[}Y0");

# Find the default encoding
# Simplified Chinese
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-cn");
    $_ = encoding();
    return 1;
};
# 19
ok($r, 1);
# 20
ok($_, "UTF-8");

# Turn to GB2312
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test_utf8", $LOCALEDIR);
    textdomain("test_utf8");
    get_handle("zh-cn");
    encoding("GB2312");
    $_ = maketext("Hello, world!");
    return 1;
};
# 21
ok($r, 1);
# 22
ok($_, "´ó¼ÒºÃ¡£");

# Encode failure
# FB_DEFAULT
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test2");
    get_handle("zh-tw");
    encoding("GB2312");
    $_ = maketext("Every story has a happy ending.");
    return 1;
};
# 23
ok($r, 1);
# 24
ok($_, "¹ÊÊÂ¶¼ÓÐÃÀ?µÄ?¾Ö¡£");

# FB_CROAK
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test2");
    get_handle("zh-tw");
    encoding("GB2312");
    encode_failure(Encode::FB_CROAK);
    $_ = maketext("Every story has a happy ending.");
    return 1;
};
# 25
ok($r, undef);
# 26
ok($@, qr/does not map to/);

# FB_HTMLCREF
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test2", $LOCALEDIR);
    textdomain("test2");
    get_handle("zh-tw");
    encoding("GB2312");
    encode_failure(Encode::FB_HTMLCREF);
    $_ = maketext("Every story has a happy ending.");
    return 1;
};
# 27
ok($r, 1);
# 28
ok($_, "¹ÊÊÂ¶¼ÓÐÃÀ&#40599;µÄ&#32080;¾Ö¡£");

# Return the unencoded UTF-8 text
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding(undef);
    $_ = maketext("Hello, world!");
    return 1;
};
# 29
ok($r, 1);
# 30
ok($_, "\x{5927}\x{5BB6}\x{597D}\x{3002}");
# 31
ok((Encode::is_utf8($_)? "utf8": "non-utf8"), "utf8");

# Return the unencoded UTF-8 text with auto lexicon
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    encoding(undef);
    $_ = maketext("Big watermelon");
    return 1;
};
# 32
ok($r, 1);
# 33
ok($_, "Big watermelon");
# 34
ok((Encode::is_utf8($_)? "utf8": "non-utf8"), "utf8");
