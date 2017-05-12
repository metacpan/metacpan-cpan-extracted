#! /usr/bin/perl -w
# Test the big endian MO files
# Copyright (c) 2003-2009 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 10 }

use FindBin;
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r);
$LOCALEDIR = catdir($FindBin::Bin, "locale");

# Check reading big-endian PO files
use vars qw($skip $POfile $MOfile $hasctxt);
# English
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, "Hiya :)");

# Traditional Chinese
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, "¤j®a¦n¡C");

# Simplified Chinese
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-cn");
    $_->bindtextdomain("test_be", $LOCALEDIR);
    $_->textdomain("test_be");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 5
ok($r, 1);
# 6
ok($_, "´ó¼ÒºÃ¡£");

# Native-built MO file
{
my $FH;
$skip = 1;
$POfile = catfile($FindBin::Bin, "test_native.po");
$MOfile = catfile($LOCALEDIR, "en", "LC_MESSAGES", "test_native.mo");
$_ = join "", `msgfmt --version 2>&1`;
last unless $? == 0;
last unless /GNU gettext/;
last unless /GNU gettext.* (\d+)\.(\d+)/;
# Gettext from 0.15 has msgctxt
$hasctxt = $1 > 0 || ($1 == 0 && $2 >= 15);
$_ = << "EOT";
# English PO file for the test_native project.
# Copyright (C) 2003-2009 imacat
# This file is distributed under the same license as the commonlib package.
# imacat <imacat\@mail.imacat.idv.tw>, 2003-%1\$04d.
# 
msgid ""
msgstr ""
"Project-Id-Version: test_native 1.1\\n"
"Report-Msgid-Bugs-To: \\n"
"POT-Creation-Date: %1\$04d-%2\$02d-%3\$02d %4\$02d:%5\$02d+0800\\n"
"PO-Revision-Date: %1\$04d-%2\$02d-%3\$02d %4\$02d:%5\$02d+0800\\n"
"Last-Translator: imacat <imacat\@mail.imacat.idv.tw>\\n"
"Language-Team: English <imacat\@mail.imacat.idv.tw>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=US-ASCII\\n"
"Content-Transfer-Encoding: 7bit\\n"
"Plural-Forms: nplurals=2; plural=n != 1;\\n"

#: test_native.pl:100
msgid "Hello, world!"
msgstr "Hiya :)"
EOT
$_ .= << "EOT" if $hasctxt;

#: test_native.pl:103
msgctxt "Menu|File|"
msgid "Hello, world!"
msgstr "Hiya :) under the File menu"

#: test_native.pl:106
msgctxt "Menu|View|"
msgid "Hello, world!"
msgstr "Hiya :) under the View menu"
EOT
@_ = localtime;
$_[5] += 1900;
$_[4]++;
$_ = sprintf $_, @_[5,4,3,2,1,0];
open $FH, ">$POfile";
print $FH $_;
close $FH;
`msgfmt -o "$MOfile" "$POfile"`;
last unless $? == 0;
$skip = 0;
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test_native", $LOCALEDIR);
    $_->textdomain("test_native");
    $_[0] = $_->maketext("Hello, world!");
    $_[1] = $_->pmaketext("Menu|File|", "Hello, world!") if $hasctxt;
    $_[2] = $_->pmaketext("Menu|View|", "Hello, world!") if $hasctxt;
    return 1;
};
}
# 7
skip($skip, $r, 1);
# 8
skip($skip, $_[0], "Hiya :)");
# 9
skip($skip || !$hasctxt, $_[1], "Hiya :) under the File menu");
# 10
skip($skip || !$hasctxt, $_[2], "Hiya :) under the View menu");

# Garbage collection
unlink $POfile;
unlink $MOfile;
